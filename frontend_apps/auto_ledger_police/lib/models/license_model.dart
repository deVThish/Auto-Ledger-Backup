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
    final rawFines = json['fines'];

    return LicenseModel(
      id: json['id']?.toString() ?? '',
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      points: _readInt(json['points']),
      driverName: user is Map<String, dynamic>
          ? user['name']?.toString() ?? ''
          : json['driverName']?.toString() ?? '',
      recentFines: rawFines is List
          ? rawFines
          .whereType<Map<String, dynamic>>()
          .map(FineModel.fromJson)
          .toList()
          : <FineModel>[],
      issueDate: DateTime.tryParse(json['issueDate']?.toString() ?? ''),
      expiryDate: DateTime.tryParse(json['expiryDate']?.toString() ?? ''),
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