import 'models.dart';

class WeightAveragePoint {
  const WeightAveragePoint(this.date, this.average);

  final DateTime date;
  final double average;
}

List<WeightAveragePoint> calculateWeightAverages(
  List<BodyMeasurement> measurements, {
  required DateTime through,
}) {
  final dailyWeights = _weightsByDate(measurements, through: through);
  final dates = dailyWeights.keys.toList()..sort();

  return [
    for (final date in dates)
      WeightAveragePoint(
        date,
        _averageInRange(
          dailyWeights,
          date.subtract(const Duration(days: 6)),
          date,
        )!,
      ),
  ];
}

double? averageWeightForDays(
  List<BodyMeasurement> measurements,
  DateTime firstDay,
  DateTime lastDay,
) {
  final weights = _weightsByDate(measurements);
  return _averageInRange(
    weights,
    _dateOnly(firstDay),
    _dateOnly(lastDay),
  );
}

Map<DateTime, double> _weightsByDate(
  List<BodyMeasurement> measurements, {
  DateTime? through,
}) {
  final dailyWeights = <DateTime, double>{};
  final sorted = measurements
      .where((measurement) => measurement.weight != null)
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));

  for (final measurement in sorted) {
    final date = _dateOnly(measurement.date);
    if (through != null && date.isAfter(_dateOnly(through))) continue;
    dailyWeights[date] = measurement.weight!;
  }
  return dailyWeights;
}

double? _averageInRange(
  Map<DateTime, double> weights,
  DateTime firstDay,
  DateTime lastDay,
) {
  final first = _dateOnly(firstDay);
  final last = _dateOnly(lastDay);
  final values = weights.entries
      .where((entry) => !entry.key.isBefore(first) && !entry.key.isAfter(last))
      .map((entry) => entry.value)
      .toList();
  if (values.isEmpty) return null;
  return values.reduce((a, b) => a + b) / values.length;
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);
