import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/ble_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final BLEController controller = Get.put(BLEController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLE Scanner"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bluetooth,
                          color: controller.isScanning.value
                              ? Colors.green
                              : Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "BLE Scanner Status",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                          controller.isScanning.value
                              ? "Scanning for BLE devices..."
                              : "Scanner stopped",
                          style: TextStyle(
                            color: controller.isScanning.value
                                ? Colors.green
                                : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        )),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Obx(
                            () => ElevatedButton.icon(
                              onPressed: controller.isScanning.value
                                  ? controller.stopScanning
                                  : controller.startScanning,
                              icon: Icon(
                                controller.isScanning.value
                                    ? Icons.stop
                                    : Icons.play_arrow,
                              ),
                              label: Text(
                                controller.isScanning.value
                                    ? "Stop Scanning"
                                    : "Start Scanning",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: controller.isScanning.value
                                    ? Colors.red
                                    : Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: controller.clearDevices,
                          icon: const Icon(Icons.clear),
                          label: const Text("Clear"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            // Nearest Device Card
            Obx(() {
              if (controller.nearestDevice.value != null) {
                return Card(
                  elevation: 4,
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.signal_cellular_4_bar,
                              color: Colors.green[700],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Nearest Device",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.green[700],
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller
                              .getDeviceName(controller.nearestDevice.value!),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "RSSI: ${controller.nearestDeviceRSSI.value} dBm",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "ID: ${controller.getDeviceId(controller.nearestDevice.value!)}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.signal_cellular_off,
                          color: Colors.grey[600],
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "No devices in range",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }),

            const SizedBox(height: 16),
            // All Discovered Devices List
            Obx(() => Text(
                  "All Discovered Devices (${controller.allDiscoveredDevices.length})",
                  style: Theme.of(context).textTheme.titleMedium,
                )),
            const SizedBox(height: 4),
            Obx(() => Text(
                  "Nearby Devices (${controller.nearbyDevices.length}) - RSSI > -70 dBm",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                )),
            const SizedBox(height: 8),

            Expanded(
              child: Obx(() {
                if (controller.allDiscoveredDevices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_disabled,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No BLE devices found",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Make sure Bluetooth is enabled and\nBLE devices are nearby",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: controller.allDiscoveredDevices.length,
                  itemBuilder: (context, index) {
                    final deviceId =
                        controller.allDiscoveredDevices.keys.elementAt(index);
                    final device = controller.allDiscoveredDevices[deviceId]!;
                    final rssi = controller.getDeviceRSSI(deviceId);
                    final isInRange =
                        controller.nearbyDevices.containsKey(deviceId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isInRange
                              ? Colors.green[100]
                              : Colors.orange[100],
                          child: Icon(
                            Icons.bluetooth,
                            color: isInRange
                                ? Colors.green[700]
                                : Colors.orange[700],
                          ),
                        ),
                        title: Text(
                          controller.getDeviceName(device),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("RSSI: $rssi dBm"),
                            Text(
                              "ID: ${controller.getDeviceId(device)}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isInRange ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isInRange ? "In Range" : "Weak Signal",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
