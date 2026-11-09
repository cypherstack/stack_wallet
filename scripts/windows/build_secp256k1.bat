@echo off
rem Compatibility entry point; the Dart helper discovers VS CMake and checks exits.
dart "%~dp0build_secp256k1.dart" %*
exit /b %errorlevel%
