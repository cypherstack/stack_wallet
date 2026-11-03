import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera_linux/camera_linux.dart';
import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_device.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as img;

import '../../notifications/show_flush_bar.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/camera_preview_frame.dart';
import '../../utilities/logger.dart';
import '../../utilities/qr_image_decoder.dart';
import '../../utilities/text_styles.dart';
import 'desktop_dialog.dart';
import 'desktop_dialog_close_button.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

class QrCodeScannerDialog extends StatefulWidget {
  const QrCodeScannerDialog({super.key});

  @override
  State<QrCodeScannerDialog> createState() => _QrCodeScannerDialogState();
}

class _QrCodeScannerDialogState extends State<QrCodeScannerDialog> {
  // Created in _initializeCamera: the constructor loads libcamera_linux.so
  // and throws if it can't.
  CameraLinux? _cameraLinuxPlugin;
  final CameraWindows? _cameraWindowsPlugin = Platform.isWindows
      ? CameraWindows()
      : null;
  bool _isCameraOpen = false;
  Image? _image;
  bool _isScanning = false;
  int _cameraId = -1;
  String? _macOSDeviceId;
  final int _imageDelayInMs = Platform.isLinux ? 500 : 250;
  int _consecutiveFailures = 0;
  // Time since the last usable frame, to notice a camera that opened but
  // stopped (or never started) returning images.
  final Stopwatch _sinceLastFrame = Stopwatch();
  static const _frameTimeout = Duration(seconds: 10);
  String? _cameraError;
  String? _initError;

  // On Windows we scan what the preview shows rather than calling
  // takePicture(), which always saves a JPEG to the user's Pictures folder.
  final GlobalKey _windowsPreviewKey = GlobalKey();
  Size? _windowsPreviewSize;
  bool _loggedBlankWindowsFrame = false;
  bool _hasWindowsFrame = false;
  // camera_windows keeps showing the last frame after the capture engine
  // fails, and toImage() keeps returning it. The fingerprint tells a new
  // frame from a repeat; the error event tells us the camera is gone at once.
  int? _lastWindowsFrameFingerprint;
  bool _loggedRepeatedWindowsFrame = false;
  bool _windowsCameraLost = false;
  StreamSubscription<CameraErrorEvent>? _windowsErrorSub;
  bool _cameraStopped = false;

