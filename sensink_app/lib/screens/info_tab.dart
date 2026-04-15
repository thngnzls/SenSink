import 'package:flutter/material.dart';

class InfoTab extends StatelessWidget {
  const InfoTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('System Guide', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 5),
            Text('Understanding your SenSink metrics', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 20),

            // pH Guide
            _buildInfoCard(
              title: 'pH Level Interpretation',
              icon: Icons.science,
              iconColor: Colors.purpleAccent,
              content: Column(
                children: [
                  _buildLegendRow('0 - 6', 'Acidic (Unsafe)', Colors.redAccent),
                  const SizedBox(height: 10),
                  _buildLegendRow('7', 'Neutral (Optimal)', Colors.green),
                  const SizedBox(height: 10),
                  _buildLegendRow('8 - 14', 'Alkaline (Basic)', Colors.blueAccent),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // Flow Rate Guide
            _buildInfoCard(
              title: 'Flow Rate (L/min)',
              icon: Icons.water_drop,
              iconColor: Colors.cyan,
              content: Text(
                'Flow rate measures how many liters of water pass through the system per minute. Keep an eye on sudden drops, which may indicate a blockage or low pump power.',
                style: TextStyle(color: Colors.grey.shade700, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required IconData icon, required Color iconColor, required Widget content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          content,
        ],
      ),
    );
  }

  Widget _buildLegendRow(String range, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: Text(range, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(width: 15),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ],
    );
  }
}