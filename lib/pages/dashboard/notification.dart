import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../../services/machine_monitoring_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'info', 'warning', 'success', 'harvest'
  final IconData icon; // Custom icon for each notification type

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'info',
    IconData? icon,
  }) : icon = icon ?? _getDefaultIcon(type);

  static IconData _getDefaultIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.celebration; // Celebration icon for success
      case 'warning':
        return Icons.warning_amber_rounded; // Warning icon
      case 'harvest':
        return Icons.precision_manufacturing; // Machine icon for fish harvest
      case 'info':
      default:
        return Icons.info_rounded; // Info icon
    }
  }

  // Get icon color based on notification type
  static Color _getIconColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'harvest':
        return Colors.brown;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'type': type,
      'iconData': icon.codePoint, // Store icon code point
    };
  }

  factory NotificationItem.fromMap(String id, Map<String, dynamic> map) {
    final iconCodePoint = map['iconData'] as int?;
    IconData? icon;
    if (iconCodePoint != null) {
      icon = IconData(iconCodePoint, fontFamily: 'MaterialIcons');
    }
    
    return NotificationItem(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'info',
      icon: icon,
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addNotification({
    required String title,
    required String message,
    String type = 'info',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Skip duplicate check for harvest notifications to ensure real-time updates
      if (type != 'harvest') {
        // Check if notification already exists in database
        final existingNotification = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('title', isEqualTo: title)
            .where('message', isEqualTo: message)
            .limit(1)
            .get();

        // If notification already exists, don't create duplicate
        if (existingNotification.docs.isNotEmpty) {
          print('Notification already exists, skipping: $title');
          return;
        }
      }

      final notification = NotificationItem(
        id: '',
        title: title,
        message: message,
        timestamp: DateTime.now(),
        type: type,
      );

      // Use batch write for better performance
      final batch = _firestore.batch();
      final notificationRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc();
      
      batch.set(notificationRef, notification.toMap());

      // Clean up old notifications (keep only last 50)
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .limit(51) // Get 51 to check if we need to delete
          .get();

      if (snapshot.docs.length > 50) {
        final docsToDelete = snapshot.docs.skip(50);
        for (final doc in docsToDelete) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
    } catch (e) {
      print('Error adding notification: $e');
    }
  }

  // Create welcome notifications only for new accounts
  Future<void> createWelcomeNotificationsForNewUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Check if user already has welcome notifications
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      final hasWelcomeNotifications = userData?['hasWelcomeNotifications'] ?? false;

      // Only create welcome notifications if they don't exist yet
      if (!hasWelcomeNotifications) {
        // Welcome notification
        await addNotification(
          title: 'Welcome To ToTepAI',
          message: 'Your smart fish farming assistant helps track and optimize your harvest. Get AI-powered recommendations and predictive analytics to maximize your bangus production.',
          type: 'info',
        );
        
        // Getting started guide
        await addNotification(
          title: 'Getting Started Guide 📋',
          message: 'Start recording your harvest data to get personalized insights. Use AI analytics on the home page to optimize your farming operations.',
          type: 'info',
        );
        
        // Pro tip
        await addNotification(
          title: 'Pro Tip 💡',
          message: 'Track daily harvest patterns to boost production. AI analytics helps identify the best strategies based on fish behavior. Increase yield by up to 30% and reduce costs.',
          type: 'success',
        );

        // Mark that welcome notifications have been created for this user
        await _firestore
            .collection('users')
            .doc(user.uid)
            .update({'hasWelcomeNotifications': true});
        
        print('Welcome notifications created for new user');
      } else {
        print('Welcome notifications already exist for this user');
      }
    } catch (e) {
      print('Error creating welcome notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  Stream<List<NotificationItem>> getNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .handleError((error) {
          print('Error in notification stream: $error');
        })
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationItem.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<QuerySnapshot> getNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .handleError((error) {
          print('Error in notification stream: $error');
        });
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing all notifications: $e');
    }
  }

  // Machine data monitoring methods
  StreamSubscription? _machineDataSubscription;
  DateTime? _lastHarvestNotification;
  String? _lastHarvestDataHash; // Store hash of last harvest data to prevent duplicates
  final Set<String> _processedDocumentIds = {}; // Track processed document IDs
  bool _isMonitoring = false; // Track if monitoring is active

  void startMachineDataMonitoring() {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_isMonitoring) {
      print('🔥 DEBUG: Machine data monitoring is already active');
      return;
    }

    print('🔥 DEBUG: Starting machine data monitoring for user ${user.uid}');

    // Listen to all harvest data changes in real-time
    _machineDataSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('harvest_data')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      print('🔥 DEBUG: Harvest data snapshot received with ${snapshot.docChanges.length} changes');
      
      // Process only ADDED documents, not modified ones to prevent duplicates
      for (final docChange in snapshot.docChanges) {
        if (docChange.type == DocumentChangeType.added) {
          final documentId = docChange.doc.id;
          final harvestData = docChange.doc.data();
          
          // Check if we've already processed this document
          if (_processedDocumentIds.contains(documentId)) {
            print('🔥 DEBUG: Document $documentId already processed, skipping');
            continue;
          }
          
          if (harvestData != null) {
            print('🔥 DEBUG: New harvest data ADDED detected - Document ID: $documentId');
            _processedDocumentIds.add(documentId); // Mark as processed
            _isMonitoring = true; // Mark monitoring as active
            _processMachineData(harvestData);
          }
        }
      }
    });

    _isMonitoring = true;
    print('🔥 DEBUG: Machine data monitoring started successfully');
  }

  void stopMachineDataMonitoring() {
    if (!_isMonitoring) {
      print('🔥 DEBUG: Machine data monitoring is not active');
      return;
    }

    print('🔥 DEBUG: Stopping machine data monitoring');
    _machineDataSubscription?.cancel();
    _machineDataSubscription = null;
    _processedDocumentIds.clear(); // Clear processed document IDs when stopping
    _isMonitoring = false;
    print('🔥 DEBUG: Machine data monitoring stopped');
  }

  Future<void> _processMachineData(Map<String, dynamic> harvestData) async {
    try {
      print('🔥 DEBUG: _processMachineData called');
      
      final timestamp = (harvestData['timestamp'] as Timestamp).toDate();
      
      final totalPieces = harvestData['totalPiecesOfHarvest'] as int? ?? 0;
      final totalWeight = harvestData['totalWeightOfHarvest'] as double? ?? 0.0;
      final month = harvestData['monthOfHarvest'] as String? ?? '';
      final year = harvestData['yearOfHarvest'] as int? ?? 0;
      final threeInOne = harvestData['threeInOneTotalPieces'] as int? ?? 0;
      final fourInOne = harvestData['fourInOneTotalPieces'] as int? ?? 0;
      final twoInOne = harvestData['twoInOneTotalPieces'] as int? ?? 0;
      final sardines = harvestData['sardinesTotalPieces'] as int? ?? 0;

      // Skip if no harvest data
      if (totalPieces == 0 && totalWeight == 0.0) {
        print('🔥 DEBUG: No harvest data, skipping');
        return;
      }

      // Create hash of harvest data to detect duplicates
      final currentDataHash = _createHarvestDataHash(
        totalPieces, totalWeight, month, year, 
        threeInOne, fourInOne, twoInOne, sardines
      );
      
      print('🔥 DEBUG: Data hash: $currentDataHash, Last hash: $_lastHarvestDataHash');
      
      // Skip if this is the same data as before (duplicate prevention)
      if (_lastHarvestDataHash == currentDataHash) {
        print('🔥 DEBUG: Same data as before, skipping notification');
        return;
      }
      
      // Avoid duplicate notifications within 60 seconds
      if (_lastHarvestNotification != null && 
          timestamp.difference(_lastHarvestNotification!).inSeconds < 60) {
        print('🔥 DEBUG: Too soon since last notification, skipping');
        return;
      }

      print('🔥 DEBUG: Creating New Harvest Data Recorded notification');

      // 1. New Harvest Data Recorded notification - using same type as Top Performing Category
      await addNotification(
        title: 'New Harvest Data Recorded',
        message: 'Harvest data for $month $year has been successfully recorded. Total pieces: $totalPieces, Total weight: ${totalWeight.toStringAsFixed(2)} kg.',
        type: 'success', // Changed from 'harvest' to 'success' to match Top Performing Category
      );

      print('🔥 DEBUG: New Harvest Data Recorded notification created');

      // 2. Real-time Top Performing Category notification for this harvest
      await _createRealTimeTopPerformingCategoryNotification(
        totalPieces, threeInOne, fourInOne, twoInOne, sardines, month, year
      );

      _lastHarvestNotification = timestamp;
      _lastHarvestDataHash = currentDataHash;
    } catch (e) {
      print('🔥 DEBUG: Error processing machine data: $e');
    }
  }

  // Create real-time Top Performing Category notification for new harvest data
  Future<void> _createRealTimeTopPerformingCategoryNotification(
    int totalPieces,
    int threeInOne,
    int fourInOne,
    int twoInOne,
    int sardines,
    String month,
    int year,
  ) async {
    try {
      if (totalPieces == 0) return;

      final categories = {
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
        print('🔥 DEBUG: Creating real-time Top Performing Category notification');
        
        await addNotification(
          title: 'Top Performing Category',
          message: '$bestCategory is your best performer for $month $year with $bestCount pieces (${(bestCount / totalPieces * 100).round()}% of total).',
          type: 'success',
        );
        
        print('🔥 DEBUG: Real-time Top Performing Category notification created');
      }
    } catch (e) {
      print('🔥 DEBUG: Error creating real-time Top Performing Category notification: $e');
    }
  }

  // Create a hash from harvest data to detect duplicates
  String _createHarvestDataHash(
    int totalPieces,
    double totalWeight,
    String month,
    int year,
    int threeInOne,
    int fourInOne,
    int twoInOne,
    int sardines,
  ) {
    // Create a string representation of all harvest data
    final dataString = '$totalPieces|$totalWeight|$month|$year|$threeInOne|$fourInOne|$twoInOne|$sardines';
    return dataString;
  }

  // Check if a notification with specific title already exists
  Future<bool> _notificationExists(String title) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final existingNotification = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('title', isEqualTo: title)
          .limit(1)
          .get();

      return existingNotification.docs.isNotEmpty;
    } catch (e) {
      print('Error checking notification existence: $e');
      return false;
    }
  }

  // Check if there's already a notification for this specific harvest data
  Future<bool> _hasHarvestDataNotification(String dataHash) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Look for "New Harvest Data Recorded" notifications with matching data in the message
      final existingNotifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('title', isEqualTo: 'New Harvest Data Recorded')
          .orderBy('timestamp', descending: true)
          .limit(20) // Check last 20 harvest notifications for better duplicate detection
          .get();

      // Extract the data from the message and compare with current hash
      for (final doc in existingNotifications.docs) {
        final message = doc.data()['message'] as String? ?? '';
        
        // Parse the message to extract harvest data
        final extractedHash = _extractHashFromMessage(message);
        if (extractedHash == dataHash) {
          print('Found existing notification with same harvest data: $dataHash');
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Error checking harvest data notification existence: $e');
      return false;
    }
  }

  // Extract hash from notification message by parsing the harvest data
  String _extractHashFromMessage(String message) {
    try {
      // Example message: "Harvest data for April 2026 has been successfully recorded. Total pieces: 750, Total weight: 230.00 kg."
      // We need to extract the data and create a hash, but since we don't have all the details in the message,
      // we'll use a simpler approach by checking if the message contains the same totals
      
      // Extract total pieces and weight from message
      final piecesRegex = RegExp(r'Total pieces: (\d+)');
      final weightRegex = RegExp(r'Total weight: ([\d.]+) kg');
      final monthYearRegex = RegExp(r'Harvest data for (\w+) (\d+)');
      
      final piecesMatch = piecesRegex.firstMatch(message);
      final weightMatch = weightRegex.firstMatch(message);
      final monthYearMatch = monthYearRegex.firstMatch(message);
      
      if (piecesMatch != null && weightMatch != null && monthYearMatch != null) {
        final totalPieces = piecesMatch.group(1) ?? '0';
        final totalWeight = weightMatch.group(1) ?? '0.0';
        final month = monthYearMatch.group(1) ?? '';
        final year = monthYearMatch.group(2) ?? '';
        
        // Create a simplified hash from the message data
        return '$totalPieces|$totalWeight|$month|$year';
      }
      
      return '';
    } catch (e) {
      print('Error extracting hash from message: $e');
      return '';
    }
  }

  // Generate notifications based on harvest data from home and forecast pages
  Future<void> generateDataBasedNotifications({
    required Map<int, List<num>> totalBangusDataByYear,
    required Map<int, List<num>> threeInOneDataByYear,
    required Map<int, List<num>> fourInOneDataByYear,
    required Map<int, List<num>> twoInOneDataByYear,
    required Map<int, List<num>> sardinesDataByYear,
    required Map<int, List<int>> recordCountByYear,
    String userRole = 'user',
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month - 1; // Convert to 0-based index

      // Get current month data
      final currentMonthTotal = totalBangusDataByYear[currentYear]?[currentMonth] ?? 0;
      final currentMonthSardines = sardinesDataByYear[currentYear]?[currentMonth] ?? 0;
      final currentMonthTwoInOne = twoInOneDataByYear[currentYear]?[currentMonth] ?? 0;
      final currentMonthFourInOne = fourInOneDataByYear[currentYear]?[currentMonth] ?? 0;
      final currentMonthThreeInOne = threeInOneDataByYear[currentYear]?[currentMonth] ?? 0;

      // Only generate Top Performing Category notification if there's data
      if (currentMonthTotal > 0) {
        final categories = {
          'Sardines': currentMonthSardines,
          '2-1': currentMonthTwoInOne,
          '4-1': currentMonthFourInOne,
          '3-1': currentMonthThreeInOne,
        };

        String bestCategory = '';
        num bestCount = 0;
        categories.forEach((category, count) {
          if (count > bestCount) {
            bestCount = count;
            bestCategory = category;
          }
        });

        if (bestCategory.isNotEmpty && bestCount > 0) {
          final categoryTitle = 'Top Performing Category';
          if (!await _notificationExists(categoryTitle)) {
            await addNotification(
              title: categoryTitle,
              message: '$bestCategory leads this month with $bestCount pieces (${(bestCount / currentMonthTotal * 100).round()}% of total).',
              type: 'success',
            );
          }
        }
      }

      print('Data-based notifications generated successfully');
    } catch (e) {
      print('Error generating data-based notifications: $e');
    }
  }

  String _getMonthName(int monthIndex) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return months[monthIndex];
  }
}

