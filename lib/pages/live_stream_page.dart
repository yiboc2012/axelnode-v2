import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

class LiveStreamPage extends StatefulWidget {
  final String ip;
  const LiveStreamPage({super.key, required this.ip});

  @override
  State<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends State<LiveStreamPage> {
  bool _isLive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 800;
          
          return Stack(
            children: [
              Center(
                child: _isLive
                  ? Mjpeg(isLive: true, stream: 'http://${widget.ip}:5000/video_feed', fit: BoxFit.contain)
                  : const Text('CAMERA STANDBY', style: TextStyle(color: Colors.white24, letterSpacing: 2)),
              ),
              Positioned(
                bottom: isWide ? 60 : 40,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton.large(
                    onPressed: () => setState(() => _isLive = !_isLive),
                    backgroundColor: _isLive ? Colors.red : Colors.greenAccent,
                    child: Icon(_isLive ? Icons.stop : Icons.play_arrow, size: 40, color: Colors.black),
                  ),
                ),
              ),
              if (isWide && _isLive)
                Positioned(
                  top: 40,
                  right: 40,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
                        SizedBox(width: 8),
                        Text('LIVE STREAMING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
