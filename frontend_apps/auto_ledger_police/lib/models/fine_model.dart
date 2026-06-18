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
    return offenses.fold<int>(0, (sum, offense) => sum + offense.points);
  }

  double get amount {
    return offenses.fold<double>(0, (sum, offense) => sum + offense.amount);
  }

  factory FineModel.fromJson(Map<String, dynamic> json) {
    final license = json['license'];
    final user = license is Map<String, dynamic> ? license['user'] : null;
    final officer = json['officer'];
    final rawOffenses =
        json['offenses'] ?? json['fineDetails'] ?? json['items'] ?? json['fine'];

    final offenses = rawOffenses is List
        ? rawOffenses
            .whereType<Map<String, dynamic>>()
            .map(OffenseModel.fromJson)
            .toList()
        : _readSingleOffense(json);

    return FineModel(
      id: _readString(
        json,
        const ['id', 'fineId', 'fine_id'],
      ),
      status: _readString(
        json,
        const ['status', 'fineStatus'],
      ),
      issuedAt: _readDate(
        json,
        const ['issuedAt', 'createdAt', 'fineIssuedAt'],
      ),
      dueDate: _readDate(
        json,
        const ['dueDate', 'payBy', 'due_at'],
      ),
      licenseNumber: license is Map<String, dynamic>
          ? _readString(
              license,
              const ['licenseNumber', 'licenseNo', 'license_no'],
            )
          : _readString(
              json,
              const ['licenseNumber', 'licenseNo', 'license_no'],
            ),
      driverName: user is Map<String, dynamic>
          ? _readString(
              user,
              const ['name', 'fullName', 'driverName'],
            )
          : _readString(
              json,
              const ['driverName', 'name', 'fullName'],
            ),
      offenses: offenses,
      officerName: officer is Map<String, dynamic>
          ? _readString(
              officer,
              const ['name', 'fullName', 'officerName'],
            )
          : _readString(
              json,
              const ['officerName', 'name', 'fullName'],
            ),
      officerBadgeNumber: officer is Map<String, dynamic>
          ? _readString(
              officer,
              const ['badgeNumber', 'badgeNo', 'badge_No'],
            )
          : _readString(
              json,
              const ['officerBadgeNumber', 'badgeNumber', 'badgeNo'],
            ),
    );
  }

  static List<OffenseModel> _readSingleOffense(Map<String, dynamic> json) {
    final offense = json['offenseCategory'] ?? json['offense'] ?? json['item'];

    if (offense is Map<String, dynamic>) {
      return [OffenseModel.fromJson(offense)];
    }

    final offenseName =
        json['offenseName']?.toString() ?? json['title']?.toString() ?? '';

    if (offenseName.trim().isEmpty) {
      return <OffenseModel>[];
    }

    return [
      OffenseModel(
        id: '',
        code: '',
        name: offenseName,
        description: offenseName,
        amount: _readDouble(json['amount'] ?? json['fee']),
        points: _readInt(json['points'] ?? json['demeritPoints']),
        isCourtCase: false,
      ),
    ];
  }

  static String _readString(
    Map<String, dynamic> json,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
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

  static DateTime? _readDate(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = json[key]?.toString() ?? '';
      if (raw.trim().isEmpty) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return null;
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
      activeOfficersOnDuty: _readInt(json['activeOfficersOnDuty']),
      totalFinesIssued: _readInt(json['totalFinesIssued']),
      totalRevenue: _readDouble(json['totalRevenue']),
      pendingFinesCount: _readInt(json['pendingFinesCount']),
      overdueCourtCases: _readInt(json['overdueCourtCases']),
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
    final rawFineDetails =
        json['fineDetails'] ?? json['fines'] ?? json['results'] ?? json['data'];

    final nestedLicense = json['license'];
    String resolvedLicenseStatus = (json['licenseStatus'] ??
            json['status'] ??
            '')
        .toString();

    if (resolvedLicenseStatus.trim().isEmpty &&
        nestedLicense is Map<String, dynamic>) {
      resolvedLicenseStatus = nestedLicense['status']?.toString() ?? '';
    }

    return FineIssueResultModel(
      fineDetails: rawFineDetails is List
          ? rawFineDetails
              .whereType<Map<String, dynamic>>()
              .map(FineModel.fromJson)
              .toList()
          : <FineModel>[],
      licenseStatus: resolvedLicenseStatus,
      accumulatedPoints:
          _readInt(json['accumulatedPoints'] ?? json['points'] ?? 0),
      temporaryLicenseExpiry: _readDate(
        json,
        const ['temporaryLicenseExpiry', 'temporaryExpiry', 'tempExpiry'],
      ),
    );
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _readDate(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final raw = json[key]?.toString() ?? '';
      if (raw.trim().isEmpty) continue;
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return parsed;
    }
    return null;
  }
}