import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'notification_service.dart';

class BackgroundService {
  static BackgroundService? _instance;
  static BackgroundService get instance => _instance ??= BackgroundService._();
  
  BackgroundService._();
  
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _scanTimer;
  final NotificationService _notificationService = NotificationService();
  
  final Map<String, BluetoothDevice> _nearbyDevices = {};
  final Map<String, int> _deviceRSSI = {};
  final int _rssiThreshold = -70;
  final Duration _scanDuration = const Duration(seconds: 10);
  final Duration _scanInterval = const Duration(seconds: 5);
  
  bool _isRunning = false;
  
  Future<void> initialize() async {
    await _notificationService.initialize();
    await _notificationService.showPersistentNotification(
      title: "BLE Scanner",
      body: "BLE scanning is running in the background",
    );
  }
  
  Future<void> startBackgroundScanning() async {
    if (_isRunning) return;
    
    _isRunning = true;
    print("Starting background BLE scanning...");
    
    // Start periodic scanning
    _scanTimer = Timer.periodic(_scanInterval, (timer) {
      _startScan();
    });
    
    // Start initial scan
    _startScan();
  }
  
  void _startScan() async {
    try {
      // Listen to scan results stream
      _scanSubscription = FlutterBluePlus.onScanResults.listen(
        _onScanResult,
        onError: (error) {
          print("Background scan error: $error");
        },
      );
      
      // Start scan with timeout
      await FlutterBluePlus.startScan(
        timeout: _scanDuration,
        androidUsesFineLocation: true,
      );
    } catch (e) {
      print("Error starting background scan: $e");
    }
  }
  
  void _onScanResult(List<ScanResult> results) {
    for (ScanResult result in results) {
      final device = result.device;
      final rssi = result.rssi;
      final deviceId = device.remoteId.toString();
      
      // Update device RSSI
      _deviceRSSI[deviceId] = rssi;
      
      // Check if device is in range
      bool isInRange = rssi > _rssiThreshold;
      bool wasInRange = _nearbyDevices.containsKey(deviceId);
      
      if (isInRange && !wasInRange) {
        // Device entered range
        _nearbyDevices[deviceId] = device;
        _notificationService.showNotification(
          title: "Device Nearby",
          body: "${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'} is nearby (RSSI: $rssi dBm)",
          payload: "background_device_nearby_$deviceId",
        );
        print("Background: Device entered range: ${device.platformName} (RSSI: $rssi)");
        
      } else if (!isInRange && wasInRange) {
        // Device left range
        _nearbyDevices.remove(deviceId);
        _notificationService.showNotification(
          title: "Device Out of Range",
          body: "${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'} is out of range",
          payload: "background_device_out_of_range_$deviceId",
        );
        print("Background: Device left range: ${device.platformName}");
      }
    }
  }
  
  Future<void> stopBackgroundScanning() async {
    if (!_isRunning) return;
    
    _isRunning = false;
    _scanTimer?.cancel();
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    
    await _notificationService.cancelNotification(999);
    print("Background BLE scanning stopped");
  }
  
  void dispose() {
    stopBackgroundScanning();
  }
} 