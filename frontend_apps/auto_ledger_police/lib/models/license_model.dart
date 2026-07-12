import 'fine_model.dart';

class LicenseModel {
  const LicenseModel({
    required this.id,
    required this.licenseNumber,
    required this.status,
    required this.points,
    required this.driverName,
    required this.recentFines,
    this.issueDate,
    this.expiryDate,
    this.temporaryLicenseExpiry,
    this.scanToken = '',
    this.scanVerifiedAt,
    this.scanExpiresAt,
  });

  final String id;
  final String licenseNumber;
  final String status;
  final int points;
  final String driverName;
  final List<FineModel> recentFines;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final DateTime? temporaryLicenseExpiry;
  final String scanToken;
  final DateTime? scanVerifiedAt;
  final DateTime? scanExpiresAt;

  bool get hasExtraDetails =>
      issueDate != null ||
      expiryDate != null ||
      temporaryLicenseExpiry != null ||
      recentFines.isNotEmpty;

  bool get hasActiveScanWindow =>
      scanExpiresAt != null && DateTime.now().isBefore(scanExpiresAt!);

  int get scanRemainingSeconds {
    final expiresAt = scanExpiresAt;
    if (expiresAt == null) return 0;
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining < 0 ? 0 : remaining;
  }

  LicenseModel copyWith({
    String? id,
    String? licenseNumber,
    String? status,
    int? points,
    String? driverName,
    List<FineModel>? recentFines,
    DateTime? issueDate,
    DateTime? expiryDate,
    DateTime? temporaryLicenseExpiry,
    String? scanToken,
    DateTime? scanVerifiedAt,
    DateTime? scanExpiresAt,
  }) {
    return LicenseModel(
      id: id ?? this.id,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      status: status ?? this.status,
      points: points ?? this.points,
      driverName: driverName ?? this.driverName,
      recentFines: recentFines ?? this.recentFines,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      temporaryLicenseExpiry:
          temporaryLicenseExpiry ?? this.temporaryLicenseExpiry,
      scanToken: scanToken ?? this.scanToken,
      scanVerifiedAt: scanVerifiedAt ?? this.scanVerifiedAt,
      scanExpiresAt: scanExpiresAt ?? this.scanExpiresAt,
    );
  }

  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    final licenseData = _asMap(json['license']) ?? json;
    final user = _asMap(licenseData['user']) ?? _asMap(json['user']);

    final rawFines = licenseData['fines'] ??
        licenseData['recentFines'] ??
        json['fines'] ??
        json['recentFines'] ??
        const [];

    final recentFines = rawFines is List
        ? rawFines
            .whereType<Map<String, dynamic>>()
            .map(FineModel.fromJson)
            .take(5)
            .toList()
        : <FineModel>[];

    final issueDate = _readDateFromMaps(
          [licenseData, json, user],
          const ['issue_Date', 'issueDate', 'issuedAt'],
        ) ??
        _readNestedDate(
          licenseData,
          'vehicleCategories',
          const ['issue_Date', 'issueDate', 'issuedAt'],
        );

    final expiryDate = _readDateFromMaps(
          [licenseData, json],
          const ['expiry_Date', 'expiryDate'],
        ) ??
        _readNestedDate(
          licenseData,
          'vehicleCategories',
          const ['expiry_Date', 'expiryDate'],
        );

    final tempExpiry = _readDateFromMaps(
          [licenseData, json],
          const ['temporaryExpiry', 'temporaryLicenseExpiry', 'expiry_Date'],
        ) ??
        _readNestedDate(
          licenseData,
          'temporaryLicenses',
          const ['expiry_Date', 'expiryDate'],
        );

    return LicenseModel(
      id: _readStringFromMaps(
        [licenseData, json],
        const ['license_Id', 'licenseId', 'license_id', 'id'],
      ),
      licenseNumber: _readStringFromMaps(
        [licenseData, json],
        const ['license_No', 'licenseNumber', 'licenseNo', 'license_no'],
      ),
      status: _readStringFromMaps(
        [licenseData, json],
        const ['status', 'licenseStatus'],
        fallback: 'ACTIVE',
      ),
      points: _readInt(licenseData['points'] ?? json['points'] ?? 24),
      driverName: _readStringFromMaps(
        [user, licenseData, json],
        const ['name', 'fullName', 'driverName', 'full_Name'],
      ),
      recentFines: recentFines,
      issueDate: issueDate,
      expiryDate: expiryDate,
      temporaryLicenseExpiry: tempExpiry,
      scanToken: _readStringFromMaps(
        [licenseData, json],
        const ['scanToken', 'scan_token', 'qrToken', 'qr_token', 'token'],
      ),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static String _readStringFromMaps(
    List<Map<String, dynamic>?> maps,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final map in maps) {
      if (map == null) continue;
      for (final key in keys) {
        final value = map[key];
        if (value == null) continue;
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return fallback;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _readDateFromMaps(
    List<Map<String, dynamic>?> maps,
    List<String> keys,
  ) {
    for (final map in maps) {
      if (map == null) continue;
      for (final key in keys) {
        final raw = map[key]?.toString() ?? '';
        if (raw.trim().isEmpty) continue;
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static DateTime? _readNestedDate(
    Map<String, dynamic> json,
    String nestedKey,
    List<String> keys,
  ) {
    final nested = json[nestedKey];
    if (nested is Map<String, dynamic>) {
      return _readDateFromMaps([nested], keys);
    }
    if (nested is List) {
      for (final item in nested.whereType<Map<String, dynamic>>()) {
        final date = _readDateFromMaps([item], keys);
        if (date != null) return date;
      }
    }
    return null;
  }
}