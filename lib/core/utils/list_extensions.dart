extension ListExtensions on List {
  List<dynamic> reshape(List<int> shape) {
    if (shape.isEmpty) return this;

    final totalElements = shape.reduce((a, b) => a * b);
    if (length != totalElements) {
      throw ArgumentError(
        'Cannot reshape list of length $length to shape $shape',
      );
    }

    if (shape.length == 1) return this;

    final result = <dynamic>[];
    final chunkSize = totalElements ~/ shape[0];

    for (int i = 0; i < shape[0]; i++) {
      final chunk = sublist(i * chunkSize, (i + 1) * chunkSize);
      if (shape.length > 2) {
        result.add(chunk.reshape(shape.sublist(1)));
      } else {
        result.add(chunk);
      }
    }

    return result;
  }
}
