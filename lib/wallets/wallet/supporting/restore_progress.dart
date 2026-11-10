double calculateRestoreProgress({
  required int scannedHeight,
  required int chainHeight,
}) => chainHeight <= 0 ? 0.0 : scannedHeight / chainHeight;
