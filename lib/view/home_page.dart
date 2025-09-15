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
                        )),
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


            // Nearby Devices List
            Obx(() => Text(
                  "Nearby Devices (${controller.nearbyDevices.length})",
                  style: Theme.of(context).textTheme.titleMedium,
                )),
            const SizedBox(height: 8),

            Expanded(
              child: Obx(() {
                if (controller.nearbyDevices.isEmpty) {
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
                  itemCount: controller.nearbyDevices.length,
                  itemBuilder: (context, index) {
                    final deviceId =
                        controller.nearbyDevices.keys.elementAt(index);
                    final device = controller.nearbyDevices[deviceId]!;
                    final rssi = controller.getDeviceRSSI(deviceId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Icon(
                            Icons.bluetooth,
                            color: Colors.blue[700],
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
                            color: rssi > -70 ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            rssi > -70 ? "In Range" : "Weak Signal",
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
