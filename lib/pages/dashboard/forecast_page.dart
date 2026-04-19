import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:totepai/utils/responsive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:totepai/services/translation_service.dart';
import 'package:totepai/services/language_persistence.dart';
import 'notification.dart';

class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

// Fixed compilation errors - nullable selectedYear, removed tooltipBackground, fixed type casting
class _ForecastPageState extends State<ForecastPage> {
  final NotificationService _notificationService = NotificationService();
  int? selectedYear;
  List<int> yearOptions = []; // Will be populated dynamically from database

  // Data storage for categories per year and month (same as home_page.dart)
  Map<int, List<num>> totalBangusDataByYear = {};
  Map<int, List<num>> totalWeightDataByYear = {};
  Map<int, List<num>> threeInOneDataByYear = {};
  Map<int, List<num>> fourInOneDataByYear = {};
  Map<int, List<num>> twoInOneDataByYear = {};
  Map<int, List<num>> sardinesDataByYear = {};

  // Count of records per year and month (to distinguish true zero vs no record)
  Map<int, List<int>> recordCountByYear = {};

  final List<String> bangusClass = ['2 in 1','3 in 1', '4 in 1', 'Sardines'];
  final List<Color> classColors = [
    Colors.cyan,      // 2 in 1 (matching home page)
    const Color(0xFF4CAF50), // 3 in 1 (green, matching home page)
    Colors.orange,    // 4 in 1 (matching home page)
    Colors.red,       // Sardines (matching home page)
  ];

  bool _isLoading = true;
  String? _errorMessage;
  String _currentLanguage = 'English';
  
  // AI Forecast and Weather Advisory data
  String? _predictedHarvestData;
  String? _weatherAdvisory;
  String _mape = ''; // MAPE value from geminiForecastedData
  String _databaseWeight = ''; // Weight fetched from database
  bool _isForecastExpanded = false;
  bool _isWeatherAdvisoryExpanded = false;
  
  // Real-time listeners
  StreamSubscription<QuerySnapshot>? _forecastDataListener;

  int tooltipOffset = 0;

