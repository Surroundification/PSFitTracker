import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_workout_tracker/app_widgets.dart';
import 'package:my_workout_tracker/main.dart';
import 'package:my_workout_tracker/models.dart';
import 'package:my_workout_tracker/storage.dart';
import 'package:my_workout_tracker/workout_components.dart';

void main() {
  testWidgets('workout dashboard and navigation render', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('YOUR PLANS'), findsOneWidget);
    expect(find.text('WORKOUT PLANS'), findsOneWidget);
    expect(find.text('New plan'), findsOneWidget);
    expect(find.text('Train'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Body'), findsOneWidget);
  });

  testWidgets('creates and saves a workout plan', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New plan'));
    await tester.pumpAndSettle();
    expect(find.text('New plan'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Upper body');
    await tester.enterText(find.byType(TextFormField).first, 'Bench press');
    await tester.tap(find.text('Save plan'));
    await tester.pumpAndSettle();

    expect(find.text('Upper body'), findsOneWidget);
    expect(find.text('Bench press'), findsOneWidget);
    expect(storage.loadPlans(), hasLength(1));
    expect(storage.loadPlans().single.name, 'Upper body');
  });

  testWidgets('deleting a plan requires confirmation', (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    await storage.savePlans([
      WorkoutPlan(
        name: 'Upper body',
        exercises: [ExercisePlan(name: 'Bench press')],
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete plan'));
    await tester.pumpAndSettle();
    expect(find.text('Delete plan?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(storage.loadPlans(), hasLength(1));

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete plan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(storage.loadPlans(), isEmpty);
  });

  testWidgets('bottom add exercise button focuses the new exercise name',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlanEditorPage()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('add-exercise-bottom')));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    final newNameField = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(TextFormField).last,
        matching: find.byType(EditableText),
      ),
    );
    expect(newNameField.focusNode.hasFocus, isTrue);
  });

  testWidgets('adds live sets and starts only the latest checked set timer',
      (tester) async {
    _useTestViewport(tester);
    final plan = WorkoutPlan(
      name: 'Full body',
      exercises: [
        ExercisePlan(name: 'Squat', sets: 1, restSeconds: 60),
        ExercisePlan(name: 'Press', sets: 1, restSeconds: 120),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ActiveWorkoutPage(
          plan: plan,
          previousRecords: const [],
          onFinish: (_, __) {},
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pump();
    expect(find.text('Resting · 01:00'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    expect(find.text('Resting · 02:00'), findsOneWidget);
    expect(find.byIcon(Icons.hourglass_bottom), findsNWidgets(2));

    await tester.tap(find.text('Add set').first);
    await tester.pump();
    expect(find.byType(Checkbox), findsNWidgets(3));

    await tester.tap(find.byTooltip('Remove set 2').first);
    await tester.pump();
    expect(find.byType(Checkbox), findsNWidgets(2));
  });

  testWidgets('workout timer is recorded in the saved session duration',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    WorkoutRecord? savedRecord;
    final plan = WorkoutPlan(
      name: 'Quick session',
      exercises: [ExercisePlan(name: 'Squat', sets: 1, restSeconds: 0)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ActiveWorkoutPage(
          plan: plan,
          previousRecords: const [],
          onFinish: (record, _) => savedRecord = record,
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('00:00'), findsOneWidget);

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 2)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('workout-elapsed-time')))
          .data,
      isNot('00:00'),
    );
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.tap(find.text('Save workout'));
    await tester.pump();

    expect(savedRecord, isNotNull);
    expect(savedRecord!.durationSeconds, greaterThanOrEqualTo(1));
    await storage.saveRecords([savedRecord!]);
    expect(storage.loadRecords().single.durationSeconds,
        savedRecord!.durationSeconds);

    final legacyRecord = WorkoutRecord.fromJson({
      'planName': 'Old session',
      'date': DateTime(2025).toIso8601String(),
      'exercises': [],
    });
    expect(legacyRecord.durationSeconds, 0);
  });

  testWidgets('negative set weights can be saved and shown in history',
      (tester) async {
    _useTestViewport(tester);
    WorkoutRecord? savedRecord;
    await tester.pumpWidget(
      MaterialApp(
        home: ActiveWorkoutPage(
          plan: WorkoutPlan(
            name: 'Negative load',
            exercises: [ExercisePlan(name: 'Counterweight', sets: 1)],
          ),
          previousRecords: const [],
          onFinish: (record, _) => savedRecord = record,
          onCancel: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final weightField =
        tester.widgetList<TextField>(find.byType(TextField)).elementAt(1);
    expect(
      weightField.keyboardType,
      const TextInputType.numberWithOptions(decimal: true, signed: true),
    );
    await tester.enterText(find.byType(TextField).at(1), '-5.5');
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.tap(find.text('Save workout'));
    await tester.pump();
    expect(savedRecord!.exercises.single.sets.single.weight, -5.5);
  });

  testWidgets('workout can be left and resumed without losing its draft',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    await storage.savePlans([
      WorkoutPlan(
        name: 'Upper body',
        exercises: [ExercisePlan(name: 'Bench press', sets: 2)],
      ),
    ]);
    await storage.saveRecords([
      WorkoutRecord(
        planName: 'Upper body',
        date: DateTime.now().subtract(const Duration(days: 7)),
        exercises: [
          LoggedExercise(
            name: 'bench press',
            restSeconds: 90,
            sets: [
              LoggedSet(reps: 8, weight: 50, completed: true),
              LoggedSet(reps: 7, weight: 55, completed: true),
            ],
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();

    final inputs = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller?.text)
        .toList();
    expect(inputs, containsAll(['50', '55']));
    expect(inputs, containsAll(['8', '7']));

    await tester.enterText(
      find.byType(TextFormField).first,
      'Keep this note while checking history.',
    );
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Return to workout'), findsOneWidget);
    final returnButton = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Return to workout'),
        matching: find.byType(FilledButton),
      ),
    );
    final returnButtonSize = tester.getSize(find.byWidget(returnButton));
    expect(returnButtonSize.width, 768);
    expect(find.text('Upper body'), findsNWidgets(2));

    await tester.tap(find.text('Return to workout'));
    await tester.pumpAndSettle();
    expect(
      find.text('Keep this note while checking history.'),
      findsOneWidget,
    );
    final resumedInputs = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((field) => field.controller?.text)
        .toList();
    expect(resumedInputs, containsAll(['50', '55']));
  });

  testWidgets('canceling a workout discards draft only after confirmation',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    await storage.savePlans([
      WorkoutPlan(
        name: 'Upper body',
        exercises: [ExercisePlan(name: 'Bench press', sets: 1)],
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Discard this draft note',
    );
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();
    expect(find.text('Cancel workout?'), findsOneWidget);
    await tester.tap(find.text('Keep workout'));
    await tester.pumpAndSettle();
    expect(find.text('Discard this draft note'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard workout'));
    await tester.pumpAndSettle();
    expect(find.text('YOUR PLANS'), findsOneWidget);
    expect(find.text('Return to workout'), findsNothing);
    expect(storage.loadRecords(), isEmpty);
  });

  testWidgets('history expands into read-only exercise and set details',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    await storage.saveRecords([
      WorkoutRecord(
        planName: 'Push day',
        date: DateTime.now().subtract(const Duration(days: 2)),
        durationSeconds: 3660,
        exercises: [
          LoggedExercise(
            name: 'Bench press',
            restSeconds: 90,
            comment: 'Paused reps; shoulder felt good.',
            sets: [
              LoggedSet(reps: 8, weight: 42.5, completed: true),
              LoggedSet(reps: 7, weight: -12.5, completed: true),
              LoggedSet(reps: 6, weight: 42.5),
            ],
          ),
          LoggedExercise(
            name: 'Unfinished flyes',
            restSeconds: 60,
            comment: 'This should not appear in the finished history.',
            sets: [LoggedSet(reps: 12, weight: 10)],
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();

    expect(find.text('Bench press'), findsOneWidget);
    expect(find.text('Paused reps; shoulder felt good.'), findsOneWidget);
    expect(find.text('Unfinished flyes'), findsNothing);
    expect(
      find.text('This should not appear in the finished history.'),
      findsNothing,
    );
    expect(find.textContaining('1 exercises'), findsOneWidget);
    expect(find.text('42.5'), findsOneWidget);
    expect(find.text('-12.5'), findsOneWidget);
    expect(find.textContaining('1 h 01 min'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('KG')).dx,
      lessThan(tester.getTopLeft(find.text('REPS')).dx),
    );
    final loggedSets = find.byType(SetRow);
    expect(loggedSets, findsNWidgets(2));
    expect(
      find.descendant(of: loggedSets.first, matching: find.text('8')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: loggedSets.last, matching: find.text('7')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: loggedSets, matching: find.text('6')),
      findsNothing,
    );
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(
        tester.widget<Checkbox>(find.byType(Checkbox).first).onChanged, isNull);
  });

  testWidgets('history workout notes, reps, and weights can be edited',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    final workoutDate = DateTime.now().subtract(const Duration(days: 2));
    await storage.saveRecords([
      WorkoutRecord(
        planName: 'Push day',
        date: workoutDate,
        durationSeconds: 2400,
        exercises: [
          LoggedExercise(
            name: 'Bench press',
            restSeconds: 90,
            comment: 'Original note',
            sets: [
              LoggedSet(reps: 8, weight: 42.5, completed: true),
            ],
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-history-workout')));
    await tester.pumpAndSettle();

    expect(find.text('Save changes'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(
      tester.widget<Checkbox>(find.byType(Checkbox).first).onChanged,
      isNull,
    );
    final setRow = find.byType(SetRow).first;
    await tester.enterText(
      find.descendant(of: setRow, matching: find.byType(TextField)).first,
      '50',
    );
    await tester.enterText(
      find.descendant(of: setRow, matching: find.byType(TextField)).last,
      '10',
    );
    await tester.enterText(find.byType(TextFormField), 'Updated note');

    await tester
        .ensureVisible(find.byKey(const ValueKey('save-history-workout')));
    await tester.tap(find.byKey(const ValueKey('save-history-workout')));
    await tester.pumpAndSettle();

    final saved = storage.loadRecords().single;
    expect(saved.date, workoutDate);
    expect(saved.durationSeconds, 2400);
    expect(saved.exercises.single.comment, 'Updated note');
    expect(saved.exercises.single.sets.single.weight, 50);
    expect(saved.exercises.single.sets.single.reps, 10);
    expect(saved.exercises.single.sets.single.completed, isTrue);
    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Updated note'), findsOneWidget);
  });

  testWidgets('added exercise can stay workout-only and appears in history',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    await storage.savePlans([
      WorkoutPlan(
        name: 'Upper body',
        exercises: [ExercisePlan(name: 'Bench press', sets: 1)],
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('add-active-exercise')));
    await tester.tap(find.byKey(const ValueKey('add-active-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('active-exercise-name')),
      'Cable fly',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add exercise'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(Checkbox).at(1));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    await tester.ensureVisible(find.text('Save workout'));
    await tester.tap(find.text('Save workout'));
    await tester.pumpAndSettle();
    expect(find.text('Save added exercises?'), findsOneWidget);
    await tester.tap(find.text('Only this workout'));
    await tester.pumpAndSettle();

    expect(storage.loadPlans().single.exercises, hasLength(1));
    expect(
      storage.loadRecords().single.exercises.map((exercise) => exercise.name),
      contains('Cable fly'),
    );
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Cable fly'), findsOneWidget);
  });

  testWidgets('added exercise can be saved into the current plan',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    await storage.savePlans([
      WorkoutPlan(
        name: 'Upper body',
        exercises: [ExercisePlan(name: 'Bench press', sets: 1)],
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start workout'));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const ValueKey('add-active-exercise')));
    await tester.tap(find.byKey(const ValueKey('add-active-exercise')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('active-exercise-name')),
      'Cable fly',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add exercise'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(Checkbox).first);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    expect(find.text('Save workout'), findsOneWidget);
    await tester.ensureVisible(find.text('Save workout'));
    await tester.tap(find.text('Save workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to current plan'));
    await tester.pumpAndSettle();

    expect(storage.loadRecords(), hasLength(1));
    expect(
      storage.loadPlans().single.exercises.map((exercise) => exercise.name),
      containsAll(['Bench press', 'Cable fly']),
    );
  });

  testWidgets('training stat sums the durations of workout history',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    await storage.saveRecords([
      WorkoutRecord(
        planName: 'First',
        date: DateTime.now(),
        durationSeconds: 600,
        exercises: const [],
      ),
      WorkoutRecord(
        planName: 'Second',
        date: DateTime.now().subtract(const Duration(days: 1)),
        durationSeconds: 901,
        exercises: const [],
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    final stat = tester
        .widgetList<StatCard>(find.byType(StatCard))
        .singleWhere((card) => card.label == 'MINUTES TRAINED');
    expect(stat.value, '25');
    expect(find.text('SETS DONE'), findsNothing);
  });

  testWidgets('reselecting or returning to a tab resets its scroll position',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    await storage.saveRecords(
      List.generate(
        12,
        (index) => WorkoutRecord(
          planName: 'Session $index',
          date: DateTime.now().subtract(Duration(days: index)),
          exercises: const [],
        ),
      ),
    );

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    expect(find.text('PAST WORKOUTS'), findsNothing);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('PAST WORKOUTS'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Body'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('PAST WORKOUTS'), findsOneWidget);
  });

  testWidgets('workout notes and backdated session appear in history',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    await storage.savePlans([
      WorkoutPlan(
        name: 'Leg day',
        exercises: [ExercisePlan(name: 'Squat', sets: 1, restSeconds: 0)],
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    final startWorkout = find.text('Start workout');
    await tester.tap(startWorkout);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Workout date'));
    await tester.pumpAndSettle();
    expect(find.text('Select workout date'), findsOneWidget);
    await tester.tap(find.text('Cancel').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'Used a slower tempo.',
    );
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    await tester.tap(find.text('Save workout'));
    await tester.pumpAndSettle();

    final savedRecord = storage.loadRecords().single;
    final expectedDate = DateTime.now();
    expect(savedRecord.date.year, expectedDate.year);
    expect(savedRecord.date.month, expectedDate.month);
    expect(savedRecord.date.day, expectedDate.day);
    expect(savedRecord.exercises.single.comment, 'Used a slower tempo.');
    expect(
      find.textContaining('Workout saved · 1 exercise · 10 reps ·'),
      findsOneWidget,
    );
    expect(storage.loadRecords(), hasLength(1));

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Used a slower tempo.'), findsOneWidget);
  });

  testWidgets('edits and deletes a check-in only after confirmation',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    await storage.saveMeasurements([
      BodyMeasurement(
        date: DateTime.now(),
        weight: 72,
        waist: 80,
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Body'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Edit check-in'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Date ·'));
    await tester.pumpAndSettle();
    expect(find.text('Select check-in date'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '74');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final edited = storage.loadMeasurements().single;
    expect(edited.weight, 74);
    expect(edited.waist, 80);
    final originalDate = DateTime.now();
    expect(edited.date.year, originalDate.year);
    expect(edited.date.month, originalDate.month);
    expect(edited.date.day, originalDate.day);

    final deleteCheckIn = find.byTooltip('Delete check-in');
    await tester.ensureVisible(deleteCheckIn);
    await tester.tap(deleteCheckIn);
    await tester.pumpAndSettle();
    expect(find.text('Delete check-in?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(storage.loadMeasurements(), hasLength(1));

    await tester.ensureVisible(deleteCheckIn);
    await tester.tap(deleteCheckIn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(storage.loadMeasurements(), isEmpty);
  });

  testWidgets('deleting a workout requires confirmation', (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    await storage.saveRecords([
      WorkoutRecord(
        planName: 'Pull day',
        date: DateTime.now(),
        exercises: [
          LoggedExercise(
            name: 'Row',
            restSeconds: 60,
            sets: [LoggedSet(completed: true)],
          ),
        ],
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete workout'));
    await tester.pumpAndSettle();
    expect(find.text('Delete workout?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(storage.loadRecords(), hasLength(1));

    await tester.tap(find.byTooltip('Delete workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(storage.loadRecords(), isEmpty);
  });

  testWidgets('body tab shows recent weight average and moving trend',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    final now = DateTime.now();
    await storage.saveMeasurements([
      BodyMeasurement(date: now, weight: 72),
      BodyMeasurement(
        date: now.subtract(const Duration(days: 2)),
        weight: 70,
      ),
      BodyMeasurement(
        date: now.subtract(const Duration(days: 10)),
        weight: 68,
      ),
      BodyMeasurement(
        date: now.subtract(const Duration(days: 20)),
        weight: 80,
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Body'));
    await tester.pumpAndSettle();

    expect(find.text('71 kg'), findsOneWidget);
    expect(find.text('7-DAY MOVING AVERAGE'), findsOneWidget);
    expect(find.text('PREVIOUS 7 DAYS'), findsOneWidget);
    expect(find.text('LAST 7 DAYS'), findsOneWidget);
    expect(find.text('68 kg'), findsNWidgets(2));
    expect(
      find.text('3 kg up compared with the previous week'),
      findsOneWidget,
    );
  });

  testWidgets('workout history reveals records older than 14 days on demand',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    final now = DateTime.now();
    await storage.saveRecords([
      WorkoutRecord(
        planName: 'Recent session',
        date: now.subtract(const Duration(days: 2)),
        exercises: [],
      ),
      WorkoutRecord(
        planName: 'Older session',
        date: now.subtract(const Duration(days: 20)),
        exercises: [],
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Recent session'), findsNWidgets(2));
    final olderSessionTitle = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'Older session' &&
          widget.style?.fontSize == 15,
    );
    expect(olderSessionTitle, findsNothing);
    expect(find.text('Show more workouts (1 older)'), findsOneWidget);
    await tester.tap(find.text('Show more workouts (1 older)'));
    await tester.pumpAndSettle();
    expect(olderSessionTitle, findsOneWidget);
    expect(storage.loadRecords(), hasLength(2));
  });

  testWidgets('history calendar shows plan names and navigates months',
      (tester) async {
    _useTestViewport(tester);
    final today = DateTime.now();
    const longPlanName =
        'A workout plan name that is much too long for a small calendar day';
    await tester.pumpWidget(
      MaterialApp(
        home: HistoryPage(
          records: [
            WorkoutRecord(
              planName: longPlanName,
              date: DateTime(today.year, today.month, 8),
              exercises: [],
            ),
          ],
          onDelete: (_) {},
          onSave: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final monthLabel = find.byKey(const ValueKey('history-calendar-month'));
    expect(
      tester.widget<Text>(monthLabel).data,
      '${monthNames[today.month - 1]} ${today.year}',
    );
    expect(
        find.byKey(const ValueKey('history-calendar-today')), findsOneWidget);
    final calendarPlan = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == longPlanName &&
          widget.maxLines == 1 &&
          widget.style?.fontSize == 8,
    );
    expect(calendarPlan, findsOneWidget);
    expect(
      tester.widget<Text>(calendarPlan).overflow,
      TextOverflow.ellipsis,
    );

    await tester.tap(find.byTooltip('Previous month'));
    await tester.pumpAndSettle();
    final previousMonth = DateTime(today.year, today.month - 1);
    expect(
      tester.widget<Text>(monthLabel).data,
      '${monthNames[previousMonth.month - 1]} ${previousMonth.year}',
    );
    expect(find.byKey(const ValueKey('history-calendar-today')), findsNothing);

    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(monthLabel).data,
      '${monthNames[today.month - 1]} ${today.year}',
    );
    expect(
        find.byKey(const ValueKey('history-calendar-today')), findsOneWidget);
  });

  testWidgets('older check-ins stay hidden until requested but affect averages',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());
    final now = DateTime.now();
    await storage.saveMeasurements([
      BodyMeasurement(date: now, weight: 70),
      BodyMeasurement(
        date: now.subtract(const Duration(days: 20)),
        weight: 80,
      ),
    ]);

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Body'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edit check-in'), findsOneWidget);
    expect(find.text('70 kg'), findsNWidgets(2));
    final showMore = find.text('Show more check-ins (1 older)');
    await tester.ensureVisible(showMore);
    await tester.tap(showMore);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Edit check-in'), findsNWidgets(2));
    expect(storage.loadMeasurements(), hasLength(2));
  });

  testWidgets('saving a second same-day check-in keeps one daily weight',
      (tester) async {
    _useTestViewport(tester);
    SharedPreferences.setMockInitialValues({});
    final storage = WorkoutStorage(await SharedPreferences.getInstance());

    await tester.pumpWidget(WorkoutApp(storage: storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Body'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add measurements'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '70');
    await tester.tap(find.text('Save check-in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add measurements'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '72');
    await tester.enterText(find.byType(TextField).at(1), '80');
    await tester.tap(find.text('Save check-in'));
    await tester.pumpAndSettle();

    final saved = storage.loadMeasurements();
    expect(saved, hasLength(1));
    expect(saved.single.weight, 72);
    expect(saved.single.waist, 80);
  });
}

void _useTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
