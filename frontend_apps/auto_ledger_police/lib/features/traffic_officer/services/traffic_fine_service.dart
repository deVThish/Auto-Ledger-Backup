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

    if (response is! List) {
      return <OffenseModel>[];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(OffenseModel.fromJson)
        .toList();
  }

  Future<LicenseModel> verifyLicense(String licenseNumber) async {
    final encodedLicenseNumber = Uri.encodeComponent(licenseNumber.trim());

    final response = await _apiClient.get(
      '${ApiConstants.verifyLicensePrefix}/$encodedLicenseNumber',
    );

    return LicenseModel.fromJson(response as Map<String, dynamic>);
  }

  Future<FineIssueResultModel> issueFine({
    required String qrToken,
    required List<String> offenseCodes,
    required String officerId,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.issueFine,
      body: {
        'qrToken': qrToken.trim(),
        'offenseCodes': offenseCodes,
        'officerId': officerId,
      },
    );

    return FineIssueResultModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<FineModel>> getFineHistory() async {
    final response = await _apiClient.get(ApiConstants.fineHistory);

    if (response is! List) {
      return <FineModel>[];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(FineModel.fromJson)
        .toList();
  }
}