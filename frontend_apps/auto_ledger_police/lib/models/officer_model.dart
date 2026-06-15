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

  bool get hasActiveShift => currentShift != null;

  bool get isOnDutyNow => status.toUpperCase() == 'ON_DUTY';

  bool get isShiftScheduled {
    final shift = currentShift;

    if (shift == null || shift.startTime == null) {
      return false;
    }

    return DateTime.now().isBefore(shift.startTime!);
  }

  bool get isShiftEnded {
    final shift = currentShift;

    if (shift == null || shift.endTime == null) {
      return false;
    }

    return DateTime.now().isAfter(shift.endTime!);
  }

  String get shiftStatusLabel {
    if (!hasActiveShift) {
      return 'No Shift';
    }

    if (status.toUpperCase() == 'ON_DUTY') {
      return 'On Duty';
    }

    if (isShiftScheduled) {
      return 'Scheduled';
    }

    if (isShiftEnded) {
      return 'Shift Ended';
    }

    return 'Off Duty';
  }

  String get shiftSummaryLabel {
    if (!hasActiveShift) {
      return 'No assigned shift';
    }

    if (status.toUpperCase() == 'ON_DUTY') {
      return 'Currently working';
    }

    if (isShiftScheduled) {
      return 'Upcoming shift';
    }

    if (isShiftEnded) {
      return 'Assigned shift ended';
    }

    return 'Outside shift time';
  }

  factory OfficerModel.fromJson(Map<String, dynamic> json) {
    final currentShiftJson = json['currentShift'];

    return OfficerModel(
      id: json['traffic_Officer_Id']?.toString() ??
          json['id']?.toString() ??
          '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      badgeNumber: json['badge_No']?.toString() ??
          json['badgeNo']?.toString() ??
          '',
      status: json['status']?.toString() ?? 'OFF_DUTY',
      role: json['role']?.toString() ?? '',
      divisionId: json['divisionId']?.toString() ??
          json['division_Id']?.toString() ??
          '',
      currentShift: currentShiftJson is Map<String, dynamic>
          ? ShiftInfoModel.fromJson(currentShiftJson)
          : null,
    );
  }
}

class ShiftInfoModel {
  const ShiftInfoModel({
    required this.startTime,
    required this.endTime,
  });

  final DateTime? startTime;
  final DateTime? endTime;

  factory ShiftInfoModel.fromJson(Map<String, dynamic> json) {
    return ShiftInfoModel(
      startTime: DateTime.tryParse(
        json['startTime']?.toString() ??
            json['start_Time']?.toString() ??
            '',
      ),
      endTime: DateTime.tryParse(
        json['endTime']?.toString() ??
            json['end_Time']?.toString() ??
            '',
      ),
    );
  }
}