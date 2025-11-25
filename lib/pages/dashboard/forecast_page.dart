import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';

class ForecastPage extends StatefulWidget {
  const ForecastPage({super.key});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  int selectedYear = 2025;
  final List<int> yearOptions = [2020, 2021, 2022, 2023, 2024, 2025];

  // Random static data by year, class, month (12 values per year/class)
  late final Map<int, Map<String, List<int>>> dataByYear;
  final List<String> bangusClass = ['3 in 1', '4 in 1', '5 in 1'];
  final List<Color> classColors = [Colors.blue, Colors.green, Colors.orange];

  @override
  void initState() {
    super.initState();
    // Generate random static data
    final random = Random(8);
    dataByYear = {};
    for (var y in yearOptions) {
      dataByYear[y] = {
        for (var j = 0; j < bangusClass.length; j++)
          bangusClass[j]: List.generate(12, (i) => 10 + random.nextInt(40)),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final simulatedForecast = {
      "predictedWeight": "850g",
      "harvestDate": DateFormat(
        'MMMM dd, yyyy',
      ).format(DateTime.now().add(const Duration(days: 7))),
      "confidence": "94%",
      "temperature": "29°C",
      "waterQuality": "Good",
    };
    return Scaffold(
      body: Column(
        children: [
          // 🌈 Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 40),
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
                  Icon(Icons.analytics_outlined, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Harvest Forecast",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Powered by ToTepAI Prediction Model",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          // --- ADDED: Year dropdown and Bangus class chart section ---
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
            child: Row(
              children: [
                const Icon(Icons.bar_chart, color: Color(0xFF00AEEF)),
                const SizedBox(width: 8),
                const Text(
                  'Bangus Class Tracking',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: selectedYear,
                  borderRadius: BorderRadius.circular(10),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black, fontSize: 15),
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
              ],
            ),
          ),
          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(
                bangusClass.length,
                (idx) => Padding(
                  padding: const EdgeInsets.only(right: 24, top: 2, bottom: 8),
                  child: Row(
                    children: [
                      Container(width: 20, height: 8, color: classColors[idx]),
                      const SizedBox(width: 6),
                      Text(
                        bangusClass[idx],
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AspectRatio(
            aspectRatio: 1.3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: LineChart(
                LineChartData(
                  lineBarsData: List.generate(bangusClass.length, (idx) {
                    final className = bangusClass[idx];
                    final color = classColors[idx];
                    final data = dataByYear[selectedYear]?[className] ?? [];
                    return LineChartBarData(
                      spots: List.generate(
                        data.length,
                        (i) => FlSpot(i.toDouble(), data[i].toDouble()),
                      ),
                      isCurved: true,
                      color: color,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.18),
                      ),
                    );
                  }),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1.0,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'JAN',
                            'FEB',
                            'MAR',
                            'APR',
                            'MAY',
                            'JUN',
                            'JUL',
                            'AUG',
                            'SEP',
                            'OCT',
                            'NOV',
                            'DEC',
                          ];
                          final idx = value.round();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Transform.rotate(
                              angle: -0.32,
                              child: Text(
                                idx >= 0 && idx < 12 ? months[idx] : '',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: 10,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
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
                  minY: 0,
                  maxY: 60,
                  gridData: FlGridData(show: true, horizontalInterval: 10),
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
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((
                        touched,
                      ) {
                        return LineTooltipItem(
                          '${bangusClass[touched.barIndex]}\n$selectedYear: ${touched.y.toInt()}',
                          TextStyle(
                            color: classColors[touched.barIndex],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // --- END SECTION ---
          // 📊 Forecast Information Card
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "AI Forecast Results",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      infoRow(
                        "Predicted Weight:",
                        simulatedForecast["predictedWeight"]!,
                      ),
                      infoRow(
                        "Estimated Harvest Date:",
                        simulatedForecast["harvestDate"]!,
                      ),
                      infoRow(
                        "Confidence Level:",
                        simulatedForecast["confidence"]!,
                      ),
                      infoRow(
                        "Average Temperature:",
                        simulatedForecast["temperature"]!,
                      ),
                      infoRow(
                        "Water Quality:",
                        simulatedForecast["waterQuality"]!,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "This forecast is generated by the ToTepAI intelligent model based on environmental and growth data from your fish pond.",
                        style: TextStyle(color: Colors.black54, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
