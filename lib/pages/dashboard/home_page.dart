import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'package:totepai/utils/responsive.dart';
import 'package:totepai/services/translation_service.dart';
import 'package:totepai/services/language_persistence.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controllers/firebase_auth.dart';
import 'widgets/stat_card.dart';
import 'forecast_page.dart';
import 'profile_page.dart';
import 'notification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  late final PageController _pageController;

  final List<Widget> _pages = [
    const DashboardContent(),
    const ForecastPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF0981D1).withOpacity(0.05),
                blurRadius: 30,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: const Color(0xFF0981D1),
              unselectedItemColor: Colors.grey.shade500,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: _buildNavItems(),
            ),
          ),
        ),
      ),
    );
  }
}

extension on _HomePageState {
  List<BottomNavigationBarItem> _buildNavItems() {
    const brand = Color(0xFF00AEEF);
    return [
      BottomNavigationBarItem(
        icon: const Icon(Icons.dashboard_outlined),
        activeIcon: _ActiveNavIcon(icon: Icons.dashboard_rounded, color: brand),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.show_chart_outlined),
        activeIcon: _ActiveNavIcon(icon: Icons.show_chart, color: brand),
        label: 'Forecast',
      ),
      BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: _ActiveNavIcon(icon: Icons.person, color: brand),
        label: 'Profile',
      ),
    ];
  }
}

class _ActiveNavIcon extends StatelessWidget {
  const _ActiveNavIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon, 
        color: color,
        size: 24,
      ),
    );
  }
}

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

// Data class for product items
class _ProductItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ProductItem(this.title, this.value, this.icon, this.color);
}

class _DashboardContentState extends State<DashboardContent> {
  int? selectedYear;
  int selectedMonth = 11; // December, latest month
  int tooltipOffset = 0;
  List<int> yearOptions = [];
  String _selectedLanguage = 'English';
  
  // User data
  Map<String, dynamic>? userData;
  String userName = 'Farmer'; // Default fallback
  String userStatus = 'active'; // Default fallback
  
  // Current harvest data
  Map<String, dynamic>? currentHarvestData;
  
  // Auth controller for status checking
  final AuthController _authController = AuthController();

  // Data storage for total bangus by year and month (12 months per year)
  Map<int, List<num>> totalBangusDataByYear = {};

  // Data for summary categories per year and month
  Map<int, List<num>> totalWeightDataByYear = {};
  Map<int, List<num>> threeInOneDataByYear = {};
  Map<int, List<num>> fourInOneDataByYear = {};
  Map<int, List<num>> twoInOneDataByYear = {};
  Map<int, List<num>> sardinesDataByYear = {};

  // Count of records per year and month (to distinguish true zero vs no record)
  Map<int, List<int>> recordCountByYear = {};

  // Harvest remarks data
  Map<int, Map<int, String>> harvestRemarksByYear = {}; // year -> month -> remarks
  String? currentHarvestRemarks;
  bool _isLoadingRemarks = false;
  bool _isHarvestRemarksExpanded = false;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isHarvesting = false;
  bool _isGloballyHarvesting = false; // Track if any user is harvesting
  String? _activeHarvestingUser; // Track who is currently harvesting
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  StreamSubscription<QuerySnapshot>? _globalStatusSubscription;
  StreamSubscription<QuerySnapshot>? _forecastRemarksSubscription;
  final NotificationService _notificationService = NotificationService();
  
