extension ListExt<T> on List<T> {
  List<List<T>> chunked({required int chunkSize}) {
    final remainder = length % chunkSize;
    final count = length ~/ chunkSize;
    final List<List<T>> result = [];

    int i = 0;
    while (i < count) {
      result.add(sublist(i, i + chunkSize));
      i++;
    }

    if (remainder > 0) {
      result.add(sublist(i, i + remainder));
    }

    return result;
  }
}
