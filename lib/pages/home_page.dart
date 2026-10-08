import 'package:flutter/material.dart';
import '../widgets/sheets.dart';

class HomePage extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onSettings;
  final String ip;
  const HomePage({super.key, required this.onStart, required this.onSettings, required this.ip});

  void _showSmartTools(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SmartToolsSheet(ip: ip),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showSmartTools(context),
            icon: const Icon(Icons.auto_awesome, color: Colors.greenAccent),
          ),
          IconButton(onPressed: onSettings, icon: const Icon(Icons.settings_outlined, color: Colors.greenAccent)),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth > 800;
          
          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade900.withOpacity(0.2), Colors.black],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(isWide ? 48.0 : 24.0),
                  child: isWide 
                    ? Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('AXEL NODE',
                                  style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.greenAccent)),
                                const Text('SMART CART ECOSYSTEM',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.grey)),
                                const SizedBox(height: 48),
                                _buildStatusChip('System Online', Colors.green),
                                const SizedBox(height: 64),
                                SizedBox(
                                  width: 400,
                                  child: ElevatedButton(
                                    onPressed: onStart,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent,
                                      foregroundColor: Colors.black,
                                      minimumSize: const Size(double.infinity, 80),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    child: const Text('ENTER CONTROL COCKPIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  color: Colors.greenAccent.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.greenAccent.withOpacity(0.2),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                  ],
                                  border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 4),
                                ),
                                child: const Icon(Icons.shopping_cart_checkout_rounded, size: 140, color: Colors.greenAccent),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.1),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                              border: Border.all(color: Colors.greenAccent.withOpacity(0.5), width: 3),
                            ),
                            child: const Icon(Icons.shopping_cart_checkout_rounded, size: 70, color: Colors.greenAccent),
                          ),
                          const SizedBox(height: 32),
                          const Text('AXEL NODE',
                            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 6, color: Colors.greenAccent)),
                          const Text('SMART CART ECOSYSTEM',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3, color: Colors.grey)),
                          const Spacer(),
                          _buildStatusChip('System Online', Colors.green),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: onStart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 64),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('ENTER CONTROL COCKPIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          const SizedBox(height: 40),
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

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
