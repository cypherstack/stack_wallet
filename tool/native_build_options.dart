// SDK-only options shared by configuration and its preflight.
String? validatedDistribution(String? value) {
  if (value == null) return null;
  final distribution = value.trim();
  if (distribution.isEmpty ||
      distribution.startsWith('-') ||
      value.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
    throw ArgumentError(
      'WSL distribution must be a non-empty name, without '
      'a leading hyphen or ASCII control characters.',
    );
  }
  return distribution;
}
