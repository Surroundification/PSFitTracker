import 'package:flutter_test/flutter_test.dart';
import 'package:my_workout_tracker/measurement_trends.dart';
import 'package:my_workout_tracker/models.dart';

void main() {
  test('weekly averages use sparse readings from both seven-day windows', () {
    final measurements = [
      BodyMeasurement(date: DateTime(2026, 1, 1), weight: 80),
      BodyMeasurement(date: DateTime(2026, 1, 5), weight: 70),
      BodyMeasurement(date: DateTime(2026, 1, 10), weight: 75),
      BodyMeasurement(date: DateTime(2026, 1, 14), weight: 65),
    ];

    expect(
      averageWeightForDays(
        measurements,
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 7),
      ),
      75,
    );
    expect(
      averageWeightForDays(
        measurements,
        DateTime(2026, 1, 8),
        DateTime(2026, 1, 14),
      ),
      70,
    );

    final chartPoints = calculateWeightAverages(
      measurements,
      through: DateTime(2026, 1, 14),
    );
    expect(
      chartPoints.map((point) => point.date),
      [
        DateTime(2026, 1, 1),
        DateTime(2026, 1, 5),
        DateTime(2026, 1, 10),
        DateTime(2026, 1, 14),
      ],
    );
  });

  test('trend points and averages use recorded weights without filling gaps',
      () {
    final measurements = [
      BodyMeasurement(
        date: DateTime(2026, 1, 10, 9),
        weight: 70,
      ),
      BodyMeasurement(
        date: DateTime(2026, 1, 10, 18),
        weight: 72,
      ),
      BodyMeasurement(
        date: DateTime(2026, 1, 14),
        weight: 74,
      ),
    ];

    final points = calculateWeightAverages(
      measurements,
      through: DateTime(2026, 1, 14),
    );

    expect(points, hasLength(2));
    expect(points.map((point) => point.date), [
      DateTime(2026, 1, 10),
      DateTime(2026, 1, 14),
    ]);
    expect(points.map((point) => point.average), [72, 73]);
    expect(
      averageWeightForDays(
        measurements,
        DateTime(2026, 1, 8),
        DateTime(2026, 1, 14),
      ),
      73,
    );
    expect(
      averageWeightForDays(
        measurements,
        DateTime(2026, 1, 11),
        DateTime(2026, 1, 13),
      ),
      isNull,
    );
  });
}
