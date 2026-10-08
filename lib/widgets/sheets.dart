import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/ai_logger.dart';
import '../pages/crop_analysis_page.dart';

class SettingsSheet extends StatefulWidget {
  final String currentIp;
  final Function(String) onSave;
  const SettingsSheet({super.key, required this.currentIp, required this.onSave});

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late TextEditingController _controller;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentIp);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('SYSTEM SETTINGS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Pi IP Address', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              widget.onSave(_controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('SAVE CONFIGURATION'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final logs = await AiLogger.readLogs();
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('AI SYSTEM LOGS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    content: SingleChildScrollView(
                      child: Text(logs, style: const TextStyle(fontSize: 10, fontFamily: 'monospace')),
                    ),
                    actions: [
                      TextButton(onPressed: () => AiLogger.clear().then((_) => Navigator.pop(context)), child: const Text('CLEAR')),
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Icons.history_edu_outlined),
            label: const Text('VIEW DETECTION HISTORY'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              foregroundColor: Colors.greenAccent,
              side: const BorderSide(color: Colors.greenAccent),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class SmartToolsSheet extends StatefulWidget {
  final String ip;
  const SmartToolsSheet({super.key, required this.ip});

  @override
  State<SmartToolsSheet> createState() => _SmartToolsSheetState();
}

class _SmartToolsSheetState extends State<SmartToolsSheet> {
  String _weight = "Fetching...";
  String _value = "\$0.00";

  @override
  void initState() {
    super.initState();
    _fetchLoadData();
  }

  Future<void> _fetchLoadData() async {
    try {
      final response = await http.get(Uri.parse('http://${widget.ip}:5000/weight')).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weight = "${data['weight']} kg";
          _value = "\$${(data['weight'] * 3.42).toStringAsFixed(2)}";
        });
      }
    } catch (e) {
      setState(() => _weight = "Sensor Error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('SMART AGRI-TOOLS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 24),
          _buildLoadItem(Icons.scale, 'CURRENT LOAD', _weight),
          const SizedBox(height: 12),
          _buildLoadItem(Icons.monetization_on_outlined, 'ESTIMATED VALUE', _value),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => CropAnalysisPage(ip: widget.ip)));
            },
            icon: const Icon(Icons.agriculture),
            label: const Text('LAUNCH CROP VISION AI'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLoadItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.greenAccent),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
