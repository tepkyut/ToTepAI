// Example usage of Machine Monitoring Service
// This file shows how to integrate the automatic notifications with machine data

import 'package:flutter/material.dart';
import '../services/machine_monitoring_service.dart';
import '../pages/dashboard/notification.dart';

class MachineNotificationExample extends StatefulWidget {
  const MachineNotificationExample({super.key});

  @override
  State<MachineNotificationExample> createState() => _MachineNotificationExampleState();
}

class _MachineNotificationExampleState extends State<MachineNotificationExample> {
  final MachineMonitoringService _machineService = MachineMonitoringService();
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Start monitoring when the app initializes
    _machineService.startMonitoring();
  }

  @override
  void dispose() {
    // Stop monitoring when the app closes
    _machineService.stopMonitoring();
    super.dispose();
  }

  Future<void> _simulateMachineData() async {
    // This simulates what happens when your machine sends data
    await _notificationService.addNotification(
      title: '🔧 Machine Data Sync Started',
      message: 'Synchronizing data from machine sensors...',
      type: 'info',
    );

    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 2));

    await _notificationService.addNotification(
      title: '✅ Machine Data Sync Complete',
      message: 'All machine data has been successfully processed and analyzed.',
      type: 'success',
    );
  }

  Future<void> _manualMachineCheck() async {
    await _machineService.triggerManualCheck();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Machine Monitoring Demo'),
        backgroundColor: const Color(0xFF0981D1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Automatic Machine Monitoring',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'The system automatically monitors your machine data and sends notifications when:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              '• New harvest data is recorded\n'
              '• Harvest count is below optimal levels\n'
              '• Excellent harvest results are achieved\n'
              '• Weight optimization is needed\n'
              '• Machine activity is low\n'
              '• Data inconsistencies are detected',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _simulateMachineData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0981D1),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Simulate Machine Data Sync',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _manualMachineCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Manual Machine Status Check',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            const NotificationBell(),
          ],
        ),
      ),
    );
  }
}
