//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <camera_windows/camera_windows.h>
#include <connectivity_plus/connectivity_plus_windows_plugin.h>
#include <cs_monero_flutter_libs_windows/cs_monero_flutter_libs_windows_plugin_c_api.h>
#include <cs_salvium_flutter_libs_windows/cs_salvium_flutter_libs_windows_plugin_c_api.h>
#include <desktop_drop/desktop_drop_plugin.h>
#include <flutter_libepiccash/flutter_libepiccash_plugin_c_api.h>
#include <flutter_secure_storage_windows/flutter_secure_storage_windows_plugin.h>
#include <isar_flutter_libs/isar_flutter_libs_plugin.h>
#include <local_auth_windows/local_auth_plugin.h>
#include <permission_handler_windows/permission_handler_windows_plugin.h>
#include <share_plus/share_plus_windows_plugin_c_api.h>
#include <sqlite3_flutter_libs/sqlite3_flutter_libs_plugin.h>
#include <stack_wallet_backup/stack_wallet_backup_plugin_c_api.h>
#include <url_launcher_windows/url_launcher_windows.h>
#include <window_size/window_size_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  CameraWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CameraWindows"));
  ConnectivityPlusWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ConnectivityPlusWindowsPlugin"));
  CsMoneroFlutterLibsWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CsMoneroFlutterLibsWindowsPluginCApi"));
  CsSalviumFlutterLibsWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CsSalviumFlutterLibsWindowsPluginCApi"));
  DesktopDropPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DesktopDropPlugin"));
  FlutterLibepiccashPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterLibepiccashPluginCApi"));
  FlutterSecureStorageWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterSecureStorageWindowsPlugin"));
  IsarFlutterLibsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("IsarFlutterLibsPlugin"));
  LocalAuthPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("LocalAuthPlugin"));
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
  SharePlusWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("SharePlusWindowsPluginCApi"));
  Sqlite3FlutterLibsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("Sqlite3FlutterLibsPlugin"));
  StackWalletBackupPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("StackWalletBackupPluginCApi"));
  UrlLauncherWindowsRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherWindows"));
  WindowSizePluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("WindowSizePlugin"));
}
