import 'package:flutter/material.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final simulatedReports = [
      {
        "date": "Nov 01, 2025",
        "actualWeight": "800g",
        "classification": "Medium",
        "remarks": "Healthy growth observed",
      },
      {
        "date": "Oct 25, 2025",
        "actualWeight": "720g",
        "classification": "Small",
        "remarks": "Lower feed intake due to temperature drop",
      },
      {
        "date": "Oct 10, 2025",
        "actualWeight": "900g",
        "classification": "Large",
        "remarks": "Excellent water conditions",
      },
    ];

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
                  Icon(
                    Icons.insert_chart_outlined_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Harvest Reports",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Records of actual weights and observations",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // 📋 Report List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: simulatedReports.length,
              itemBuilder: (context, index) {
                final report = simulatedReports[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFF00AEEF),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              report['date']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1),
                        infoRow("Actual Weight:", report['actualWeight']!),
                        infoRow("Classification:", report['classification']!),
                        const SizedBox(height: 8),
                        Text(
                          "Remarks: ${report['remarks']}",
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
