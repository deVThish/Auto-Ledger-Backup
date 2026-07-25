import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/officer_model.dart';
import '../../../models/shift_model.dart';
import '../services/officer_service.dart';
import 'assign_shift_screen.dart';

class TrafficOfficerListScreen extends StatefulWidget {
  const TrafficOfficerListScreen({super.key});

  @override
  State<TrafficOfficerListScreen> createState() =>
      _TrafficOfficerListScreenState();
}

class _TrafficOfficerListScreenState extends State<TrafficOfficerListScreen> {
  final _officerService = OfficerService();
  late Future<List<OfficerModel>> _officersFuture;
  List<OfficerModel> _cachedOfficers = [];
  List<DivisionalHeadModel> _cachedHeads = [];
  final Map<String, List<ShiftModel>> _shiftCache = {};
  final Map<String, bool> _shiftLoadingMap = {};
  Timer? _clockTimer;
  bool _isTransferring = false;

  @override
  void initState() {
    super.initState();
    _officersFuture = _loadOfficers();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _officersFuture = _loadOfficers(clearCache: true);
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  Future<List<OfficerModel>> _loadOfficers({bool clearCache = false}) async {
    if (clearCache) {
      _shiftCache.clear();
      _shiftLoadingMap.clear();
    }

    try {
      final officers = await _officerService.getDistrictTrafficOfficers();
      _cachedOfficers = officers;

      for (final officer in officers) {
        unawaited(_loadOfficerShifts(officer.id));
      }

      if (_cachedHeads.isEmpty) {
        try {
          _cachedHeads = await _officerService.getDivisionalHeads();
        } catch (_) {}
      }
      return officers;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _loadOfficerShifts(String officerId) async {
    if (_shiftLoadingMap[officerId] == true) return;
    if (_shiftCache.containsKey(officerId)) return;

    setState(() => _shiftLoadingMap[officerId] = true);

    try {
      final shifts = await _officerService.getOfficerShifts(officerId);
      if (mounted) {
        setState(() {
          _shiftCache[officerId] = shifts;
          _shiftLoadingMap[officerId] = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _shiftCache[officerId] = [];
          _shiftLoadingMap[officerId] = false;
        });
      }
    }
  }

  String _getStatusForOfficer(OfficerModel officer) {
    final shifts = _shiftCache[officer.id];
    if (shifts == null || shifts.isEmpty) return 'No Shift';

    final now = DateTime.now();
    for (final s in shifts) {
      final start = s.startTime;
      final end = s.endTime;
      if (start != null &&
          end != null &&
          start.isBefore(now) &&
          end.isAfter(now)) {
        return 'On Duty';
      }
    }
    return 'Off Duty';
  }

  String _formatShiftTime(OfficerModel officer) {
    final shifts = _shiftCache[officer.id];
    if (shifts == null || shifts.isEmpty) return 'No shifts assigned';

    final now = DateTime.now();
    ShiftModel? activeShift;
    for (final s in shifts) {
      final start = s.startTime;
      final end = s.endTime;
      if (start != null &&
          end != null &&
          start.isBefore(now) &&
          end.isAfter(now)) {
        activeShift = s;
        break;
      }
    }

    if (activeShift != null) {
      final start = activeShift.startTime;
      final end = activeShift.endTime;
      if (start == null || end == null) return 'Invalid shift times';
      final startLocal = start.toLocal();
      final endLocal = end.toLocal();
      final sHour = startLocal.hour > 12
          ? startLocal.hour - 12
          : startLocal.hour == 0
              ? 12
              : startLocal.hour;
      final sMin = startLocal.minute.toString().padLeft(2, '0');
      final sPeriod = startLocal.hour >= 12 ? 'PM' : 'AM';
      final eHour = endLocal.hour > 12
          ? endLocal.hour - 12
          : endLocal.hour == 0
              ? 12
              : endLocal.hour;
      final eMin = endLocal.minute.toString().padLeft(2, '0');
      final ePeriod = endLocal.hour >= 12 ? 'PM' : 'AM';
      return 'Current: $sHour:$sMin $sPeriod - $eHour:$eMin $ePeriod';
    }

    final futureShifts = shifts
        .where((s) => s.startTime != null && s.startTime!.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime!.compareTo(b.startTime!));

    if (futureShifts.isNotEmpty) {
      final next = futureShifts.first;
      final start = next.startTime;
      final end = next.endTime;
      if (start == null || end == null) return 'Invalid shift times';
      final startLocal = start.toLocal();
      final endLocal = end.toLocal();
      final sHour = startLocal.hour > 12
          ? startLocal.hour - 12
          : startLocal.hour == 0
              ? 12
              : startLocal.hour;
      final sMin = startLocal.minute.toString().padLeft(2, '0');
      final sPeriod = startLocal.hour >= 12 ? 'PM' : 'AM';
      final eHour = endLocal.hour > 12
          ? endLocal.hour - 12
          : endLocal.hour == 0
              ? 12
              : endLocal.hour;
      final eMin = endLocal.minute.toString().padLeft(2, '0');
      final ePeriod = endLocal.hour >= 12 ? 'PM' : 'AM';
      return 'Upcoming: $sHour:$sMin $sPeriod - $eHour:$eMin $ePeriod';
    }

    final pastShifts = shifts
        .where((s) => s.endTime != null && s.endTime!.isBefore(now))
        .toList()
      ..sort((a, b) => b.endTime!.compareTo(a.endTime!));

    if (pastShifts.isNotEmpty) {
      final last = pastShifts.first;
      final start = last.startTime;
      final end = last.endTime;
      if (start == null || end == null) return 'Invalid shift times';
      final startLocal = start.toLocal();
      final endLocal = end.toLocal();
      final sHour = startLocal.hour > 12
          ? startLocal.hour - 12
          : startLocal.hour == 0
              ? 12
              : startLocal.hour;
      final sMin = startLocal.minute.toString().padLeft(2, '0');
      final sPeriod = startLocal.hour >= 12 ? 'PM' : 'AM';
      final eHour = endLocal.hour > 12
          ? endLocal.hour - 12
          : endLocal.hour == 0
              ? 12
              : endLocal.hour;
      final eMin = endLocal.minute.toString().padLeft(2, '0');
      final ePeriod = endLocal.hour >= 12 ? 'PM' : 'AM';
      return 'Last: $sHour:$sMin $sPeriod - $eHour:$eMin $ePeriod';
    }
    return 'No shifts assigned';
  }

  Color _getStatusColor(String status) {
    if (status == 'On Duty') return const Color(0xFF059669);
    return const Color(0xFF64748B);
  }

  Color _getStatusBackground(String status) {
    if (status == 'On Duty') {
      return const Color(0xFF059669).withValues(alpha: 0.1);
    }
    return const Color(0xFFF1F5F9);
  }

  IconData _getStatusIcon(String status) {
    if (status == 'On Duty') return Icons.play_circle_outline_rounded;
    return Icons.schedule_outlined;
  }

  Future<void> _openAssignShift(OfficerModel officer) async {
    await _loadOfficerShifts(officer.id);
    if (!mounted) return;

    final shiftToEdit = _getShiftToEdit(officer);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssignShiftScreen(
          initialOfficer: officer,
          initialShift: shiftToEdit,
        ),
      ),
    );

    if (!mounted) return;
    await _refreshOfficers();
  }

  ShiftModel? _getShiftToEdit(OfficerModel officer) {
    final shifts = _shiftCache[officer.id];
    if (shifts == null || shifts.isEmpty) return null;
    final now = DateTime.now();

    for (final s in shifts) {
      final start = s.startTime;
      final end = s.endTime;
      if (start != null &&
          end != null &&
          start.isBefore(now) &&
          end.isAfter(now)) {
        return s;
      }
    }

    final futureShifts = shifts
        .where((s) => s.startTime != null && s.startTime!.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime!.compareTo(b.startTime!));
    if (futureShifts.isNotEmpty) return futureShifts.first;
    return null;
  }

  Future<void> _transferOfficer(OfficerModel officer) async {
    if (_cachedHeads.isEmpty) {
      try {
        _cachedHeads = await _officerService.getDivisionalHeads();
      } catch (_) {
        AppErrorHandler.showPopup(
          context,
          message: 'Unable to load divisional heads. Please try again.',
        );
        return;
      }
    }

    final availableHeads =
        _cachedHeads.where((h) => h.id != officer.id).toList();

    if (availableHeads.isEmpty) {
      AppErrorHandler.showPopup(
        context,
        message: 'No other divisional heads available for transfer.',
      );
      return;
    }

    DivisionalHeadModel? selectedHead;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentDivisionName = _cachedHeads
                .firstWhere(
                  (h) => h.id == officer.divisionId,
                  orElse: () => availableHeads.first,
                )
                .divisionName;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0B1A30).withValues(alpha: 0.15),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0B1A30),
                                  Color(0xFF1E3A8A),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0B1A30)
                                      .withValues(alpha: 0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.swap_horiz_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Transfer Officer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF0B1A30),
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${officer.name} (${officer.badgeNumber})',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF0B1A30),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF0B1A30).withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Current Division',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentDivisionName,
                                  style: const TextStyle(
                                    color: Color(0xFF0B1A30),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<DivisionalHeadModel>(
                            value: selectedHead,
                            isExpanded: true,
                            hint: const Text(
                              'Select New Divisional Head',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return availableHeads.map<Widget>((head) {
                                final divisionName = head.divisionName.isEmpty
                                    ? 'Unknown Division'
                                    : head.divisionName;
                                final headName = head.name.isEmpty
                                    ? 'Unknown Head'
                                    : head.name;
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$divisionName • $headName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0B1A30),
                                      fontSize: 13,
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            decoration: InputDecoration(
                              labelText: 'New Divisional Head',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              labelStyle: const TextStyle(
                                color: Color(0xFF0B1A30),
                                fontWeight: FontWeight.w600,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                  width: 1.2,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0B1A30),
                                  width: 1.8,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            items: availableHeads.map((head) {
                              final divisionName = head.divisionName.isEmpty
                                  ? 'Unknown Division'
                                  : head.divisionName;
                              final headName = head.name.isEmpty
                                  ? 'Unknown Head'
                                  : head.name;
                              return DropdownMenuItem(
                                value: head,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        divisionName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0B1A30),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        headName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedHead = value;
                              });
                            },
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0B1A30),
                                    side: const BorderSide(
                                      color: Color(0xFFCBD5E1),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: selectedHead == null
                                      ? null
                                      : () =>
                                          Navigator.pop(dialogContext, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0B1A30),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  child: const Text(
                                    'Transfer',
                                    style: TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (confirmed != true || selectedHead == null) return;

    setState(() => _isTransferring = true);

    try {
      await _officerService.transferOfficer(
        officerId: officer.id,
        newHeadId: selectedHead!.id,
      );
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message:
            'Officer transferred to ${selectedHead!.name} successfully.',
        isError: false,
      );
      await _refreshOfficers();
    } on ApiException catch (error) {
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to transfer officer. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isTransferring = false);
      }
    }
  }

  Future<void> _refreshOfficers() async {
    setState(() {
      _officersFuture = _loadOfficers(clearCache: true);
    });
    await _officersFuture;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(
                  color: Color(0xFF0B1A30),
                ),
                title: const Text(
                  'Traffic Officers',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0B1A30),
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding =
                        constraints.maxWidth < 380 ? 20.0 : 24.0;
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: FutureBuilder<List<OfficerModel>>(
                          future: _officersFuture,
                          builder: (context, snapshot) {
                            final snapshotData = snapshot.data;
                            final officers =
                                snapshotData ?? _cachedOfficers;
                            final isFirstLoad = snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                _cachedOfficers.isEmpty &&
                                snapshotData == null;

                            if (snapshot.hasError && officers.isEmpty) {
                              return Column(
                                children: [
                                  const SizedBox(height: 16),
                                  const _HeaderCard(),
                                  const SizedBox(height: 24),
                                  _ErrorCard(
                                    message: snapshot.error is ApiException
                                        ? (snapshot.error as ApiException)
                                            .message
                                        : 'Unable to load traffic officers.',
                                    onRetry: () {
                                      setState(() {
                                        _officersFuture = _loadOfficers(
                                          clearCache: true,
                                        );
                                      });
                                    },
                                  ),
                                ],
                              );
                            }

                            if (isFirstLoad) {
                              return const Padding(
                                padding:
                                    EdgeInsets.symmetric(vertical: 80),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF0B1A30),
                                    strokeWidth: 3,
                                  ),
                                ),
                              );
                            }

                            return Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                const _HeaderCard(),
                                const SizedBox(height: 24),
                                _HeaderStats(officers: officers),
                                const SizedBox(height: 14),
                                if (officers.isEmpty)
                                  const _EmptyCard()
                                else
                                  ...officers.map(
                                    (officer) {
                                      final status =
                                          _getStatusForOfficer(officer);
                                      final isOffDuty = status ==
                                              'Off Duty' ||
                                          status == 'No Shift';
                                      final showTransfer =
                                          status != 'On Duty';
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        child: _OfficerListCard(
                                          officer: officer,
                                          status: status,
                                          shiftTime:
                                              _formatShiftTime(officer),
                                          statusColor:
                                              _getStatusColor(status),
                                          statusBackground:
                                              _getStatusBackground(status),
                                          statusIcon:
                                              _getStatusIcon(status),
                                          showAssignButton: isOffDuty,
                                          showTransferButton: showTransfer,
                                          onAssignShift: () =>
                                              _openAssignShift(officer),
                                          onTransfer: () =>
                                              _transferOfficer(officer),
                                          isTransferring: _isTransferring,
                                        ),
                                      );
                                    },
                                  ),
                                const SizedBox(height: 32),
                              ],
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1A30),
            Color(0xFF162A4A),
            Color(0xFF0F213C),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: const Icon(
              Icons.groups_2_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'District Officers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'View officers assigned to your district',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({required this.officers});
  final List<OfficerModel> officers;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Officer List',
          style: TextStyle(
            color: Color(0xFF0B1A30),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${officers.length} officers',
            style: const TextStyle(
              color: Color(0xFF0B1A30),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _OfficerListCard extends StatelessWidget {
  const _OfficerListCard({
    required this.officer,
    required this.status,
    required this.shiftTime,
    required this.statusColor,
    required this.statusBackground,
    required this.statusIcon,
    required this.showAssignButton,
    required this.showTransferButton,
    required this.onAssignShift,
    required this.onTransfer,
    required this.isTransferring,
  });

  final OfficerModel officer;
  final String status;
  final String shiftTime;
  final Color statusColor;
  final Color statusBackground;
  final IconData statusIcon;
  final bool showAssignButton;
  final bool showTransferButton;
  final VoidCallback onAssignShift;
  final VoidCallback onTransfer;
  final bool isTransferring;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1A30).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0B1A30).withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  color: Color(0xFF0B1A30),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      officer.name.isEmpty ? 'Unnamed Officer' : officer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF0B1A30),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      officer.badgeNumber.isEmpty
                          ? 'No Badge'
                          : officer.badgeNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: status == 'On Duty'
                        ? const Color(0xFF059669).withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'On Duty') ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF059669),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  statusIcon,
                  color: const Color(0xFF0B1A30),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status == 'No Shift'
                            ? 'No Shift Assigned'
                            : status == 'Off Duty'
                                ? 'Off Duty'
                                : 'Shift Details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0B1A30),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shiftTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showAssignButton || showTransferButton) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                if (showAssignButton)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAssignShift,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B1A30),
                        side: const BorderSide(
                          color: Color(0xFFCBD5E1),
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Assign Shift',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (showAssignButton && showTransferButton)
                  const SizedBox(width: 10),
                if (showTransferButton)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isTransferring ? null : onTransfer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B1A30),
                        side: BorderSide(
                          color: isTransferring
                              ? Colors.grey.shade300
                              : const Color(0xFF0B1A30).withValues(alpha: 0.3),
                        ),
                        backgroundColor: isTransferring
                            ? Colors.grey.shade50
                            : const Color(0xFF0B1A30).withValues(alpha: 0.04),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: isTransferring
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF0B1A30),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Transfer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.onRetry,
    required this.message,
  });
  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppTheme.errorRed.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.errorRed,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.errorRed,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
              side: const BorderSide(color: AppTheme.errorRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text(
              'Retry',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1A30).withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        children: [
          Icon(
            Icons.person_off_outlined,
            color: Color(0xFF0B1A30),
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'No traffic officers found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0B1A30),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create a traffic officer account first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}