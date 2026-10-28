import 'package:flutter/material.dart';

import 'app_formatters.dart';
import 'app_theme.dart';
import 'history_page.dart';
import 'measurements_page.dart';
import 'models.dart';
import 'plans_page.dart';
import 'storage.dart';
import 'workout_page.dart';

export 'history_page.dart';
export 'measurements_page.dart';
export 'plans_page.dart';
export 'workout_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await WorkoutStorage.load();
  runApp(WorkoutApp(storage: storage));
}

class WorkoutApp extends StatefulWidget {
  const WorkoutApp({super.key, required this.storage});

  final WorkoutStorage storage;

  @override
  State<WorkoutApp> createState() => _WorkoutAppState();
}

class _WorkoutAppState extends State<WorkoutApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late List<WorkoutPlan> _plans = widget.storage.loadPlans();
  late List<WorkoutRecord> _records = widget.storage.loadRecords();
  late List<BodyMeasurement> _measurements = widget.storage.loadMeasurements();
  final List<ScrollController> _tabScrollControllers =
      List.generate(4, (_) => ScrollController());
  WorkoutPlan? _activeWorkoutPlan;
  int _tab = 0;

  BuildContext get _navigatorContext =>
      _navigatorKey.currentContext ??
      (throw StateError('The app navigator is not available.'));

  Future<void> _savePlans() => widget.storage.savePlans(_plans);
  Future<void> _saveRecords() => widget.storage.saveRecords(_records);
  Future<void> _saveMeasurements() =>
      widget.storage.saveMeasurements(_measurements);

  Future<bool> _persist(Future<void> Function() save, String label) async {
    try {
      await save();
      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(_navigatorContext).showSnackBar(
          SnackBar(content: Text('$label could not be saved: $error')),
        );
      }
      return false;
    }
  }

  Future<void> _editPlan([WorkoutPlan? plan]) async {
    final result = await _navigatorKey.currentState!.push<WorkoutPlan>(
      MaterialPageRoute(builder: (_) => PlanEditorPage(plan: plan)),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _plans.indexWhere((item) => item.id == result.id);
      if (index == -1) {
        _plans = [..._plans, result];
      } else {
        _plans[index] = result;
      }
    });
    await _persist(_savePlans, 'Plan');
  }

  @override
  void dispose() {
    for (final controller in _tabScrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _selectTab(int tab) {
    final controller = _tabScrollControllers[tab];
    if (controller.hasClients) controller.jumpTo(0);
    setState(() {
      _tab = tab;
    });
  }

  void _startWorkout(WorkoutPlan plan) {
    _activeWorkoutPlan = plan;
    _selectTab(3);
  }

  void _cancelWorkout() {
    if (_tabScrollControllers[0].hasClients) {
      _tabScrollControllers[0].jumpTo(0);
    }
    setState(() {
      _activeWorkoutPlan = null;
      _tab = 0;
    });
  }

  Future<void> _finishWorkout(
    WorkoutRecord record,
    bool addExercisesToPlan,
  ) async {
    if (!mounted) return;
    final activePlan = _activeWorkoutPlan;
    WorkoutPlan? updatedPlan;
    if (addExercisesToPlan && activePlan != null) {
      final plannedNames = activePlan.exercises
          .map((exercise) => exercise.name.trim().toLowerCase())
          .toSet();
      final addedExercises = record.exercises.where(
        (exercise) =>
            !plannedNames.contains(exercise.name.trim().toLowerCase()),
      );
      final newPlanExercises = addedExercises
          .map(
            (exercise) => ExercisePlan(
              name: exercise.name,
              sets: exercise.sets.isEmpty ? 3 : exercise.sets.length,
              reps: exercise.sets.isEmpty ? 10 : exercise.sets.first.reps,
              restSeconds: exercise.restSeconds,
            ),
          )
          .toList();
      if (newPlanExercises.isNotEmpty) {
        updatedPlan = WorkoutPlan(
          id: activePlan.id,
          name: activePlan.name,
          exercises: [...activePlan.exercises, ...newPlanExercises],
        );
      }
    }
    if (_tabScrollControllers[0].hasClients) {
      _tabScrollControllers[0].jumpTo(0);
    }
    setState(() {
      _records = [record, ..._records]
        ..sort((a, b) => b.date.compareTo(a.date));
      if (updatedPlan case final planToSave?) {
        _plans = _plans
            .map((plan) => plan.id == planToSave.id ? planToSave : plan)
            .toList();
      }
      _activeWorkoutPlan = null;
      _tab = 0;
    });
    if (updatedPlan != null) await _persist(_savePlans, 'Plan');
    if (!await _persist(_saveRecords, 'Workout') || !mounted) return;
    final completedExercises = record.exercises
        .where((exercise) => exercise.sets.any((set) => set.completed))
        .length;
    final completedReps = record.exercises
        .expand((exercise) => exercise.sets)
        .where((set) => set.completed)
        .fold<int>(0, (total, set) => total + set.reps);
    final exerciseLabel = completedExercises == 1 ? 'exercise' : 'exercises';
    final repLabel = completedReps == 1 ? 'rep' : 'reps';
    ScaffoldMessenger.of(_navigatorContext).showSnackBar(
      SnackBar(
        content: Text(
          'Workout saved · $completedExercises $exerciseLabel · '
          '$completedReps $repLabel · '
          '${formatWorkoutDuration(record.durationSeconds)}',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _editMeasurement([BodyMeasurement? measurement]) async {
    final result = await showModalBottomSheet<BodyMeasurement>(
      context: _navigatorContext,
      isScrollControlled: true,
      backgroundColor: appSurface,
      builder: (_) => MeasurementForm(measurement: measurement),
    );
    if (result == null || !mounted) return;
    final sameDateMeasurements = _measurements
        .where(
          (item) =>
              item.id != result.id &&
              item.date.year == result.date.year &&
              item.date.month == result.date.month &&
              item.date.day == result.date.day,
        )
        .toList();

    T? existingValue<T>(T? Function(BodyMeasurement) select) {
      for (final item in sameDateMeasurements) {
        final value = select(item);
        if (value != null) return value;
      }
      return null;
    }

    final merged = BodyMeasurement(
      id: sameDateMeasurements.isEmpty
          ? result.id
          : sameDateMeasurements.first.id,
      date: result.date,
      weight: result.weight ?? existingValue((item) => item.weight),
      waist: result.waist ?? existingValue((item) => item.waist),
      bodyFat: result.bodyFat ?? existingValue((item) => item.bodyFat),
    );
    setState(() {
      _measurements = _measurements
          .where(
            (item) =>
                item.id != result.id &&
                !(item.date.year == result.date.year &&
                    item.date.month == result.date.month &&
                    item.date.day == result.date.day),
          )
          .toList()
        ..add(merged);
      _measurements.sort((a, b) => b.date.compareTo(a.date));
    });
    await _persist(_saveMeasurements, 'Check-in');
  }

  Future<bool> _confirmDelete(String title, String message) async =>
      await showDialog<bool>(
        context: _navigatorContext,
        builder: (context) => AlertDialog(
          backgroundColor: appSurface,
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _deleteRecord(WorkoutRecord record) async {
    if (!await _confirmDelete(
      'Delete workout?',
      '“${record.planName}” and its recorded sets will be permanently deleted.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _records.removeWhere((item) => item.id == record.id));
    await _persist(_saveRecords, 'Workout');
  }

  Future<void> _updateRecord(WorkoutRecord updatedRecord) async {
    if (!mounted) return;
    setState(() {
      final index =
          _records.indexWhere((record) => record.id == updatedRecord.id);
      if (index != -1) _records[index] = updatedRecord;
    });
    await _persist(_saveRecords, 'Workout');
  }

  Future<void> _deleteMeasurement(BodyMeasurement measurement) async {
    if (!await _confirmDelete(
      'Delete check-in?',
      'This body measurement check-in will be permanently deleted.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(
      () => _measurements.removeWhere((item) => item.id == measurement.id),
    );
    await _persist(_saveMeasurements, 'Check-in');
  }

  Future<void> _deletePlan(WorkoutPlan plan) async {
    if (!await _confirmDelete(
      'Delete plan?',
      '“${plan.name}” will be permanently deleted. Recorded workouts and '
          'measurements will not be affected.',
    )) {
      return;
    }
    if (!mounted) return;
    setState(() => _plans.removeWhere((item) => item.id == plan.id));
    await _persist(_savePlans, 'Plan');
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      PlansPage(
        plans: _plans,
        records: _records,
        scrollController: _tabScrollControllers[0],
        onAdd: () => _editPlan(),
        onEdit: _editPlan,
        onStart: _startWorkout,
        onDelete: _deletePlan,
      ),
      HistoryPage(
        records: _records,
        scrollController: _tabScrollControllers[1],
        onDelete: _deleteRecord,
        onSave: _updateRecord,
      ),
      BodyPage(
        measurements: _measurements,
        scrollController: _tabScrollControllers[2],
        onAdd: () => _editMeasurement(),
        onEdit: _editMeasurement,
        onDelete: _deleteMeasurement,
      ),
    ];
    if (_activeWorkoutPlan case final plan?) {
      pages.add(
        ActiveWorkoutPage(
          key: ValueKey('active-workout-${plan.id}'),
          plan: plan,
          previousRecords: _records,
          scrollController: _tabScrollControllers[3],
          onFinish: _finishWorkout,
          onCancel: _cancelWorkout,
        ),
      );
    }
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'PSFitTracker',
      theme: appTheme,
      home: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _tab,
            children: pages,
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_activeWorkoutPlan != null && _tab != 3)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _selectTab(3),
                    icon: const Icon(Icons.fitness_center),
                    label: const Text('Return to workout'),
                    style: FilledButton.styleFrom(
                      backgroundColor: appAccent,
                      foregroundColor: appBackground,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ),
            NavigationBar(
              backgroundColor: appSurface,
              indicatorColor: appAccent.withValues(alpha: 0.8),
              selectedIndex: _tab == 3 ? 0 : _tab,
              onDestinationSelected: _selectTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.fitness_center_outlined),
                  selectedIcon: Icon(Icons.fitness_center),
                  label: 'Train',
                ),
                NavigationDestination(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.monitor_weight_outlined),
                  selectedIcon: Icon(Icons.monitor_weight),
                  label: 'Body',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
