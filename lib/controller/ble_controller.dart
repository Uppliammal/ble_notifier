import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';

class BLEController extends GetxController {
  // Observable variables
  var isScanning = false.obs;
  var nearbyDevices = <String, BluetoothDevice>{}.obs;
  var deviceRSSI = <String, int>{}.obs;
  var nearestDevice = Rxn<BluetoothDevice>();
  var nearestDeviceRSSI = 0.obs;
  
  // Configuration
  final int rssiThreshold = -70; // dBm threshold for "in range"
  final Duration scanDuration = const Duration(seconds: 10);
  final Duration scanInterval = const Duration(seconds: 5);
  
  // Services
  final NotificationService _notificationService = NotificationService();
  
  // Stream subscriptions
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Timer? _scanTimer;
  
  @override
  void onInit() {
    super.onInit();
    _initializeBLE();
  }
  
  @override
  void onClose() {
    _stopScanning();
    _scanSubscription?.cancel();
    _scanTimer?.cancel();
    super.onClose();
  }
  
  Future<void> _initializeBLE() async {
    // Request permissions
    await _requestPermissions();
    
    // Initialize notification service
    await _notificationService.initialize();
    
    // Check if Bluetooth is available
    if (await FlutterBluePlus.isSupported == false) {
      Get.snackbar("Error", "Bluetooth is not supported on this device");
      return;
    }
    
    // Listen to Bluetooth adapter state
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        _startPeriodicScanning();
      } else {
        _stopScanning();
        Get.snackbar("Bluetooth", "Bluetooth is turned off");
      }
    });
    
    // Start scanning if Bluetooth is already on
    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.on) {
      _startPeriodicScanning();
    }
  }
  
  Future<void> _requestPermissions() async {
    // Request location permission (required for BLE scanning on Android)
    await Permission.locationWhenInUse.request();
    await Permission.locationAlways.request();
    
    // Request notification permission
    await Permission.notification.request();
    
    // Request Bluetooth permissions
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }
  
  void _startPeriodicScanning() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(scanInterval, (timer) {
      if (!isScanning.value) {
        _startScanning();
      }
    });
    
    // Start initial scan
    _startScanning();
  }
  
  void _startScanning() async {
    if (isScanning.value) return;
    
    try {
      isScanning.value = true;
      
      // Listen to scan results stream
      _scanSubscription = FlutterBluePlus.onScanResults.listen(
        _onScanResult,
        onError: (error) {
          print("Scan error: $error");
          isScanning.value = false;
        },
      );
      
      // Start scan with timeout
      await FlutterBluePlus.startScan(
        timeout: scanDuration,
        androidUsesFineLocation: true,
      );
      
    } catch (e) {
      print("Error starting scan: $e");
      isScanning.value = false;
    }
  }
  
  
  void _stopScanning() {
    _scanTimer?.cancel();
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    isScanning.value = false;
  }
  
  void _onScanResult(List<ScanResult> results) {
    for (ScanResult result in results) {
      final device = result.device;
      final rssi = result.rssi;
      final deviceId = device.remoteId.toString();
      
      // Update device RSSI
      deviceRSSI[deviceId] = rssi;
      
      // Check if device is in range
      bool isInRange = rssi > rssiThreshold;
      bool wasInRange = nearbyDevices.containsKey(deviceId);
      
      if (isInRange && !wasInRange) {
        // Device entered range
        nearbyDevices[deviceId] = device;
        _notificationService.showNotification(
          title: "Device Nearby",
          body: "${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'} is nearby (RSSI: $rssi dBm)",
          payload: "device_nearby_$deviceId",
        );
        print("Device entered range: ${device.platformName} (RSSI: $rssi)");
        
      } else if (!isInRange && wasInRange) {
        // Device left range
        nearbyDevices.remove(deviceId);
        _notificationService.showNotification(
          title: "Device Out of Range",
          body: "${device.platformName.isNotEmpty ? device.platformName : 'Unknown Device'} is out of range",
          payload: "device_out_of_range_$deviceId",
        );
        print("Device left range: ${device.platformName}");
      }
      
      // Update nearest device
      _updateNearestDevice();
    }
  }
  
  void _updateNearestDevice() {
    if (nearbyDevices.isEmpty) {
      nearestDevice.value = null;
      nearestDeviceRSSI.value = 0;
      return;
    }
    
    String nearestDeviceId = '';
    int strongestRSSI = -1000;
    
    nearbyDevices.forEach((deviceId, device) {
      int rssi = deviceRSSI[deviceId] ?? -1000;
      if (rssi > strongestRSSI) {
        strongestRSSI = rssi;
        nearestDeviceId = deviceId;
      }
    });
    
    if (nearestDeviceId.isNotEmpty) {
      nearestDevice.value = nearbyDevices[nearestDeviceId];
      nearestDeviceRSSI.value = strongestRSSI;
    }
  }
  
  // Public methods
  void startScanning() {
    _startPeriodicScanning();
  }
  
  void stopScanning() {
    _stopScanning();
  }
  
  void clearDevices() {
    nearbyDevices.clear();
    deviceRSSI.clear();
    nearestDevice.value = null;
    nearestDeviceRSSI.value = 0;
  }
  
  // Get device info for UI
  String getDeviceName(BluetoothDevice device) {
    return device.platformName.isNotEmpty ? device.platformName : 'Unknown Device';
  }
  
  String getDeviceId(BluetoothDevice device) {
    return device.remoteId.toString();
  }
  
  int getDeviceRSSI(String deviceId) {
    return deviceRSSI[deviceId] ?? -1000;
  }
  
  bool isDeviceInRange(String deviceId) {
    return nearbyDevices.containsKey(deviceId);
  }
}