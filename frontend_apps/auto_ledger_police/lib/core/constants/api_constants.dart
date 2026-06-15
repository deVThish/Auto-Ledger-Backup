class ApiConstants {
  static const String baseUrl = 'http://47.129.144.60:3000';

  static const String login = '/auth/head/login';

  static const String districtOfficers = '/officers/my-division';
  static const String assignShift = '/officers/shift';

  static const String districtCourtCases = '/fines/court-cases';
  static const String resolveCourtCasePrefix = '/fines';

  static const String districtStatistics = '/fines/dashboard-stats';

  static const String offenses = '/fines/offenses';
  static const String verifyLicensePrefix = '/fines/verify-license';
  static const String issueFine = '/fines/issue';
  static const String fineHistory = '/fines/history';

  static const String registerOfficer = '/officers/officer';
}