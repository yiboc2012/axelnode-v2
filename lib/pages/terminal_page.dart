import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';
import 'dart:convert';

class TerminalPage extends StatefulWidget {
  final String ip;
  const TerminalPage({super.key, required this.ip});

  @override
  State<TerminalPage> createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final terminal = Terminal();
  final focusNode = FocusNode();
  SSHClient? client;
  SSHSession? session;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    if (client != null) return;
    
    terminal.write('Connecting to ${widget.ip}...\r\n');
    try {
      final socket = await SSHSocket.connect(widget.ip, 22, timeout: const Duration(seconds: 10));
      client = SSHClient(socket, username: 'rpi', onPasswordRequest: () => 'Ilove67');
      session = await client!.shell();
      
      terminal.onOutput = (data) {
        session?.write(Uint8List.fromList(utf8.encode(data)));
      };
      
      session!.stdout.listen((data) => terminal.write(utf8.decode(data, allowMalformed: true)));
      session!.stderr.listen((data) => terminal.write(utf8.decode(data, allowMalformed: true)));
      
      terminal.write('Connected.\r\n');
    } catch (e) { 
      terminal.write('Connection failed: $e\r\n'); 
      client = null;
    }
  }

  @override
  void dispose() {
    session?.close();
    client?.close();
    focusNode.dispose();
    super.dispose();
  }

  void _sendCommand(String cmd) {
    session?.write(Uint8List.fromList('$cmd\n'.codeUnits));
  }

  void _sendControlKey(int charCode) {
    session?.write(Uint8List.fromList([charCode]));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 800;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Cart Terminal'),
            actions: [
              IconButton(
                onPressed: () {
                  session?.close();
                  client?.close();
                  client = null;
                  _connect();
                },
                icon: const Icon(Icons.refresh, color: Colors.greenAccent),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Container(
                  color: Colors.black, 
                  padding: EdgeInsets.all(isWide ? 20 : 0),
                  child: TerminalView(
                    terminal, 
                    focusNode: focusNode, 
                    autofocus: true,
                  ),
                ),
              ),
              Container(
                height: isWide ? 60 : 40,
                color: Colors.black,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _ctrlButton('^C', 0x03, isWide),
                    _ctrlButton('^X', 0x18, isWide),
                    _ctrlButton('^O', 0x0F, isWide),
                    _ctrlButton('^Z', 0x1A, isWide),
                    _ctrlButton('TAB', 0x09, isWide),
                    _ctrlButton('ESC', 0x1B, isWide),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => focusNode.unfocus(),
                      icon: Icon(Icons.keyboard_hide, color: Colors.greenAccent, size: isWide ? 28 : 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white10),
              Container(
                height: isWide ? 80 : 60,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey[900],
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    _cmdButton('SYSTEM', 'uptime && vcgencmd measure_temp', isWide),
                    _cmdButton('PROCESS', 'top -bn1 | head -n 10', isWide),
                    _cmdButton('FILES', 'ls -lh', isWide),
                    _cmdButton('NETWORK', 'ifconfig | grep inet', isWide),
                    _cmdButton('REBOOT', 'sudo reboot', isWide),
                    _cmdButton('LOGS', 'tail -n 20 camera_server/camera.log', isWide),
                    _cmdButton('SERVICES', 'systemctl list-units --type=service --state=running | head -n 20', isWide),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ctrlButton(String label, int code, bool isWide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () => _sendControlKey(code),
        style: TextButton.styleFrom(
          minimumSize: Size(isWide ? 60 : 45, isWide ? 40 : 30),
          padding: EdgeInsets.zero,
          backgroundColor: Colors.white10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(label, style: TextStyle(color: Colors.white70, fontSize: isWide ? 14 : 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _cmdButton(String label, String cmd, bool isWide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(label, style: TextStyle(fontSize: isWide ? 14 : 10, fontWeight: FontWeight.bold)),
        onPressed: () => _sendCommand(cmd),
        backgroundColor: Colors.blueAccent.withOpacity(0.2),
        padding: isWide ? const EdgeInsets.all(12) : null,
      ),
    );
  }
}
