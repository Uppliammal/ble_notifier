import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/notification_service.dart';

class BLEController extends GetxController {
  // Observable variables
  var isScanning = false.obs;
  var nearbyDevices = <String, BluetoothDevice>{}.obs;
  var allDiscoveredDevices = <String, BluetoothDevice>{}.obs;
  var deviceRSSI = <String, int>{}.obs;
  var nearestDevice = Rxn<BluetoothDevice>();
  var nearestDeviceRSSI = 0.obs;
  
  // Configuration
  final int rssiThreshold = -70; // dBm threshold for "in range" (fixed as per assignment)
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
          isScanning.value = false;
        },
      );
      
      // Start scan with timeout
      await FlutterBluePlus.startScan(
        timeout: scanDuration,
        androidUsesFineLocation: true,
      );
      
    } catch (e) {
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
    print("=== BLE Scan Results: ${results.length} devices found ===");
    
    if (results.isEmpty) {
      print("No devices found in this scan cycle");
      return;
    }
    
    for (ScanResult result in results) {
      final device = result.device;
      final rssi = result.rssi;
      final deviceId = device.remoteId.toString();
      final deviceName = device.platformName.isNotEmpty ? device.platformName : 'Unknown Device';
      
      // Debug: Print all discovered devices with comprehensive details
      print("Device found: $deviceName (ID: $deviceId, RSSI: $rssi dBm)");
      print(" - Platform name: '${device.platformName}'");
      print(" - Local name: '${result.advertisementData.localName}'");
      print(" - Complete local name: '${result.advertisementData.advName}'");
      print(" - Appearance: '${result.advertisementData.appearance}'");
      print(" - Connectable: '${result.advertisementData.connectable}'");
      print(" - Manufacturer data: '${result.advertisementData.manufacturerData}'");
      print(" - Service data: '${result.advertisementData.serviceData}'");
      print(" - Service UUIDs: '${result.advertisementData.serviceUuids}'");
      print(" - TX Power Level: '${result.advertisementData.txPowerLevel}'");
      
      // Check if this could be our test device
      if (deviceName.toLowerCase().contains('test') || 
          result.advertisementData.advName?.toLowerCase().contains('test') == true ||
          result.advertisementData.localName?.toLowerCase().contains('test') == true) {
        print("POTENTIAL TEST BLE DEVICE FOUND!");
      }
      
      // Update device RSSI and track all devices
      deviceRSSI[deviceId] = rssi;
      allDiscoveredDevices[deviceId] = device;
      
      // Check if device is in range
      bool isInRange = rssi > rssiThreshold;
      bool wasInRange = nearbyDevices.containsKey(deviceId);
      
      // Log range status
      if (isInRange) {
        print("Device IN RANGE: $deviceName (RSSI: $rssi > threshold: $rssiThreshold)");
      } else {
        print("Device OUT OF RANGE: $deviceName (RSSI: $rssi <= threshold: $rssiThreshold)");
      }
      
      if (isInRange && !wasInRange) {
        // Device entered range
        print("Device ENTERED range: $deviceName - Sending notification");
        nearbyDevices[deviceId] = device;
        _notificationService.showNotification(
          title: "Device Nearby",
          body: "$deviceName is nearby (RSSI: $rssi dBm)",
          payload: "device_nearby_$deviceId",
        );
        
      } else if (!isInRange && wasInRange) {
        // Device left range
        print("Device LEFT range: $deviceName - Sending notification");
        nearbyDevices.remove(deviceId);
        _notificationService.showNotification(
          title: "Device Out of Range",
          body: "$deviceName is out of range",
          payload: "device_out_of_range_$deviceId",
        );
      } else if (isInRange && wasInRange) {
        print("Device STILL in range: $deviceName (RSSI: $rssi dBm)");
      } else {
        print("Device STILL out of range: $deviceName (RSSI: $rssi dBm)");
      }
      
      // Update nearest device
      _updateNearestDevice();
    }
    
    // Print scan summary
    print("=== Scan Summary ===");
    print("Total devices discovered: ${allDiscoveredDevices.length}");
    print("Devices in range (RSSI > $rssiThreshold): ${nearbyDevices.length}");
    print("Devices out of range: ${allDiscoveredDevices.length - nearbyDevices.length}");
    if (nearestDevice.value != null) {
      print("Nearest device: ${getDeviceName(nearestDevice.value!)} (RSSI: ${nearestDeviceRSSI.value} dBm)");
    } else {
      print("Nearest device: None in range");
    }
    print("=== End of scan results ===\n");
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
    allDiscoveredDevices.clear();
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
  
  // RSSI threshold is fixed at -70 dBm as per assignment requirements
}