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

  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final rawFines =
        json['recentFines'] ?? json['fines'] ?? json['fineDetails'];

    return LicenseModel(
      id: _readString(
        json,
        const ['id', 'licenseId', 'license_id', 'licenseID'],
      ),
      licenseNumber: _readString(
        json,
        const ['licenseNumber', 'licenseNo', 'license_no', 'licenseNumberNo'],
      ),
      status: _readString(
        json,
        const ['status', 'licenseStatus'],
        fallback: 'UNKNOWN',
      ),
      points: _readInt(json['points'] ?? json['currentPoints'] ?? json['demeritPoints']),
      driverName: user is Map<String, dynamic>
          ? _readString(
              user,
              const ['name', 'fullName', 'driverName'],
            )
          : _readString(
              json,
              const ['driverName', 'name', 'fullName'],
            ),
      recentFines: rawFines is List
          ? rawFines
              .whereType<Map<String, dynamic>>()
              .map(FineModel.fromJson)
              .toList()
          : <FineModel>[],
      issueDate: _readDate(
        json,
        const ['issueDate', 'issuedAt', 'createdAt'],
      ),
      expiryDate: _readDate(
        json,
        const ['expiryDate', 'expiresAt', 'expiryAt'],
      ),
      temporaryLicenseExpiry: _readDate(
        json,
        const ['temporaryLicenseExpiry', 'temporaryExpiry'],
      ),
    );
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