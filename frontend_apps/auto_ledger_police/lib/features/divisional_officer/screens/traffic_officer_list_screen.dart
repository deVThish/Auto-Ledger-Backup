import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
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

  final Map<String, List<ShiftModel>> _shiftCache = {};
  final Map<String, bool> _shiftLoadingMap = {};

  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();
    _officersFuture = _loadOfficers();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
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

    final officers = await _officerService.getDistrictTrafficOfficers();
    _cachedOfficers = officers;

    for (final officer in officers) {
      unawaited(_loadOfficerShifts(officer.id));
    }
    return officers;
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
    final hasActive = shifts.any((s) {
      final start = s.startTime;
      final end = s.endTime;
      if (start == null || end == null) return false;
      return start.isBefore(now) && end.isAfter(now);
    });
    if (hasActive) return 'Duty';

    final hasFuture = shifts.any((s) {
      final start = s.startTime;
      if (start == null) return false;
      return start.isAfter(now);
    });
    if (hasFuture) return 'Scheduled';

    return 'Duty';
  }

  ShiftModel? _getShiftToEdit(OfficerModel officer) {
    final shifts = _shiftCache[officer.id];
    if (shifts == null || shifts.isEmpty) return null;

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
    if (activeShift != null) return activeShift;

    final futureShifts = <ShiftModel>[];
    for (final s in shifts) {
      final start = s.startTime;
      if (start != null && start.isAfter(now)) {
        futureShifts.add(s);
      }
    }
    futureShifts.sort((a, b) => a.startTime!.compareTo(b.startTime!));
    if (futureShifts.isNotEmpty) return futureShifts.first;

    return null;
  }

  Future<void> _refreshOfficers() async {
    setState(() {
      _officersFuture = _loadOfficers(clearCache: true);
    });
    await _officersFuture;
  }

  Future<void> _openAssignShift(OfficerModel officer) async {
    await _loadOfficerShifts(officer.id);
    if (!mounted) return;

    final shiftToEdit = _getShiftToEdit(officer);

    final result = await Navigator.of(context).push<bool>(
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

    final shiftToShow = activeShift ?? shifts.first;
    final start = shiftToShow.startTime;
    final end = shiftToShow.endTime;
    if (start == null || end == null) return 'Invalid shift times';

    final startLocal = start.toLocal();
    final endLocal = end.toLocal();

    final sHour = startLocal.hour > 12 ? startLocal.hour - 12 : startLocal.hour;
    final sMin = startLocal.minute.toString().padLeft(2, '0');
    final sPeriod = startLocal.hour >= 12 ? 'PM' : 'AM';

    final eHour = endLocal.hour > 12 ? endLocal.hour - 12 : endLocal.hour;
    final eMin = endLocal.minute.toString().padLeft(2, '0');
    final ePeriod = endLocal.hour >= 12 ? 'PM' : 'AM';

    return '$sHour:$sMin $sPeriod - $eHour:$eMin $ePeriod';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Traffic Officers',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 26.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: FutureBuilder<List<OfficerModel>>(
                  future: _officersFuture,
                  builder: (context, snapshot) {
                    final snapshotData = snapshot.data;
                    final officers = snapshotData ?? _cachedOfficers;
                    final isFirstLoad = snapshot.connectionState ==
                            ConnectionState.waiting &&
                        _cachedOfficers.isEmpty &&
                        snapshotData == null;

                    if (snapshot.hasError && officers.isEmpty) {
                      return _ErrorCard(
                        message: snapshot.error is ApiException
                            ? (snapshot.error as ApiException).message
                            : 'Unable to load traffic officers.',
                        onRetry: _refreshOfficers,
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),
                        _HeaderCard(),
                        const SizedBox(height: 24),
                        _HeaderStats(officers: officers),
                        const SizedBox(height: 14),
                        if (isFirstLoad)
                          const SizedBox.shrink()
                        else if (officers.isEmpty)
                          const _EmptyCard()
                        else
                          ...officers.map(
                            (officer) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _OfficerListCard(
                                officer: officer,
                                status: _getStatusForOfficer(officer),
                                shiftTime: _formatShiftTime(officer),
                                onAssignShift: () =>
                                    _openAssignShift(officer),
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
                      ],
                    );
                  },
                ),
              ),
            );
          },
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlack,
            AppTheme.primaryBlack.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlack.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.groups_2_outlined, color: Colors.white, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'District Officers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'View and manage duty shifts',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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
      children: [
        const Expanded(
          child: Text(
            'Officer List',
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '${officers.length} Officers',
            style: const TextStyle(
              color: AppTheme.primaryBlack,
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
    required this.onAssignShift,
  });

  final OfficerModel officer;
  final String status;
  final String shiftTime;
  final VoidCallback onAssignShift;

  Color get _statusColor {
    if (status == 'Duty') return AppTheme.successGreen;
    if (status == 'Scheduled') return AppTheme.primaryBlack;
    return AppTheme.textGray;
  }

  Color get _statusBackground {
    if (status == 'Duty') {
      return AppTheme.successGreen.withValues(alpha: 0.12);
    }
    if (status == 'Scheduled') {
      return AppTheme.primaryBlack.withValues(alpha: 0.06);
    }
    return AppTheme.lightGray;
  }

  IconData get _statusIcon {
    if (status == 'Duty') return Icons.play_circle_outline_rounded;
    if (status == 'Scheduled') return Icons.schedule_rounded;
    return Icons.schedule_outlined;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.primaryBlack.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(-4, -4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(4, 4),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                child: const Icon(
                  Icons.local_police_outlined,
                  color: AppTheme.primaryBlack,
                  size: 28,
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
                        color: AppTheme.primaryBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      officer.badgeNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: _statusBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: status == 'Duty'
                        ? AppTheme.successGreen.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (status == 'Duty') ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: AppTheme.successGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        color: _statusColor,
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _statusIcon,
                  color: AppTheme.primaryBlack,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status == 'No Shift'
                            ? 'No Shift Assigned'
                            : status == 'Scheduled'
                                ? 'Upcoming Shift'
                                : 'Shift Details',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        shiftTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textGray,
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onAssignShift,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlack,
                side: BorderSide(
                  color: AppTheme.primaryBlack.withValues(alpha: 0.3),
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Assign Shift',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.onRetry, required this.message});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 32),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.errorRed,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
              side: const BorderSide(color: AppTheme.errorRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w800)),
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.primaryBlack.withValues(alpha: 0.1)),
      ),
      child: const Column(
        children: [
          Icon(Icons.person_off_outlined, color: AppTheme.primaryBlack, size: 34),
          SizedBox(height: 12),
          Text(
            'No traffic officers found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create a traffic officer account first.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}