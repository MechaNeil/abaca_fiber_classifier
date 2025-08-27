import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// This app replicates the Python TFLite prediction flow using MobileNetV3 preprocess_input.
// Python reference: mobilenet_v3.preprocess_input -> scale to [-1, 1] via x / 127.5 - 1.

void main() {
  runApp(const AbacaApp());
}

class AbacaApp extends StatelessWidget {
  const AbacaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abaca Prototype',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const InferencePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InferencePage extends StatefulWidget {
  const InferencePage({super.key});

  @override
  State<InferencePage> createState() => _InferencePageState();
}

class _InferencePageState extends State<InferencePage> {
  final _picker = ImagePicker();
  Interpreter? _interpreter;
  List<String> _labels = const [];

  String? _imagePath;
  String? _predictedClass;
  double? _confidence;
  List<double>? _probs;
  String? _error;
  bool _busy = false;
  String? _inputInfo;
  String? _outputInfo;
  String? _pyStyleOutput;

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    setState(() => _busy = true);
    try {
      // Load labels from assets (one label per line)
      final labelsTxt = await rootBundle.loadString('assets/labels.txt');
      _labels = labelsTxt
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);

      // Load TFLite model from assets
      // Note: Path must match pubspec.yaml assets entry
      _interpreter = await Interpreter.fromAsset(
        'assets/mobilenetv3small_b2.tflite',
      );
      _interpreter!.allocateTensors();

      // Introspect input/output tensors for shape/type sanity
      final inTensor = _interpreter!.getInputTensor(0);
      final outTensor = _interpreter!.getOutputTensor(0);
      final inputShape = inTensor.shape;
      final outputShape = outTensor.shape;
      final inputType = inTensor.type.toString();
      final outputType = outTensor.type.toString();

      // Save info for UI/debug
      _inputInfo = 'shape=${_fmtShape(inputShape)} type=$inputType';
      _outputInfo = 'shape=${_fmtShape(outputShape)} type=$outputType';

      // Basic validations to catch mismatches early
      if (inputShape.length != 4) {
        throw StateError(
          'Expected 4D input tensor [1,H,W,3], got ${_fmtShape(inputShape)}',
        );
      }
      if (inputShape[0] != 1) {
        throw StateError('Expected batch=1, got batch=${inputShape[0]}');
      }
      if (inputShape[3] != 3) {
        throw StateError(
          'Expected 3-channel RGB, got channels=${inputShape[3]}',
        );
      }

