import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/secure_storage.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _showQR = false;
  int _remainingSeconds = 180;
  Timer? _timer;

  bool _isFront = true;

  final String fakeName = "DOE JOHN SAMANTHA";
  final String fakeAddress = "NO 123, FAKE ROAD, COLOMBO 07";
  final String fakeNicNo = "199012345678";
  final String fakeLicenseNo = "B1234567";
  final String fakeDob = "01.01.1990";
  final String fakeBloodGroup = "A+";
  final String fakeIssueDate = "05.07.2022";
  final String fakeExpiryDate = "05.07.2030";
  final String fakeRestriction = "AT";

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateQR() {
    setState(() {
      _showQR = true;
      _remainingSeconds = 180;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        setState(() => _showQR = false);
      }
    });
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _logout() async {
    await SecureStorage.deleteToken();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  // --- Card Front Design ---
  Widget _buildFrontCard() {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/emblem.png',
                  width: 150,
                  color: Colors.black,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ),
            ),
          ),

          // 2. SL Text Watermark (Bottom Right)
          Positioned(
            right: 20,
            bottom: 10,
            child: Opacity(
              opacity: 0.05,
              child: Text(
                'SL',
                style: TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.green[900]),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side (Photo Only - Signature Removed)
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 70,
                      height: 85,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(Icons.person, size: 50, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 12),

                // Right Side Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Headers & Flag
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DEMOCRATIC SOCIALIST REPUBLIC OF SRI LANKA',
                                  style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1)),
                                ),
                                Text(
                                  'DRIVING LICENCE',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          // Sri Lankan Flag Image
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 0.5),
                            ),
                            child: Image.asset(
                              'assets/flag.png',
                              width: 40,
                              height: 25,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 40, height: 25, color: Colors.grey[300], child: const Icon(Icons.flag, size: 15),
                              ), // පින්තූරය නැත්නම් error එකක් නොපෙන්වා ඉන්න
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Numbered Fields
                      _buildDetailRow('5.', fakeLicenseNo, isBold: true),
                      _buildDetailRow('4c.', fakeNicNo),
                      _buildDetailRow('1, 2.', fakeName),
                      _buildDetailRow('8.', fakeAddress),

                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(child: _buildDetailRow('3.', fakeDob)),
                          Expanded(child: _buildDetailRow('4a.', fakeIssueDate)),
                        ],
                      ),

                      const Spacer(),
                      // Bottom Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text('Blood Group  ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                              Text(fakeBloodGroup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                            ],
                          ),
                          const Text('SL', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF795548))),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Card Back Design ---
  Widget _buildBackCard() {
    return Container(
      width: double.infinity,
      height: 230,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5E1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Stack(
        children: [
          // Left Side Text
          Positioned(
            left: 5,
            top: 20,
            bottom: 20,
            child: RotatedBox(
              quarterTurns: 3,
              child: Text(
                'Department of Motor Traffic - Sri Lanka',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 30, right: 12, top: 20, bottom: 12),
            child: Column(
              children: [
                // Vehicle Classes Table
                Expanded(
                  child: Table(
                    border: TableBorder.all(color: Colors.black.withValues(alpha: 0.3), width: 0.5),
                    columnWidths: const {
                      0: FlexColumnWidth(1.2), // Category + Icon
                      1: FlexColumnWidth(2), // Issue
                      2: FlexColumnWidth(2), // Expiry
                      3: FlexColumnWidth(1), // Restriction
                    },
                    children: [
                      _buildTableRow('9.', '10.', '11.', restriction: '12.', isHeader: true),
                      _buildTableRow('A 🏍️', fakeIssueDate, fakeExpiryDate, restriction: '---'),
                      _buildTableRow('B 🚗', fakeIssueDate, fakeExpiryDate, restriction: fakeRestriction), // AT එක මෙතන
                      _buildTableRow('B1 🛺', fakeIssueDate, fakeExpiryDate, restriction: '---'),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Table Rows
  TableRow _buildTableRow(String col1, String col2, String col3, {String? restriction, bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(color: isHeader ? Colors.grey.withValues(alpha: 0.2) : Colors.transparent),
      children: [
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(col1, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 8 : 10, fontWeight: isHeader ? FontWeight.normal : FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(col2, textAlign: TextAlign.center, style: TextStyle(fontSize: 8)),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(col3, textAlign: TextAlign.center, style: TextStyle(fontSize: 8)),
        ),
        Padding(
          padding: const EdgeInsets.all(6.0),
          child: Text(restriction ?? '-------', textAlign: TextAlign.center, style: TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  // Helper for Front Card Details
  Widget _buildDetailRow(String number, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25,
            child: Text(number, style: TextStyle(fontSize: 9, color: Colors.blueGrey[800], fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 10, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('Tap the card to see the back side', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
          const SizedBox(height: 8),

          // 1. Digital License Card with 3D Flip
          GestureDetector(
            onTap: () {
              setState(() {
                _isFront = !_isFront;
              });
            },
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: _isFront ? 0 : pi),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                bool isFrontView = value < (pi / 2);
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(value),
                  child: isFrontView
                      ? _buildFrontCard()
                      : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateX(pi),
                    child: _buildBackCard(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),

          // 2. QR Code Section
          if (!_showQR)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2980),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                icon: const Icon(Icons.qr_code_scanner, size: 28),
                label: const Text('SHOW QR TO OFFICER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _generateQR,
              ),
            )
          else
            Column(
              children: [
                const Text(
                  'Scan within the time limit',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: QrImageView(
                    data: 'SECURE_TOKEN_$fakeNicNo',
                    version: QrVersions.auto,
                    size: 200.0,
                    eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1A2980)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _formattedTime,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _timer?.cancel();
                    setState(() => _showQR = false);
                  },
                  child: const Text('Close QR', style: TextStyle(fontSize: 16)),
                )
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A2980),
        foregroundColor: Colors.white,
        title: const Text('Auto-Ledger Dashboard', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _currentIndex == 0
          ? _buildDashboard()
          : _currentIndex == 1
          ? const Center(child: Text('Fines Screen Coming Soon!'))
          : const Center(child: Text('Profile Screen Coming Soon!')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.credit_card), label: 'License'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Fines'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}