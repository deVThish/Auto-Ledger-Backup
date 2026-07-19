class OfficerModel {
  const OfficerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.badgeNumber,
    required this.status,
    required this.role,
    required this.divisionId,
    required this.divisionName,
    required this.divisionalHeadName,
    required this.currentShift,
    this.shifts = const [],
  });

  final String id;
  final String name;
  final String email;
  final String badgeNumber;
  final String status;
  final String role;
  final String divisionId;
  final String divisionName;
  final String divisionalHeadName;
  final ShiftInfoModel? currentShift;
  final List<ShiftInfoModel> shifts;

  ShiftInfoModel? get activeShift => _resolveDisplayShift();

  bool get hasActiveShift => activeShift != null;

  bool get isShiftScheduled {
    final shift = activeShift;
    final start = shift?.startTime;

    if (shift == null || start == null) {
      return false;
    }

    return DateTime.now().isBefore(start);
  }

  bool get isShiftEnded {
    final shift = activeShift;
    final end = shift?.endTime;

    if (shift == null || end == null) {
      return false;
    }

    return DateTime.now().isAfter(end);
  }

  bool get isOnDutyNow {
    final shift = activeShift;
    final start = shift?.startTime;
    final end = shift?.endTime;

    if (start != null && end != null) {
      final now = DateTime.now();
      return !now.isBefore(start) && !now.isAfter(end);
    }

    return status.toUpperCase() == 'ON_DUTY';
  }

  String get shiftStatusLabel {
    if (!hasActiveShift) {
      return 'No Duty';
    }

    if (isOnDutyNow) {
      return 'Duty';
    }

    if (isShiftScheduled) {
      return 'Scheduled';
    }

    return 'No Duty';
  }

  String get shiftSummaryLabel {
    if (!hasActiveShift) {
      return 'No assigned shift';
    }

    if (isOnDutyNow) {
      return 'Currently on duty';
    }

    if (isShiftScheduled) {
      return 'Upcoming shift';
    }

    return 'Assigned shift ended';
  }

  String get shiftTimeRange {
    final shift = activeShift;
    final start = shift?.startTime;
    final end = shift?.endTime;

    if (start == null || end == null) {
      return 'Shift not assigned';
    }

    return '${_formatLocalDateTime(start)} - ${_formatLocalDateTime(end)}';
  }

  ShiftInfoModel? _resolveDisplayShift() {
    final now = DateTime.now();
    final candidates = <ShiftInfoModel>[];
    final seenKeys = <String>{};

    void addCandidate(ShiftInfoModel? shift) {
      if (shift == null) return;

      final key = shift.id.isNotEmpty
          ? 'id:${shift.id}'
          : 'time:${shift.startTime?.toIso8601String() ?? ''}:${shift.endTime?.toIso8601String() ?? ''}';

      if (seenKeys.add(key)) {
        candidates.add(shift);
      }
    }

    addCandidate(currentShift);
    for (final shift in shifts) {
      addCandidate(shift);
    }

    if (candidates.isEmpty) {
      return null;
    }

    for (final shift in candidates) {
      if (_isShiftActiveNow(shift, now)) {
        return shift;
      }
    }

    final futureShifts = candidates.where((shift) {
      final start = shift.startTime;
      if (start == null) return false;
      return start.isAfter(now);
    }).toList()
      ..sort((a, b) {
        final aStart = a.startTime;
        final bStart = b.startTime;
        if (aStart == null && bStart == null) return 0;
        if (aStart == null) return 1;
        if (bStart == null) return -1;
        return aStart.compareTo(bStart);
      });

    if (futureShifts.isNotEmpty) {
      return futureShifts.first;
    }

    final pastShifts = candidates.where((shift) {
      final end = shift.endTime;
      if (end == null) return false;
      return end.isBefore(now);
    }).toList()
      ..sort((a, b) {
        final aEnd = a.endTime;
        final bEnd = b.endTime;
        if (aEnd == null && bEnd == null) return 0;
        if (aEnd == null) return 1;
        if (bEnd == null) return -1;
        return bEnd.compareTo(aEnd);
      });

    if (pastShifts.isNotEmpty) {
      return pastShifts.first;
    }

    candidates.sort((a, b) {
      final aStart = a.startTime;
      final bStart = b.startTime;
      if (aStart == null && bStart == null) return 0;
      if (aStart == null) return 1;
      if (bStart == null) return -1;
      return bStart.compareTo(aStart);
    });

    return candidates.first;
  }

  factory OfficerModel.fromJson(Map<String, dynamic> json) {
    final currentShiftJson = json['currentShift'] ??
        json['activeShift'] ??
        json['shift'] ??
        json['current_shift'];

    return OfficerModel(
      id: json['traffic_Officer_Id']?.toString() ??
          json['trafficOfficerId']?.toString() ??
          json['officerId']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ??
          json['fullName']?.toString() ??
          json['officerName']?.toString() ??
          '',
      email: json['email']?.toString() ?? '',
      badgeNumber: json['badge_No']?.toString() ??
          json['badgeNo']?.toString() ??
          json['badgeNumber']?.toString() ??
          json['username']?.toString() ??
          json['badge']?.toString() ??
          '',
      status: json['status']?.toString() ??
          json['officerStatus']?.toString() ??
          json['currentStatus']?.toString() ??
          'OFF_DUTY',
      role: json['role']?.toString() ?? '',
      divisionId: json['divisionId']?.toString() ??
          json['division_Id']?.toString() ??
          json['districtId']?.toString() ??
          json['district_Id']?.toString() ??
          '',
      divisionName: json['divisionName']?.toString() ??
          json['division_Name']?.toString() ??
          '',
      divisionalHeadName: json['divisionalHeadName']?.toString() ??
          json['divisional_Head_Name']?.toString() ??
          '',
      currentShift: currentShiftJson is Map<String, dynamic>
          ? ShiftInfoModel.fromJson(currentShiftJson)
          : null,
      shifts: _readShiftList(json['shifts']),
    );
  }
}

