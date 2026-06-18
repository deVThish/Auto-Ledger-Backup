class ApiConstants {
  static const String baseUrl = 'http://47.129.144.60:3000';

  static const String headLogin = '/auth/head/login';
  static const String officerLogin = '/auth/officer/login';
  static const String login = officerLogin;

  static const String changePassword = '/auth/change-password';

  static const String districtOfficers = '/officers/my-division';
  static const String assignShift = '/officers/shift';

  static const String districtCourtCases = '/fines/court-cases';
  static const String resolveCourtCasePrefix = '/fines';

  static const String districtStatistics = '/fines/dashboard-stats';

  static const String offenses = '/fines/offenses';
  static const String scanQr = '/license/scan-qr';
  static const String verifyLicensePrefix = '/license/search';
  static const String issueFine = '/fines';
  static const String fineHistory = '/fines/my-fines';

  static const String registerOfficer = '/officers/officer';
}