  @override
  void initState() {
    super.initState();

    _initializeCamera().then((camOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && camOpen) {
          setState(() {
            _isCameraOpen = true;
          });
          unawaited(_captureAndScanImage());
        } else if (mounted) {
          setState(() {
            _cameraError =
                "Unable to open the camera"
                "${_initError == null ? "" : " ($_initError)"}. You can "
                "still use \"Select file\" to scan a QR code image.";
          });
        }
      });
    });
  }

  Future<bool> _initializeCamera() async {
    try {
      if (Platform.isLinux) {
        final plugin = _cameraLinuxPlugin = CameraLinux();
        // This only starts a capture thread. If OpenCV can't open a camera
        // the thread just exits, and captureImage() keeps returning nothing,
        // so wait for a first frame before calling the camera open.
        await plugin.initializeCamera();
        if (!await _waitForFirstLinuxFrame(plugin)) {
          plugin.stopCamera();
          if (!mounted) return false;
          throw TimeoutException("No image from the camera", _frameTimeout);
        }
        Logging.instance.d("Linux Camera initialized");
      } else if (Platform.isWindows && _cameraWindowsPlugin != null) {
        final List<CameraDescription> cameras = await _cameraWindowsPlugin
            .availableCameras();
        if (cameras.isEmpty) {
          throw CameraException('No cameras available', 'No cameras found.');
        }
        Logging.instance.d(
          "Windows cameras: ${cameras.map((c) => c.name).toList()}",
        );
        // Try anything that looks like an IR camera last.
        final irName = RegExp(r'\bIR\b|infrared', caseSensitive: false);
        final ordered = [
          ...cameras.where((c) => !irName.hasMatch(c.name)),
          ...cameras.where((c) => irName.hasMatch(c.name)),
        ];

        // initializeCamera() starts the preview, and camera_windows picks the
        // preview mode as the largest one with height <= the preset cap
        // (low = 240, medium = 480, max = none) at >= 15 fps. If no mode fits,
        // it fails with "Failed to initialize video preview". We scan the
        // preview, so this also sets the scan resolution. fps and
        // videoBitrate only apply to video recording, so leave them out.
        CameraException? lastError;
        bool opened = false;
        for (final camera in ordered) {
          for (final preset in [
            ResolutionPreset.medium,
            ResolutionPreset.max,
          ]) {
            if (!mounted) return false;
            try {
              _cameraId = await _cameraWindowsPlugin.createCameraWithSettings(
                camera,
                MediaSettings(resolutionPreset: preset, enableAudio: false),
              );
              // The plugin reports the preview size through this event,
              // which it adds before initializeCamera() returns.
              final initialized = _cameraWindowsPlugin
                  .onCameraInitialized(_cameraId)
                  .first;
              await _cameraWindowsPlugin.initializeCamera(_cameraId);
              final event = await initialized;
              _windowsPreviewSize = Size(
                event.previewWidth,
                event.previewHeight,
              );
              opened = true;
              break;
            } on CameraException catch (e) {
              lastError = e;
              Logging.instance.w(
                "Windows camera ${camera.name} failed with $preset",
                error: e,
              );
              if (_cameraId >= 0) {
                await _cameraWindowsPlugin.dispose(_cameraId);
                _cameraId = -1;
              }
            }
          }
          if (opened) break;
        }
        if (!opened) {
          throw lastError ??
              CameraException('camera_error', 'No usable camera found.');
        }
        if (!mounted) {
          // Closed while the camera was opening; PopScope already ran.
          await _cameraWindowsPlugin.dispose(_cameraId);
          return false;
        }
        // The plugin's only closing event comes from our own dispose(), so
        // the error event is the one that matters.
        _windowsErrorSub = _cameraWindowsPlugin
            .onCameraError(_cameraId)
            .listen((e) => _onWindowsCameraLost(e.description));
        Logging.instance.d(
          "Windows Camera initialized with ID: $_cameraId, "
          "preview $_windowsPreviewSize",
        );
      } else if (Platform.isMacOS) {
        final List<CameraMacOSDevice> videoDevices = await CameraMacOS.instance
            .listDevices(deviceType: CameraMacOSDeviceType.video);
        if (videoDevices.isEmpty) {
          throw Exception('No cameras available');
        }
        _macOSDeviceId = videoDevices.first.deviceId;
        await CameraMacOS.instance.initialize(
          cameraMacOSMode: CameraMacOSMode.photo,
        );

        Logging.instance.d("macOS Camera initialized with ID: $_macOSDeviceId");
      }

      return true;
    } catch (e, s) {
      _initError = switch (e) {
        CameraException() => e.description ?? e.code,
        TimeoutException() => e.message ?? "$e",
        _ => "$e",
      };
      Logging.instance.e(
        "Failed to initialize camera",
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  /// Polls [plugin] until it returns a frame. Returns false on timeout or if
  /// the dialog closes first.
  Future<bool> _waitForFirstLinuxFrame(CameraLinux plugin) async {
    final stopwatch = Stopwatch()..start();
    Object? lastError;
    while (mounted && stopwatch.elapsed < _frameTimeout) {
      try {
        if ((await plugin.captureImage()).isNotEmpty) {
          return true;
        }
      } catch (e) {
        // captureImage() can throw on the null pointer it gets when there is
        // no frame yet.
        lastError = e;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    if (lastError != null) {
      Logging.instance.w("No frame from Linux camera", error: lastError);
    }
    return false;
  }

  /// Shows an error once no new frame has arrived for [_frameTimeout].
  void _checkFrameTimeout() {
    if (_sinceLastFrame.elapsed >= _frameTimeout &&
        _cameraError == null &&
        mounted) {
      setState(() {
        _cameraError =
            "The camera preview has stopped updating. You can still "
            "use \"Select file\" to scan a QR code image.";
      });
    }
  }

  /// The plugin reported a capture engine error. Its preview keeps the last
  /// frame and it never restarts the stream, so stop scanning and say so now
  /// rather than waiting for the frame timeout.
  void _onWindowsCameraLost(String description) {
    // The engine can report one failure several times, and an event already
    // queued can still arrive after the dialog started closing.
    if (_windowsCameraLost || !_isScanning) return;
    _windowsCameraLost = true;
    _isScanning = false;
    Logging.instance.w("Windows camera error: $description");
    // FormatMessage text ends in ".\r\n", and unknown errors come through
    // empty.
    final detail = description.trim().replaceFirst(RegExp(r"\.$"), "");
    if (!mounted) return;
    setState(() {
      _cameraError =
          "The camera stopped working"
          "${detail.isEmpty ? "" : " ($detail)"}. Close and reopen the "
          "scanner to try again, or use \"Select file\" to scan a QR code "
          "image.";
    });
  }

  Future<void> _stopCamera() async {
    _isScanning = false;
    // Runs from PopScope and from dispose(); the second call has nothing to
    // do.
    if (_cameraStopped) return;
    _cameraStopped = true;

    try {
      if (Platform.isLinux && _cameraLinuxPlugin != null) {
        _cameraLinuxPlugin!.stopCamera();
        Logging.instance.d("Linux Camera stopped");
      } else if (Platform.isWindows && _cameraWindowsPlugin != null) {
        await _windowsErrorSub?.cancel();
        _windowsErrorSub = null;
        // if (_cameraId >= 0) {
        await _cameraWindowsPlugin.dispose(_cameraId);
        Logging.instance.d("Windows Camera stopped with ID: $_cameraId");
        // } else {
        //   Logging.instance.log("Windows Camera ID is null. Cannot dispose.",
        //       level: LogLevel.Error);
        // }
      } else if (Platform.isMacOS) {
        // if (_macOSDeviceId != null) {
        await CameraMacOS.instance.stopImageStream();
        Logging.instance.d("macOS Camera stopped with ID: $_macOSDeviceId");
        // } else {
        //   Logging.instance.log("macOS Camera ID is null. Cannot stop.",
        //       level: LogLevel.Error);
        // }
      }
    } catch (e, s) {
      Logging.instance.e("Failed to stop camera", error: e, stackTrace: s);
    }
  }

  @override
  void dispose() {
    // PopScope normally gets here first; this covers a route removed without
    // a pop.
    unawaited(_stopCamera());
    super.dispose();
  }

  /// Grabs the frame the Windows preview is showing, in memory. Returns null
  /// when there is nothing to scan yet, or nothing new since the last call.
  Future<img.Image?> _captureWindowsPreviewFrame() async {
    final boundary = _windowsPreviewKey.currentContext?.findRenderObject();
    // Not laid out or painted yet, e.g. just after the camera opened.
    // debugNeedsPaint is always false in release builds, where toImage()
    // would throw instead and the capture loop retries after a delay.
    if (boundary is! RenderRepaintBoundary ||
        !boundary.hasSize ||
        boundary.size.isEmpty ||
        boundary.debugNeedsPaint) {
      return null;
    }

    // toImage() redraws the texture at whatever scale we ask for, so match
    // the camera's own resolution instead of the on-screen size.
    final preview = _windowsPreviewSize;
    double pixelRatio = 1;
    if (preview != null && preview.width > 0 && preview.height > 0) {
      final fit = min(
        1.0,
        _cameraFrameMaxDimension / max(preview.width, preview.height),
      );
      // toImage() rounds each side up, and the laid-out box is rarely exactly
      // the camera's aspect ratio, so take the smaller ratio and stay a hair
      // under it. Otherwise a 640x480 camera can come back as 640x481.
      pixelRatio =
          min(
            preview.width * fit / boundary.size.width,
            preview.height * fit / boundary.size.height,
          ) *
          (1 - 1e-9);
    }

    final ui.Image frame = await boundary.toImage(pixelRatio: pixelRatio);
    final int width = frame.width;
    final int height = frame.height;
    final ByteData? bytes;
    try {
      bytes = await frame.toByteData(format: ui.ImageByteFormat.rawRgba);
    } finally {
      frame.dispose();
    }
    // The dialog closed while we were waiting on the raster thread.
    if (!_isScanning || !mounted || bytes == null) return null;

    final rgba = bytes.buffer.asUint8List(
      bytes.offsetInBytes,
      bytes.lengthInBytes,
    );
    final blank = blankPreviewFrame(rgba);
    if (blank != null) {
      if (!_loggedBlankWindowsFrame) {
        _loggedBlankWindowsFrame = true;
        Logging.instance.w(
          "Windows camera preview frame is ${blank.name}, "
          "waiting for a usable one",
        );
      }
      return null;
    }
    _loggedBlankWindowsFrame = false;

    // A repeat of the last capture means the preview has stopped updating,
    // so treat it like no frame and let the frame timeout notice.
    final fingerprint = previewFrameFingerprint(rgba);
    if (fingerprint == _lastWindowsFrameFingerprint) {
      if (!_loggedRepeatedWindowsFrame) {
        _loggedRepeatedWindowsFrame = true;
        Logging.instance.w(
          "Windows camera preview frame has not changed, waiting for a new one",
        );
      }
      return null;
    }
    _lastWindowsFrameFingerprint = fingerprint;
    _loggedRepeatedWindowsFrame = false;

    // camera_windows mirrors the preview, so flip it back for zxing.
    return imageFromMirroredPreviewRgba(rgba, width: width, height: height);
  }

  Future<void> _captureAndScanImage() async {
    _isScanning = true;
    _sinceLastFrame.start();
    while (_isScanning) {
      try {
        String? base64Image;
        img.Image? windowsFrame;
        if (Platform.isLinux && _cameraLinuxPlugin != null) {
          base64Image = await _cameraLinuxPlugin!.captureImage();
        } else if (Platform.isWindows) {
          windowsFrame = await _captureWindowsPreviewFrame();
        } else if (Platform.isMacOS) {
          final macOSimg = await CameraMacOS.instance.takePicture();
          if (macOSimg == null) {
            Logging.instance.w("Failed to capture image");
            await Future<void>.delayed(Duration(milliseconds: _imageDelayInMs));
            _checkFrameTimeout();
            continue;
          }
          final img.Image? image = img.decodeImage(macOSimg.bytes!);
          if (image == null) {
            Logging.instance.w("Failed to capture image");
            await Future<void>.delayed(Duration(milliseconds: _imageDelayInMs));
            _checkFrameTimeout();
            continue;
          }
          base64Image = base64Encode(img.encodePng(image));
        }
        if (windowsFrame == null &&
            (base64Image == null || base64Image.isEmpty)) {
          // Logging.instance
          //     .log("Failed to capture image", level: LogLevel.Error);
          // Spammy.
          await Future<void>.delayed(Duration(milliseconds: _imageDelayInMs));
          _checkFrameTimeout();
          continue;
        }
        final img.Image? image =
            windowsFrame ?? img.decodeImage(base64Decode(base64Image!));
        // TODO [prio=low]: Optimize this process. Docs say:
        // > WARNING Since this will check the image data against all known
        // > decoders, it is much slower than using an explicit decoder
        if (image == null) {
          Logging.instance.w("Failed to decode image");
          await Future<void>.delayed(Duration(milliseconds: _imageDelayInMs));
          _checkFrameTimeout();
          continue;
        }

        _consecutiveFailures = 0;
        _sinceLastFrame.reset();
        if (mounted) {
          setState(() {
            _cameraError = null;
            // Windows already shows the live preview.
            if (windowsFrame == null) {
              _image = Image.memory(
                base64Decode(base64Image!),
                fit: BoxFit.cover,
              );
            } else {
              _hasWindowsFrame = true;
            }
          });
        }

        final String? scanResult = await _scanImage(
          image,
          maxDimension: _cameraFrameMaxDimension,
        );
        if (scanResult != null && scanResult.isNotEmpty) {
          await _stopCamera();

          if (mounted) {
            Navigator.of(context).pop(scanResult);
          }
          break;
        } else {
          // Logging.instance.log("No QR code found in the image");
          // if (mounted) {
          //   widget.onSnackbar("No QR code found in the image.");
          // }
          // Spammy.
        }

        await Future<void>.delayed(Duration(milliseconds: _imageDelayInMs));
      } catch (e, s) {
        _consecutiveFailures++;
        // Log the first failure and every 20th after it, so a capture that
        // fails on every iteration shows up in the logs without flooding them.
        if (_consecutiveFailures == 1 || _consecutiveFailures % 20 == 0) {
          Logging.instance.e(
            "Failed to capture image ($_consecutiveFailures in a row)",
            error: e,
            stackTrace: s,
          );
        }
        _checkFrameTimeout();
        // Without this a failing capture spins the loop with no delay.
        await Future<void>.delayed(Duration(milliseconds: _imageDelayInMs));
      }
    }
  }

  // Camera frames bigger than this are scaled down before scanning, and
  // Windows preview captures are taken at no more than this. Files picked
  // with "Select file" are scanned at full size.
  static const _cameraFrameMaxDimension = 1280;

  Future<String?> _scanImage(img.Image image, {int? maxDimension}) async =>
      decodeQrFromImage(image, maxDimension: maxDimension);

  Widget _buildCameraView(BuildContext context) {
    if (Platform.isWindows && _isCameraOpen) {
      return _buildWindowsPreview(context);
    }
    if (_cameraError != null) {
      return _buildCameraError(context);
    }
    if (_isCameraOpen && _image != null) {
      return _image!;
    }
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildCameraError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          _cameraError!,
          textAlign: TextAlign.center,
          style: STextStyles.desktopTextSmall(context),
        ),
      ),
    );
  }

  Widget _buildWindowsPreview(BuildContext context) {
    final size = _windowsPreviewSize;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: size != null && size.width > 0 && size.height > 0
                ? size.width / size.height
                : 4 / 3,
            child: RepaintBoundary(
              key: _windowsPreviewKey,
              child: _cameraWindowsPlugin!.buildPreview(_cameraId),
            ),
          ),
        ),
        // Cover the preview rather than replace it, so it keeps painting and
        // scanning picks up again once frames come back.
        if (_cameraError != null)
          ColoredBox(
            color: Theme.of(context).extension<StackColors>()!.popupBG,
            child: _buildCameraError(context),
          )
        else if (!_hasWindowsFrame)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) {
        _stopCamera();
      },
      child: DesktopDialog(
        maxWidth: 696,
        maxHeight: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(
                    "Scan QR code",
                    style: STextStyles.desktopH3(context),
                  ),
                ),
                const DesktopDialogCloseButton(),
              ],
            ),
            Expanded(child: _buildCameraView(context)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(child: Container()),
                  // "Select file" button.
                  SecondaryButton(
                    buttonHeight: ButtonHeight.l,
                    label: "Select file",
                    width: 200,
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ["png", "jpg", "jpeg"],
                      );

                      if (context.mounted) {
                        if (result == null ||
                            result.files.single.path == null) {
                          await showFloatingFlushBar(
                            type: FlushBarType.info,
                            message: "No file selected",
                            iconAsset: Assets.svg.file,
                            context: context,
                          );
                          return;
                        }

                        final filePath = result.files.single.path;
                        if (filePath == null) {
                          await showFloatingFlushBar(
                            type: FlushBarType.info,
                            message: "Error selecting file.",
                            iconAsset: Assets.svg.file,
                            context: context,
                          );
                          return;
                        }

                        try {
                          final img.Image? image = img.decodeImage(
                            File(filePath).readAsBytesSync(),
                          );
                          if (image == null) {
                            await showFloatingFlushBar(
                              type: FlushBarType.info,
                              message: "Failed to decode image.",
                              iconAsset: Assets.svg.file,
                              context: context,
                            );
                            return;
                          }

                          final String? scanResult = await _scanImage(image);
                          if (context.mounted) {
                            if (scanResult != null && scanResult.isNotEmpty) {
                              Navigator.of(context).pop(scanResult);
                            } else {
                              await showFloatingFlushBar(
                                type: FlushBarType.info,
                                message: "No QR code found in the image.",
                                iconAsset: Assets.svg.file,
                                context: context,
                              );
                            }
                          }
                        } catch (e, s) {
                          Logging.instance.e(
                            "Failed to decode image: ",
                            error: e,
                            stackTrace: s,
                          );
                          if (context.mounted) {
                            await showFloatingFlushBar(
                              type: FlushBarType.info,
                              message: "Error processing the image. Please try again.",
                              iconAsset: Assets.svg.file,
                              context: context,
                            );
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  // Close button.
                  PrimaryButton(
                    buttonHeight: ButtonHeight.l,
                    label: "Close",
                    width: 272.5,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
