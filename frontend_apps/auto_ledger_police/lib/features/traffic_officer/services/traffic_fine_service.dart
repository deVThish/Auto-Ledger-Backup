import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

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

    final offenses = items
        .whereType<Map<String, dynamic>>()
        .map(OffenseModel.fromJson)
        .toList();

    offenses.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return offenses;
  }

  Future<LicenseModel> scanQr({
    required String qrToken,
    required String location,
  }) async {
    final requestBody = <String, dynamic>{
      'qrToken': qrToken.trim(),
      'location': location.trim().isEmpty
          ? 'Current Location'
          : location.trim(),
    };

    debugPrint('==================== SCAN QR REQUEST ====================');
    debugPrint('URL: ${ApiConstants.scanQr}');
    debugPrint('BODY: $requestBody');
    debugPrint('=========================================================');

    final response = await _apiClient.post(
      ApiConstants.scanQr,
      body: requestBody,
    );

    debugPrint('==================== SCAN QR RESPONSE ===================');
    debugPrint('RESPONSE: $response');
    debugPrint('=========================================================');

    final payload = _unwrapMap(response);
    final verifiedAt = DateTime.now();
    final parsedLicense = LicenseModel.fromJson(payload);

    final scanToken = parsedLicense.scanToken.trim().isNotEmpty
        ? parsedLicense.scanToken.trim()
        : qrToken.trim();

    final expiresAt = _extractExpiryFromJwt(scanToken);

    if (expiresAt == null) {
      debugPrint('==================== SCAN TOKEN ERROR ===================');
      debugPrint('Could not extract expiry date from JWT. Token is invalid or expired.');
      debugPrint('=========================================================');
      throw const ApiException(
        statusCode: 400,
        message: 'Invalid or expired QR token. Session duration could not be determined.',
      );
    }

    debugPrint('==================== SCAN TOKEN RESULT ==================');
    debugPrint('parsedLicense.id: ${parsedLicense.id}');
    debugPrint('parsedLicense.licenseNumber: ${parsedLicense.licenseNumber}');
    debugPrint('parsedLicense.driverName: ${parsedLicense.driverName}');
    debugPrint('scanToken used in app: $scanToken');
    debugPrint('scanVerifiedAt: $verifiedAt');
    debugPrint('scanExpiresAt: $expiresAt');
    debugPrint('=========================================================');

    return parsedLicense.copyWith(
      scanToken: scanToken,
      scanVerifiedAt: verifiedAt,
      scanExpiresAt: expiresAt,
    );
  }

  Future<FineIssueResultModel> issueFine({
    required String scanToken,
    String? licenseId,
    required List<String> offenseIds,
    required String comment,
    required LicenseModel license,
    required List<OffenseModel> selectedOffenses,
  }) async {
    final resolvedScanToken = _resolveScanToken(
      scanToken: scanToken,
      license: license,
    );

    final resolvedOffenseIds = _resolveOffenseIds(
      offenseIds: offenseIds,
      selectedOffenses: selectedOffenses,
    );

    debugPrint('==================== ISSUE FINE REQUEST ==================');
    debugPrint('URL: ${ApiConstants.issueFine}');
    debugPrint('scanToken raw: $scanToken');
    debugPrint('scanToken resolved: $resolvedScanToken');
    debugPrint('licenseId arg: $licenseId');
    debugPrint('license.id: ${license.id}');
    debugPrint('license.licenseNumber: ${license.licenseNumber}');
    debugPrint('license.scanToken: ${license.scanToken}');
    debugPrint('selected offenseIds raw: $offenseIds');
    debugPrint('selected offenseIds resolved: $resolvedOffenseIds');
    debugPrint('selectedOffenses count: ${selectedOffenses.length}');
    debugPrint('comment: $comment');
    debugPrint('=========================================================');

    if (resolvedScanToken.trim().isEmpty) {
      throw Exception('Scan token is missing.');
    }

    if (resolvedOffenseIds.isEmpty) {
      throw Exception('No valid offense ids selected.');
    }

    final body = <String, dynamic>{
      'scanToken': resolvedScanToken.trim(),
      'offenseIds': resolvedOffenseIds,
    };

    final trimmedComment = comment.trim();
    if (trimmedComment.isNotEmpty) {
      body['comment'] = trimmedComment;
    }

    debugPrint('==================== ISSUE FINE BODY =====================');
    debugPrint('$body');
    debugPrint('=========================================================');

    final response = await _apiClient.post(
      ApiConstants.issueFine,
      body: body,
    );

    debugPrint('==================== ISSUE FINE RESPONSE ================');
    debugPrint('RESPONSE: $response');
    debugPrint('=========================================================');

    final payload = _unwrapMap(response);

    final fineDetails = _buildFineDetails(
      payload: payload,
      selectedOffenses: selectedOffenses,
      license: license,
    );

    final fineResult = FineIssueResultModel(
      fineId: _readString(
        payload,
        const ['fine_Id', 'fineId', 'fine_id', 'id'],
      ),
      licenseId: _readString(
        payload,
        const ['license_Id', 'licenseId', 'license_id'],
        fallback: licenseId?.trim().isNotEmpty == true
            ? licenseId!.trim()
            : license.licenseNumber,
      ),
      status: _readString(
        payload,
        const ['status', 'fineStatus'],
        fallback: 'PENDING',
      ),
      licenseStatus: _readString(
        payload,
        const ['licenseStatus', 'license_status'],
        fallback: license.status,
      ),
      accumulatedPoints: _readInt(
        payload['accumulatedPoints'] ??
            payload['currentPoints'] ??
            payload['points'] ??
            license.points,
      ),
      temporaryLicenseExpiry: _readDate(
        payload['temporaryLicenseExpiry'] ??
            payload['temporary_license_expiry'] ??
            payload['tempLicenseExpiry'] ??
            payload['temporaryExpiry'],
      ),
      fineDetails: fineDetails,
    );

    debugPrint('==================== ISSUE FINE RESULT ==================');
    debugPrint('fineId: ${fineResult.fineId}');
    debugPrint('licenseId: ${fineResult.licenseId}');
    debugPrint('status: ${fineResult.status}');
    debugPrint('licenseStatus: ${fineResult.licenseStatus}');
    debugPrint('accumulatedPoints: ${fineResult.accumulatedPoints}');
    debugPrint('temporaryLicenseExpiry: ${fineResult.temporaryLicenseExpiry}');
    debugPrint('fineDetails count: ${fineResult.fineDetails.length}');
    debugPrint('=========================================================');

    return fineResult;
  }

  Future<List<FineModel>> getFineHistory() async {
    final response = await _apiClient.get(ApiConstants.fineHistory);
    final items = _unwrapList(response);

    if (items.isEmpty) return <FineModel>[];

    final fines = items
        .whereType<Map<String, dynamic>>()
        .map(FineModel.fromJson)
        .toList();

    fines.sort((a, b) {
      final aDate = a.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return fines;
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

  List<FineModel> _buildFineDetails({
    required Map<String, dynamic> payload,
    required List<OffenseModel> selectedOffenses,
    required LicenseModel license,
  }) {
    final rawFineDetails = payload['offenses'] ??
        payload['fineDetails'] ??
        payload['items'] ??
        payload['fine'];

    if (rawFineDetails is List) {
      final parsed = rawFineDetails
          .whereType<Map<String, dynamic>>()
          .map(FineModel.fromJson)
          .toList();

      if (parsed.isNotEmpty) {
        return parsed;
      }
    }

    final dueDate = _readDate(
      payload['dueDate'] ?? payload['payBy'] ?? payload['due_at'],
    );

    final status = _readString(
      payload,
      const ['status', 'fineStatus'],
      fallback: 'PENDING',
    );

    return selectedOffenses.map((offense) {
      return FineModel(
        id: offense.id.isNotEmpty ? offense.id : offense.code,
        status: status,
        issuedAt: DateTime.now(),
        dueDate: dueDate,
        licenseNumber: license.licenseNumber,
        driverName: license.driverName,
        offenses: [offense],
        officerName: '',
        officerBadgeNumber: '',
      );
    }).toList();
  }

  String _resolveScanToken({
    required String scanToken,
    required LicenseModel license,
  }) {
    final licenseToken = license.scanToken.trim();
    final requestToken = scanToken.trim();

    if (_isJwtToken(licenseToken)) {
      return licenseToken;
    }

    if (_isJwtToken(requestToken)) {
      return requestToken;
    }

    if (licenseToken.isNotEmpty) {
      return licenseToken;
    }

    return requestToken;
  }

  List<String> _resolveOffenseIds({
    required List<String> offenseIds,
    required List<OffenseModel> selectedOffenses,
  }) {
    final selectedIds = selectedOffenses
        .map((offense) => offense.id.trim())
        .where((id) => id.isNotEmpty)
        .toList();

    if (selectedIds.isNotEmpty) {
      return selectedIds;
    }

    return offenseIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }

  bool _isJwtToken(String value) {
    final token = value.trim();
    if (token.isEmpty) return false;
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  DateTime? _extractExpiryFromJwt(String token) {
    final cleaned = token.trim();
    if (cleaned.isEmpty) return null;

    try {
      return JwtDecoder.getExpirationDate(cleaned);
    } catch (_) {
      return null;
    }
  }

  DateTime? _parseScanExpiry(
    Map<String, dynamic> payload,
    DateTime verifiedAt,
  ) {
    final directExpiry = _readDate(
      payload['scanExpiresAt'] ??
          payload['scan_expires_at'] ??
          payload['tokenExpiresAt'] ??
          payload['token_expires_at'] ??
          payload['expiresAt'] ??
          payload['expires_at'],
    );
    if (directExpiry != null) return directExpiry;

    final expiresIn = payload['expiresIn'] ??
        payload['expires_in'] ??
        payload['ttl'] ??
        payload['duration'];

    if (expiresIn == null) return null;

    if (expiresIn is num) {
      return verifiedAt.add(Duration(seconds: expiresIn.toInt()));
    }

    final text = expiresIn.toString().trim().toLowerCase();
    if (text.isEmpty) return null;

    final duration = _parseDurationString(text);
    if (duration != null) {
      return verifiedAt.add(duration);
    }

    final seconds = int.tryParse(text);
    if (seconds != null) {
      return verifiedAt.add(Duration(seconds: seconds));
    }

    return null;
  }

  Duration? _parseDurationString(String text) {
    if (text.endsWith('ms')) {
      final value = int.tryParse(text.substring(0, text.length - 2));
      if (value != null) return Duration(milliseconds: value);
    }

    if (text.endsWith('s')) {
      final value = int.tryParse(text.substring(0, text.length - 1));
      if (value != null) return Duration(seconds: value);
    }

    if (text.endsWith('m')) {
      final value = int.tryParse(text.substring(0, text.length - 1));
      if (value != null) return Duration(minutes: value);
    }

    if (text.endsWith('h')) {
      final value = int.tryParse(text.substring(0, text.length - 1));
      if (value != null) return Duration(hours: value);
    }

    if (text.contains(':')) {
      final parts = text.split(':').map((p) => int.tryParse(p) ?? 0).toList();
      if (parts.length == 2) {
        return Duration(
          minutes: parts[0],
          seconds: parts[1],
        );
      }
      if (parts.length == 3) {
        return Duration(
          hours: parts[0],
          minutes: parts[1],
          seconds: parts[2],
        );
      }
    }

    return null;
  }

  String _readString(
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

  int _readInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}