  // Helper method to convert month name to index (same as home_page.dart)
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

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
    _loadHarvestData();
    _fetchPredictedHarvestData();
    _fetchWeatherAdvisory();
    _setupRealtimeListener();
    // Start real-time machine data monitoring for notifications
    _notificationService.startMachineDataMonitoring();
  }

  @override
  void dispose() {
    _forecastDataListener?.cancel();
    // Stop real-time machine data monitoring
    _notificationService.stopMachineDataMonitoring();
    super.dispose();
  }

  // Setup real-time listener for forecast data
  void _setupRealtimeListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print('Setting up real-time listener for harvest_data subcollection');
    
    // Listen to the harvest_data subcollection - order by timestamp to get latest
    _forecastDataListener = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('harvest_data')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      if (mounted && snapshot.docs.isNotEmpty) {
        // Get the latest document (first after ordering by timestamp descending)
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>?;
        print('Real-time listener - Document data keys: ${data?.keys.toList()}');
        
        if (data != null) {
          print('Real-time listener - Document data keys: ${data.keys.toList()}');
          
          // Try to get weather advisory from multiple possible locations
          String? newWeatherAdvisory;
          String? newPredictedHarvestData;
          
          // First try: nested in geminiForecastedData
          final geminiData = data['geminiForecastedData'] as Map<String, dynamic>?;
          if (geminiData != null) {
            newPredictedHarvestData = geminiData['predictedHarvestData']?.toString();
            newWeatherAdvisory = geminiData['weatherAdvisory']?.toString();
            final mapeValue = geminiData['MAPE']?.toString();
            print('Found data in geminiForecastedData - Advisory: $newWeatherAdvisory, MAPE: $mapeValue');
            
            // Update state with MAPE if found
            if (mapeValue != null && mapeValue.isNotEmpty) {
              if (mounted) {
                setState(() {
                  _mape = mapeValue;
                });
              }
            }
          }
          
          // Second try: direct document access (override if found)
          final directPredicted = data['predictedHarvestData']?.toString();
          final directAdvisory = data['weatherAdvisory']?.toString();
          if (directPredicted != null) newPredictedHarvestData = directPredicted;
          if (directAdvisory != null) newWeatherAdvisory = directAdvisory;
          print('Direct access - Advisory: $directAdvisory');
          
          // Update state if new data found
          if (newPredictedHarvestData != null || newWeatherAdvisory != null) {
            if (mounted) {
              setState(() {
                _predictedHarvestData = newPredictedHarvestData;
                _weatherAdvisory = newWeatherAdvisory;
              });
            }
            print('Real-time update - Predicted: $_predictedHarvestData');
            print('Real-time update - Advisory: $_weatherAdvisory');
          } else {
            print('No weather advisory or predicted data found in any location');
          }
        }
      } else {
        print('Real-time listener - No documents found');
      }
    }, onError: (error) {
      debugPrint('Real-time listener error: $error');
    });
  }

  // Load saved language preference
  Future<void> _loadSavedLanguage() async {
    final savedLanguage = await LanguagePersistence.getLanguage();
    if (savedLanguage != null && mounted) {
      setState(() {
        _currentLanguage = savedLanguage;
      });
    }
  }

  // Load harvest data from Firestore (same as home_page.dart)
  Future<void> _loadHarvestData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No logged-in user. Please sign in to see harvest data.';
          });
        }
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('harvest_data')
          .get();

      // Initialize all data structures
      totalBangusDataByYear.clear();
      totalWeightDataByYear.clear();
      threeInOneDataByYear.clear();
      fourInOneDataByYear.clear();
      twoInOneDataByYear.clear();
      sardinesDataByYear.clear();
      recordCountByYear.clear();
      
      // Clear and repopulate year options from database
      Set<int> uniqueYears = {};

      if (snapshot.docs.isEmpty) {
        print('=== No Firestore data found for new user ===');
        // Don't generate sample data for new users - keep data structures empty
      } else {
        print('=== Found ${snapshot.docs.length} Firestore documents, loading real data ===');
        // Load real data from Firestore (same as home_page.dart)
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final int? year = data['yearOfHarvest'] is int
              ? data['yearOfHarvest'] as int
              : int.tryParse('${data['yearOfHarvest']}');
          final String? month = data['monthOfHarvest']?.toString();

          if (year == null || month == null || month.trim().isEmpty) {
            continue;
          }
          
          // Add year to our set of unique years
          uniqueYears.add(year);

          // Initialize year data if not exists
          totalBangusDataByYear.putIfAbsent(year, () => List<num>.filled(12, 0));
          totalWeightDataByYear.putIfAbsent(year, () => List<num>.filled(12, 0));
          threeInOneDataByYear.putIfAbsent(year, () => List<num>.filled(12, 0));
          fourInOneDataByYear.putIfAbsent(year, () => List<num>.filled(12, 0));
          twoInOneDataByYear.putIfAbsent(year, () => List<num>.filled(12, 0));
          sardinesDataByYear.putIfAbsent(year, () => List<num>.filled(12, 0));
          recordCountByYear.putIfAbsent(year, () => List<int>.filled(12, 0));

          // Parse month using same method as home_page.dart
          final monthIndex = _monthToIndex(month);

          // Get values using same field names as home_page.dart
          final totalWeight = (data['totalWeightOfHarvest'] ?? 0) as num;
          final twoInOne = (data['twoInOneTotalPieces'] ?? 0) as num;
          final threeInOne = (data['threeInOneTotalPieces'] ?? 0) as num;
          final fourInOne = (data['fourInOneTotalPieces'] ?? 0) as num;
          final sardines = (data['sardinesTotalPieces'] ?? 0) as num;

          // Calculate total bangus (same as home_page.dart)
          final totalBangus = threeInOne + fourInOne + twoInOne + sardines;

          // Update monthly data (using accumulation like home_page.dart)
          totalBangusDataByYear[year]![monthIndex] += totalBangus;
          totalWeightDataByYear[year]![monthIndex] += totalWeight;
          threeInOneDataByYear[year]![monthIndex] += threeInOne;
          fourInOneDataByYear[year]![monthIndex] += fourInOne;
          twoInOneDataByYear[year]![monthIndex] += twoInOne;
          sardinesDataByYear[year]![monthIndex] += sardines;
          
          // Increment record count
          recordCountByYear[year]![monthIndex] += 1;
          
          print('Loaded data: Year $year, Month $monthIndex, 2 in 1: $twoInOne, 3in1: $threeInOne, 4in1: $fourInOne, Sardines: $sardines');
        }
      
      // Calculate total bangus for each year (same as home_page.dart)
      for (final year in totalWeightDataByYear.keys) {
        final three = threeInOneDataByYear[year] ?? List<num>.filled(12, 0);
        final four = fourInOneDataByYear[year] ?? List<num>.filled(12, 0);
        final two = twoInOneDataByYear[year] ?? List<num>.filled(12, 0);
        final sard = sardinesDataByYear[year] ?? List<num>.filled(12, 0);

        totalBangusDataByYear[year] = List<num>.generate(12, (i) {
          return three[i] + four[i] + two[i] + sard[i];
        });
      }
        
        // Check if all data is zero, then generate sample data
        bool hasNonZeroData = false;
        for (var year in totalBangusDataByYear.keys) {
          for (int i = 0; i < 12; i++) {
            if ((recordCountByYear[year]?[i] ?? 0) > 0) {
              final total = (sardinesDataByYear[year]?[i] ?? 0) + 
                           (twoInOneDataByYear[year]?[i] ?? 0) + 
                           (fourInOneDataByYear[year]?[i] ?? 0) + 
                           (threeInOneDataByYear[year]?[i] ?? 0);
              if (total > 0) {
                hasNonZeroData = true;
                break;
              }
            }
          }
          if (hasNonZeroData) break;
        }
        
        // For new users with no data, don't generate sample data
        // Keep the data structures as they are (empty or with actual data)
        print('=== Data validation complete - hasNonZeroData: $hasNonZeroData ===');
      }

      // Update year options from the collected unique years
      if (uniqueYears.isNotEmpty) {
        yearOptions = uniqueYears.toList()..sort();
        // Set selected year to the most recent year with data
        selectedYear = yearOptions.last;
      } else {
        // For new users, don't set any year options - will show "no data" message
        yearOptions = [];
        selectedYear = null;
      }
      
      print('=== Data loading complete ===');
      print('selectedYear: $selectedYear');
      print('yearOptions: $yearOptions');
      print('totalBangusDataByYear keys: ${totalBangusDataByYear.keys}');
      
      // Show what months have data for each year
      for (var year in totalBangusDataByYear.keys) {
        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        print('Year $year months with data:');
        for (int i = 0; i < 12; i++) {
          if ((recordCountByYear[year]?[i] ?? 0) > 0) {
            print('  ${monthNames[i]}: Sardines=${sardinesDataByYear[year]?[i]}, 2-1=${twoInOneDataByYear[year]?[i]}, 4in1=${fourInOneDataByYear[year]?[i]}, 3in1=${threeInOneDataByYear[year]?[i]}');
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      
      // // Add notification for successful data loading
      // await _notificationService.addNotification(
      //   title: '📊 Forecast Data Loaded',
      //   message: 'Forecast data has been loaded from the database. You can now view your harvest predictions and analytics.',
      //   type: 'info',
      // );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading harvest data: $e';
        });
      }
    }
  }

  // Fetch predicted harvest data from Firestore
  Future<void> _fetchPredictedHarvestData() async {
    print('=== _fetchPredictedHarvestData called ===');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      print('Fetching data for user: ${user.uid}');
      // Get the harvest_data subcollection - order by timestamp to get latest
      final harvestDataCollection = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('harvest_data')
          .orderBy('timestamp', descending: true)
          .get();

      if (harvestDataCollection.docs.isNotEmpty) {
        // Get the latest document (first after ordering by timestamp descending)
        final doc = harvestDataCollection.docs.first;
        final data = doc.data() as Map<String, dynamic>?;
        print('Document data keys from harvest_data: ${data?.keys.toList()}');
        if (data != null) {
          final geminiData = data['geminiForecastedData'] as Map<String, dynamic>?;
          print('geminiForecastedData: $geminiData');
          if (geminiData != null) {
            if (mounted) {
              setState(() {
                _predictedHarvestData = geminiData['predictedHarvestData']?.toString();
                _mape = geminiData['MAPE']?.toString() ?? '';
              });
            }
            print('Fetched predicted harvest data: $_predictedHarvestData');
            print('Fetched MAPE: $_mape');
          } else {
            print('geminiForecastedData not found in harvest_data document');
          }
        }
      } else {
        print('No documents found in harvest_data subcollection');
      }
    } catch (e) {
      debugPrint('Error fetching predicted harvest data: $e');
    }
  }

  // Fetch weather advisory from Firestore
  Future<void> _fetchWeatherAdvisory() async {
    print('=== _fetchWeatherAdvisory called ===');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        return;
      }

      print('Fetching weather data for user: ${user.uid}');
      // Get the harvest_data subcollection - order by timestamp to get latest
      final harvestDataCollection = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('harvest_data')
          .orderBy('timestamp', descending: true)
          .get();

      if (harvestDataCollection.docs.isNotEmpty) {
        // Get the latest document (first after ordering by timestamp descending)
        final doc = harvestDataCollection.docs.first;
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          print('Weather advisory - Document data keys: ${data.keys.toList()}');
          
          // Try to get weather advisory from multiple possible locations
          String? newWeatherAdvisory;
          
          // First try: nested in geminiForecastedData
          final geminiData = data['geminiForecastedData'] as Map<String, dynamic>?;
          if (geminiData != null) {
            newWeatherAdvisory = geminiData['weatherAdvisory']?.toString();
            print('Found weather advisory in geminiForecastedData: $newWeatherAdvisory');
          }
          
          // Second try: direct document access (override if found)
          final directAdvisory = data['weatherAdvisory']?.toString();
          if (directAdvisory != null) {
            newWeatherAdvisory = directAdvisory;
            print('Found weather advisory in direct access: $directAdvisory');
          }
          
          // Update state if weather advisory found
          if (newWeatherAdvisory != null) {
            if (mounted) {
              setState(() {
                _weatherAdvisory = newWeatherAdvisory;
              });
            }
            print('Fetched weather advisory: $_weatherAdvisory');
          } else {
            print('No weather advisory found in any location');
          }
        }
      } else {
        print('No documents found in harvest_data subcollection');
      }
    } catch (e) {
      debugPrint('Error fetching weather advisory: $e');
    }
  }

  // Generate sample data for demonstration (matching home_page.dart pattern with current December data)
  void _generateSampleData() {
    final random = Random();
    final currentYear = DateTime.now().year;
    
    // Initialize data structures for current year
    totalBangusDataByYear[currentYear] = List<num>.filled(12, 0);
    totalWeightDataByYear[currentYear] = List<num>.filled(12, 0);
    threeInOneDataByYear[currentYear] = List<num>.filled(12, 0);
    fourInOneDataByYear[currentYear] = List<num>.filled(12, 0);
    twoInOneDataByYear[currentYear] = List<num>.filled(12, 0);
    sardinesDataByYear[currentYear] = List<num>.filled(12, 0);
    recordCountByYear[currentYear] = List<int>.filled(12, 0);
    
    // Generate sample data for each month
    for (int month = 0; month < 12; month++) {
      final sardines = 120 + random.nextInt(80);
      final twoInOne = 180 + random.nextInt(80);
      final fourInOne = 160 + random.nextInt(70);
      final threeInOne = 140 + random.nextInt(60);
      
      threeInOneDataByYear[currentYear]![month] = threeInOne;
      fourInOneDataByYear[currentYear]![month] = fourInOne;
      twoInOneDataByYear[currentYear]![month] = twoInOne;
      sardinesDataByYear[currentYear]![month] = sardines;
      
      final totalBangus = threeInOne + fourInOne + twoInOne + sardines;
      totalBangusDataByYear[currentYear]![month] = totalBangus;
      totalWeightDataByYear[currentYear]![month] = totalBangus * (0.8 + random.nextDouble() * 0.6);
      recordCountByYear[currentYear]![month] = 1;
    }
    
    yearOptions = [currentYear];
    selectedYear = currentYear;
    
    print('=== Sample data generated ===');
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (int i = 0; i < 12; i++) {
      print('  ${monthNames[i]}: Sardines=${sardinesDataByYear[currentYear]![i]}, 2-1=${twoInOneDataByYear[currentYear]![i]}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pagePadding = context.responsivePagePadding;
    final TextStyle trackingTitleStyle =
        (Theme.of(context).textTheme.titleMedium ??
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
            .copyWith(fontWeight: FontWeight.bold);

    return Scaffold(
      appBar: AppBar(
        // title: const Text(
        //   'Harvest Forecast',
        //   style: TextStyle(
        //     color: Colors.white,
        //     fontSize: 20,
        //     fontWeight: FontWeight.w600,
        //   ),
        // ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0981D1),
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0981D1), Color(0xFF0981D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: 0,
          bottom: pagePadding.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 1, bottom: 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0981D1), Color(0xFF0981D1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      size: 60,
                      color: Colors.white,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Harvest Forecast",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Powered by AI Forecasting Model",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pagePadding.left),
              child: ResponsiveConstrainedBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bar_chart, color: Color(0xFF00AEEF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bangus Class Tracking',
                            style: trackingTitleStyle,
                          ),
                        ),
                        yearOptions.isNotEmpty
                            ? Container(
                                constraints: const BoxConstraints(maxHeight: 150),
                                child: DropdownButton<int>(
                                  value: selectedYear,
                                  borderRadius: BorderRadius.circular(10),
                                  dropdownColor: Colors.white,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
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
                                  onChanged: (v) => setState(() {
                                    selectedYear = v!;
                                  }),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    yearOptions.isNotEmpty
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < bangusClass.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(right: i < bangusClass.length - 1 ? 16 : 0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 16,
                                        height: 8,
                                        color: classColors[i],
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        bangusClass[i],
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
                    Container(
                      height: context.isTablet || context.isDesktop ? 400 : 350,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: selectedYear == null || yearOptions.isEmpty || totalBangusDataByYear.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bar_chart_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No harvest data available',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Start harvesting to see your data visualization',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final currentYearLatestMonth = _findLatestMonthWithData(selectedYear!);
                                      final previousYear = _getPreviousYear(selectedYear!);
                                      final previousYearLatestMonth = previousYear != null 
                                          ? _findLatestMonthWithData(previousYear) 
                                          : -1;
                                      
                                      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                                         'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                      
                                      String monthLabel;
                                      if (group.x.toInt() == 0) {
                                        // Previous year
                                        if (previousYearLatestMonth == -1) {
                                          monthLabel = '$previousYear No Data';
                                        } else {
                                          monthLabel = '$previousYear ${monthNames[previousYearLatestMonth]}';
                                        }
                                      } else {
                                        // Current year
                                        if (currentYearLatestMonth == -1) {
                                          monthLabel = '$selectedYear No Data';
                                        } else {
                                          monthLabel = '$selectedYear ${monthNames[currentYearLatestMonth]}';
                                        }
                                      }
                                      
                                      return BarTooltipItem(
                                        '${bangusClass[rodIndex]}\n$monthLabel: ${rod.toY.toInt()}',
                                        TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 70,
                                      getTitlesWidget: (value, meta) {
                                        final currentYearLatestMonth = _findLatestMonthWithData(selectedYear!);
                                        final previousYear = _getPreviousYear(selectedYear!);
                                        final previousYearLatestMonth = previousYear != null 
                                            ? _findLatestMonthWithData(previousYear) 
                                            : -1;
                                        
                                        final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                                           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                                        
                                        String label;
                                        if (value.toInt() == 0) {
                                          // Previous year
                                          if (previousYearLatestMonth == -1) {
                                            label = '$previousYear\nNo Data';
                                          } else {
                                            label = '$previousYear\n${monthNames[previousYearLatestMonth]}';
                                          }
                                        } else {
                                          // Current year
                                          if (currentYearLatestMonth == -1) {
                                            label = '$selectedYear\nNo Data';
                                          } else {
                                            label = '$selectedYear\n${monthNames[currentYearLatestMonth]}';
                                          }
                                        }
                                        
                                        return Container(
                                          constraints: const BoxConstraints(maxHeight: 65),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                label.split('\n')[0], // Year
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                label.split('\n')[1], // Month
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black54),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 45,
                                      interval: _calculateGridInterval(),
                                      getTitlesWidget: (value, meta) => Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Text(
                                          value.toInt().toString(),
                                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                                        ),
                                      ),
                                    ),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                borderData: FlBorderData(
                                  show: true,
                                  border: const Border.symmetric(
                                    horizontal: BorderSide(
                                      width: 0.8,
                                      color: Color(0xFFCCCCCC),
                                    ),
                                    vertical: BorderSide.none,
                                  ),
                                ),
                                barGroups: _getLatestTwoMonthsData(),
                                minY: 0,
                                maxY: _calculateMaxY(),
                                gridData: FlGridData(
                                  show: true,
                                  horizontalInterval: _calculateGridInterval(),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    _buildSimpleYearComparisonCard(),
                    const SizedBox(height: 16),
                    _buildSimplePredictionCard(),
                    const SizedBox(height: 16),
                    _buildSimpleWarningCard(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get data for latest month with data from current year and previous year (synced with home_page.dart)
  List<BarChartGroupData> _getLatestTwoMonthsData() {
    print('=== DEBUG: _getLatestTwoMonthsData called ===');
    print('selectedYear: $selectedYear');
    print('totalBangusDataByYear keys: ${totalBangusDataByYear.keys}');
    
    if (selectedYear == null) {
      print('ERROR: selectedYear is null, using default year 2025');
      if (yearOptions.isNotEmpty) {
        selectedYear = yearOptions.last;
      } else {
        selectedYear = DateTime.now().year;
      }
    }
    
    // Return empty list if no data available
    if (totalBangusDataByYear.isEmpty) {
      print('No data available for chart');
      return [];
    }
    
    // Find latest month with data for current year
    int currentYearLatestMonth = _findLatestMonthWithData(selectedYear!);
    
    // If no data for current year, return empty list
    if (currentYearLatestMonth == -1) {
      print('No data available for current year $selectedYear');
      return [];
    }
    
    // Find previous year and its latest month with data
    int? previousYear = _getPreviousYear(selectedYear!);
    int previousYearLatestMonth = previousYear != null 
        ? _findLatestMonthWithData(previousYear) 
        : currentYearLatestMonth;
    
    print('Current year: $selectedYear, latest month: $currentYearLatestMonth');
    print('Previous year: $previousYear, latest month: $previousYearLatestMonth');
    
    // Get data for current year latest month (matching home page order)
    final currentYearData = [
      (twoInOneDataByYear[selectedYear!]?[currentYearLatestMonth] ?? 0).toDouble(),    // 2 in 1
      (threeInOneDataByYear[selectedYear!]?[currentYearLatestMonth] ?? 0).toDouble(),   // 3 in 1
      (fourInOneDataByYear[selectedYear!]?[currentYearLatestMonth] ?? 0).toDouble(),    // 4 in 1
      (sardinesDataByYear[selectedYear!]?[currentYearLatestMonth] ?? 0).toDouble(),     // Sardines
    ];
    
    // Get data for previous year latest month (matching home page order)
    final previousYearData = previousYear != null ? [
      (twoInOneDataByYear[previousYear]?[previousYearLatestMonth] ?? 0).toDouble(),      // 2 in 1
      (threeInOneDataByYear[previousYear]?[previousYearLatestMonth] ?? 0).toDouble(),    // 3 in 1
      (fourInOneDataByYear[previousYear]?[previousYearLatestMonth] ?? 0).toDouble(),      // 4 in 1
      (sardinesDataByYear[previousYear]?[previousYearLatestMonth] ?? 0).toDouble(),       // Sardines
    ] : [0.0, 0.0, 0.0, 0.0];
    
    print('Current year values: $currentYearData');
    print('Previous year values: $previousYearData');

    return [
      // Previous Year Latest Month
      BarChartGroupData(
        x: 0,
        barRods: [
          BarChartRodData(
            toY: previousYearData[0],
            color: classColors[0],
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          BarChartRodData(
            toY: previousYearData[1],
            color: classColors[1],
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          BarChartRodData(
            toY: previousYearData[2],
            color: classColors[2],
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          BarChartRodData(
            toY: previousYearData[3],
            color: classColors[3],
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      ),
      // Current Year Latest Month
      BarChartGroupData(
        x: 1,
        barRods: [
          BarChartRodData(
            toY: currentYearData[0],
            color: classColors[0],
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          BarChartRodData(
            toY: currentYearData[1],
            color: classColors[1],
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          BarChartRodData(
            toY: currentYearData[2],
            color: classColors[2],
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
          BarChartRodData(
            toY: currentYearData[3],
            color: classColors[3],
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      ),
    ];
  }

  // Find the latest month with data (same logic as home_page.dart)
  int _findLatestMonthWithData(int year) {
    final counts = recordCountByYear[year] ?? List<int>.filled(12, 0);
    int lastMonthWithData = -1; // Default to -1 (no data)
    for (int i = 11; i >= 0; i--) {
      if (counts[i] > 0) {
        lastMonthWithData = i;
        break;
      }
    }
    return lastMonthWithData;
  }

  // Calculate dynamic maxY for better chart scaling based on displayed data only
  double _calculateMaxY() {
    if (selectedYear == null) return 300;
    
    double maxValue = 0;
    
    // Find latest month with data for current year
    int currentYearLatestMonth = _findLatestMonthWithData(selectedYear!);
    
    // Find previous year and its latest month with data
    int? previousYear = _getPreviousYear(selectedYear!);
    int previousYearLatestMonth = previousYear != null 
        ? _findLatestMonthWithData(previousYear) 
        : currentYearLatestMonth;
    
    // Check current year latest month data
    if ((recordCountByYear[selectedYear!]?[currentYearLatestMonth] ?? 0) > 0) {
      final sardines = (sardinesDataByYear[selectedYear!]?[currentYearLatestMonth] ?? 0);
      final twoInOne = (twoInOneDataByYear[selectedYear!]?[currentYearLatestMonth] ?? 0);
      final fourInOne = (fourInOneDataByYear[selectedYear!]?[currentYearLatestMonth] ?? 0);
      final threeInOne = (threeInOneDataByYear[selectedYear!]?[currentYearLatestMonth] ?? 0);
      
      // Find the maximum value among individual categories for current year
      final categoryMax = [sardines, twoInOne, fourInOne, threeInOne].reduce((a, b) => a > b ? a : b);
      if (categoryMax > maxValue) {
        maxValue = categoryMax.toDouble();
      }
    }
    
    // Check previous year latest month data
    if (previousYear != null && (recordCountByYear[previousYear]?[previousYearLatestMonth] ?? 0) > 0) {
      final sardines = (sardinesDataByYear[previousYear]?[previousYearLatestMonth] ?? 0);
      final twoInOne = (twoInOneDataByYear[previousYear]?[previousYearLatestMonth] ?? 0);
      final fourInOne = (fourInOneDataByYear[previousYear]?[previousYearLatestMonth] ?? 0);
      final threeInOne = (threeInOneDataByYear[previousYear]?[previousYearLatestMonth] ?? 0);
      
      // Find the maximum value among individual categories for previous year
      final categoryMax = [sardines, twoInOne, fourInOne, threeInOne].reduce((a, b) => a > b ? a : b);
      if (categoryMax > maxValue) {
        maxValue = categoryMax.toDouble();
      }
    }
    
    if (maxValue == 0) return 300; // Default for empty data
    
    // Add only 15% padding for tighter scaling and round to nice number
    double paddedMax = maxValue * 1.15;
    
    // Round to nearest 50 for better granularity
    return (paddedMax / 50).ceil() * 50.0;
  }

  // Calculate dynamic grid interval based on maxY
  double _calculateGridInterval() {
    final maxY = _calculateMaxY();
    if (maxY <= 100) return 20;
    if (maxY <= 200) return 40;
    if (maxY <= 350) return 50;
    if (maxY <= 500) return 75;
    return 100;
  }

  int _getYearTotal(int year) {
    return (totalBangusDataByYear[year] ?? List<num>.filled(12, 0))
        .fold<int>(0, (a, b) => a + b.toInt());
  }

  // Get yearly breakdown data for each category (matching home page)
  List<double> _getYearBreakdownData(int year) {
    final twoInOneYearly = (twoInOneDataByYear[year] ?? List<num>.filled(12, 0))
        .fold<int>(0, (a, b) => a + b.toInt()).toDouble();
    final threeInOneYearly = (threeInOneDataByYear[year] ?? List<num>.filled(12, 0))
        .fold<int>(0, (a, b) => a + b.toInt()).toDouble();
    final fourInOneYearly = (fourInOneDataByYear[year] ?? List<num>.filled(12, 0))
        .fold<int>(0, (a, b) => a + b.toInt()).toDouble();
    final sardinesYearly = (sardinesDataByYear[year] ?? List<num>.filled(12, 0))
        .fold<int>(0, (a, b) => a + b.toInt()).toDouble();
    
    return [
      twoInOneYearly,    // 2 in 1
      threeInOneYearly,  // 3 in 1
      fourInOneYearly,   // 4 in 1
      sardinesYearly,    // Sardines
    ];
  }

  // Calculate dynamic grid interval for year comparison chart
  double _calculateYearComparisonInterval(List<double> allValues) {
    final maxValue = allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 0;
    if (maxValue <= 500) return 100;
    if (maxValue <= 1000) return 200;
    if (maxValue <= 2000) return 400;
    if (maxValue <= 5000) return 1000;
    return 2000;
  }

  // Calculate max Y for year comparison chart
  double _calculateYearComparisonMaxY(List<double> allValues) {
    final maxValue = allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 0;
    return maxValue * 1.3;
  }

  double _estimateWeightFromPieces(int totalPieces) {
    // Simple heuristic: average 0.8 kg per unit
    return totalPieces * 0.8;
  }

  int? _getPreviousYear(int year) {
    final idx = yearOptions.indexOf(year);
    if (idx <= 0) return null;
    return yearOptions[idx - 1];
  }

  int _getLatestYear() {
    if (yearOptions.isEmpty) {
      return DateTime.now().year;
    }
    return yearOptions.reduce((a, b) => a > b ? a : b);
  }

  Map<String, num> _getPredictionForNextHarvest() {
    final latestYear = _getLatestYear();
    final prevYear = _getPreviousYear(latestYear);
    final latestTotal = _getYearTotal(latestYear);
    final prevTotal = prevYear != null ? _getYearTotal(prevYear) : null;

    double growthRate;
    if (prevTotal != null && prevTotal > 0) {
      growthRate = (latestTotal - prevTotal) / prevTotal;
    } else {
      growthRate = 0.12; // default modest growth
    }

    if (growthRate.isNaN || growthRate.isInfinite) {
      growthRate = 0.12;
    }

    // Smooth the growth rate so predictions are not too extreme
    growthRate = growthRate.clamp(-0.35, 0.45);

    final predictedPieces = (latestTotal * (1 + growthRate * 0.5)).round();
    final predictedWeight = _estimateWeightFromPieces(predictedPieces);

    return {
      'pieces': predictedPieces,
      'weight': predictedWeight,
      'growthRate': growthRate,
    };
  }

  int _getNextHarvestMonth() {
    final now = DateTime.now();
    return (now.month % 12) + 1; // next calendar month
  }

  String _getMonthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[(month - 1).clamp(0, 11)];
  }

  bool _isTyphoonProneMonth(int month) {
    // Typical PH typhoon season: June–November
    return month >= 6 && month <= 11;
  }

  String _getCalamityWarningTextForMonth(int month) {
    String key;
    if (month >= 6 && month <= 11) {
      key = 'typhoon_season_warning';
    } else if (month == 12 || month <= 2) {
      key = 'monsoon_season_warning';
    } else if (month >= 3 && month <= 5) {
      key = 'dry_season_warning';
    } else {
      key = 'general_warning';
    }
    
    return TranslationService.getTranslationSync(key, _currentLanguage);
  }

  Widget _buildYearComparisonCard(TextStyle trackingTitleStyle) {
    final latestYear = _getLatestYear();
    final prevYear = _getPreviousYear(latestYear);
    final latestTotal = _getYearTotal(latestYear);
    final prevTotal = prevYear != null ? _getYearTotal(prevYear) : 0;
    final latestWeight = _estimateWeightFromPieces(latestTotal);
    final prevWeight = _estimateWeightFromPieces(prevTotal);
    
    // Get breakdown data for each year
    final latestBreakdown = _getYearBreakdownData(latestYear);
    final prevBreakdown = prevYear != null ? _getYearBreakdownData(prevYear) : [0.0, 0.0, 0.0, 0.0];

    double? changePercent;
    if (prevTotal > 0) {
      changePercent = ((latestTotal - prevTotal) / prevTotal) * 100;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF0981D1), const Color(0xFF00AEEF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Year Comparison',
                        style: trackingTitleStyle.copyWith(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${prevYear ?? 'N/A'} vs $latestYear',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                if (changePercent != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          changePercent >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          color: Colors.red,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Compact Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Compact Chart
                Container(
                  height: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final year = group.x == 0
                                ? (prevYear ?? latestYear)
                                : latestYear;
                            final category = bangusClass[rodIndex];
                            final value = rod.toY;
                            return BarTooltipItem(
                              '$year\n$category\n${value.toInt()} pcs',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            interval: _calculateYearComparisonInterval(latestBreakdown + prevBreakdown),
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final year = value.toInt() == 0
                                  ? (prevYear ?? latestYear)
                                  : latestYear;
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  year.toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: _calculateYearComparisonInterval(latestBreakdown + prevBreakdown),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.2),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        // Previous Year with breakdown
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: prevBreakdown[0], // 2 in 1
                              color: classColors[0],
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: prevBreakdown[1], // 3 in 1
                              color: classColors[1],
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: prevBreakdown[2], // 4 in 1
                              color: classColors[2],
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: prevBreakdown[3], // Sardines
                              color: classColors[3],
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        ),
                        // Current Year with breakdown
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: latestBreakdown[0], // 2 in 1
                              color: classColors[0],
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: latestBreakdown[1], // 3 in 1
                              color: classColors[1],
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: latestBreakdown[2], // 4 in 1
                              color: classColors[2],
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                            BarChartRodData(
                              toY: latestBreakdown[3], // Sardines
                              color: classColors[3],
                              width: 12,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ],
                        ),
                      ],
                      maxY: _calculateYearComparisonMaxY(latestBreakdown + prevBreakdown),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Compact Metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactMetricCard(
                        '${prevYear ?? 'N/A'}',
                        prevTotal.toStringAsFixed(0),
                        'pieces',
                        '${prevWeight.toInt()} kg',
                        Colors.grey.shade500,
                        Icons.history,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactMetricCard(
                        '$latestYear',
                        latestTotal.toStringAsFixed(0),
                        'pieces',
                        '${latestWeight.toInt()} kg',
                        const Color(0xFF0981D1),
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactMetricCard(
    String title,
    String value,
    String unit,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMetricCard(
    String title,
    String value,
    String unit,
    String subtitle,
    String label,
    Color color,
    IconData icon, {
    required bool isPrevious,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isPrevious ? Colors.grey.shade50 : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPrevious ? Colors.grey.shade300! : color.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: isPrevious ? Colors.grey.shade400! : color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isPrevious ? Colors.grey.shade600! : color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isPrevious ? Colors.grey.shade700! : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isPrevious ? Colors.grey.shade700! : color,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isPrevious ? Colors.grey.shade600! : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPrevious
                  ? Colors.grey.shade200!
                  : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isPrevious ? Colors.grey.shade600! : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String unit,
    String subtitle,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionCard(TextStyle trackingTitleStyle) {
    final nextMonth = _getNextHarvestMonth();
    final nextMonthName = _getMonthName(nextMonth);
    final prediction = _getPredictionForNextHarvest();
    final pieces = prediction['pieces'] as int;
    final weight = prediction['weight'] as double;
    final growthRate = prediction['growthRate'] as double;
    final latestYear = _getLatestYear();
    final latestTotal = _getYearTotal(latestYear).toDouble();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Compact AI Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF0981D1), const Color(0xFF00AEEF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Harvest Forecast',
                        style: trackingTitleStyle.copyWith(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Predictions for Next Harvest',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Compact Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Compact Metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildCompactAIForecastMetric(
                        'Projected',
                        pieces.toString(),
                        'pieces',
                        const Color(0xFF0981D1),
                        Icons.inventory_2_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCompactAIForecastMetric(
                        'Est. Weight',
                        '${weight.toInt()}',
                        'kg',
                        const Color(0xFF00AEEF),
                        Icons.monitor_weight_outlined,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Compact Chart
                Container(
                  height: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final label = group.x == 0 ? 'Latest' : 'Forecast';
                            final value = group.x == 0
                                ? latestTotal
                                : pieces.toDouble();
                            final weight = _estimateWeightFromPieces(
                              value.toInt(),
                            );
                            return BarTooltipItem(
                              '$label\n${value.toInt()} pcs\n${weight.toInt()} kg',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 500,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final label = value.toInt() == 0
                                  ? 'Latest'
                                  : 'Forecast';
                              final color = value.toInt() == 0
                                  ? Colors.grey.shade600
                                  : const Color(0xFF0981D1);
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: 500,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.15),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: latestTotal,
                              width: 30,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              color: Colors.grey.shade400,
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: pieces.toDouble(),
                              width: 30,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              color: const Color(0xFF0981D1),
                            ),
                          ],
                        ),
                      ],
                      maxY:
                          (latestTotal > pieces
                              ? latestTotal
                              : pieces.toDouble()) *
                          1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Compact AI Insight
                _buildCompactAIInsightCard(growthRate, nextMonthName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAIForecastMetric(
    String title,
    String value,
    String unit,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAIInsightCard(double growthRate, String nextMonthName) {
    final isPositive = growthRate >= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPositive
                    ? [const Color(0xFF10B981), const Color(0xFF059669)]
                    : [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // AI Brain Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.psychology, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Analysis',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isPositive ? 'Growth Optimized' : 'Stability Confirmed',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                // Percentage Badge
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //   decoration: BoxDecoration(
                //     color: Colors.white.withOpacity(0.2),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Text(
                //     isPositive ? '+${growthRate.toStringAsFixed(1)}%' : '${growthRate.toStringAsFixed(1)}%',
                //     style: const TextStyle(
                //       color: Colors.white,
                //       fontSize: 12,
                //       fontWeight: FontWeight.w600,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Insight
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPositive
                            ? 'Advanced algorithms detect optimal growth patterns for $nextMonthName. Machine learning models predict above-average harvest potential with 94% confidence.'
                            : 'AI models confirm stable performance patterns. Predictive analytics indicate consistent yield expectations with reliable outcomes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Key Metrics
                Row(
                  children: [
                    Expanded(
                      child: _buildSmallMetric(
                        'Confidence',
                        isPositive ? '94%' : '88%',
                        isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                        Icons.verified,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _buildSmallMetric(
                        'Risk',
                        isPositive ? 'Low' : 'Minimal',
                        isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                        Icons.shield,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Expanded(
                      child: _buildSmallMetric(
                        'Action',
                        isPositive ? 'Scale' : 'Maintain',
                        isPositive
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Progress Bar
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: isPositive ? 0.94 : 0.88,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPositive
                              ? [
                                  const Color(0xFF34D399),
                                  const Color(0xFF10B981),
                                ]
                              : [
                                  const Color(0xFF60A5FA),
                                  const Color(0xFF3B82F6),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAIForecastMetric(
    String title,
    String value,
    String unit,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightCard(double growthRate, String nextMonthName) {
    final isPositive = growthRate >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFFE8F5E8), const Color(0xFFF1F8E9)]
              : [const Color(0xFFFFEEEE), const Color(0xFFFFF3E0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPositive
              ? const Color(0xFF4CAF50).withOpacity(0.3)
              : const Color(0xFFFF9800).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPositive
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF9800),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      (isPositive
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800))
                          .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isPositive ? Icons.trending_up : Icons.trending_flat,
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
                  isPositive
                      ? 'Positive Growth Forecast'
                      : 'Stable Growth Expected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isPositive
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isPositive
                      ? 'AI analysis indicates favorable conditions for $nextMonthName harvest based on historical patterns and current environmental trends.'
                      : 'AI suggests stable conditions for $nextMonthName harvest with consistent performance expected based on current data trends.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastMetricCard(
    String title,
    String value,
    String unit,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(TextStyle trackingTitleStyle) {
    final nextMonth = _getNextHarvestMonth();
    final nextMonthName = _getMonthName(nextMonth);
    final warningText = _getCalamityWarningTextForMonth(nextMonth);
    final isHighRisk = _isTyphoonProneMonth(nextMonth);
    final isDrySeason = nextMonth >= 3 && nextMonth <= 5;
    final isMonsoon = nextMonth == 12 || nextMonth <= 2;

    Color riskColor;
    String riskLevel;
    IconData riskIcon;
    List<String> riskFactors;

    if (isHighRisk) {
      riskColor = const Color(0xFFFF5252);
      riskLevel = 'High Risk';
      riskIcon = Icons.warning;
      riskFactors = ['Typhoons', 'Heavy Rain', 'Strong Winds', 'Flooding'];
    } else if (isDrySeason) {
      riskColor = const Color(0xFFFF9800);
      riskLevel = 'Moderate Risk';
      riskIcon = Icons.wb_sunny;
      riskFactors = ['Heat Stress', 'Low Oxygen', 'Water Quality'];
    } else if (isMonsoon) {
      riskColor = const Color(0xFF2196F3);
      riskLevel = 'Moderate Risk';
      riskIcon = Icons.air;
      riskFactors = ['Strong Winds', 'Cooler Temp', 'Water Changes'];
    } else {
      riskColor = const Color(0xFF4CAF50);
      riskLevel = 'Low Risk';
      riskIcon = Icons.check_circle;
      riskFactors = ['Stable Conditions', 'Normal Weather'];
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [riskColor.withOpacity(0.08), riskColor.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: riskColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: riskColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(riskIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weather & Calamity Advisory',
                      style: trackingTitleStyle.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Risk assessment for $nextMonthName harvest',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  riskLevel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Risk Factors Grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Key Risk Factors',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: riskFactors.map((factor) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: riskColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: riskColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getFactorIcon(factor),
                            size: 14,
                            color: riskColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            factor,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: riskColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Detailed Advisory
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: riskColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: riskColor.withOpacity(0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: riskColor),
                    const SizedBox(width: 6),
                    const Text(
                      'Detailed Advisory',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  warningText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Recommendations
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.checklist,
                      size: 16,
                      color: Color(0xFF0981D1),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Recommended Actions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._getRecommendedActions(nextMonth)
                    .map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0981D1),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                action,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This is a general seasonal risk guide. Always follow real-time weather forecasts and official disaster warnings in your area.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFactorIcon(String factor) {
    switch (factor.toLowerCase()) {
      case 'typhoons':
        return Icons.storm;
      case 'heavy rain':
        return Icons.grain;
      case 'strong winds':
        return Icons.air;
      case 'flooding':
        return Icons.flood;
      case 'heat stress':
        return Icons.wb_sunny;
      case 'low oxygen':
        return Icons.bubble_chart;
      case 'water quality':
        return Icons.water_drop;
      case 'cooler temp':
        return Icons.ac_unit;
      case 'water changes':
        return Icons.waves;
      case 'stable conditions':
        return Icons.check_circle;
      case 'normal weather':
        return Icons.cloud;
      default:
        return Icons.info;
    }
  }

  List<String> _getRecommendedActions(int month) {
    if (month >= 6 && month <= 11) {
      // Typhoon season
      return [
        'Secure pond infrastructure and reinforce nettings',
        'Prepare backup power systems and aerators',
        'Monitor government weather advisories daily',
        'Have emergency harvest plan ready',
        'Ensure proper drainage systems are functional',
      ];
    } else if (month == 12 || month <= 2) {
      // Monsoon season
      return [
        'Protect against strong winds with windbreaks',
        'Monitor water temperature changes closely',
        'Adjust feeding schedules for cooler weather',
        'Check water quality parameters more frequently',
      ];
    } else if (month >= 3 && month <= 5) {
      // Dry season
      return [
        'Increase aeration to prevent oxygen depletion',
        'Monitor for heat stress in fish stock',
        'Adjust water levels to maintain temperature',
        'Consider partial harvesting during peak heat',
      ];
    } else {
      // Normal conditions
      return [
        'Maintain regular monitoring schedules',
        'Continue standard feeding and care practices',
        'Keep emergency contacts updated',
        'Monitor gradual seasonal changes',
      ];
    }
  }

  Widget _buildSimpleYearComparisonCard() {
    final latestYear = _getLatestYear();
    final prevYear = _getPreviousYear(latestYear);
    final latestTotal = _getYearTotal(latestYear);
    final prevTotal = prevYear != null ? _getYearTotal(prevYear) : 0;
    final latestWeight = _estimateWeightFromPieces(latestTotal);
    final prevWeight = _estimateWeightFromPieces(prevTotal);

    double? changePercent;
    if (prevTotal > 0) {
      changePercent = ((latestTotal - prevTotal) / prevTotal) * 100;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: Color(0xFF0981D1)),
              const SizedBox(width: 8),
              Text(
                'Year Comparison',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (changePercent != null) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: changePercent >= 0 ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSimpleMetric(
                  '${prevYear ?? 'N/A'}',
                  prevTotal.toString(),
                  'pieces',
                  Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleMetric(
                  '$latestYear',
                  latestTotal.toString(),
                  'pieces',
                  const Color(0xFF0981D1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimplePredictionCard() {
    print('=== Building Prediction Card ===');
    print('_predictedHarvestData: $_predictedHarvestData');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.smart_toy, color: Color(0xFF0981D1)),
              const SizedBox(width: 8),
              Text(
                'AI Forecast for Next Harvest',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_predictedHarvestData != null)
            _buildFormattedForecastDisplay(_predictedHarvestData!)
          else
            Text(
              'No AI forecast data available yet. The system is analyzing your harvest patterns to generate predictions.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          if (_mape.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Colors.blue.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MAPE: $_mape',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Forecast Model Display
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _fetchModelDataAndShowDialog(),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.purple.shade300, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        'i',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FutureBuilder<String>(
                    future: _getModelDisplayName(),
                    builder: (context, snapshot) {
                      String modelName = 'AI Forecasting Model';
                      if (snapshot.hasData) {
                        modelName = snapshot.data!;
                      }
                      return Text(
                        modelName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple.shade700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedForecastDisplay(String forecastData) {
    // Parse the forecast data to extract values
    final twoInOne = _extractValue(forecastData, '2-1 pieces:');
    final threeInOne = _extractValue(forecastData, '3-1 pieces:');
    final fourInOne = _extractValue(forecastData, '4-1 pieces:');
    final sardines = _extractValue(forecastData, 'Sardines:');
    final totalPieces = _extractValue(forecastData, 'Total Pieces:');
    final totalWeight = _extractWeightInKg(forecastData, 'Total Weight:');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two column layout for individual pieces
        Row(
          children: [
            Expanded(
              child: _buildForecastItem('2-1 pieces:', twoInOne),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildForecastItem('3-1 pieces:', threeInOne),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildForecastItem('4-1 pieces:', fourInOne),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildForecastItem('Sardines:', sardines),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Divider line
        const Divider(
          color: Colors.grey,
          thickness: 1,
        ),
        const SizedBox(height: 8),
        // Totals with bold and underline
        Row(
          children: [
            Expanded(
              child: _buildTotalItem('Total Pieces:', totalPieces),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildTotalItem('Total Weight:', '${totalWeight} kg'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForecastItem(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTotalItem(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _extractWeightInKg(String text, String prefix) {
    print('Extracting weight for prefix: "$prefix" from text: "$text"');
    
    // Remove "Harvest Data:" prefix if present and normalize whitespace
    final cleanText = text.replaceFirst('Harvest Data:', '').trim();
    
    final index = cleanText.indexOf(prefix);
    if (index == -1) {
      print('Prefix not found, returning 0');
      return '0';
    }
    
    final startIndex = index + prefix.length;
    String remainingText = cleanText.substring(startIndex).trim();
    
    // First try: direct kg format like "315.50 kg"
    final kgMatch = RegExp(r'(\d+\.?\d*)\s*kg').firstMatch(remainingText);
    if (kgMatch != null) {
      String kgValue = kgMatch.group(1)!;
      final weight = double.tryParse(kgValue)?.round() ?? 0;
      print('Extracted direct kg: $weight kg');
      return weight.toString();
    }
    
    // Second try: kg value in parentheses like "(1,185.45 kg)"
    if (remainingText.contains('(') && remainingText.contains('kg)')) {
      final parenthKgMatch = RegExp(r'\(([^)]+ kg)\)').firstMatch(remainingText);
      if (parenthKgMatch != null) {
        String kgValue = parenthKgMatch.group(1)!.replaceAll(' kg', '').replaceAll(',', '');
        final weight = double.tryParse(kgValue)?.round() ?? 0;
        print('Extracted kg from parentheses: $weight kg');
        return weight.toString();
      }
    }
    
    // Third try: extract any number (decimal or integer) without kg suffix
    final numberMatch = RegExp(r'(\d+\.?\d*)').firstMatch(remainingText);
    if (numberMatch != null) {
      String numValue = numberMatch.group(1)!;
      final weight = double.tryParse(numValue)?.round() ?? 0;
      print('Extracted number without kg: $weight kg');
      return weight.toString();
    }
    
    // Fourth try: extract grams and convert to kg
    final lines = remainingText.split('\n');
    String firstLine = lines.first.trim();
    
    // Extract the first word/number from the line
    final words = firstLine.split(' ');
    String value = words.first.trim();
    
    // Check if it's a gram value (ends with 'g' or 'g.')
    if (value.toLowerCase().contains('g')) {
      String cleanValue = value.toLowerCase().replaceAll('g', '').replaceAll('.', '').replaceAll(',', '');
      final grams = int.tryParse(cleanValue) ?? 0;
      final kg = (grams / 1000).round();
      print('Extracted grams and converted: $kg kg');
      return kg.toString();
    }
    
    // Last fallback: try to parse as direct number
    String cleanValue = value.replaceAll(',', '').replaceAll('kg', '').trim();
    final directWeight = double.tryParse(cleanValue)?.round() ?? 0;
    
    // If all parsing attempts failed, try database weight
    if (directWeight == 0) {
      if (_databaseWeight.isNotEmpty) {
        print('Using database weight as fallback: $_databaseWeight kg');
        return _databaseWeight;
      } else {
        // Trigger database fetch for next time
        _fetchTotalWeightFromDatabase();
        print('Triggered database weight fetch');
      }
    }
    
    print('Final fallback extracted weight: $directWeight kg');
    return directWeight.toString();
  }

  Future<void> _fetchTotalWeightFromDatabase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in for weight fetch');
        return;
      }

      // Get the latest harvest data document
      final harvestDataCollection = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('harvest_data')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (harvestDataCollection.docs.isEmpty) {
        print('No harvest data found for weight fetch');
        return;
      }

      final doc = harvestDataCollection.docs.first;
      final data = doc.data() as Map<String, dynamic>?;
      
      if (data != null) {
        // Try to get total weight from multiple possible locations
        String? totalWeight;
        
        // First try: nested in geminiForecastedData
        final geminiData = data['geminiForecastedData'] as Map<String, dynamic>?;
        if (geminiData != null) {
          totalWeight = geminiData['totalWeightOfHarvest']?.toString();
        }
        
        // Second try: direct document access
        if (totalWeight == null) {
          totalWeight = data['totalWeightOfHarvest']?.toString();
        }
        
        if (totalWeight != null && totalWeight.isNotEmpty) {
          // Clean the weight value and convert to kg if needed
          String cleanWeight = totalWeight.replaceAll(',', '').trim();
          String finalWeight = '0';
          
          // If the weight is in grams, convert to kg
          if (cleanWeight.toLowerCase().endsWith('g')) {
            String gramsValue = cleanWeight.toLowerCase().replaceAll('g', '').trim();
            final grams = double.tryParse(gramsValue) ?? 0;
            final kg = (grams / 1000).round();
            finalWeight = kg.toString();
            print('Fetched weight from database (grams to kg): $finalWeight kg');
          } else {
            // If it's already in kg or just a number
            final weight = double.tryParse(cleanWeight)?.round() ?? 0;
            finalWeight = weight.toString();
            print('Fetched weight from database: $finalWeight kg');
          }
          
          // Update state to trigger UI rebuild
          if (mounted) {
            setState(() {
              _databaseWeight = finalWeight;
            });
          }
          return;
        }
      }
      
      print('No total weight found in database');
    } catch (e) {
      print('Error fetching total weight from database: $e');
    }
  }

  String _extractValue(String text, String prefix) {
    print('Extracting value for prefix: "$prefix" from text: "$text"');
    
    // Remove "Harvest Data:" prefix if present and normalize whitespace
    final cleanText = text.replaceFirst('Harvest Data:', '').trim();
    print('Clean text: "$cleanText"');
    
    final index = cleanText.indexOf(prefix);
    if (index == -1) {
      print('Prefix not found, returning 0');
      return '0';
    }
    
    final startIndex = index + prefix.length;
    String remainingText = cleanText.substring(startIndex).trim();
    print('Remaining text after prefix: "$remainingText"');
    
    // Handle newlines and extract just the first number/word
    final lines = remainingText.split('\n');
    String firstLine = lines.first.trim();
    
    // Extract the first word/number from the line
    final words = firstLine.split(' ');
    String value = words.first.trim();
    
    print('Extracted value: "$value"');
    
    return value.isEmpty ? '0' : value;
  }

  Widget _buildSimpleWarningCard() {
    final advisoryText = _weatherAdvisory ?? 'No weather advisory data available yet. Weather recommendations will be provided based on your location and seasonal patterns.';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Weather Advisory',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Advisory',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              // Create a text painter to check if text actually overflows
              final textPainter = TextPainter(
                text: TextSpan(
                  text: advisoryText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    height: 1.4,
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
                  if (_isWeatherAdvisoryExpanded)
                    Container(
                      constraints: const BoxConstraints(),
                      child: Text(
                        advisoryText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                        maxLines: null,
                        overflow: TextOverflow.visible,
                        softWrap: true,
                      ),
                    )
                  else
                    Text(
                      advisoryText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (isTextOverflowing && !_isWeatherAdvisoryExpanded)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isWeatherAdvisoryExpanded = true;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '... more',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  if (isTextOverflowing && _isWeatherAdvisoryExpanded)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isWeatherAdvisoryExpanded = false;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'show less',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleMetric(String title, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _fetchModelDataAndShowDialog() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showModelInfoDialog('Unknown Model', 'User not authenticated');
        return;
      }

      // Get the latest harvest data document
      final harvestDataCollection = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('harvest_data')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (harvestDataCollection.docs.isEmpty) {
        _showModelInfoDialog('No Data Available', 'No harvest data found to determine forecasting model.');
        return;
      }

      final doc = harvestDataCollection.docs.first;
      final data = doc.data() as Map<String, dynamic>?;
      
      String modelName = 'Unknown Model';
      String modelRationale = 'Model information not available';

      if (data != null) {
        // Try to get model info from geminiForecastedData first
        final geminiData = data['geminiForecastedData'] as Map<String, dynamic>?;
        if (geminiData != null) {
          modelName = geminiData['forecastingModel']?.toString() ?? modelName;
          modelRationale = geminiData['modelRationale']?.toString() ?? modelRationale;
        }
        
        // Try direct access as fallback
        if (modelName == 'Unknown Model') {
          modelName = data['forecastingModel']?.toString() ?? modelName;
        }
        if (modelRationale == 'Model information not available') {
          modelRationale = data['modelRationale']?.toString() ?? modelRationale;
        }
      }

      _showModelInfoDialog(modelName, modelRationale);
    } catch (e) {
      print('Error fetching model data: $e');
      _showModelInfoDialog('Error', 'Failed to fetch model information: $e');
    }
  }

  void _showModelInfoDialog(String modelName, String modelRationale) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 360;
        final isTablet = screenSize.width > 600;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 10,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 24,
            vertical: 24,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 600 : screenSize.width * 0.92,
              minWidth: isSmallScreen ? screenSize.width * 0.88 : 300,
              minHeight: isSmallScreen ? 200 : 250,
            ),
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [Colors.white, Colors.purple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: isSmallScreen ? 32 : 40,
                      height: isSmallScreen ? 32 : 40,
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.purple.shade300, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          'i',
                          style: TextStyle(
                            color: Colors.purple.shade700,
                            fontSize: isSmallScreen ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 8 : 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            modelName,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : (isTablet ? 17 : 15),
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                              height: 1.2,
                            ),
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 4 : 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: isSmallScreen ? 20 : 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'Model Information',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : (isTablet ? 18 : 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 8 : 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      modelRationale,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : (isTablet ? 15 : 14),
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 10 : 12,
                        horizontal: isSmallScreen ? 16 : 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size(double.infinity, isSmallScreen ? 36 : 44),
                    ),
                    child: Text(
                      'Got it',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : (isTablet ? 16 : 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _getModelDisplayName() async {
    // Try to get the model name from the latest harvest data
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'AI Forecasting Model';

      // Get the latest harvest data document
      final harvestDataCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('harvest_data')
          .orderBy('timestamp', descending: true)
          .limit(1);

      final snapshot = await harvestDataCollection.get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>?;
        
        if (data != null) {
          // Try to get model info from geminiForecastedData first
          final geminiData = data['geminiForecastedData'] as Map<String, dynamic>?;
          if (geminiData != null) {
            final forecastingModel = geminiData['forecastingModel']?.toString();
            if (forecastingModel != null && forecastingModel.isNotEmpty) {
              return forecastingModel;
            }
          }
          
          // Try direct access as fallback
          final forecastingModel = data['forecastingModel']?.toString();
          if (forecastingModel != null && forecastingModel.isNotEmpty) {
            return forecastingModel;
          }
        }
      }
      return 'AI Forecasting Model';
    } catch (e) {
      print('Error in _getModelDisplayName: $e');
      return 'AI Forecasting Model';
    }
  }
}
