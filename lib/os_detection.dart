import 'dart:io';

class OSDetector {
  static Future<bool> isTails() async {
    try {
      final osReleaseFile = File('/etc/os-release');
      if (await osReleaseFile.exists()) {
        final osReleaseContent = await osReleaseFile.readAsString();
        return osReleaseContent.contains('Tails');
      }
    } catch (e) {
      print('Error detecting Tails: $e');
    }
    return false;
  }

  static Future<bool> isWhonix() async {
    try {
      final whonixVersionFile = File('/etc/whonix_version');
      return await whonixVersionFile.exists();
    } catch (e) {
      print('Error detecting Whonix: $e');
    }
    return false;
  }
}
