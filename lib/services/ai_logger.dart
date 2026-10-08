import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class AiLogger {
  static Future<void> log(String message) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ai_system.log');
      final now = DateTime.now();
      final date = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final time = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
      await file.writeAsString("[$date $time] $message\n", mode: FileMode.append);
    } catch (e) {
      debugPrint("Logging Error: $e");
    }
  }

  static Future<String> readLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ai_system.log');
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint("Read Log Error: $e");
    }
    return "No logs found.";
  }

  static Future<void> clear() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ai_system.log');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint("Clear Log Error: $e");
    }
  }
}
