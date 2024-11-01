#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  camera_windows
  connectivity_plus
  cs_monero_flutter_libs_windows
  desktop_drop
  flutter_libepiccash
  flutter_secure_storage_windows
  isar_flutter_libs
  local_auth_windows
  permission_handler_windows
  share_plus
  sqlite3_flutter_libs
  stack_wallet_backup
  url_launcher_windows
  window_size
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
  coinlib_flutter
  flutter_libsparkmobile
  frostdart
  tor_ffi_plugin
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
