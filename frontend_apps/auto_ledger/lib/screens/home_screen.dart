import 'dart:async';
import 'dart:ui';
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

  // --- Dummy Data for License Card ---
  final String fakeName = "DOE JOHN SAMANTHA";
  final String fakeAddress = "NO 123, FAKE ROAD\nCOLOMBO 07";
  final String fakeNicNo = "199012345678";
  final String fakeLicenseNo = "B1234567";
  final String fakeDob = "01.01.1990";
  final String fakeBloodGroup = "O+";
  final String fakeIssueDate = "05.07.2022";
  final String fakeExpiryDate = "05.07.2030";
  final String fakeRestriction = "AT";

  // --- Dummy Data for Status ---
  final String fakeStatus = "ACTIVE"; // Change to 'ACTIVE', 'SUSPENDED', 'REVOKED' to test

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

  Widget _buildFrontCard() {
    return Container(
      key: const ValueKey(true),
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
          // Hologram effect background
          Positioned.fill(
            child: Opacity(
              opacity: 0.12,
              child: ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.3, 1.0],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/sadakadapahana.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topLeft,
                  color: Colors.black,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/emblem.png',
                  width: 130,
                  color: Colors.black,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 25,
            right: 60,
            child: Opacity(
              opacity: 0.25,
              child: Container(
                width: 35,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.4), width: 0.5),
                ),
                child: const Icon(Icons.person, size: 30, color: Colors.black),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 0.5)),
                      child: Image.asset(
                        'assets/flag.png',
                        width: 35,
                        height: 22,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(width: 35, height: 22, color: Colors.grey[300]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text('DRIVING LICENCE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1), letterSpacing: 1.0)),
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 2),
                            height: 1.0,
                            width: double.infinity,
                            color: Colors.grey.withValues(alpha: 0.4),
                          ),
                          const Text('DEMOCRATIC SOCIALIST REPUBLIC OF SRI LANKA', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF0D47A1))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Image.asset(
                      'assets/emblem.png',
                      width: 30,
                      height: 40,
                      errorBuilder: (c, e, s) => const SizedBox(width: 30, height: 40),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 10.0),
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 85,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.4), width: 0.5),
                              ),
                              child: const Icon(Icons.person, size: 55, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Text('4a. $fakeIssueDate', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87)),
                            const SizedBox(height: 12),

                            // --- NEW SHINY & DYNAMIC STATUS BADGE ---
                            Builder(
                              builder: (context) {
                                List<Color> statusGradient;
                                Color glowColor;
                                IconData statusIcon;

                                if (fakeStatus == 'ACTIVE') {
                                  statusGradient = [const Color(0xFF00b09b), const Color(0xFF96c93d)];
                                  glowColor = const Color(0xFF00b09b);
                                  statusIcon = Icons.check_circle_rounded;
                                } else if (fakeStatus == 'SUSPENDED') {
                                  statusGradient = [const Color(0xFFf12711), const Color(0xFFf5af19)];
                                  glowColor = const Color(0xFFf12711);
                                  statusIcon = Icons.warning_rounded;
                                } else {
                                  statusGradient = [const Color(0xFFcb2d3e), const Color(0xFFef473a)];
                                  glowColor = const Color(0xFFcb2d3e);
                                  statusIcon = Icons.cancel_rounded;
                                }

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: statusGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: glowColor.withValues(alpha: 0.5),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, color: Colors.white, size: 11),
                                      const SizedBox(width: 4),
                                      Text(
                                        fakeStatus,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            // --- END OF BADGE ---
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildDetailText('5. ', fakeLicenseNo, isBold: true),
                                  _buildDetailText('4c. ', fakeNicNo),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildDetailText('1, 2. ', fakeName),
                              const SizedBox(height: 8),
                              _buildDetailText('8. ', fakeAddress),
                              const SizedBox(height: 8),
                              _buildDetailText('3. ', fakeDob),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text('Blood Group  ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  Text(fakeBloodGroup, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  const Spacer(),
                                  const Text('SL', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF8E24AA))),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildBackCard() {
    return Container(
      key: const ValueKey(false),
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
                opacity: 0.04,
                child: Image.asset(
                  'assets/emblem.png',
                  width: 130,
                  color: Colors.black,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (c, e, s) => const SizedBox(),
                ),
              ),
            ),
          ),
          Positioned(
            left: 6,
            top: 15,
            bottom: 15,
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'Department of Motor Traffic - Sri Lanka',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 28, right: 16, top: 12, bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendText('1. Surname'),
                      _buildLegendText('2. Other names'),
                      _buildLegendText('3. Date of birth'),
                      _buildLegendText('4a. Date of Issue of the License'),
                      _buildLegendText('4b. Issuing Authority'),
                      _buildLegendText('4c. Administrative Number'),
                      _buildLegendText('5. Number of the LICENCE'),
                      _buildLegendText('7. Signature of the holder'),
                      _buildLegendText('8. Permanent place of residence'),
                      _buildLegendText('9. Categories of vehicles'),
                      _buildLegendText('10. Date of Issue per category'),
                      _buildLegendText('11. Date of Expiry per category'),
                      _buildLegendText('12. Restrictions in code form'),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 7,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Table(
                      border: TableBorder.all(color: Colors.black.withValues(alpha: 0.3), width: 0.5),
                      columnWidths: const {
                        0: FlexColumnWidth(1.2),
                        1: FlexColumnWidth(2.2),
                        2: FlexColumnWidth(2.2),
                        3: FlexColumnWidth(1.2),
                      },
                      children: [
                        _buildTableRow('9.', '10.', '11.', '12.', isHeader: true),
                        _buildTableRow('A1 🛺', '---', '---', '---'),
                        _buildTableRow('A 🏍️', fakeIssueDate, fakeExpiryDate, '---'),
                        _buildTableRow('B1 🛺', fakeIssueDate, fakeExpiryDate, '---'),
                        _buildTableRow('B 🚗', fakeIssueDate, fakeExpiryDate, fakeRestriction),
                        _buildTableRow('C1 🚚', '---', '---', '---'),
                        _buildTableRow('C 🚛', '---', '---', '---'),
                        _buildTableRow('CE 🚛', '---', '---', '---'),
                        _buildTableRow('D1 🚐', '---', '---', '---'),
                        _buildTableRow('D 🚌', '---', '---', '---'),
                        _buildTableRow('DE 🚌', '---', '---', '---'),
                        _buildTableRow('G1 🚜', '---', '---', '---'),
                        _buildTableRow('G 🚜', '---', '---', '---'),
                        _buildTableRow('J 🏗️', '---', '---', '---'),
                        _buildTableRow('H ♿', '---', '---', '---'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.5),
      child: Text(
        text,
        style: TextStyle(fontSize: 6.0, color: Colors.blueGrey[800], fontWeight: FontWeight.w600, height: 1.0),
      ),
    );
  }

  TableRow _buildTableRow(String col1, String col2, String col3, String restriction, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(color: isHeader ? Colors.grey.withValues(alpha: 0.2) : Colors.transparent),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
          child: Text(col1, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
          child: Text(col2, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
          child: Text(col3, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
          child: Text(restriction, textAlign: TextAlign.center, style: TextStyle(fontSize: isHeader ? 7.5 : 8.5, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal)),
        ),
      ],
    );
  }

  Widget _buildDetailText(String number, String value, {bool isBold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(number, style: TextStyle(fontSize: 8.5, color: Colors.blueGrey[800], fontWeight: FontWeight.bold)),
        const SizedBox(width: 2),
        Text(value, style: TextStyle(fontSize: 9.5, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Text(
            _isFront ? 'Tap the card to see the back side' : 'Tap the card to see the front side',
            style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _isFront = !_isFront;
              });
            },
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _isFront ? _buildFrontCard() : _buildBackCard(),
            ),
          ),
          const SizedBox(height: 32),
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
                const Text('Scan within the time limit', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
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
        height: 65,
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