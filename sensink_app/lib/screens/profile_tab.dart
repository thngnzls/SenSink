import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({Key? key}) : super(key: key);

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final DatabaseReference _dbRef;
  User? user;

  // State for the selected color
  int _selectedColorIndex = 0;

  // A curated list of 5 beautiful, vibrant colors that look great with white text
  final List<Color> _avatarColors = [
    Colors.blue.shade700,
    Colors.teal.shade600,
    Colors.deepOrange.shade600,
    Colors.purple.shade600,
    Colors.red.shade600,
  ];

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;

    // Initialize Database to save/load the user's color preference
    _dbRef = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://sensink-appdev-default-rtdb.asia-southeast1.firebasedatabase.app/',
    ).ref();

    _loadUserColor();
  }

  // --- LOAD COLOR PREFERENCE ---
  void _loadUserColor() async {
    if (user != null) {
      final snapshot = await _dbRef.child('users/${user!.uid}/avatarColorIndex').get();
      if (snapshot.value != null) {
        setState(() {
          _selectedColorIndex = int.tryParse(snapshot.value.toString()) ?? 0;
        });
      }
    }
  }

  // --- LOGIC TO EXTRACT INITIALS ---
  String _getUserInitials() {
    String name = user?.displayName ?? '';
    if (name.isEmpty) {
      name = user?.email?.split('@')[0] ?? 'User';
    }

    name = name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (name.isEmpty) return '??';
    if (name.length == 1) return name;

    return name.substring(0, 1) + name.substring(name.length - 1);
  }

  // --- EDIT USERNAME LOGIC ---
  void _editUsername() {
    TextEditingController nameController = TextEditingController(text: user?.displayName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'New Username', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await user?.updateDisplayName(nameController.text);
                  await user?.reload();
                  setState(() => user = _auth.currentUser);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username updated successfully!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // --- CHANGE PASSWORD LOGIC ---
  void _changePassword() {
    TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'New Password (min 6 chars)', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.length >= 6) {
                try {
                  await user?.updatePassword(passwordController.text);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: Please re-login before changing password.')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // --- COLOR PICKER DIALOG ---
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Profile Color', textAlign: TextAlign.center),
          content: Wrap(
            spacing: 15,
            runSpacing: 15,
            alignment: WrapAlignment.center,
            children: List.generate(_avatarColors.length, (index) {
              bool isSelected = _selectedColorIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedColorIndex = index);
                  if (user != null) {
                    _dbRef.child('users/${user!.uid}/avatarColorIndex').set(index);
                  }
                  Navigator.pop(context);
                },
                child: Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                      color: _avatarColors[index],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black87 : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(color: _avatarColors[index].withOpacity(0.5), blurRadius: 10, spreadRadius: 2)
                      ]
                  ),
                  child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                ),
              );
            }),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),

            _buildPlaceholderAvatar(),

            const SizedBox(height: 20),

            Text(user?.displayName ?? 'User', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.email ?? 'No Email Found', style: TextStyle(color: Colors.grey.shade600)),

            const SizedBox(height: 30),

            _buildSettingsButton(Icons.edit, 'Edit Username', _editUsername),
            _buildSettingsButton(Icons.lock, 'Change Password', _changePassword),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            _buildSettingsButton(Icons.info_outline, 'App Info & Connection Status', () => _showAppInfoDialog(context)),

            const SizedBox(height: 40),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withOpacity(0.1),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                await _auth.signOut();
                Navigator.of(context).pushReplacementNamed('/');
              },
            )
          ],
        ),
      ),
    );
  }

  // --- AVATAR BUILDER ---
  Widget _buildPlaceholderAvatar() {
    String initials = _getUserInitials();
    Color currentColor = _avatarColors[_selectedColorIndex];

    return GestureDetector(
      onTap: _showColorPicker,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: currentColor.withOpacity(0.5), blurRadius: 20, spreadRadius: 3, offset: const Offset(0, 5)),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(color: Colors.black26, offset: Offset(1, 2), blurRadius: 3), // Ensures text pops on any color
                ],
              ),
            ),
            // A little icon badge to let the user know they can click to edit the color
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Icon(Icons.palette, size: 16, color: currentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black54),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('App Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('SenSink App v1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('Server: asia-southeast1 (Realtime DB)'),
            SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text('Auth Linked'),
              ],
            )
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }
}