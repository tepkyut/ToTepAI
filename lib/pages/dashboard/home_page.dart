import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/stat_card.dart';
import 'widgets/forecast_chart.dart';
import 'forecast_page.dart';
import 'report_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardContent(),
    ForecastPage(),
    ReportPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                ),
              ],
            ),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: const Color(0xFF00AEEF),
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
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
        icon: const Icon(Icons.insert_drive_file_outlined),
        activeIcon: _ActiveNavIcon(
          icon: Icons.insert_drive_file_rounded,
          color: brand,
        ),
        label: 'Reports',
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
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFF00AEEF),
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
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                        Text(
                          "Welcome back, Farmer!",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Here’s your updated overview for today.",
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

            const SizedBox(height: 25),

            // ⚡ Quick Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF00AEEF)),
                      foregroundColor: const Color(0xFF00AEEF),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.sensor_occupied_rounded),
                    label: Text(
                      "Add Data",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
              ],
            ),

            const SizedBox(height: 20),

            // 📊 Statistic Cards
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const [
                StatCard(
                  icon: Icons.water_drop,
                  title: "Total Bangus",
                  value: "1,240",
                  color: Colors.blueAccent,
                ),
                StatCard(
                  icon: Icons.monitor_weight,
                  title: "Avg. Weight",
                  value: "350g",
                  color: Colors.teal,
                ),
                StatCard(
                  icon: Icons.calendar_month,
                  title: "Next Harvest",
                  value: "Nov 12, 2025",
                  color: Colors.orangeAccent,
                ),
                StatCard(
                  icon: Icons.trending_up,
                  title: "Growth Rate",
                  value: "+4.5%",
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 📈 Forecast Chart
            Text(
              "Harvest Forecast Trend",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const ForecastChart(),
            ),

            const SizedBox(height: 30),

            // 🧾 Forecast Summary
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Forecast Summary",
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Based on current growth and feeding data, your estimated harvest is projected to be ready in about 12 days. Maintain optimal pond conditions to ensure consistent growth.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 📝 Recent Activity
            Text(
              "Recent Activity",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Column(
              children: const [
                _ActivityTile(
                  icon: Icons.check_circle_rounded,
                  iconColor: Color(0xFF00AEEF),
                  title: "Report submitted",
                  subtitle: "Weekly pond status has been updated",
                  time: "2h ago",
                ),
                SizedBox(height: 8),
                _ActivityTile(
                  icon: Icons.update_rounded,
                  iconColor: Colors.orangeAccent,
                  title: "Sensor readings",
                  subtitle: "New water temperature recorded",
                  time: "5h ago",
                ),
                SizedBox(height: 8),
                _ActivityTile(
                  icon: Icons.trending_up_rounded,
                  iconColor: Colors.green,
                  title: "Forecast refreshed",
                  subtitle: "AI model recalculated harvest estimate",
                  time: "1d ago",
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
