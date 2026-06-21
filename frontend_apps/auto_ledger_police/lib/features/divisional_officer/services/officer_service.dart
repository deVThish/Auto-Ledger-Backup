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

    final data = _extractMap(response);
    if (data != null) {
      return OfficerModel.fromJson(data);
    }

    return OfficerModel.fromJson(response as Map<String, dynamic>);
  }

  Future<List<OfficerModel>> getDistrictTrafficOfficers() async {
    final response = await _apiClient.get(
      ApiConstants.districtOfficers,
    );

    final rawList = _extractList(response);
    return rawList.map(OfficerModel.fromJson).toList();
  }

  Future<List<ShiftModel>> getOfficerShifts(String officerId) async {
    final response = await _apiClient.get(
      '/officers/$officerId/shifts',
    );

    final rawList = _extractList(response);
    return rawList.map(ShiftModel.fromJson).toList();
  }

  Future<ShiftModel> assignShift({
    required String officerId,
    required DateTime startTime,
    required DateTime endTime,
    String location = 'Duty Location',
  }) async {
    final payload = {
      'officerId': officerId,
      'date': startTime.toUtc().toIso8601String(),
      'startTime': startTime.toUtc().toIso8601String(),
      'endTime': endTime.toUtc().toIso8601String(),
      'location': location,
    };

    final response = await _apiClient.post(
      ApiConstants.assignShift,
      body: payload,
    );

    final data = _extractMap(response);
    if (data != null) {
      return ShiftModel.fromJson(data);
    }

    return ShiftModel.fromJson(response as Map<String, dynamic>);
  }

  Future<ShiftModel> updateShift({
    required String shiftId,
    DateTime? startTime,
    required DateTime endTime,
    String location = 'Duty Location',
  }) async {
    final payload = <String, dynamic>{
      'endTime': endTime.toUtc().toIso8601String(),
      'location': location,
    };

    if (startTime != null) {
      payload['date'] = startTime.toUtc().toIso8601String();
      payload['startTime'] = startTime.toUtc().toIso8601String();
    }

    final response = await _apiClient.patch(
      '${ApiConstants.assignShift}/$shiftId',
      body: payload,
    );

    final data = _extractMap(response);
    if (data != null) {
      return ShiftModel.fromJson(data);
    }

    return ShiftModel.fromJson(response as Map<String, dynamic>);
  }

  List<Map<String, dynamic>> _extractList(dynamic response) {
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().toList();
    }

    if (response is Map<String, dynamic>) {
      final keys = <String>[
        'data',
        'items',
        'results',
        'officers',
        'list',
      ];

      for (final key in keys) {
        final candidate = response[key];
        final extracted = _extractList(candidate);
        if (extracted.isNotEmpty) {
          return extracted;
        }
      }
    }

    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic>? _extractMap(dynamic response) {
    if (response is Map<String, dynamic>) {
      final dataKeys = <String>[
        'data',
        'result',
        'item',
      ];

      for (final key in dataKeys) {
        final candidate = response[key];
        if (candidate is Map<String, dynamic>) {
          return candidate;
        }
      }

      return response;
    }

    return null;
  }
}