class ShiftInfoModel {
  const ShiftInfoModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isActive,
    required this.location,
    required this.officerId,
  });

  final String id;
  final DateTime? date;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isActive;
  final String location;
  final String officerId;

  factory ShiftInfoModel.fromJson(Map<String, dynamic> json) {
    return ShiftInfoModel(
      id: json['shift_Id']?.toString() ??
          json['shiftId']?.toString() ??
          json['id']?.toString() ??
          '',
      date: _readDateTime(json, const [
        'date',
        'shiftDate',
        'shift_date',
      ]),
      startTime: _readDateTime(json, const [
        'startTime',
        'start_Time',
        'shiftStartTime',
        'shift_start_time',
        'fromTime',
        'start',
      ]),
      endTime: _readDateTime(json, const [
        'endTime',
        'end_Time',
        'shiftEndTime',
        'shift_end_time',
        'toTime',
        'end',
      ]),
      isActive: json['is_Active'] == true || json['isActive'] == true,
      location: json['location']?.toString() ?? '',
      officerId: json['traffic_Officer_Id']?.toString() ??
          json['trafficOfficerId']?.toString() ??
          json['officerId']?.toString() ??
          '',
    );
  }
}

List<ShiftInfoModel> _readShiftList(dynamic rawShifts) {
  if (rawShifts is! List) {
    return const [];
  }

  return rawShifts
      .whereType<Map<String, dynamic>>()
      .map(ShiftInfoModel.fromJson)
      .toList();
}

bool _isShiftActiveNow(ShiftInfoModel shift, DateTime now) {
  final start = shift.startTime;
  final end = shift.endTime;

  if (start != null && end != null) {
    return !now.isBefore(start) && !now.isAfter(end);
  }

  if (start != null) {
    return !now.isBefore(start);
  }

  if (end != null) {
    return !now.isAfter(end);
  }

  return false;
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final raw = json[key]?.toString() ?? '';
    if (raw.trim().isEmpty) {
      continue;
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed != null) {
      return parsed;
    }
  }

  return null;
}

String _formatLocalDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');

  final hour = local.hour > 12
      ? local.hour - 12
      : local.hour == 0
          ? 12
          : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';

  return '$year-$month-$day $hour:$minute $period';
}