      // Warn if quantized model (users often mix preprocessing)
      if (inputType.toLowerCase().contains('uint8') ||
          inputType.toLowerCase().contains('int8')) {
        // We proceed, but preprocessing must be changed for quantized models
        debugPrint(
          '[Warning] Detected quantized input tensor ($inputType). The current preprocessing uses float [-1,1].',
        );
      }

      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = 'Failed to load model/labels: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _pickAndPredict() async {
    if (_interpreter == null) {
      setState(() => _error = 'Interpreter not ready');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _predictedClass = null;
      _confidence = null;
      _probs = null;
    });
    try {
      final xfile = await _picker.pickImage(source: ImageSource.gallery);
      if (xfile == null) {
        setState(() => _busy = false);
        return;
      }
      _imagePath = xfile.path;

      final result = await _predict(_interpreter!, _imagePath!);
      setState(() {
        _predictedClass = result.predictedLabel;
        _confidence = result.confidence;
        _probs = result.probabilities;
        _pyStyleOutput = _toPythonTuple(
          result.predictedLabel,
          result.confidence,
          result.probabilities,
        );
      });
      // Also print to console in Python-like format for quick verification
      // Example: ('I', 0.928134560585022, array([0.00174234, ...], dtype=float32))
      // ignore: avoid_print
      print(_pyStyleOutput);
    } catch (e) {
      setState(() => _error = 'Prediction failed: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPredict = _interpreter != null && _labels.isNotEmpty && !_busy;
    return Scaffold(
      appBar: AppBar(title: const Text('TFLite MobileNetV3 Inference')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: canPredict ? _pickAndPredict : null,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pick image'),
                ),
                const SizedBox(width: 12),
                if (_busy)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_imagePath!),
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_inputInfo != null || _outputInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Input tensor: ${_inputInfo ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                'Output tensor: ${_outputInfo ?? ''}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            if (_predictedClass != null && _confidence != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prediction: ${_predictedClass!}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Confidence: ${(_confidence! * 100).toStringAsFixed(2)}%',
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (_probs != null)
              Expanded(
                child: ListView.separated(
                  itemCount: math.min(_labels.length, _probs!.length),
                  separatorBuilder: (_, __) => const Divider(height: 8),
                  itemBuilder: (context, i) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          i < _labels.length ? _labels[i] : 'Class $i',
                        ),
                      ),
                      Text(_probs![i].toStringAsFixed(6)),
                    ],
                  ),
                ),
              ),
            if (_pyStyleOutput != null) ...[
              const SizedBox(height: 12),
              const Text('Python-style output:'),
              SelectableText(
                _pyStyleOutput!,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Replicates the Python pipeline:
  // - Read image from disk
  // - Convert to RGB, resize to 224x224
  // - Apply MobileNetV3 preprocess_input (x/127.5 - 1)
  // - Run TFLite interpreter
  Future<_PredictionResult> _predict(
    Interpreter interpreter,
    String imagePath,
  ) async {
    // Read and decode image
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw StateError('Unable to decode image');
    }

    // Ensure RGB and resize to 224x224
    // If the model input size differs, we will detect below, but we default to 224x224.
    final inputTensor = interpreter.getInputTensor(0);
    final inputShape = inputTensor.shape; // e.g., [1, 224, 224, 3]
    final targetH = inputShape.length >= 3 ? inputShape[1] : 224;
    final targetW = inputShape.length >= 3 ? inputShape[2] : 224;
    // Avoid altering content: if already target size keep as-is; otherwise letterbox-pad without distortion
    final bool alreadyTarget =
        decoded.width == targetW && decoded.height == targetH;
    // Precompute letterbox parameters if needed
    final double scale = alreadyTarget
        ? 1.0
        : math.min(targetW / decoded.width, targetH / decoded.height);
    final int newW = (decoded.width * scale).round();
    final int newH = (decoded.height * scale).round();
    final int dx = (targetW - newW) ~/ 2;
    final int dy = (targetH - newH) ~/ 2;
    final img.Image? resizedNoDistort = alreadyTarget
        ? null
        : img.copyResize(
            decoded,
            width: newW,
            height: newH,
            interpolation: img.Interpolation.nearest,
          );

    // Prepare input as nested List [1, H, W, 3] with minimal changes (no normalization)
    final channels = inputShape.length >= 4 ? inputShape[3] : 3;
    if (channels != 3) {
      throw StateError('Expected 3-channel RGB input, got $channels');
    }
    final inputTypeStr = inputTensor.type.toString().toLowerCase();
    final bool isQuantized =
        inputTypeStr.contains('uint8') || inputTypeStr.contains('int8');
    final dynamic input = isQuantized
        ? List.generate(
            1,
            (_) => List.generate(
              targetH,
              (_) => List.generate(targetW, (_) => List<int>.filled(3, 0)),
            ),
          )
        : List.generate(
            1,
            (_) => List.generate(
              targetH,
              (_) => List.generate(targetW, (_) => List<double>.filled(3, 0.0)),
            ),
          );

    // Fill input with raw RGB values (0..255) to avoid altering the image
    for (int y = 0; y < targetH; y++) {
      for (int x = 0; x < targetW; x++) {
        int r = 0, g = 0, b = 0;
        // Map to source coords if within the resized region; else leave as 0 (letterbox)
        if (alreadyTarget) {
          final sp = decoded.getPixel(x, y);
          r = sp.r.toInt();
          g = sp.g.toInt();
          b = sp.b.toInt();
        } else {
          final int rx = x - dx;
          final int ry = y - dy;
          if (rx >= 0 && ry >= 0 && rx < newW && ry < newH) {
            final sp = resizedNoDistort!.getPixel(rx, ry);
            r = sp.r.toInt();
            g = sp.g.toInt();
            b = sp.b.toInt();
          }
        }
        if (isQuantized) {
          input[0][y][x][0] = r;
          input[0][y][x][1] = g;
          input[0][y][x][2] = b;
        } else {
          input[0][y][x][0] = r.toDouble();
          input[0][y][x][1] = g.toDouble();
          input[0][y][x][2] = b.toDouble();
        }
      }
    }

    // Prepare output buffer
    final outputTensor = interpreter.getOutputTensor(0);
    final outputShape = outputTensor.shape; // e.g., [1, 8]

    final outputLen = outputShape.reduce((a, b) => a * b);
    final outputFlat = List<double>.filled(outputLen, 0.0);
    final output = outputFlat.reshape(outputShape);

    // Run inference with correctly shaped inputs/outputs
    try {
      interpreter.run(input, output);
    } catch (e) {
      throw StateError(
        'Interpreter run failed ($e). InputShape=$inputShape OutputShape=$outputShape',
      );
    }

    // If output has a batch dimension (e.g., [1, N]), drop it
    // Typical classifier output is [1, numClasses]
    final List<double> probs = List<double>.from(
      (output[0] as List).map((e) => (e as num).toDouble()),
    );

    // Optionally apply softmax if model's last layer didn't include it.
    // We heuristically check if sum of probs ~ 1; if not, softmax.
    final sum = probs.fold<double>(0.0, (s, v) => s + v);
    if (!(sum > 0.98 && sum < 1.02)) {
      final softmaxed = _softmax(probs);
      for (var i = 0; i < probs.length; i++) {
        probs[i] = softmaxed[i];
      }
    }

    // Argmax
    int maxIdx = 0;
    double maxVal = probs[0];
    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxVal) {
        maxVal = probs[i];
        maxIdx = i;
      }
    }

    final predictedLabel = (maxIdx < _labels.length)
        ? _labels[maxIdx]
        : 'Class $maxIdx';
    final confidence = maxVal;

    return _PredictionResult(
      predictedLabel: predictedLabel,
      confidence: confidence,
      probabilities: probs,
    );
  }

  String _fmtShape(List<int> shape) => '[${shape.join(', ')}]';

  String _toPythonTuple(String label, double conf, List<double> probs) {
    final probsStr = _numpyArray(probs);
    // Confidence printed with higher precision similar to Python sample
    final confStr = conf.toStringAsFixed(15);
    return "('$label', $confStr, $probsStr)";
  }

  String _numpyArray(List<double> values) {
    // Format like: array([0.00174234, 0.03384768, ...], dtype=float32)
    final formatted = values.map((v) => v.toStringAsFixed(8)).join(', ');
    return 'array([' + formatted + '], dtype=float32)';
  }

  List<double> _softmax(List<double> logits) {
    // Stable softmax
    final maxLogit = logits.reduce(math.max);
    final exps = logits
        .map((v) => math.exp(v - maxLogit))
        .toList(growable: false);
    final sum = exps.fold<double>(0.0, (s, v) => s + v);
    return exps.map((v) => v / sum).toList(growable: false);
  }
}

class _PredictionResult {
  final String predictedLabel;
  final double confidence;
  final List<double> probabilities;

  _PredictionResult({
    required this.predictedLabel,
    required this.confidence,
    required this.probabilities,
  });
}