class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final NotificationService _notificationService = NotificationService();
  int _unreadCount = 0;
  StreamSubscription<List<NotificationItem>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    _notificationSubscription = _notificationService.getNotifications().listen((_) {
      _loadUnreadCount(); // Refresh count when notifications change
    }, onError: (error) {
      print('Error in notification stream: $error');
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () async {
            try {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
              _loadUnreadCount(); // Refresh count after returning
            } catch (e) {
              print('Error navigating to notifications: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error opening notifications'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0981D1),
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              if (value == 'mark_all_read') {
                await _notificationService.markAllAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('All notifications marked as read'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else if (value == 'clear_all') {
                final confirm = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 10,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey.shade50,
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Warning Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.delete_sweep_rounded,
                              size: 32,
                              color: Colors.red.shade600,
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Title
                          const Text(
                            "Clear All Notifications",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          
                          // Message
                          const Text(
                            "Are you sure you want to clear all notifications?\nThis action cannot be undone.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          
                          // Notification count
                          StreamBuilder<QuerySnapshot>(
                            stream: _notificationService.getNotificationsStream(),
                            builder: (context, snapshot) {
                              final count = snapshot.data?.docs.length ?? 0;
                              if (count > 0) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    "$count notification${count == 1 ? '' : 's'} will be deleted",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }
                              return const Text(
                                "No notifications to clear",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          
                          // Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: Colors.grey.shade300),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.delete_sweep_rounded,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Clear All",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                
                if (confirm == true) {
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade600),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Clearing notifications...",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                  
                  // Clear notifications with real-time feedback
                  await _notificationService.clearAllNotifications();
                  
                  // Close loading dialog
                  if (mounted) {
                    Navigator.pop(context);
                    
                    // Show success message with animation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            const Text('All notifications cleared successfully'),
                          ],
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read, size: 18),
                    SizedBox(width: 8),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 18),
                    SizedBox(width: 8),
                    Text('Clear all'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationItem>>(
        stream: _notificationService.getNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0981D1)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0981D1),
                    ),
                    child: const Text('Retry', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'re all caught up!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                onDismissed: (direction) async {
                  try {
                    await _notificationService.deleteNotification(notification.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notification deleted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error deleting notification: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error deleting notification: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: NotificationTile(
                  notification: notification,
                  onTap: () async {
                    try {
                      if (!notification.isRead) {
                        await _notificationService.markAsRead(notification.id);
                      }
                    } catch (e) {
                      print('Error marking notification as read: $e');
                    }
                  },
                  onDelete: () async {
                    try {
                      await _notificationService.deleteNotification(notification.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notification deleted'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error deleting notification: $e');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationTile extends StatefulWidget {
  final NotificationItem notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  bool _isExpanded = false;
  bool _isTitleExpanded = false;

  Color _getTypeColor(String type) {
    return NotificationItem._getIconColor(type);
  }

  IconData _getTypeIcon(String type) {
    return NotificationItem._getDefaultIcon(type);
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final messageTextStyle = GoogleFonts.poppins(
      fontSize: 14,
      color: widget.notification.isRead 
          ? Colors.grey.shade600 
          : Colors.grey.shade700,
      height: 1.4,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.notification.isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: widget.notification.isRead 
              ? Colors.grey.shade200 
              : _getTypeColor(widget.notification.type).withOpacity(0.3),
          width: widget.notification.isRead ? 1 : 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced Icon Container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getTypeColor(widget.notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getTypeColor(widget.notification.type).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: widget.notification.title.contains('Welcome To ToTepAI') 
                    ? Image.asset(
                        'assets/icon/fish.png',
                        width: 24,
                        height: 24,
                        color: _getTypeColor(widget.notification.type),
                      )
                    : Icon(
                        widget.notification.icon,
                        color: _getTypeColor(widget.notification.type),
                        size: 24,
                      ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with expand/collapse functionality
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final titleTextStyle = GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: widget.notification.isRead 
                                ? FontWeight.w500 
                                : FontWeight.w600,
                            color: widget.notification.isRead 
                                ? Colors.grey.shade700 
                                : Colors.black87,
                          );
                          
                          // Create a text painter to check if title overflows
                          final titleTextPainter = TextPainter(
                            text: TextSpan(
                              text: widget.notification.title,
                              style: titleTextStyle,
                            ),
                            maxLines: 2,
                            textDirection: TextDirection.ltr,
                          );
                          titleTextPainter.layout(maxWidth: constraints.maxWidth);
                          final isTitleOverflowing = titleTextPainter.didExceedMaxLines;
                          
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_isTitleExpanded)
                                      Text(
                                        widget.notification.title,
                                        style: titleTextStyle,
                                        maxLines: null,
                                        overflow: TextOverflow.visible,
                                        softWrap: true,
                                      )
                                    else
                                      Text(
                                        widget.notification.title,
                                        style: titleTextStyle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    if (isTitleOverflowing && !_isTitleExpanded)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isTitleExpanded = true;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            '... more',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: _getTypeColor(widget.notification.type),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (isTitleOverflowing && _isTitleExpanded)
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isTitleExpanded = false;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Text(
                                            'show less',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: _getTypeColor(widget.notification.type),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (!widget.notification.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: BoxDecoration(
                                    color: _getTypeColor(widget.notification.type),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      // Message text with expand/collapse functionality
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Create a text painter to check if text actually overflows
                          final textPainter = TextPainter(
                            text: TextSpan(
                              text: widget.notification.message,
                              style: messageTextStyle,
                            ),
                            maxLines: 3,
                            textDirection: TextDirection.ltr,
                          );
                          textPainter.layout(maxWidth: constraints.maxWidth);
                          final isTextOverflowing = textPainter.didExceedMaxLines;
                          
                          // Additional fallback: check if message is long enough to potentially overflow
                          final isLongMessage = widget.notification.message.length > 100;
                          final shouldShowMore = isTextOverflowing || isLongMessage;
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isExpanded)
                                Container(
                                  constraints: const BoxConstraints(),
                                  child: Text(
                                    widget.notification.message,
                                    style: messageTextStyle,
                                    maxLines: null,
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
                                  ),
                                )
                              else
                                Text(
                                  widget.notification.message,
                                  style: messageTextStyle,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (shouldShowMore && !_isExpanded)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isExpanded = true;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      '... more',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: _getTypeColor(widget.notification.type),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              if (shouldShowMore && _isExpanded)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isExpanded = false;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'show less',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: _getTypeColor(widget.notification.type),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDateTime(widget.notification.timestamp),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const Spacer(),
                          // Delete button
                          GestureDetector(
                            onTap: widget.onDelete,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}