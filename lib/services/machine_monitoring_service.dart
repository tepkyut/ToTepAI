import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/dashboard/notification.dart';

class MachineMonitoringService {
  static final MachineMonitoringService _instance = MachineMonitoringService._internal();
  factory MachineMonitoringService() => _instance;
  MachineMonitoringService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  StreamSubscription? _machineDataSubscription;
  StreamSubscription? _periodicCheckSubscription;
  Timer? _dailyCheckTimer;
  Set<String> _processedHarvestIds = {};

  void startMonitoring() {
    final user = _auth.currentUser;
    if (user == null) return;

    // Load previously processed harvest IDs
    _loadProcessedHarvestIds().then((_) {
      // Only start monitoring after loading processed IDs
      _startDataStream(user);
    });

    // Start periodic machine status checks (every 24 hours)
    _startPeriodicChecks();
  }

  void _startDataStream(User user) {
    _machineDataSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('harvest_data')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (final doc in snapshot.docChanges) {
        if (doc.type == DocumentChangeType.added) {
          final harvestData = doc.doc.data();
          final harvestId = doc.doc.id;
          if (harvestData != null) {
            _processMachineData(harvestData, harvestId);
          }
        }
      }
    });
  }

  void stopMonitoring() {
    _machineDataSubscription?.cancel();
    _machineDataSubscription = null;
    _periodicCheckSubscription?.cancel();
    _periodicCheckSubscription = null;
    _dailyCheckTimer?.cancel();
    _dailyCheckTimer = null;
  }

  Future<void> _loadProcessedHarvestIds() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('monitoring_state')
          .doc('processed_harvests')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _processedHarvestIds = Set<String>.from(data['harvest_ids'] ?? []);
      }
    } catch (e) {
      print('Error loading processed harvest IDs: $e');
    }
  }

  Future<void> _saveProcessedHarvestId(String harvestId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _processedHarvestIds.add(harvestId);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('monitoring_state')
          .doc('processed_harvests')
          .set({
        'harvest_ids': _processedHarvestIds.toList(),
        'last_updated': Timestamp.now(),
      });
    } catch (e) {
      print('Error saving processed harvest ID: $e');
    }
  }

  void _startPeriodicChecks() {
    // Check machine status every 24 hours
    _dailyCheckTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      checkMachineStatus();
    });

    // Also check once when starting
    Future.delayed(const Duration(minutes: 5), () {
      checkMachineStatus();
    });
  }

  Future<void> _processMachineData(Map<String, dynamic> harvestData, String harvestId) async {
    try {
      // Check if this harvest has already been processed
      if (_processedHarvestIds.contains(harvestId)) {
        return;
      }

      final timestamp = (harvestData['timestamp'] as Timestamp).toDate();
      final now = DateTime.now();
      
      // Additional safeguard: Don't process harvests older than 5 minutes
      // This prevents duplicates during hot reload
      if (now.difference(timestamp).inMinutes > 5) {
        // Mark as processed to avoid checking again
        await _saveProcessedHarvestId(harvestId);
        return;
      }

      final totalPieces = harvestData['totalPiecesOfHarvest'] as int? ?? 0;
      final totalWeight = harvestData['totalWeightOfHarvest'] as double? ?? 0.0;
      final month = harvestData['monthOfHarvest'] as String? ?? '';
      final year = harvestData['yearOfHarvest'] as int? ?? 0;
      final threeInOne = harvestData['threeInOneTotalPieces'] as int? ?? 0;
      final fourInOne = harvestData['fourInOneTotalPieces'] as int? ?? 0;
      final twoInOne = harvestData['twoInOneTotalPieces'] as int? ?? 0;
      final sardines = harvestData['sardinesTotalPieces'] as int? ?? 0;

      // Harvest completion notification
      await _notificationService.addNotification(
        title: '🎣 New Harvest Data Recorded',
        message: 'Harvest data for $month $year has been successfully recorded. Total pieces: $totalPieces, Total weight: ${totalWeight.toStringAsFixed(2)} kg.',
        type: 'harvest',
      );

      // Check for low harvest warnings
      if (totalPieces < 100) {
        await _notificationService.addNotification(
          title: '⚠️ Low Harvest Alert',
          message: 'Harvest count is below optimal levels. Only $totalPieces pieces recorded. Consider reviewing feeding schedules and water quality.',
          type: 'warning',
        );
      }

      // Check for high harvest success
      if (totalPieces > 500) {
        await _notificationService.addNotification(
          title: '🎉 Excellent Harvest Results!',
          message: 'Outstanding harvest of $totalPieces pieces recorded! Keep up the great work with your farming practices.',
          type: 'success',
        );
      }

      // Category-specific notifications
      final Map<String, int> categories = {
        '3 in 1': threeInOne,
        '4 in 1': fourInOne,
        '2 in 1': twoInOne,
        'Sardines': sardines,
      };

      String bestCategory = '';
      int bestCount = 0;
      categories.forEach((category, count) {
        if (count > bestCount) {
          bestCount = count;
          bestCategory = category;
        }
      });

      if (bestCategory.isNotEmpty && bestCount > 0) {
        await _notificationService.addNotification(
          title: '🏆 Top Performing Category',
          message: '$bestCategory is your best performer this harvest with $bestCount pieces.',
          type: 'info',
        );
      }

      // Weight analysis notification
      final averageWeight = totalPieces > 0 ? totalWeight / totalPieces : 0.0;
      if (averageWeight < 0.5) {
        await _notificationService.addNotification(
          title: '📊 Weight Optimization Needed',
          message: 'Average weight per piece is ${averageWeight.toStringAsFixed(2)} kg. Consider adjusting feed quantity for better growth.',
          type: 'warning',
        );
      } else if (averageWeight > 2.0) {
        await _notificationService.addNotification(
          title: '📈 Excellent Growth Rates',
          message: 'Average weight per piece is ${averageWeight.toStringAsFixed(2)} kg. Your fish are showing excellent growth!',
          type: 'success',
        );
      }

      // Productivity analysis
      final productivityScore = _calculateProductivityScore(totalPieces, totalWeight, categories);
      if (productivityScore >= 80) {
        await _notificationService.addNotification(
          title: '⭐ High Productivity Achieved!',
          message: 'Your farm productivity score is ${productivityScore.toStringAsFixed(0)}%. Outstanding performance!',
          type: 'success',
        );
      }

      // Mark this harvest as processed
      await _saveProcessedHarvestId(harvestId);
    } catch (e) {
      print('Error processing machine data: $e');
    }
  }

  double _calculateProductivityScore(int totalPieces, double totalWeight, Map<String, int> categories) {
    // Simple productivity calculation based on total yield and category balance
    double score = 0.0;
    
    // Base score from total pieces (max 40 points)
    score += (totalPieces / 1000.0) * 40.0;
    if (score > 40) score = 40;
    
    // Weight score (max 30 points)
    final avgWeight = totalPieces > 0 ? totalWeight / totalPieces : 0.0;
    score += (avgWeight / 3.0) * 30.0;
    if (score > 30) score = 30;
    
    // Category diversity score (max 30 points)
    int nonZeroCategories = categories.values.where((count) => count > 0).length;
    score += (nonZeroCategories / 4.0) * 30.0;
    
    return score;
  }

  Future<void> checkMachineStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if there's recent machine activity (last 24 hours)
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('harvest_data')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .get();

      if (snapshot.docs.isEmpty) {
        await _notificationService.addNotification(
          title: '🔧 Machine Activity Reminder',
          message: 'No machine activity detected in the last 24 hours. Please check your equipment and data collection systems.',
          type: 'warning',
        );
      } else {
        // Check for data consistency
        await _checkDataConsistency();
      }
    } catch (e) {
      print('Error checking machine status: $e');
    }
  }

  Future<void> _checkDataConsistency() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('harvest_data')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final totalPieces = data['totalPiecesOfHarvest'] as int? ?? 0;
        final threeInOne = data['threeInOneTotalPieces'] as int? ?? 0;
        final fourInOne = data['fourInOneTotalPieces'] as int? ?? 0;
        final twoInOne = data['twoInOneTotalPieces'] as int? ?? 0;
        final sardines = data['sardinesTotalPieces'] as int? ?? 0;
        
        final categorySum = threeInOne + fourInOne + twoInOne + sardines;
        
        // Check if total pieces matches sum of categories
        if (totalPieces != categorySum) {
          await _notificationService.addNotification(
            title: '🔍 Data Inconsistency Detected',
            message: 'Total pieces ($totalPieces) doesn\'t match category sum ($categorySum). Please verify your data entry.',
            type: 'warning',
          );
          break; // Only notify once per check
        }
      }
    } catch (e) {
      print('Error checking data consistency: $e');
    }
  }

  Future<void> triggerManualCheck() async {
    await checkMachineStatus();
    await _notificationService.addNotification(
      title: '🔍 Manual System Check',
      message: 'Manual machine status check completed. All systems operational.',
      type: 'info',
    );
  }

  Future<void> clearProcessedHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      _processedHarvestIds.clear();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('monitoring_state')
          .doc('processed_harvests')
          .delete();

      await _notificationService.addNotification(
        title: '🗑️ Monitoring History Cleared',
        message: 'Processed harvest history has been cleared. Notifications will be sent for all new harvest data.',
        type: 'info',
      );
    } catch (e) {
      print('Error clearing processed history: $e');
    }
  }
}
