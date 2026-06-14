import 'offense_model.dart';

class FineModel {
  const FineModel({
    required this.id,
    required this.status,
    required this.issuedAt,
    required this.dueDate,
    required this.licenseNumber,
    required this.driverName,
    required this.offenses,
    required this.officerName,
    required this.officerBadgeNumber,
  });

  final String id;
  final String status;
  final DateTime? issuedAt;
  final DateTime? dueDate;
  final String licenseNumber;
  final String driverName;
  final List<OffenseModel> offenses;
  final String officerName;
  final String officerBadgeNumber;

  String get offenseName {
    if (offenses.isEmpty) return '';
    return offenses.map((offense) => offense.name).join(', ');
  }

  int get points {
    return offenses.fold<int>(
      0,
      (sum, offense) => sum + offense.points,
    );
  }

  double get amount {
    return offenses.fold<double>(
      0,
      (sum, offense) => sum + offense.amount,
    );
  }

  factory FineModel.fromJson(Map<String, dynamic> json) {
    final license = json['license'];
    final user = license is Map<String, dynamic> ? license['user'] : null;
    final officer = json['officer'];
    final rawOffenses = json['offenses'];

    final offenses = rawOffenses is List
        ? rawOffenses
            .whereType<Map<String, dynamic>>()
            .map(OffenseModel.fromJson)
            .toList()
        : _readSingleOffense(json);

    return FineModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      issuedAt: DateTime.tryParse(json['issuedAt']?.toString() ?? ''),
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? ''),
      licenseNumber: license is Map<String, dynamic>
          ? license['licenseNumber']?.toString() ?? ''
          : json['licenseNumber']?.toString() ?? '',
      driverName: user is Map<String, dynamic>
          ? user['name']?.toString() ?? ''
          : json['driverName']?.toString() ?? '',
      offenses: offenses,
      officerName: officer is Map<String, dynamic>
          ? officer['name']?.toString() ?? ''
          : json['officerName']?.toString() ?? '',
      officerBadgeNumber: officer is Map<String, dynamic>
          ? officer['badgeNumber']?.toString() ?? ''
          : json['officerBadgeNumber']?.toString() ?? '',
    );
  }

  static List<OffenseModel> _readSingleOffense(Map<String, dynamic> json) {
    final offense = json['offenseCategory'] ?? json['offense'];

    if (offense is Map<String, dynamic>) {
      return [OffenseModel.fromJson(offense)];
    }

    final offenseName = json['offenseName']?.toString() ?? '';

    if (offenseName.trim().isEmpty) {
      return <OffenseModel>[];
    }

    return [
      OffenseModel(
        id: '',
        code: '',
        name: offenseName,
        description: offenseName,
        amount: _readDouble(json['amount']),
        points: _readInt(json['points']),
        isCourtCase: false,
      ),
    ];
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class DistrictStatisticsModel {
  const DistrictStatisticsModel({
    required this.totalOfficers,
    required this.activeOfficersOnDuty,
    required this.totalFinesIssued,
    required this.totalRevenue,
    required this.pendingFinesCount,
    required this.overdueCourtCases,
  });

  final int totalOfficers;
  final int activeOfficersOnDuty;
  final int totalFinesIssued;
  final double totalRevenue;
  final int pendingFinesCount;
  final int overdueCourtCases;

  factory DistrictStatisticsModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return DistrictStatisticsModel(
      totalOfficers: _readInt(json['totalOfficers']),
      activeOfficersOnDuty:
          _readInt(json['activeOfficersOnDuty']),
      totalFinesIssued:
          _readInt(json['totalFinesIssued']),
      totalRevenue:
          _readDouble(json['totalRevenue']),
      pendingFinesCount:
          _readInt(json['pendingFinesCount']),
      overdueCourtCases:
          _readInt(json['overdueCourtCases']),
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class FineIssueResultModel {
  const FineIssueResultModel({
    required this.fineDetails,
    required this.licenseStatus,
    required this.accumulatedPoints,
    this.temporaryLicenseExpiry,
  });

  final List<FineModel> fineDetails;
  final String licenseStatus;
  final int accumulatedPoints;
  final DateTime? temporaryLicenseExpiry;

  factory FineIssueResultModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawFineDetails = json['fineDetails'];

    return FineIssueResultModel(
      fineDetails: rawFineDetails is List
          ? rawFineDetails
              .whereType<Map<String, dynamic>>()
              .map(FineModel.fromJson)
              .toList()
          : <FineModel>[],
      licenseStatus:
          json['licenseStatus']?.toString() ?? '',
      accumulatedPoints:
          _readInt(json['accumulatedPoints']),
      temporaryLicenseExpiry: DateTime.tryParse(
        json['temporaryLicenseExpiry']?.toString() ?? '',
      ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}