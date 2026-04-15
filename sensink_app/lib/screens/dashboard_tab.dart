import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({Key? key}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  late final DatabaseReference _dbRef;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  bool isSystemOn = false;
  double? waterLevel;
  double? phLevel;
  double? flowRate;
  bool isAppConnected = false;

  // Prevents logging when the app first opens
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://sensink-appdev-default-rtdb.asia-southeast1.firebasedatabase.app/',
    ).ref();
    _activateRealtimeListeners();
  }

  void _activateRealtimeListeners() {
    _dbRef.child('.info/connected').onValue.listen((event) {
      setState(() => isAppConnected = event.snapshot.value as bool? ?? false);
    });

    // --- THE FIX: We log the history inside the listener instead of the button! ---
    // This allows the app to catch ESP32 auto-shutoffs as long as the app is open
    _dbRef.child('sink_monitor/isPumpOn').onValue.listen((event) async {
      if (event.snapshot.value != null) {
        final val = event.snapshot.value;
        bool newPumpState = (val is bool) ? val : (val == 1);

        // Do not generate a log when the app is just starting up
        if (_isFirstLoad) {
          setState(() => isSystemOn = newPumpState);
          _isFirstLoad = false;
          return;
        }

        // If the state actually changed (either by you, or the ESP32)
        if (isSystemOn != newPumpState) {
          setState(() => isSystemOn = newPumpState);

          // Get the EXACT water level directly from Firebase at this exact millisecond to prevent 0%
          DataSnapshot wlSnap = await _dbRef.child('sink_monitor/waterLevelPercent').get();
          double currentWl = double.tryParse(wlSnap.value?.toString() ?? '0') ?? 0.0;

          final now = DateTime.now();
          String timeString = "${now.hour > 12 ? now.hour - 12 : now.hour == 0 ? 12 : now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}";
          String dateString = "${now.month}/${now.day}/${now.year}";

          // Push the log!
          _dbRef.child('sink_monitor/history').push().set({
            'action': newPumpState ? 'FAUCET OPENED' : 'FAUCET CLOSED',
            'date': dateString,
            'time': timeString,
            'waterLevel': currentWl,
            'timestamp': ServerValue.timestamp,
          });
        }
      }
    });

    _dbRef.child('sink_monitor/waterLevelPercent').onValue.listen((event) {
      if (event.snapshot.value != null) setState(() => waterLevel = double.tryParse(event.snapshot.value.toString()));
    });

    _dbRef.child('sink_monitor/phValue').onValue.listen((event) {
      if (event.snapshot.value != null) setState(() => phLevel = double.tryParse(event.snapshot.value.toString()));
    });

    _dbRef.child('sink_monitor/flowRate').onValue.listen((event) {
      if (event.snapshot.value != null) setState(() => flowRate = double.tryParse(event.snapshot.value.toString()));
    });
  }

  void _toggleHardwarePower() {
    if (isAppConnected) {
      // The button ONLY changes the state now. The listener above handles the logging.
      _dbRef.child('sink_monitor/isPumpOn').set(!isSystemOn).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Firebase Error: $error')));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot toggle: No internet connection.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    String displayPh = (isAppConnected && phLevel != null) ? phLevel!.toStringAsFixed(1) : '--';
    String displayFlow = (isAppConnected && flowRate != null) ? '${flowRate!.toStringAsFixed(1)} L/min' : '-- L/min';
    String displayWaterText = (isAppConnected && waterLevel != null) ? '${waterLevel!.toInt()}%' : '--%';
    double progressValue = (isAppConnected && waterLevel != null) ? (waterLevel! / 100).clamp(0.0, 1.0) : 0.0;

    String userName = currentUser?.displayName ?? 'User';

    return Column(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                const Icon(Icons.account_circle, color: Colors.black54, size: 35),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHugeControlButton(),
                const SizedBox(height: 40),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('System Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _buildMetricCard('pH Level', displayPh, 'Optimal', Icons.science, Colors.lightGreenAccent.shade700)),
                    const SizedBox(width: 15),
                    Expanded(child: _buildMetricCard('Flow Rate', displayFlow, 'Steady Flow', Icons.water_drop, Colors.cyan)),
                  ],
                ),
                const SizedBox(height: 15),
                _buildWaterLevelCard(primaryColor, displayWaterText, progressValue),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildConnectionStatusBar(),
      ],
    );
  }

  Widget _buildHugeControlButton() {
    Color offColor = const Color(0xFFD9534F);
    Color onColor = const Color(0xFF5CB85C);
    return Column(
      children: [
        GestureDetector(
          onTap: _toggleHardwarePower,
          child: Container(
            height: 180,
            width: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 20, spreadRadius: 5, offset: const Offset(0, 10))],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(shape: BoxShape.circle, color: isSystemOn ? onColor : offColor),
                child: Center(child: Icon(isSystemOn ? Icons.water_drop : Icons.do_not_disturb_alt, color: Colors.white, size: 80)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isSystemOn ? 'FAUCET OPEN' : 'FAUCET CLOSED',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSystemOn ? onColor : offColor, letterSpacing: 1.2),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String status, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
          const SizedBox(height: 2),
          Text(status, style: TextStyle(fontSize: 12, color: status == 'Optimal' ? Colors.green : Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildWaterLevelCard(Color primaryColor, String displayValue, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.waves, color: primaryColor, size: 24),
                  const SizedBox(width: 8),
                  const Text('Water Level', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              Text(displayValue, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade200, color: primaryColor, minHeight: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusBar() {
    return Container(
      width: double.infinity,
      color: isAppConnected ? Colors.white : Colors.red.shade100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isAppConnected ? Icons.wifi : Icons.wifi_off, color: isAppConnected ? Colors.green : Colors.red, size: 18),
          const SizedBox(width: 8),
          Text(isAppConnected ? 'System Connected' : 'App Offline - Check Wi-Fi', style: TextStyle(color: isAppConnected ? Colors.grey.shade600 : Colors.red.shade800, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 5))]);
  }
}