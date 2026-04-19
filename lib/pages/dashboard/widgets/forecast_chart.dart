// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';

// class ForecastChart extends StatelessWidget {
//   const ForecastChart({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: 200,
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.15),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.all(16),
//       child: LineChart(
//         LineChartData(
//           gridData: const FlGridData(show: false),
//           titlesData: FlTitlesData(
//             leftTitles: const AxisTitles(
//               sideTitles: SideTitles(showTitles: false),
//             ),
//             rightTitles: const AxisTitles(
//               sideTitles: SideTitles(showTitles: false),
//             ),
//             topTitles: const AxisTitles(
//               sideTitles: SideTitles(showTitles: false),
//             ),
//             bottomTitles: AxisTitles(
//               sideTitles: SideTitles(
//                 showTitles: true,
//                 reservedSize: 32,
//                 getTitlesWidget: (value, meta) {
//                   switch (value.toInt()) {
//                     case 0:
//                       return const Text("Jun");
//                     case 2:
//                       return const Text("Jul");
//                     case 4:
//                       return const Text("Aug");
//                     default:
//                       return const Text("");
//                   }
//                 },
//               ),
//             ),
//           ),
//           borderData: FlBorderData(show: false),
//           minX: 0,
//           maxX: 5,
//           minY: 0,
//           maxY: 6,
//           lineBarsData: [
//             LineChartBarData(
//               spots: const [
//                 FlSpot(0, 0),
//                 FlSpot(1, 0),
//                 FlSpot(2, 2.5),
//                 FlSpot(3, 4.5),
//                 FlSpot(4, 6),
//                 FlSpot(5, 4),
//               ],
//               isCurved: true,
//               color: Colors.orange,
//               belowBarData: BarAreaData(
//                 show: true,
//                 color: Colors.orangeAccent.withOpacity(0.2),
//               ),
//               dotData: const FlDotData(show: false),
//               barWidth: 4,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
