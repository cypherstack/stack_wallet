import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    var flutter_native_splash = 1
    UIApplication.shared.isStatusBarHidden = false

    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let filePolicyChannel = FlutterMethodChannel(
      name: "STACK_WALLET_FILE_POLICY",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    filePolicyChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(
          code: "FILE_POLICY_FAILED",
          message: "Sapling parameter storage is unavailable",
          details: nil
        ))
        return
      }
      guard call.method == "saplingParameterCacheRoot" ||
              call.method == "excludeSaplingParametersFromBackup" else {
        result(FlutterMethodNotImplemented)
        return
      }
      do {
        let directory = try self.prepareSaplingParameterDirectory()
        if call.method == "saplingParameterCacheRoot" {
          result(directory.path)
        } else {
          result(nil)
        }
      } catch {
        result(FlutterError(
          code: "FILE_POLICY_FAILED",
          message: "Sapling parameter storage could not be prepared",
          details: nil
        ))
      }
    }
  }

  private func prepareSaplingParameterDirectory() throws -> URL {
    let manager = FileManager.default
    let support = try manager.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let namespace = Bundle.main.bundleIdentifier ?? "StackWallet"
    var directory = support
      .appendingPathComponent(namespace, isDirectory: true)
      .appendingPathComponent("zcash", isDirectory: true)
      .appendingPathComponent("proving-parameters", isDirectory: true)
    try manager.createDirectory(
      at: directory,
      withIntermediateDirectories: true,
      attributes: nil
    )
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try directory.setResourceValues(values)
    return directory
  }
}