  // Harvest result dialog state
  bool _showHarvestResultDialog = false;
  Map<String, dynamic>? _harvestResultData;
  String? _lastShownHarvestId; // Track ID of last shown harvest to prevent duplicates

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _loadLastShownHarvestId(); // Load the last shown harvest ID
    _loadHarvestData();
    _createWelcomeNotifications();
    _fetchUserData();
    _startStatusListener();
    _startGlobalStatusListener();
    _startForecastRemarksListener();
    // Start real-time machine data monitoring for notifications
    _notificationService.startMachineDataMonitoring();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for language changes when returning from profile page
    _loadSavedLanguage();
  }

  @override
  void dispose() {
    // Cancel any ongoing operations to prevent memory leaks
    _statusSubscription?.cancel();
    _globalStatusSubscription?.cancel();
    _forecastRemarksSubscription?.cancel();
    // Stop real-time machine data monitoring
    _notificationService.stopMachineDataMonitoring();
    super.dispose();
  }

  // Start real-time status listener
  void _startStatusListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _statusSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
          if (mounted && snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>?;
            if (data != null) {
              final status = data['status'];
              final bool isHarvestingActive = status == 1;
              
              setState(() {
                _isHarvesting = isHarvestingActive;
                userStatus = data['status']?.toString() ?? 'inactive';
              });
              
              print('User status updated: $status (isHarvesting: $isHarvestingActive)');
            }
          }
        }, onError: (error) {
          print('Error listening to status changes: $error');
        });
  }

  // Start global status listener to check if any user is harvesting
  void _startGlobalStatusListener() {
    _globalStatusSubscription = FirebaseFirestore.instance
        .collection('users')
        .where('status', isEqualTo: 1)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
          if (mounted) {
            if (snapshot.docs.isNotEmpty) {
              // Get the first active user (there should only be one)
              final activeUser = snapshot.docs.first;
              final userData = activeUser.data() as Map<String, dynamic>?;
              final activeUserName = userData?['name'] ?? 'Unknown User';
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              final activeUserId = activeUser.id;
              
              setState(() {
                _isGloballyHarvesting = true;
                _activeHarvestingUser = activeUserId == currentUserId ? 'You' : activeUserName;
              });
              
              print('Global: Active harvesting detected: $activeUserName ($activeUserId)');
            } else {
              setState(() {
                _isGloballyHarvesting = false;
                _activeHarvestingUser = null;
              });
              
              print('Global: No active harvesting detected');
            }
          }
        }, onError: (error) {
          print('Error listening to global status changes: $error');
        });
  }

  // Start real-time forecast remarks listener
  void _startForecastRemarksListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print('Setting up real-time forecast remarks listener');
    
    _forecastRemarksSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('harvest_data')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
          if (mounted && snapshot.docs.isNotEmpty) {
            // Get the latest document (first after ordering by timestamp descending)
            final doc = snapshot.docs.first;
            final data = doc.data() as Map<String, dynamic>?;
            final docId = doc.id; // Get document ID
            
            if (data != null) {
              // Access geminiForecastRemarks directly from the document
              final remarks = data['geminiForecastRemarks']?.toString();
              if (remarks != null && remarks.trim().isNotEmpty) {
                // Update the latest month's remarks
                final currentYear = DateTime.now().year;
                final currentMonth = DateTime.now().month - 1; // Convert to 0-based
                
                setState(() {
                  harvestRemarksByYear[currentYear] ??= <int, String>{};
                  harvestRemarksByYear[currentYear]![currentMonth] = remarks;
                  currentHarvestRemarks = remarks;
                });
                
                print('Real-time forecast remarks updated: $remarks');
              }
              
              // Check if this is new harvest data and show dialog
              if (_lastShownHarvestId != docId && data['totalPiecesOfHarvest'] != null) {
                final timestamp = data['timestamp'] as Timestamp?;
                if (timestamp != null) {
                  final now = DateTime.now();
                  final harvestTime = timestamp.toDate();
                  final difference = now.difference(harvestTime);
                  
                  // Show dialog for:
                  // 1. New harvest data (within 5 minutes), OR
                  // 2. New users who haven't seen any harvest results yet (_lastShownHarvestId is null)
                  final bool isNewUser = _lastShownHarvestId == null;
                  final bool shouldShowDialog = (difference.inMinutes < 5 || isNewUser) && !_showHarvestResultDialog;
                  
                  print('Harvest dialog check: isNewUser=$isNewUser, difference=${difference.inMinutes}min, shouldShow=$shouldShowDialog');
                  
                  if (shouldShowDialog) {
                    setState(() {
                      _harvestResultData = data;
                      _showHarvestResultDialog = true;
                      _lastShownHarvestId = docId;
                    });
                    
                    // Save to persistent storage
                    _saveLastShownHarvestId(docId);
                    
                    // Show the dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return _buildHarvestResultDialog();
                      },
                    );
                  }
                }
              }
            }
          }
        }, onError: (error) {
          print('Error listening to forecast remarks changes: $error');
        });
  }

  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await LanguagePersistence.getLanguage();
    if (_selectedLanguage != savedLanguage) {
      setState(() {
        _selectedLanguage = savedLanguage;
      });
    }
  }

  // Load the last shown harvest ID from SharedPreferences
  Future<void> _loadLastShownHarvestId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _lastShownHarvestId = prefs.getString('last_shown_harvest_id');
      });
      print('Loaded last shown harvest ID: $_lastShownHarvestId');
    } catch (e) {
      print('Error loading last shown harvest ID: $e');
    }
  }

  // Save the last shown harvest ID to SharedPreferences
  Future<void> _saveLastShownHarvestId(String harvestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_shown_harvest_id', harvestId);
      print('Saved last shown harvest ID: $harvestId');
    } catch (e) {
      print('Error saving last shown harvest ID: $e');
    }
  }

  // Fetch user data to get the user's name
  Future<void> _fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          userData = doc.data();
          userName = userData?["name"] ?? "Farmer";
          userStatus = userData?["status"] ?? "active";
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  // Method to translate harvest remarks in real-time
  Future<String> _translateHarvestRemarks(String remarks) async {
    if (_selectedLanguage == 'English') {
      return remarks;
    }
    
    // Try to translate specific known remarks first
    final translatedRemark = _translateSpecificRemark(remarks);
    if (translatedRemark != remarks) {
      return translatedRemark;
    }
    
    // If not a specific remark, try to translate common phrases
    return _translateCommonPhrases(remarks);
  }
  
  // Method to translate specific known remarks from database
  String _translateSpecificRemark(String remarks) {
    // Convert to lowercase for matching
    final lowerRemarks = remarks.toLowerCase();
    
    // Tagalog translations
    if (_selectedLanguage == 'Tagalog') {
      if (lowerRemarks.contains('heavy rains') || lowerRemarks.contains('rain')) {
        return 'Babala: Ang darating na quarter ay maaaring magdulot ng mababani ani dahil sa malakas na ulan batay sa datos ng nakaraang mga taon sa parehong quarter.';
      }
      if (lowerRemarks.contains('good harvest') || lowerRemarks.contains('favorable')) {
        return 'Magandang balita: Inaasahan na ang darating na ani ay magiging maganda dahil sa paborableng kondisyon ng panahon at tamang pamamahala ng isda.';
      }
      if (lowerRemarks.contains('failure') || lowerRemarks.contains('prone to failure')) {
        return 'Babala: Ang darating na quarter ay madaling magkaproblema sa ani batay sa datos ng nakaraang mga taon.';
      }
      if (lowerRemarks.contains('temperature') || lowerRemarks.contains('weather')) {
        return 'Batay sa panahon at temperatura, inaasahan na ang kondisyon ng ani ay magiging normal para sa panahong ito.';
      }
    }
    
    // Cebuano translations
    if (_selectedLanguage == 'Cebuano') {
      if (lowerRemarks.contains('heavy rains') || lowerRemarks.contains('rain')) {
        return 'Bala: Ang moabut nga quarter mahimong magdulot sa sayop nga ani tungod sa kusog nga ulan base sa datos sa nagbayad nga tuig sa samang quarter.';
      }
      if (lowerRemarks.contains('good harvest') || lowerRemarks.contains('favorable')) {
        return 'Maayong balita: Gikinahanglan nga ang moabut nga ani mahimong maayo tungod sa paborableng kondisyon sa panahon ug tinuod nga pagdumala sa isda.';
      }
      if (lowerRemarks.contains('failure') || lowerRemarks.contains('prone to failure')) {
        return 'Bala: Ang moabut nga quadrant sayopon nga ani base sa datos sa nagbayad nga tuig.';
      }
      if (lowerRemarks.contains('temperature') || lowerRemarks.contains('weather')) {
        return 'Base sa panahon ug temperatura, gikinahanglan nga ang kondisyon sa ani normal para sa kining panahona.';
      }
    }
    
    // If no specific match, return original
    return remarks;
  }
  
  // Method to translate common phrases in remarks
  String _translateCommonPhrases(String remarks) {
    String translated = remarks;
    
    if (_selectedLanguage == 'Tagalog') {
      translated = translated.replaceAll('Next Quarter', 'Darating na Quarter');
      translated = translated.replaceAll('based on the data', 'batay sa datos');
      translated = translated.replaceAll('previous years', 'nakaraang mga taon');
      translated = translated.replaceAll('same quarter', 'parehong quarter');
      translated = translated.replaceAll('heavy rains', 'malakas na ulan');
      translated = translated.replaceAll('failure harvest', 'mababang ani');
      translated = translated.replaceAll('prone to', 'madaling');
      translated = translated.replaceAll('because of', 'dahil sa');
      translated = translated.replaceAll('good harvest', 'magandang ani');
      translated = translated.replaceAll('favorable conditions', 'paborableng kondisyon');
      translated = translated.replaceAll('weather conditions', 'kondisyon ng panahon');
      translated = translated.replaceAll('proper fish management', 'tamang pamamahala ng isda');
      translated = translated.replaceAll('expected to be', 'inaasahan na');
      translated = translated.replaceAll('due to', 'dahil sa');
    }
    
    if (_selectedLanguage == 'Cebuano') {
      translated = translated.replaceAll('Next Quarter', 'Sunod nga Quarter');
      translated = translated.replaceAll('based on the data', 'base sa datos');
      translated = translated.replaceAll('previous years', 'nagbayad nga mga tuig');
      translated = translated.replaceAll('same quarter', 'samang quarter');
      translated = translated.replaceAll('heavy rains', 'kusog nga ulan');
      translated = translated.replaceAll('failure harvest', 'sayop nga ani');
      translated = translated.replaceAll('prone to', 'sayopon nga');
      translated = translated.replaceAll('because of', 'tungod sa');
      translated = translated.replaceAll('good harvest', 'maayo nga ani');
      translated = translated.replaceAll('favorable conditions', 'paborableng kondisyon');
      translated = translated.replaceAll('weather conditions', 'kondisyon sa panahon');
      translated = translated.replaceAll('proper fish management', 'tinuod nga pagdumala sa isda');
      translated = translated.replaceAll('expected to be', 'gikinahanglan nga');
      translated = translated.replaceAll('due to', 'tungod sa');
    }
    
    return translated;
  }

  Future<void> _createWelcomeNotifications() async {
    final notificationService = NotificationService();
    await notificationService.createWelcomeNotificationsForNewUser();
  }

  int _monthToIndex(String month) {
    final m = month.toLowerCase();
    const months = [
      'jan', 'feb', 'mar', 'apr', 'may', 'jun',
      'jul', 'aug', 'sep', 'oct', 'nov', 'dec'
    ];
    for (int i = 0; i < months.length; i++) {
      if (m.startsWith(months[i])) {
        return i;
      }
    }
    return 0; // Default to January if not found
  }

  Future<void> _loadHarvestData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No logged-in user. Please sign in to see harvest data.';
        });
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('harvest_data')
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          yearOptions = [];
          selectedYear = null;
        });
        return;
      }

      totalWeightDataByYear.clear();
      threeInOneDataByYear.clear();
      fourInOneDataByYear.clear();
      twoInOneDataByYear.clear();
      sardinesDataByYear.clear();
      totalBangusDataByYear.clear();
      recordCountByYear.clear();
      harvestRemarksByYear.clear();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final int? year = data['yearOfHarvest'] is int
            ? data['yearOfHarvest'] as int
            : int.tryParse('${data['yearOfHarvest']}');
        final String? month = data['monthOfHarvest']?.toString();

        if (year == null || month == null || month.trim().isEmpty) {
          continue;
        }

        final int monthIndex = _monthToIndex(month);

        totalWeightDataByYear[year] ??= List<num>.filled(12, 0);
        threeInOneDataByYear[year] ??= List<num>.filled(12, 0);
        fourInOneDataByYear[year] ??= List<num>.filled(12, 0);
        twoInOneDataByYear[year] ??= List<num>.filled(12, 0);
        sardinesDataByYear[year] ??= List<num>.filled(12, 0);
        recordCountByYear[year] ??= List<int>.filled(12, 0);

        final num totalWeight = (data['totalWeightOfHarvest'] ?? 0) as num;
        final num threePieces = (data['threeInOneTotalPieces'] ?? 0) as num;
        final num fourPieces = (data['fourInOneTotalPieces'] ?? 0) as num;
        final num twoPieces = (data['twoInOneTotalPieces'] ?? 0) as num;
        final num sardinesPieces = (data['sardinesTotalPieces'] ?? 0) as num;
        
        // Access geminiForecastRemarks directly from the document (same as real-time listener)
        final String? remarks = data['geminiForecastRemarks']?.toString();

        totalWeightDataByYear[year]![monthIndex] += totalWeight;
        threeInOneDataByYear[year]![monthIndex] += threePieces;
        fourInOneDataByYear[year]![monthIndex] += fourPieces;
        twoInOneDataByYear[year]![monthIndex] += twoPieces;
        sardinesDataByYear[year]![monthIndex] += sardinesPieces;
        recordCountByYear[year]![monthIndex] += 1;
        
        // Store harvest remarks
        if (remarks != null && remarks.trim().isNotEmpty) {
          harvestRemarksByYear[year] ??= <int, String>{};
          harvestRemarksByYear[year]![monthIndex] = remarks;
        }
      }

      for (final year in totalWeightDataByYear.keys) {
        final three = threeInOneDataByYear[year] ?? List<num>.filled(12, 0);
        final four = fourInOneDataByYear[year] ?? List<num>.filled(12, 0);
        final two = twoInOneDataByYear[year] ?? List<num>.filled(12, 0);
        final sard = sardinesDataByYear[year] ?? List<num>.filled(12, 0);

        totalBangusDataByYear[year] = List<num>.generate(12, (i) {
          return three[i] + four[i] + two[i] + sard[i];
        });
      }

      yearOptions = totalBangusDataByYear.keys.toList()..sort();
      if (yearOptions.isNotEmpty) {
        selectedYear = yearOptions.last;

        final dataForYear = recordCountByYear[selectedYear] ??
            List<int>.filled(12, 0);
        int lastMonthWithData = 11;
        for (int i = 11; i >= 0; i--) {
          if (dataForYear[i] > 0) {
            lastMonthWithData = i;
            break;
          }
        }
        selectedMonth = lastMonthWithData;
        tooltipOffset = selectedMonth >= 10 ? -40 : 0;
      }

      setState(() {
        _isLoading = false;
      });
      
      // Load initial remarks for selected month
      _updateCurrentRemarks();
      
      // Show harvest result dialog if data is loaded for the first time
      // Add a small delay to ensure UI is properly initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showHarvestResultDialogIfNeeded();
        }
      });
            
      // Generate data-based notifications
      await _generateDataNotifications();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load harvest data: $e';
        });
      }
    }
  }

  Future<void> _generateDataNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get user role from database
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      final userRole = userData?['role'] ?? 'user'; // Default to 'user' if no role specified

      final notificationService = NotificationService();
      
      // Generate notifications based on user role and data
      await notificationService.generateDataBasedNotifications(
        totalBangusDataByYear: totalBangusDataByYear,
        threeInOneDataByYear: threeInOneDataByYear,
        fourInOneDataByYear: fourInOneDataByYear,
        twoInOneDataByYear: twoInOneDataByYear,
        sardinesDataByYear: sardinesDataByYear,
        recordCountByYear: recordCountByYear,
        userRole: userRole,
      );
      
      print('Data-based notifications generated successfully for role: $userRole');
    } catch (e) {
      print('Error generating data-based notifications: $e');
    }
  }

  // Method to update current harvest remarks based on selected year and month
  void _updateCurrentRemarks() {
    if (selectedYear != null) {
      final remarksForYear = harvestRemarksByYear[selectedYear];
      if (remarksForYear != null) {
        setState(() {
          currentHarvestRemarks = remarksForYear[selectedMonth];
        });
      } else {
        setState(() {
          currentHarvestRemarks = null;
        });
      }
    } else {
      setState(() {
        currentHarvestRemarks = null;
      });
    }
  }

  // Method to stop harvest session
  Future<void> _stopHarvest() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No logged-in user');
      }

      // Set user status to 0 (inactive harvesting) in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'status': 0});

      setState(() {
        _isHarvesting = false;
      });

      if (mounted) {
        // Close any open dialogs
        Navigator.of(context, rootNavigator: true).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Harvest session stopped',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error stopping harvest: ${e.toString()}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Method to handle start harvest process
  Future<void> _startHarvest() async {
    // Check if another user is already harvesting
    if (_isGloballyHarvesting && !_isHarvesting) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.block, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  const Text('Harvest Session Active'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_activeHarvestingUser is currently harvesting.',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Only one harvest session can be active at a time. Please wait for the current session to end or contact the active user.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, 
                             color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This restriction prevents conflicts with the single harvesting machine.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0981D1),
                  ),
                  child: const Text('Understood'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    // Check user status first
    final userStatus = await _authController.getCurrentUserStatus();
    
    if (userStatus.toLowerCase() != 'active') {
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.block, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  const Text('Account Inactive'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your account status is currently: ${userStatus.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Only users with ACTIVE status can start harvesting. Please contact support to activate your account.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    setState(() {
      _isHarvesting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No logged-in user');
      }

      // Set user status to 1 (active harvesting) in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'status': 1});

      // Show waiting dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0981D1)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Harvest session started!',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your device can now upload harvest data. Waiting for data...',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tip: Make sure your Orange Pi is connected and ready to upload data',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _stopHarvest();
                        },
                        child: Text(
                          'Stop Harvest',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _checkForNewHarvestDataAndRefresh();
                        },
                        child: Text(
                          'Check Data',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0981D1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Start checking for new harvest data periodically
      await _startHarvestDataMonitoring();

    } catch (e) {
      setState(() {
        _isHarvesting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Start checking for new harvest data periodically
  Future<void> _startHarvestDataMonitoring() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    int attempts = 0;
    const maxAttempts = 24; // 2 minutes = 24 * 5 seconds

    while (attempts < maxAttempts && _isHarvesting) {
      await Future.delayed(const Duration(seconds: 5));
      attempts++;

      bool newDataFound = await _checkForNewHarvestData(user.uid);
      if (newDataFound) {
        // Data received, stop monitoring and refresh
        await _stopHarvest();
        _loadHarvestData();
        
        // Show harvest result dialog after data is loaded
        Future.delayed(const Duration(milliseconds: 500), () {
          _getLatestHarvestDataForDialog();
        });
        
        return;
      }
    }

    // Timeout reached
    if (_isHarvesting && mounted) {
      Navigator.of(context).pop();
      setState(() {
        _isHarvesting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Timeout: No harvest data received within 2 minutes',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // Check for new harvest data and refresh UI
  Future<void> _checkForNewHarvestDataAndRefresh() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      bool newDataFound = await _checkForNewHarvestData(user.uid);
      
      if (newDataFound) {
        // Close dialog and show success
        if (mounted) {
          Navigator.of(context).pop();
          setState(() {
            _isHarvesting = false;
          });

          // Show harvest result dialog instead of the old dialog
          if (currentHarvestData != null) {
            // Get the document ID to track duplicates
            final snapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('harvest_data')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .get();
            
            if (snapshot.docs.isNotEmpty) {
              final docId = snapshot.docs.first.id;
              
              // Only show if this harvest hasn't been shown before (genuinely new data)
              if (_lastShownHarvestId != docId) {
                setState(() {
                  _harvestResultData = currentHarvestData;
                  _showHarvestResultDialog = true;
                  _lastShownHarvestId = docId;
                });
                
                // Save to persistent storage
                _saveLastShownHarvestId(docId);
                
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) {
                    return _buildHarvestResultDialog();
                  },
                );
              }
            }
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No new harvest data found yet. Still waiting...',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error checking harvest data: ${e.toString()}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Build widget to display latest harvest data
  Widget _buildLatestHarvestDataDisplay() {
    if (currentHarvestData == null) {
      return const Text('No data available');
    }

    final data = currentHarvestData!;
    final totalPieces = data['totalPiecesOfHarvest'] ?? 0;
    final totalWeight = data['totalWeightOfHarvest'] ?? 0;
    final timestamp = data['timestamp'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Pieces: $totalPieces',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total Weight: ${totalWeight}kg',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (timestamp != null) ...[
            const SizedBox(height: 4),
            Text(
              'Time: ${timestamp.toDate().toString().substring(0, 19)}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Build harvest result dialog
  Widget _buildHarvestResultDialog() {
    if (_harvestResultData == null) {
      return const SizedBox.shrink();
    }

    final totalPieces = _harvestResultData!['totalPiecesOfHarvest'] ?? 0;
    final timestamp = _harvestResultData!['timestamp'] as Timestamp?;
    final duration = _calculateHarvestDuration(timestamp);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 15,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          minWidth: 280,
        ),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: const Color(0xFF0981D1).withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF0981D1).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            
            // Title with gradient
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0981D1).withOpacity(0.1),
                    const Color(0xFF00AEEF).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icon/fish.png',
                    width: 42,
                    height: 42,
                    color: const Color(0xFF0981D1),
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.catching_pokemon,
                        size: 32,
                        color: Color(0xFF0981D1),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Harvested Result',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0981D1),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Enhanced results container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.grey.shade50,
                    Colors.grey.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Total Pieces Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0981D1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: const Color(0xFF0981D1),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Pieces',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$totalPieces pieces',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Duration Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.schedule_outlined,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Duration',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                duration,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Enhanced OK Button
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0981D1),
                    Color(0xFF00AEEF),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0981D1).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showHarvestResultDialog = false;
                    _harvestResultData = null;
                  });
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            
            // Date display at bottom
            if (timestamp != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _formatDate(timestamp.toDate()),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Calculate harvest duration
  String _calculateHarvestDuration(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Unknown';
    }

    final harvestTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(harvestTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return minutes > 0 ? '$hours hours $minutes minutes' : '$hours hours';
    } else {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      return hours > 0 ? '$days days $hours hours' : '$days days';
    }
  }

  // Format date to Month,Day.Year format
  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final month = months[date.month - 1];
    final day = date.day;
    final year = date.year;
    
    return '$month,$day.$year';
  }

  // Show harvest result dialog if needed
  void _showHarvestResultDialogIfNeeded() {
    // ENABLED: Show dialog for new users who haven't seen any harvest results yet
    // This handles the case where a new user opens the app and already has harvest data
    _getLatestHarvestDataForDialog();
  }

  // Get latest harvest data for dialog
  Future<void> _getLatestHarvestDataForDialog() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      print('🔍 DIALOG CHECK: Starting harvest dialog check for user ${user.uid}');
      print('🔍 DIALOG CHECK: Current _lastShownHarvestId: $_lastShownHarvestId');
      print('🔍 DIALOG CHECK: Current _showHarvestResultDialog: $_showHarvestResultDialog');

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('harvest_data')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final latestDoc = snapshot.docs.first;
        final data = latestDoc.data();
        final docId = latestDoc.id; // Get document ID to track duplicates
        
        print('🔍 DIALOG CHECK: Found harvest document: $docId');
        print('🔍 DIALOG CHECK: Document has totalPiecesOfHarvest: ${data['totalPiecesOfHarvest']}');
        
        // Show dialog if not already showing, data has totalPiecesOfHarvest, and not shown before
        if (!_showHarvestResultDialog && mounted && _lastShownHarvestId != docId && data['totalPiecesOfHarvest'] != null) {
          final timestamp = data['timestamp'] as Timestamp?;
          if (timestamp != null) {
            final now = DateTime.now();
            final harvestTime = timestamp.toDate();
            final difference = now.difference(harvestTime);
            
            // Show dialog for:
            // 1. Recent data (within 1 hour), OR
            // 2. First load (_isLoading), OR
            // 3. New users who haven't seen any harvest results yet (_lastShownHarvestId is null)
            final bool isNewUser = _lastShownHarvestId == null;
            final bool shouldShowDialog = difference.inHours < 1 || _isLoading || isNewUser;
            
            print('Harvest dialog check (manual): isNewUser=$isNewUser, difference=${difference.inHours}h, isLoading=$_isLoading, shouldShow=$shouldShowDialog');
            
            if (shouldShowDialog) {
              setState(() {
                _harvestResultData = data;
                _showHarvestResultDialog = true;
                _lastShownHarvestId = docId; // Track that we showed this harvest
              });
              
              // Show the dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return _buildHarvestResultDialog();
                },
              );
            }
          }
        }
      } else {
        print('🔍 DIALOG CHECK: No harvest documents found for user');
      }
    } catch (e) {
      print('Error getting latest harvest data for dialog: $e');
    }
  }

  // Simulate harvest process locally
  Future<void> _simulateHarvestProcess() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No logged-in user');
      }

      // Check for new harvest data in Firestore
      bool newDataFound = await _checkForNewHarvestData(user.uid);

      if (newDataFound) {
        // Close the waiting dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Show success dialog with real data
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'New Harvest Data Found!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New harvest data has been uploaded to the database:',
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    _buildLatestHarvestData(user.uid),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Refresh data after harvest
                      _loadHarvestData();
                    },
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      } else {
        // No new data found
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No new harvest data found. Please make sure your device has uploaded data to the database.',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error checking harvest data: ${e.toString()}',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isHarvesting = false;
      });
    }
  }

  // Check for new harvest data in Firestore
  Future<bool> _checkForNewHarvestData(String userId) async {
    try {
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('harvest_data')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final latestDoc = snapshot.docs.first;
        final data = latestDoc.data();
        
        // Store the latest harvest data for display
        setState(() {
          currentHarvestData = data;
        });
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking for new harvest data: $e');
      return false;
    }
  }

  // Build widget to display latest harvest data
  Widget _buildLatestHarvestData(String userId) {
    if (currentHarvestData == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          'Loading harvest data...',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
      );
    }

    final timestamp = currentHarvestData!['timestamp'] as Timestamp?;
    final totalPieces = currentHarvestData!['totalPiecesOfHarvest'] as int? ?? 0;
    final totalWeight = currentHarvestData!['totalWeightOfHarvest'] as double? ?? 0.0;
    final twoInOne = currentHarvestData!['twoInOneTotalPieces'] as int? ?? 0;
    final threeInOne = currentHarvestData!['threeInOneTotalPieces'] as int? ?? 0;
    final fourInOne = currentHarvestData!['fourInOneTotalPieces'] as int? ?? 0;
    final sardines = currentHarvestData!['sardinesTotalPieces'] as int? ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          if (timestamp != null) ...[
            Text(
              'Uploaded: ${timestamp.toDate().toString().substring(0, 19)}',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          _buildSummaryRow('2-1', threeInOne.toString()),
          _buildSummaryRow('3-1', fourInOne.toString()),
          _buildSummaryRow('4-1', twoInOne.toString()),
          _buildSummaryRow('Sardines', sardines.toString()),
          const Divider(),
          _buildSummaryRow('Total Pieces', totalPieces.toString(), isBold: true),
          if (totalWeight > 0) ...[
            const SizedBox(height: 4),
            _buildSummaryRow('Total Weight', '${totalWeight.toStringAsFixed(2)} kg', isBold: true),
          ],
        ],
      ),
    );
  }

  // Build harvest summary widget
  Widget _buildHarvestSummary() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildSummaryRow('2 in 1', '${45 + (DateTime.now().millisecond % 20)}'),
          _buildSummaryRow('3 in 1', '${60 + (DateTime.now().millisecond % 30)}'),
          _buildSummaryRow('4 in 1', '${35 + (DateTime.now().millisecond % 25)}'),
          _buildSummaryRow('Sardines', '${25 + (DateTime.now().millisecond % 15)}'),
          const Divider(),
          _buildSummaryRow(
            'Total Pieces',
            '${165 + (DateTime.now().millisecond % 90)}',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              color: isBold ? const Color(0xFF0981D1) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Start a new harvest session
  Future<void> _startHarvestSession(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-api-url.com/start-harvest-session'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      print('Start Session API Response Status: ${response.statusCode}');
      print('Start Session API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Poll for harvest data every 5 seconds for up to 2 minutes
        int attempts = 0;
        const maxAttempts = 24; // 2 minutes = 24 * 5 seconds

        while (attempts < maxAttempts) {
          await Future.delayed(const Duration(seconds: 5));
          attempts++;

          // Check if harvest data has been uploaded
          final dataResponse = await http.get(
            Uri.parse('https://your-api-url.com/check-harvest-data'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
          );

          print('Check Data API Response Status: ${dataResponse.statusCode}');
          print('Check Data API Response Body: ${dataResponse.body}');

          if (dataResponse.statusCode == 200) {
            try {
              final data = json.decode(dataResponse.body);
              if (data['has_data'] == true) {
                // Data received, end the session
                await _endHarvestSession(idToken);
                return;
              }
            } catch (e) {
              print('Error parsing check data response: $e');
            }
          }
        }

        // Timeout reached, end session anyway
        await _endHarvestSession(idToken);
        throw Exception('Timeout: No harvest data received within 2 minutes');

      } else {
        throw Exception('Failed to start harvest session: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Check for harvest data and end session
  Future<void> _checkForHarvestDataAndEndSession(String idToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://your-api-url.com/check-harvest-data'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      print('Check Data End Session API Response Status: ${response.statusCode}');
      print('Check Data End Session API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data['has_data'] == true) {
            // Process the new data and end session
            await _endHarvestSession(idToken);
          } else {
            throw Exception('No new harvest data available');
          }
        } catch (e) {
          throw Exception('Invalid JSON response: ${e.toString()}');
        }
      } else {
        throw Exception('Failed to check harvest data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // End harvest session
  Future<void> _endHarvestSession(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('https://your-api-url.com/end-harvest-session'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      print('End Session API Response Status: ${response.statusCode}');
      print('End Session API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Success - close dialog and show completion
        if (mounted) {
          Navigator.of(context).pop();
          setState(() {
            _isHarvesting = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Harvest data processed successfully!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              backgroundColor: const Color(0xFF4CAF50),
              duration: const Duration(seconds: 2),
            ),
          );

          // Reload harvest data to show updated information
          _loadHarvestData();
        }
      } else {
        throw Exception('Failed to end harvest session: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Helper method to build summary cards
  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build product cards
  Widget _buildProductCard({
    required String title,
    required List<_ProductItem> items,
    required String total,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: items.map((item) => _buildProductItem(item)).toList(),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '$total pieces',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build individual product items
  Widget _buildProductItem(_ProductItem item) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          item.title,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          item.value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: item.color,
          ),
        ),
      ],
    );
  }

  // Helper method to format numbers with commas
  String _formatNumber(int num) {
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Build horizontal bar chart like the one in the image
  Widget _buildHorizontalBarChart() {
    final bool hasAnyData = yearOptions.isNotEmpty && selectedYear != null;
    final int yearKey = hasAnyData ? selectedYear! : DateTime.now().year;
    final List<num> series = hasAnyData
        ? (totalBangusDataByYear[yearKey] ?? List<num>.filled(12, 0))
        : List<num>.filled(12, 0);
    final List<int> counts = hasAnyData
        ? (recordCountByYear[yearKey] ?? List<int>.filled(12, 0))
        : List<int>.filled(12, 0);

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    // Find maximum value for scaling (add some padding for better visualization)
    double maxValue = 0;
    for (int i = 0; i < series.length; i++) {
      if (series[i] > maxValue) {
        maxValue = series[i].toDouble();
      }
    }
    if (maxValue == 0) maxValue = 1000; // Default max if all values are 0
    // Add 20% padding to max value for better visualization
    maxValue = maxValue * 1.2;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: List.generate(12, (index) {
          final int value = series[index].toInt();
          final bool hasData = counts[index] > 0;
          final double barWidth = value > 0 ? (value / maxValue) * 220 : 0;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: GestureDetector(
              onTap: () {
                if (hasData) {
                  setState(() {
                    selectedMonth = index;
                  });
                  // Update remarks when month changes
                  _updateCurrentRemarks();
                }
              },
              child: Row(
                children: [
                  // Month label
                  SizedBox(
                    width: 55,
                    child: Text(
                      months[index],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hasData ? Colors.black87 : Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  // Bar
                  Expanded(
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Background bar
                          Container(
                            width: double.infinity,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          // Value bar
                          if (barWidth > 0)
                            Container(
                              width: barWidth,
                              height: 24,
                              decoration: BoxDecoration(
                                color: selectedMonth == index 
                                    ? const Color(0xFF00AEEF) 
                                    : const Color(0xFF0981D1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Value text
                  SizedBox(
                    width: 60,
                    child: Text(
                      hasData ? '${value}pcs' : '0',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: hasData 
                            ? (selectedMonth == index ? const Color(0xFF00AEEF) : const Color(0xFF0981D1))
                            : Colors.grey[600],
                      ),
                      textAlign: TextAlign.right,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pagePadding = context.responsivePagePadding;
    final bool hasAnyData = yearOptions.isNotEmpty && selectedYear != null;
    final int year = hasAnyData ? selectedYear! : (DateTime.now().year);

    final bool hasDataForMonth = hasAnyData &&
        ((recordCountByYear[year]?[selectedMonth] ?? 0) > 0);

    // Calculate current values based on selected year and month
    final int threeInOne = hasAnyData
        ? (threeInOneDataByYear[year]?[selectedMonth] ?? 0).toInt()
        : 0;
    final int fourInOne = hasAnyData
        ? (fourInOneDataByYear[year]?[selectedMonth] ?? 0).toInt()
        : 0;
    final int twoInOne = hasAnyData
        ? (twoInOneDataByYear[year]?[selectedMonth] ?? 0).toInt()
        : 0;
    final int sardines = hasAnyData
        ? (sardinesDataByYear[year]?[selectedMonth] ?? 0).toInt()
        : 0;
    final int totalBangus = threeInOne + fourInOne + twoInOne + sardines;
    final int totalWeight = hasAnyData
        ? (totalWeightDataByYear[year]?[selectedMonth] ?? 0).toInt()
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFF0981D1),
        titleSpacing: 12,
        title: Row(
          children: [
            const SizedBox(width: 10),
            Text(
              'ToTepAI',
              style: GoogleFonts.alfaSlabOne(
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        actions: [
          NotificationBell(),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: pagePadding.left,
          right: pagePadding.right,
          top: 20,
          bottom: pagePadding.bottom + 20,
        ),
        child: ResponsiveConstrainedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👋 Welcome Section
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Welcome back, ",
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: userName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.black87,
                                    decorationThickness: 2,
                                  ),
                                ),
                                TextSpan(
                                  text: "!",
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            TranslationService.getTranslationSync('welcome_overview', _selectedLanguage),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 97,
                        height: 97,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),

              // 📊 Harvest Data Detailed Breakdown Stats Section
              const SizedBox(height: 16),
              Text(
                'Harvest Data Breakdown',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 20),
              // Total Bangus and Weight
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Total Bangus',
                      value: hasDataForMonth
                          ? _formatNumber(totalBangus)
                          : 'N/A',
                      unit: 'pieces',
                      icon: Icons.analytics_outlined,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Total Weight',
                      value: hasDataForMonth
                          ? _formatNumber(totalWeight)
                          : 'N/A',
                      unit: 'kg',
                      icon: Icons.scale_outlined,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: '2 in 1',
                      value: hasDataForMonth
                          ? _formatNumber(twoInOne)
                          : 'N/A',
                      unit: 'pieces',
                      icon: Icons.inventory_2_outlined,
                      color: Colors.cyan,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      title: '3 in 1',
                      value: hasDataForMonth
                          ? _formatNumber(threeInOne)
                          : 'N/A',
                      unit: 'pieces',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: '4 in 1',
                      value: hasDataForMonth
                          ? _formatNumber(fourInOne)
                          : 'N/A',
                      unit: 'pieces',
                      icon: Icons.inventory_2_outlined,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Sardines',
                      value: hasDataForMonth
                          ? _formatNumber(sardines)
                          : 'N/A',
                      unit: 'pieces',
                      icon: Icons.set_meal_outlined,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 17),

              // � Total Bangus Actual Data Chart
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0981D1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF0981D1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Actual Data of Harvest",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<String>(
                        future: _getHarvestDuration(),
                        builder: (context, snapshot) {
                          String durationText = 'Loading...';
                          if (snapshot.hasData) {
                            durationText = snapshot.data!;
                          } else if (snapshot.hasError) {
                            durationText = 'Duration not available';
                          }
                          return Text(
                            "Duration: $durationText",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (hasAnyData)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: DropdownButton<int>(
                        value: year,
                        borderRadius: BorderRadius.circular(10),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black, fontSize: 14),
                        isExpanded: false,
                        menuMaxHeight: 150,
                        items: yearOptions
                            .map(
                              (y) => DropdownMenuItem<int>(
                                value: y,
                                child: Text(y.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            selectedYear = v;
                            final counts = recordCountByYear[v] ??
                                List<int>.filled(12, 0);
                            int lastMonthWithData = 11;
                            for (int i = 11; i >= 0; i--) {
                              if (counts[i] > 0) {
                                lastMonthWithData = i;
                                break;
                              }
                            }
                          selectedMonth = lastMonthWithData;
                          tooltipOffset = selectedMonth >= 10 ? -40 : 0;
                        });
                        // Update remarks when year changes
                        _updateCurrentRemarks();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(1, 4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 400,
                  child: _buildHorizontalBarChart(),
                ),
              ),

              const SizedBox(height: 30),

              // 🧾 Harvest Remarks Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0981D1).withOpacity(0.05),
                      const Color(0xFF00AEEF).withOpacity(0.02),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF0981D1).withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0981D1).withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with icon and title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF0981D1),
                                  const Color(0xFF00AEEF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0981D1).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.auto_awesome_outlined,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  TranslationService.getTranslationSync('harvest_remarks', _selectedLanguage),
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  TranslationService.getTranslationSync('ai_powered_insights', _selectedLanguage),
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selectedYear != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0981D1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF0981D1).withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                "${['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][selectedMonth]} $selectedYear",
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF0981D1),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Divider
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                                  Colors.transparent,
                                  const Color(0xFF0981D1).withOpacity(0.2),
                                  Colors.transparent,
                                ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Remarks content
                      if (currentHarvestRemarks != null && currentHarvestRemarks!.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF0981D1).withOpacity(0.1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon and title row
                              Row(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00AEEF).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.lightbulb_outline,
                                      color: const Color(0xFF00AEEF),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Remarks:',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Remarks content below the icon
                              FutureBuilder<String>(
                                key: ValueKey('harvest_remarks_$_selectedLanguage'),
                                future: _translateHarvestRemarks(currentHarvestRemarks!),
                                builder: (context, snapshot) {
                                  String displayText = snapshot.data ?? currentHarvestRemarks!;
                                  
                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      // Create a text painter to check if text actually overflows
                                      final textPainter = TextPainter(
                                        text: TextSpan(
                                          text: displayText,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: const Color(0xFF374151),
                                            height: 1.6,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        maxLines: 3,
                                        textDirection: TextDirection.ltr,
                                      );
                                      textPainter.layout(maxWidth: constraints.maxWidth);
                                      final isTextOverflowing = textPainter.didExceedMaxLines;
                                      
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (_isHarvestRemarksExpanded)
                                            Container(
                                              constraints: const BoxConstraints(),
                                              child: Text(
                                                displayText,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 14,
                                                  color: const Color(0xFF374151),
                                                  height: 1.6,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.left,
                                                maxLines: null,
                                                overflow: TextOverflow.visible,
                                                softWrap: true,
                                              ),
                                            )
                                          else
                                            Text(
                                              displayText,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                color: const Color(0xFF374151),
                                                height: 1.6,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              textAlign: TextAlign.left,
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          if (isTextOverflowing && !_isHarvestRemarksExpanded)
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _isHarvestRemarksExpanded = true;
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  '... more',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: const Color(0xFF00AEEF),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (isTextOverflowing && _isHarvestRemarksExpanded)
                                            GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _isHarvestRemarksExpanded = false;
                                                });
                                              },
                                              child: Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  'show less',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: const Color(0xFF00AEEF),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[200]!,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300]!.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      TranslationService.getTranslationSync('no_remarks_available', _selectedLanguage),
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      TranslationService.getTranslationSync('no_harvest_remarks_message', _selectedLanguage),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey[500],
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getHarvestDuration() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'No data';
      
      // Get the latest harvest start timestamp from user document
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      final userData = userDoc.data() as Map<String, dynamic>?;
      if (userData == null) return 'No data';
      
      print('🔥 DEBUG: User data: ${userData.keys.toList()}');
      print('🔥 DEBUG: Status: ${userData['status']}');
      print('🔥 DEBUG: HarvestStartTime: ${userData['harvestStartTime']}');
      
      // Get the harvest start timestamp from user status changes
      DateTime? harvestStartTime;
      
      // Check for harvest start timestamp in user data
      final startTimestamp = userData['harvestStartTime'] as Timestamp?;
      if (startTimestamp != null) {
        harvestStartTime = startTimestamp.toDate();
        print('🔥 DEBUG: Found harvest start time: $harvestStartTime');
      } else {
        // Fallback: check if user is currently harvesting (status = 1)
        final status = userData['status'] as int?;
        print('🔥 DEBUG: User status: $status');
        if (status == 1) {
          // If currently harvesting but no start time, use a recent time
          harvestStartTime = DateTime.now().subtract(const Duration(minutes: 30));
          print('🔥 DEBUG: Using fallback start time: $harvestStartTime');
        } else {
          return 'No active harvest session';
        }
      }
      
      // Get harvest data that was created AFTER the harvest start time
      final harvestDataCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('harvest_data')
          .where('timestamp', isGreaterThan: harvestStartTime)
          .orderBy('timestamp', descending: true)
          .limit(1);
      
      print('🔥 DEBUG: Querying harvest data after start time: $harvestStartTime');
      
      final harvestSnapshot = await harvestDataCollection.get();
      print('🔥 DEBUG: Harvest data docs found since start: ${harvestSnapshot.docs.length}');
      
      if (harvestSnapshot.docs.isEmpty) {
        // If no data since start time, check if currently harvesting
        final status = userData['status'] as int?;
        if (status == 1) {
          // Currently harvesting but no data yet
          final currentDuration = DateTime.now().difference(harvestStartTime);
          print('🔥 DEBUG: Currently harvesting, duration so far: $currentDuration');
          return _formatDuration(currentDuration);
        } else {
          return 'No harvest data this session';
        }
      }
      
      final latestHarvestDoc = harvestSnapshot.docs.first;
      final latestHarvestData = latestHarvestDoc.data() as Map<String, dynamic>?;
      if (latestHarvestData == null) return 'No harvest data';
      
      print('🔥 DEBUG: Latest harvest data keys: ${latestHarvestData.keys.toList()}');
      
      final latestTimestamp = latestHarvestData['timestamp'] as Timestamp?;
      if (latestTimestamp == null) {
        print('🔥 DEBUG: No timestamp in harvest data');
        return 'No timing data';
      }
      
      final harvestEndTime = latestTimestamp.toDate();
      print('🔥 DEBUG: Latest harvest data time: $harvestEndTime');
      
      // Calculate duration from harvest start to latest data
      final duration = harvestEndTime.difference(harvestStartTime);
      print('🔥 DEBUG: Duration calculated: $duration');
      
      return _formatDuration(duration);
    } catch (e) {
      print('🔥 DEBUG: Error in _getHarvestDuration: $e');
      return 'Duration not available';
    }
  }

  String _formatDuration(Duration duration) {
    // Handle negative duration (data before start)
    if (duration.isNegative) {
      print('🔥 DEBUG: Negative duration detected');
      return 'Calculating...';
    }
    
    // Get days, hours, minutes, seconds
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    print('🔥 DEBUG: Duration breakdown - Days: $days, Hours: $hours, Minutes: $minutes, Seconds: $seconds');
    
    // Build the duration string
    List<String> parts = [];
    
    if (days > 0) {
      parts.add('$days day${days > 1 ? 's' : ''}');
    }
    
    if (hours > 0) {
      parts.add('$hours hr');
    }
    
    if (minutes > 0) {
      parts.add('$minutes min');
    }
    
    if (seconds > 0 && parts.isEmpty) {
      parts.add('$seconds sec');
    }
    
    // If no parts (duration is 0), return seconds
    if (parts.isEmpty) {
      return '0 sec';
    }
    
    // Join parts with spaces
    return parts.join(' ');
  }
}

// Small activity row widget for the dashboard list
class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            time,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  }
