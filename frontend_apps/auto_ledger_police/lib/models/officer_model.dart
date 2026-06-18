class OfficerModel {
  const OfficerModel({
    required this.id,
    required this.name,
    required this.email,
    required this.badgeNumber,
    required this.status,
    required this.role,
    required this.divisionId,
    required this.currentShift,
  });

  final String id;
  final String name;
  final String email;
  final String badgeNumber;
  final String status;
  final String role;
  final String divisionId;
  final ShiftInfoModel? currentShift;

  ShiftInfoModel? get activeShift => currentShift;

  bool get hasActiveShift {
    final shift = currentShift;
    return shift != null && (shift.startTime != null || shift.endTime != null);
  }

  bool get isShiftScheduled {
    final shift = currentShift;
    final start = shift?.startTime;

    if (shift == null || start == null) {
      return false;
    }

    return DateTime.now().isBefore(start);
  }

  bool get isShiftEnded {
    final shift = currentShift;
    final end = shift?.endTime;

    if (shift == null || end == null) {
      return false;
    }

    return DateTime.now().isAfter(end);
  }

  bool get isOnDutyNow {
    final shift = currentShift;
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
      return 'No Shift';
    }

    if (isShiftEnded) {
      return 'No Shift';
    }

    if (isOnDutyNow) {
      return 'Duty';
    }

    if (isShiftScheduled) {
      return 'Scheduled';
    }

    return 'No Shift';
  }

  String get shiftSummaryLabel {
    if (!hasActiveShift) {
      return 'No assigned shift';
    }

    if (isShiftEnded) {
      return 'Assigned shift ended';
    }

    if (isOnDutyNow) {
      return 'Currently on duty';
    }

    if (isShiftScheduled) {
      return 'Upcoming shift';
    }

    return 'Outside shift time';
  }

  String get shiftTimeRange {
    final shift = currentShift;
    final start = shift?.startTime;
    final end = shift?.endTime;

    if (start == null || end == null) {
      return 'Shift not assigned';
    }

    return '${_formatLocalDateTime(start)} - ${_formatLocalDateTime(end)}';
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
      currentShift: currentShiftJson is Map<String, dynamic>
          ? ShiftInfoModel.fromJson(currentShiftJson)
          : null,
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