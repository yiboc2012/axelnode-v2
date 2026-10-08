import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/home_page.dart';
import 'pages/live_stream_page.dart';
import 'pages/ai_analysis_page.dart';
import 'pages/terminal_page.dart';
import 'widgets/sheets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const AxelNodeApp());
}

class AxelNodeApp extends StatelessWidget {
  const AxelNodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AXEL NODE Smart Cart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.greenAccent,
          brightness: Brightness.dark,
          surface: const Color(0xFF0A0E0A),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  String _currentIp = '192.168.0.112';
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentIp = prefs.getString('pi_ip') ?? '192.168.0.112';
    });
  }

  Future<void> _saveSettings(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pi_ip', ip);
    setState(() {
      _currentIp = ip;
    });
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SettingsSheet(
        currentIp: _currentIp,
        onSave: _saveSettings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth > 800;
        
        return Scaffold(
          body: Row(
            children: [
              if (isWide)
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                    _pageController.jumpToPage(index);
                  },
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: const Color(0xFF111111),
                  selectedIconTheme: const IconThemeData(color: Colors.greenAccent),
                  unselectedIconTheme: const IconThemeData(color: Colors.white24),
                  selectedLabelTextStyle: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  unselectedLabelTextStyle: const TextStyle(color: Colors.white24, fontSize: 10),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Status')),
                    NavigationRailDestination(icon: Icon(Icons.videocam_outlined), selectedIcon: Icon(Icons.videocam), label: Text('Drive')),
                    NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Cart AI')),
                    NavigationRailDestination(icon: Icon(Icons.terminal_outlined), selectedIcon: Icon(Icons.terminal), label: Text('SSH')),
                  ],
                ),
              if (isWide) const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    HomePage(onStart: () {
                      setState(() => _selectedIndex = 1);
                      _pageController.jumpToPage(1);
                    }, onSettings: _showSettings, ip: _currentIp),
                    LiveStreamPage(ip: _currentIp),
                    AiAnalysisPage(ip: _currentIp),
                    TerminalPage(ip: _currentIp),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: isWide ? null : NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
              _pageController.jumpToPage(index);
            },
            destinations: const [
              NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Status'),
              NavigationDestination(icon: Icon(Icons.videocam_outlined), label: 'Drive'),
              NavigationDestination(icon: Icon(Icons.analytics_outlined), label: 'Cart AI'),
              NavigationDestination(icon: Icon(Icons.terminal_outlined), label: 'SSH'),
            ],
          ),
        );
      },
    );
  }
}
