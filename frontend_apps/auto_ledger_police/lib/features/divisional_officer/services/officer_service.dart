import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../models/officer_model.dart';
import '../../../models/shift_model.dart';

class OfficerService {
  OfficerService({
    ApiClient? apiClient,
  }) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<OfficerModel> registerTrafficOfficer({
    required String name,
    required String email,
    required String badgeNumber,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConstants.registerOfficer,
      body: {
        'badgeNo': badgeNumber.trim(),
        'email': email.trim(),
        'name': name.trim(),
        'passwordStr': password.trim(),
      },
    );

    return OfficerModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<OfficerModel>> getDistrictTrafficOfficers() async {
    final response = await _apiClient.get(
      ApiConstants.districtOfficers,
    );

    if (response is! List) {
      return <OfficerModel>[];
    }

    return response
        .whereType<Map<String, dynamic>>()
        .map(OfficerModel.fromJson)
        .toList();
  }

  Future<ShiftModel> assignShift({
    required String officerId,
    required DateTime startTime,
    required DateTime endTime,
    String location = 'Duty Location',
  }) async {
    final payload = {
      'officerId': officerId,
      'date':
          '${startTime.year}-${startTime.month.toString().padLeft(2, '0')}-${startTime.day.toString().padLeft(2, '0')}T00:00:00.000Z',
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'location': location,
    };

    final response = await _apiClient.post(
      ApiConstants.assignShift,
      body: payload,
    );

    return ShiftModel.fromJson(
      response as Map<String, dynamic>,
    );
  }
}