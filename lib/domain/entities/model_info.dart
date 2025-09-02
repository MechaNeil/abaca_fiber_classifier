class ModelInfo {
  final String inputInfo;
  final String outputInfo;
  final List<int> inputShape;
  final List<int> outputShape;
  final String inputType;
  final String outputType;

  const ModelInfo({
    required this.inputInfo,
    required this.outputInfo,
    required this.inputShape,
    required this.outputShape,
    required this.inputType,
    required this.outputType,
  });

  bool get isQuantized {
    final inputTypeStr = inputType.toLowerCase();
    return inputTypeStr.contains('uint8') || inputTypeStr.contains('int8');
  }

  bool get isValidImageInput {
    return inputShape.length == 4 && inputShape[0] == 1 && inputShape[3] == 3;
  }

  int get imageHeight => inputShape.length >= 3 ? inputShape[1] : 224;
  int get imageWidth => inputShape.length >= 3 ? inputShape[2] : 224;
  int get channels => inputShape.length >= 4 ? inputShape[3] : 3;
}
