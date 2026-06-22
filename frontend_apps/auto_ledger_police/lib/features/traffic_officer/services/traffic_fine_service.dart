import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../models/fine_model.dart';
import '../../../models/license_model.dart';
import '../../../models/offense_model.dart';

class TrafficFineService {
  TrafficFineService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<OffenseModel>> getOffenses() async {
    final response = await _apiClient.get(ApiConstants.offenses);
    final items = _unwrapList(response);
    if (items.isEmpty) return <OffenseModel>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(OffenseModel.fromJson)
        .toList();
  }

  Future<LicenseModel> scanQr({
    required String qrToken,
    required String location,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.scanQr,
      body: {
        'qrToken': qrToken.trim(),
        'location': location.trim().isEmpty ? 'Current Location' : location.trim(),
      },
    );
    final payload = _unwrapMap(response);
    return LicenseModel.fromJson(payload);
  }

  Future<FineIssueResultModel> issueFine({
    required String licenseId,
    required List<String> offenseIds,
    required String comment,
    required LicenseModel license,
    required List<OffenseModel> selectedOffenses,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.issueFine,
      body: {
        'licenseId': licenseId.trim(),
        'offenseIds': offenseIds
            .map((id) => id.trim())
            .where((id) => id.isNotEmpty)
            .toList(),
        'comment': comment.trim(),
      },
    );

    final payload = _unwrapMap(response);

    // ── Fix: Build FineModel correctly with all required fields ──
    final fineDetails = selectedOffenses.map((offense) {
      return FineModel(
        id: offense.id,
        status: 'PENDING',
        issuedAt: DateTime.now(),
        dueDate: null,
        licenseNumber: license.licenseNumber,
        driverName: license.driverName,
        offenses: [offense],
        officerName: '', // Will be updated from session if needed
        officerBadgeNumber: '', // Will be updated from session if needed
      );
    }).toList();

    return FineIssueResultModel(
      fineId: payload['fine_Id']?.toString() ?? payload['id']?.toString() ?? '',
      licenseId: licenseId,
      status: payload['status']?.toString() ?? 'PENDING',
      licenseStatus: license.status,
      accumulatedPoints: license.points,
      temporaryLicenseExpiry: payload['temporaryLicenseExpiry'] != null
          ? DateTime.tryParse(payload['temporaryLicenseExpiry'].toString())
          : null,
      fineDetails: fineDetails,
    );
  }

  Future<List<FineModel>> getFineHistory() async {
    final response = await _apiClient.get(ApiConstants.fineHistory);
    final items = _unwrapList(response);
    if (items.isEmpty) return <FineModel>[];
    return items
        .whereType<Map<String, dynamic>>()
        .map(FineModel.fromJson)
        .toList();
  }

  Map<String, dynamic> _unwrapMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      final result = response['result'];
      if (result is Map<String, dynamic>) return result;
      return response;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _unwrapList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      final items = response['items'];
      if (items is List) return items;
      final data = response['data'];
      if (data is List) return data;
      final fines = response['fines'];
      if (fines is List) return fines;
      final results = response['results'];
      if (results is List) return results;
    }
    return <dynamic>[];
  }
}