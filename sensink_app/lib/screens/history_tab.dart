import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  late final DatabaseReference _historyRef;

  @override
  void initState() {
    super.initState();
    _historyRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://sensink-appdev-default-rtdb.asia-southeast1.firebasedatabase.app/',
    ).ref('sink_monitor/history');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activity Log', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 5),
            Text('Real-time hardware events', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _historyRef.orderByChild('timestamp').onValue, // Firebase sorts it chronologically
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text('No activity yet.\nTry toggling the pump!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    );
                  }

                  // FIX: Use .children to perfectly preserve Firebase's chronological sorting!
                  List<Map<String, dynamic>> historyList = [];
                  for (final child in snapshot.data!.snapshot.children) {
                    final data = Map<String, dynamic>.from(child.value as Map);
                    historyList.add(data);
                  }

                  // Reverse the list so the NEWEST event is at the top of the screen
                  historyList = historyList.reversed.toList();

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: historyList.length,
                    itemBuilder: (context, index) {
                      final log = historyList[index];
                      bool isOpened = log['action'] == 'FAUCET OPENED';
                      Color statusColor = isOpened ? const Color(0xFF5CB85C) : const Color(0xFFD9534F);
                      IconData statusIcon = isOpened ? Icons.water_drop : Icons.do_not_disturb_alt;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 5))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
                              child: Icon(statusIcon, color: statusColor, size: 24),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(log['action'] ?? 'Unknown Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor)),
                                  const SizedBox(height: 4),
                                  Text('${log['date']} at ${log['time']}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Tank Level', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text('${log['waterLevel']}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent)),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}