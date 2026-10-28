import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class WorkoutStorage {
  WorkoutStorage(this._preferences);

  final SharedPreferences _preferences;

  static Future<WorkoutStorage> load() async =>
      WorkoutStorage(await SharedPreferences.getInstance());

  List<WorkoutPlan> loadPlans() =>
      decodeList(_preferences.getString('plans'), WorkoutPlan.fromJson);

  List<WorkoutRecord> loadRecords() =>
      decodeList(_preferences.getString('records'), WorkoutRecord.fromJson);

  List<BodyMeasurement> loadMeasurements() =>
      decodeList(
        _preferences.getString('measurements'),
        BodyMeasurement.fromJson,
      );

  Future<void> savePlans(List<WorkoutPlan> plans) => _save(
        'plans',
        jsonEncode(plans.map((plan) => plan.toJson()).toList()),
      );

  Future<void> saveRecords(List<WorkoutRecord> records) => _save(
        'records',
        jsonEncode(records.map((record) => record.toJson()).toList()),
      );

  Future<void> saveMeasurements(
    List<BodyMeasurement> measurements,
  ) =>
      _save(
        'measurements',
        jsonEncode(
          measurements.map((measurement) => measurement.toJson()).toList(),
        ),
      );

  Future<void> _save(String key, String value) async {
    if (!await _preferences.setString(key, value)) {
      throw StateError('Could not save $key on this device.');
    }
  }
}
