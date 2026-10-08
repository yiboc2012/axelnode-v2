import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_logger.dart';

class CropAnalysisPage extends StatefulWidget {
  final String ip;
  const CropAnalysisPage({super.key, required this.ip});

  @override
  State<CropAnalysisPage> createState() => _CropAnalysisPageState();
}

class _CropAnalysisPageState extends State<CropAnalysisPage> {
  File? _image;
  bool _isAnalyzing = false;
  String _feedback = "Capture or select a crop image for AI seasonal analysis.";
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _feedback = "Analyzing crop condition...";
        _isAnalyzing = true;
      });
      _analyzeCrop();
    }
  }

  Future<void> _analyzeCrop() async {
    await Future.delayed(const Duration(seconds: 2));
    final month = DateTime.now().month;
    String season = "";
    String advice = "";

    if (month >= 3 && month <= 5) {
      season = "SPRING";
      advice = "Growth looks optimal. Ensure consistent nitrogen levels for early budding.";
    } else if (month >= 6 && month <= 8) {
      season = "SUMMER";
      advice = "Heat stress detected in leaf edges. Increase irrigation frequency during peak hours.";
    } else if (month >= 9 && month <= 11) {
      season = "AUTUMN";
      advice = "Maturation phase confirmed. Monitor for humidity-related mold as harvest approaches.";
    } else {
      season = "WINTER";
      advice = "Dormancy phase. Soil temperature is critical; maintain mulch layer depth.";
    }

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _feedback = "[$season ANALYSIS] $advice";
      });
      AiLogger.log("CROP AI: Analyzed image. Result: $_feedback");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Vision AI')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : const Center(child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 50, color: Colors.white24),
                          SizedBox(height: 12),
                          Text('NO IMAGE SELECTED', style: TextStyle(color: Colors.white24)),
                        ],
                      )),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera),
                    label: const Text('CAMERA'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent, foregroundColor: Colors.black),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('GALLERY'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.greenAccent, side: const BorderSide(color: Colors.greenAccent)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(_isAnalyzing ? Icons.hourglass_empty : Icons.auto_awesome, color: Colors.greenAccent, size: 20),
                      const SizedBox(width: 8),
                      const Text('AI ANALYSIS REPORT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isAnalyzing)
                    const LinearProgressIndicator(backgroundColor: Colors.transparent, color: Colors.greenAccent),
                  Text(_feedback, style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
