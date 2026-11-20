/// Removes one or more Dart [Exception.toString] prefixes from [error].
String stripExceptionPrefixes(Object error) =>
    error.toString().replaceFirst(RegExp(r'^(?:Exception:\s*)+'), '');
