import 'dart:convert';

class ExercisePlan {
  ExercisePlan({
    required this.name,
    this.sets = 3,
    this.reps = 10,
    this.restSeconds = 90,
  });

  String name;
  int sets;
  int reps;
  int restSeconds;

  Map<String, Object> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'restSeconds': restSeconds,
      };

  factory ExercisePlan.fromJson(Map<String, dynamic> json) => ExercisePlan(
        name: json['name'] as String? ?? 'Exercise',
        sets: json['sets'] as int? ?? 3,
        reps: json['reps'] as int? ?? 10,
        restSeconds: json['restSeconds'] as int? ?? 90,
      );
}

class WorkoutPlan {
  WorkoutPlan({
    required this.name,
    required this.exercises,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  String name;
  List<ExercisePlan> exercises;

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
      };

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => WorkoutPlan(
        id: json['id'] as String?,
        name: json['name'] as String? ?? 'Workout',
        exercises: (json['exercises'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ExercisePlan.fromJson)
            .toList(),
      );
}

class LoggedSet {
  LoggedSet({this.reps = 10, this.weight = 0, this.completed = false});

  int reps;
  double weight;
  bool completed;

  Map<String, Object> toJson() => {
        'reps': reps,
        'weight': weight,
        'completed': completed,
      };

  factory LoggedSet.fromJson(Map<String, dynamic> json) => LoggedSet(
        reps: json['reps'] as int? ?? 0,
        weight: (json['weight'] as num?)?.toDouble() ?? 0,
        completed: json['completed'] as bool? ?? false,
      );
}

class LoggedExercise {
  LoggedExercise({
    required this.name,
    required this.restSeconds,
    required this.sets,
    this.comment = '',
  });

  String name;
  int restSeconds;
  List<LoggedSet> sets;
  String comment;

  Map<String, Object> toJson() => {
        'name': name,
        'restSeconds': restSeconds,
        'sets': sets.map((set) => set.toJson()).toList(),
        'comment': comment,
      };

  factory LoggedExercise.fromJson(Map<String, dynamic> json) => LoggedExercise(
        name: json['name'] as String? ?? 'Exercise',
        restSeconds: json['restSeconds'] as int? ?? 90,
        sets: (json['sets'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(LoggedSet.fromJson)
            .toList(),
        comment: json['comment'] as String? ?? '',
      );
}

class WorkoutRecord {
  WorkoutRecord({
    required this.planName,
    required this.date,
    required this.exercises,
    this.durationSeconds = 0,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  String planName;
  DateTime date;
  List<LoggedExercise> exercises;
  int durationSeconds;

  int get completedSets => exercises.fold(
        0,
        (total, exercise) =>
            total + exercise.sets.where((set) => set.completed).length,
      );

  Map<String, Object> toJson() => {
        'id': id,
        'planName': planName,
        'date': date.toIso8601String(),
        'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
        'durationSeconds': durationSeconds,
      };

  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
        id: json['id'] as String?,
        planName: json['planName'] as String? ?? 'Workout',
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        exercises: (json['exercises'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(LoggedExercise.fromJson)
            .toList(),
        durationSeconds: json['durationSeconds'] as int? ?? 0,
      );
}

class BodyMeasurement {
  BodyMeasurement({
    required this.date,
    this.weight,
    this.waist,
    this.bodyFat,
    String? id,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  final String id;
  DateTime date;
  double? weight;
  double? waist;
  double? bodyFat;

  Map<String, Object?> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'weight': weight,
        'waist': waist,
        'bodyFat': bodyFat,
      };

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) =>
      BodyMeasurement(
        id: json['id'] as String?,
        date:
            DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        weight: (json['weight'] as num?)?.toDouble(),
        waist: (json['waist'] as num?)?.toDouble(),
        bodyFat: (json['bodyFat'] as num?)?.toDouble(),
      );
}

List<T> decodeList<T>(
  String? source,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (source == null || source.isEmpty) return [];
  final decoded = jsonDecode(source);
  if (decoded is! List<dynamic>) {
    throw const FormatException('Expected a list of saved items.');
  }
  return decoded.whereType<Map<String, dynamic>>().map(fromJson).toList();
}
