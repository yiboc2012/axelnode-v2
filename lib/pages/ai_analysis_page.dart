import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path_provider/path_provider.dart';
import '../services/ai_logger.dart';
import '../widgets/object_painter.dart';

class AiAnalysisPage extends StatefulWidget {
  final String ip;
  const AiAnalysisPage({super.key, required this.ip});

  @override
  State<AiAnalysisPage> createState() => _AiAnalysisPageState();
}

class _AiAnalysisPageState extends State<AiAnalysisPage> {
  bool _isLive = false;
  bool _isScanning = false;
  List<DetectedObject> _objects = [];
  Size? _imageSize;
  String _aiLog = "Waiting for stream...";
  ObjectDetector? _objectDetector;

  @override
  void initState() {
    super.initState();
    try {
      _objectDetector = ObjectDetector(
        options: ObjectDetectorOptions(
          mode: DetectionMode.single,
          classifyObjects: true,
          multipleObjects: true,
        ),
      );
    } catch (e) {
      debugPrint("Object Detector Init Error: $e");
    }
  }

  @override
  void dispose() {
    _isLive = false;
    _objectDetector?.close();
    super.dispose();
  }

  void _toggleLive() {
    setState(() {
      _isLive = !_isLive;
      if (_isLive) {
        _analysisLoop();
      }
    });
  }

  Future<void> _analysisLoop() async {
    while (_isLive && mounted) {
      if (!_isScanning) {
        await _runScan();
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _runScan() async {
    if (_objectDetector == null) return;
    _isScanning = true;
    try {
      final response = await http.get(Uri.parse('http://${widget.ip}:5000/snapshot')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/live_scan.jpg');
        await file.writeAsBytes(bytes);

        final decodedImage = await decodeImageFromList(bytes);
        if (mounted) {
          setState(() {
            _imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
          });
        }

        final inputImage = InputImage.fromFile(file);
        final detectedObjects = await _objectDetector!.processImage(inputImage);

        if (mounted) {
          setState(() {
            _objects = detectedObjects;
            _checkHazards(_objects, bytes);
            if (_objects.isNotEmpty) {
              final labels = _objects.map((o) => o.labels.isNotEmpty ? o.labels.first.text : 'Object').join(", ");
              _aiLog = "SYSTEM: Detected $labels in proximity.";
              AiLogger.log("Cart AI: Detected $labels");
            } else {
              _aiLog = "SYSTEM: Monitoring clear path...";
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Live AI Error: $e");
    } finally {
      _isScanning = false;
    }
  }

  void _checkHazards(List<DetectedObject> objects, Uint8List imageBytes) {
    for (var o in objects) {
      final rect = o.boundingBox;
      final area = rect.width * rect.height;
      final screenArea = _imageSize != null ? _imageSize!.width * _imageSize!.height : 1.0;
      
      if (area / screenArea > 0.25) {
        final label = o.labels.isNotEmpty ? o.labels.first.text : 'Obstacle';
        _triggerHazardAlert(label, imageBytes);
        break;
      }
    }
  }

  void _triggerHazardAlert(String hazard, Uint8List imageBytes) {
    HapticFeedback.vibrate();
    http.post(Uri.parse('http://${widget.ip}:5000/alert')).catchError((e) => debugPrint("Alert Error: $e"));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(image: MemoryImage(imageBytes), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('HAZARD DETECTED', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Close proximity to $hazard. Sounding alert.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    AiLogger.log("HAZARD: Close proximity to $hazard");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart AI (OpenCV Live)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.greenAccent),
            onPressed: () async {
              final logs = await AiLogger.readLogs();
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('CART AI HISTORY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    content: SingleChildScrollView(
                      child: Text(logs, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
                    ],
                  ),
                );
              }
            },
          ),
          Switch(value: _isLive, onChanged: (v) => _toggleLive()),
          const SizedBox(width: 12),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 900;
          
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildCameraContainer(),
                ),
                const VerticalDivider(width: 1, color: Colors.white10),
                Expanded(
                  flex: 2,
                  child: _buildAiFeedbackPanel(),
                ),
              ],
            );
          }
          
          return Column(
            children: [
              Expanded(
                flex: 3,
                child: _buildCameraContainer(),
              ),
              Expanded(
                flex: 2,
                child: _buildAiFeedbackPanel(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCameraContainer() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isLive ? Colors.greenAccent : Colors.white10, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _isLive 
              ? Mjpeg(isLive: true, stream: 'http://${widget.ip}:5000/video_feed', fit: BoxFit.cover)
              : const Center(child: Text('AI SYSTEM OFFLINE', style: TextStyle(color: Colors.white24))),
            if (_isLive && _imageSize != null)
              LayoutBuilder(
                builder: (context, constraints) {
                  return CustomPaint(
                    painter: ObjectPainter(_objects, _imageSize!, constraints.biggest),
                  );
                },
              ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                child: Text(_isLive ? 'LIVE INFERENCE' : 'STANDBY', style: const TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiFeedbackPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('AI NEURAL FEEDBACK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(_aiLog, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('REAL-TIME OBJECT LOG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          Expanded(
            child: _objects.isEmpty
              ? const Center(child: Text('Scanning for entities...', style: TextStyle(color: Colors.white10, fontSize: 12)))
              : ListView.builder(
                  itemCount: _objects.length,
                  itemBuilder: (context, index) {
                    final o = _objects[index];
                    final label = o.labels.isNotEmpty ? o.labels.first.text : 'Entity';
                    final conf = o.labels.isNotEmpty ? (o.labels.first.confidence * 100).toStringAsFixed(0) : '0';
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.chevron_right, color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 8),
                          Text(label.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text('$conf% CONFIDENCE', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
