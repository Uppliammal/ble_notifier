import 'package:ble_notifier/view/home_page.dart';
import 'package:ble_notifier/services/background_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize background service
  await BackgroundService.instance.initialize();
  
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      title: 'BLE Scanning',
      debugShowCheckedModeBanner: false,
      home: AppLifecycleWrapper(),
    );
  }
}

class AppLifecycleWrapper extends StatefulWidget {
  const AppLifecycleWrapper({super.key});

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground
        print("App resumed - stopping background service");
        BackgroundService.instance.stopBackgroundScanning();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is in background or terminated
        print("App backgrounded - starting background service");
        BackgroundService.instance.startBackgroundScanning();
        break;
      case AppLifecycleState.hidden:
        // App is hidden
        break;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
