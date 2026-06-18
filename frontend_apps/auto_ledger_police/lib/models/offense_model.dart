class OffenseModel {
  const OffenseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.amount,
    required this.points,
    required this.isCourtCase,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final double amount;
  final int points;
  final bool isCourtCase;

  factory OffenseModel.fromJson(Map<String, dynamic> json) {
    final name = _readString(
      json,
      const ['name', 'title', 'offenseName', 'offenseTitle'],
    );
    final description = _readString(
      json,
      const ['description', 'details'],
      fallback: name,
    );

    return OffenseModel(
      id: _readString(
        json,
        const ['id', 'offenseId', 'offense_id'],
      ),
      code: _readString(
        json,
        const ['code', 'offenseCode', 'offense_code'],
      ),
      name: name,
      description: description,
      amount: _readDouble(
        json['amount'] ?? json['fee'] ?? json['price'],
      ),
      points: _readInt(
        json['points'] ?? json['demeritPoints'] ?? json['deductPoints'],
      ),
      isCourtCase: json['isCourtCase'] == true ||
          json['courtCase'] == true ||
          json['is_court_case'] == true,
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

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(dynamic value) {
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}