import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MonitorTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MonitorTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.black87),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
