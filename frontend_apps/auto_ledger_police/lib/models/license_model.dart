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
    final licenseData = json['license'] as Map<String, dynamic>? ?? json;
    final user = licenseData['user'];
    final rawFines = licenseData['fines'] ?? licenseData['recentFines'] ?? [];

    // Get issue date from vehicle categories
    DateTime? issueDate;
    if (licenseData['issue_Date'] != null) {
      issueDate = DateTime.tryParse(licenseData['issue_Date'].toString());
    } else if (licenseData['vehicleCategories'] is List) {
      final categories = licenseData['vehicleCategories'] as List;
      if (categories.isNotEmpty) {
        final firstCategory = categories.first as Map<String, dynamic>;
        if (firstCategory['issue_Date'] != null) {
          issueDate = DateTime.tryParse(firstCategory['issue_Date'].toString());
        }
      }
    }

    // Get expiry date from vehicle categories
    DateTime? expiryDate;
    if (licenseData['vehicleCategories'] is List) {
      final categories = licenseData['vehicleCategories'] as List;
      if (categories.isNotEmpty) {
        final firstCategory = categories.first as Map<String, dynamic>;
        if (firstCategory['expiry_Date'] != null) {
          expiryDate = DateTime.tryParse(firstCategory['expiry_Date'].toString());
        }
      }
    }

    // Get temporary license expiry
    DateTime? tempExpiry;
    if (licenseData['temporaryLicenses'] is List) {
      final temps = licenseData['temporaryLicenses'] as List;
      if (temps.isNotEmpty) {
        final firstTemp = temps.first as Map<String, dynamic>;
        if (firstTemp['expiry_Date'] != null) {
          tempExpiry = DateTime.tryParse(firstTemp['expiry_Date'].toString());
        }
      }
    }

    // Get recent fines
    final recentFines = rawFines is List
        ? rawFines
            .whereType<Map<String, dynamic>>()
            .map((f) => FineModel.fromJson(f))
            .take(5)
            .toList()
        : <FineModel>[];

    return LicenseModel(
      id: licenseData['license_Id']?.toString() ??
          licenseData['id']?.toString() ??
          '',
      licenseNumber: licenseData['license_No']?.toString() ??
          licenseData['licenseNumber']?.toString() ??
          '',
      status: licenseData['status']?.toString() ?? 'ACTIVE',
      points: licenseData['points'] as int? ?? 24,
      driverName: user is Map<String, dynamic>
          ? user['name']?.toString() ??
              user['fullName']?.toString() ??
              ''
          : licenseData['full_Name']?.toString() ??
              licenseData['driverName']?.toString() ??
              '',
      recentFines: recentFines,
      issueDate: issueDate,
      expiryDate: expiryDate,
      temporaryLicenseExpiry: tempExpiry,
    );
  }
}