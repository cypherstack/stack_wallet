import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera_linux/camera_linux.dart';
import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_device.dart';
import 'package:camera_macos/camera_macos_platform_interface.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:camera_windows/camera_windows.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

import '../../notifications/show_flush_bar.dart';
import '../../utilities/assets.dart';
import '../../utilities/logger.dart';
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
  final CameraLinux? _cameraLinuxPlugin =
      Platform.isLinux ? CameraLinux() : null;
  final CameraWindows? _cameraWindowsPlugin =
      Platform.isWindows ? CameraWindows() : null;
  bool _isCameraOpen = false;
  Image? _image;
  bool _isScanning = false;
  int _cameraId = -1;
  String? _macOSDeviceId;
  final int _imageDelayInMs = Platform.isLinux ? 500 : 250;

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
        }
      });
    });
  }

  Future<bool> _initializeCamera() async {
    try {
      if (Platform.isLinux && _cameraLinuxPlugin != null) {
        await _cameraLinuxPlugin.initializeCamera();
        Logging.instance.d("Linux Camera initialized");
      } else if (Platform.isWindows && _cameraWindowsPlugin != null) {
        final List<CameraDescription> cameras =
            await _cameraWindowsPlugin.availableCameras();
        if (cameras.isEmpty) {
          throw CameraException('No cameras available', 'No cameras found.');
        }
        final CameraDescription camera = cameras[0]; // Could be user-selected.
        _cameraId = await _cameraWindowsPlugin.createCameraWithSettings(
          camera,
          const MediaSettings(
            resolutionPreset: ResolutionPreset.low,
            fps: 4,
            videoBitrate: 200000,
            enableAudio: false,
          ),
        );
        await _cameraWindowsPlugin.initializeCamera(_cameraId);
        // await _cameraWindowsPlugin!.onCameraInitialized(_cameraId).first;
        // TODO [prio=low]: Make this work. ^^^
        Logging.instance.d(
          "Windows Camera initialized with ID: $_cameraId",
        );
      } else if (Platform.isMacOS) {
        final List<CameraMacOSDevice> videoDevices = await CameraMacOS.instance
            .listDevices(deviceType: CameraMacOSDeviceType.video);
        if (videoDevices.isEmpty) {
          throw Exception('No cameras available');
        }
        _macOSDeviceId = videoDevices.first.deviceId;
        await CameraMacOS.instance
            .initialize(cameraMacOSMode: CameraMacOSMode.photo);

        Logging.instance.d(
          "macOS Camera initialized with ID: $_macOSDeviceId",
        );
      }

      return true;
    } catch (e, s) {
      Logging.instance.e(
        "Failed to initialize camera",
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  Future<void> _stopCamera() async {
    _isScanning = false;

    try {
      if (Platform.isLinux && _cameraLinuxPlugin != null) {
        _cameraLinuxPlugin.stopCamera();
        Logging.instance.d("Linux Camera stopped");
      } else if (Platform.isWindows && _cameraWindowsPlugin != null) {
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
      Logging.instance.e(
        "Failed to stop camera",
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> _captureAndScanImage() async {
    _isScanning = true;
    while (_isScanning) {
      try {
        String? base64Image;
        if (Platform.isLinux && _cameraLinuxPlugin != null) {
          base64Image = await _cameraLinuxPlugin.captureImage();
        } else if (Platform.isWindows) {
          final XFile xfile =
              await _cameraWindowsPlugin!.takePicture(_cameraId);
          final bytes = await xfile.readAsBytes();
          base64Image = base64Encode(bytes);
          // We could use a Uint8List to optimize for Windows and macOS.
        } else if (Platform.isMacOS) {
          final macOSimg = await CameraMacOS.instance.takePicture();
          if (macOSimg == null) {
            Logging.instance.w("Failed to capture image");
            await Future<void>.delayed(Duration(milliseconds: _imageDelayInMs));
            continue;
          }
          final img.Image? image = img.decodeImage(macOSimg.bytes!);
          if (image == null) {
            Logging.instance.w("Failed to capture image");
            await Future<void>.delayed(Duration(milliseconds: _imageDelayInMs));
            continue;
          }
          base64Image = base64Encode(img.encodePng(image));
        }
        if (base64Image == null || base64Image.isEmpty) {
          // Logging.instance
          //     .log("Failed to capture image", level: LogLevel.Error);
          // Spammy.
          await Future<void>.delayed(Duration(milliseconds: _imageDelayInMs));
          continue;
        }
        final img.Image? image = img.decodeImage(base64Decode(base64Image));
        // TODO [prio=low]: Optimize this process. Docs say:
        // > WARNING Since this will check the image data against all known
        // > decoders, it is much slower than using an explicit decoder
        if (image == null) {
          Logging.instance.w("Failed to decode image");
          await Future<void>.delayed(Duration(milliseconds: _imageDelayInMs));
          continue;
        }

        if (mounted) {
          setState(() {
            _image = Image.memory(
              base64Decode(base64Image!),
              fit: BoxFit.cover,
            );
          });
        }

        final String? scanResult = await _scanImage(image);
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
      } catch (e) {
        // Logging.instance.log("Failed to capture and scan image", error: e, stackTrace: s,);
        // Spammy.

        // if (mounted) {
        //   widget.onSnackbar(
        //       "Error capturing or scanning the image. Please try again.");
        // }
      }
    }
  }

  Future<String?> _scanImage(img.Image image) async {
    try {
      final LuminanceSource source = RGBLuminanceSource(
        image.width,
        image.height,
        image
            .convert(numChannels: 4)
            .getBytes(order: img.ChannelOrder.abgr)
            .buffer
            .asInt32List(),
      );
      final BinaryBitmap bitmap =
          BinaryBitmap(GlobalHistogramBinarizer(source));

      final QRCodeReader reader = QRCodeReader();
      final qrDecode = reader.decode(bitmap);
      if (qrDecode.text.isEmpty) {
        return null;
      }
      return qrDecode.text;
    } catch (e) {
      // Logging.instance.log("Failed to decode QR code", error: e, stackTrace: s,);
      // Spammy.
      return null;
    }
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
            Expanded(
              child: _isCameraOpen
                  ? _image != null
                      ? _image!
                      : const Center(
                          child: CircularProgressIndicator(),
                        )
                  : const Center(
                      child:
                          CircularProgressIndicator(), // Show progress indicator immediately
                    ),
            ),
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
                          final img.Image? image =
                              img.decodeImage(File(filePath).readAsBytesSync());
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
                              message:
                                  "Error processing the image. Please try again.",
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
