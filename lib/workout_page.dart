import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_formatters.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'models.dart';
import 'workout_components.dart';

class ActiveWorkoutPage extends StatefulWidget {
  const ActiveWorkoutPage({
    super.key,
    required this.plan,
    required this.previousRecords,
    required this.onFinish,
    required this.onCancel,
    this.scrollController,
  });

  final WorkoutPlan plan;
  final List<WorkoutRecord> previousRecords;
  final void Function(WorkoutRecord record, bool addExercisesToPlan) onFinish;
  final VoidCallback onCancel;
  final ScrollController? scrollController;

  @override
  State<ActiveWorkoutPage> createState() => _ActiveWorkoutPageState();
}

class _ActiveWorkoutPageState extends State<ActiveWorkoutPage> {
  late final List<LoggedExercise> _exercises;
  final List<LoggedExercise> _addedExercises = [];
  DateTime _sessionDate = DateTime.now();
  final Stopwatch _workoutStopwatch = Stopwatch();
  Timer? _workoutClock;
  int _workoutElapsedSeconds = 0;
  Timer? _timer;
  int? _activeTimerExerciseIndex;
  int? _activeTimerSetIndex;
  int _secondsLeft = 0;
  bool _saveDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _workoutStopwatch.start();
    _workoutClock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _workoutElapsedSeconds = _workoutStopwatch.elapsed.inSeconds;
        });
      }
    });
    _exercises = widget.plan.exercises.map((exercise) {
      final previous = _latestExerciseFor(exercise.name);
      return LoggedExercise(
        name: exercise.name,
        restSeconds: exercise.restSeconds,
        sets: List.generate(
          exercise.sets,
          (index) => LoggedSet(
            reps: previous != null && index < previous.sets.length
                ? previous.sets[index].reps
                : exercise.reps,
            weight: previous != null && index < previous.sets.length
                ? previous.sets[index].weight
                : 0,
          ),
        ),
      );
    }).toList();
  }

  LoggedExercise? _latestExerciseFor(String name) {
    final normalizedName = name.trim().toLowerCase();
    final records = [...widget.previousRecords]
      ..removeWhere((record) => record.date.isAfter(DateTime.now()))
      ..sort((a, b) => b.date.compareTo(a.date));
    for (final record in records) {
      final index = record.exercises.indexWhere(
        (exercise) => exercise.name.trim().toLowerCase() == normalizedName,
      );
      if (index != -1) return record.exercises[index];
    }
    return null;
  }

  @override
  void dispose() {
    _workoutStopwatch.stop();
    _workoutClock?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(int exerciseIndex, int seconds, {int? setIndex}) {
    _timer?.cancel();
    if (seconds <= 0) {
      setState(() {
        _activeTimerExerciseIndex = null;
        _activeTimerSetIndex = null;
        _secondsLeft = 0;
      });
      return;
    }
    setState(() {
      _activeTimerExerciseIndex = exerciseIndex;
      _activeTimerSetIndex = setIndex;
      _secondsLeft = seconds;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        unawaited(HapticFeedback.vibrate());
        if (mounted) {
          setState(() {
            _activeTimerExerciseIndex = null;
            _activeTimerSetIndex = null;
            _secondsLeft = 0;
          });
        }
      } else if (mounted) {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _editRestTime(int index) async {
    final seconds = await showDialog<int>(
      context: context,
      builder: (context) => RestTimerDialog(
        initialSeconds: _exercises[index].restSeconds,
      ),
    );
    if (seconds == null) return;
    setState(() => _exercises[index].restSeconds = seconds);
  }

  void _onSetCompleted(int exerciseIndex, int setIndex, bool completed) {
    setState(() {
      _exercises[exerciseIndex].sets[setIndex].completed = completed;
    });
    if (completed) {
      _startTimer(
        exerciseIndex,
        _exercises[exerciseIndex].restSeconds,
        setIndex: setIndex,
      );
    } else if (_activeTimerExerciseIndex == exerciseIndex &&
        _activeTimerSetIndex == setIndex) {
      _timer?.cancel();
      setState(() {
        _activeTimerExerciseIndex = null;
        _activeTimerSetIndex = null;
        _secondsLeft = 0;
      });
    }
  }

  void _addSet(int exerciseIndex) {
    final sets = _exercises[exerciseIndex].sets;
    final previousSet = sets.isEmpty ? null : sets.last;
    setState(() {
      sets.add(
        LoggedSet(
          reps: previousSet?.reps ?? 10,
          weight: previousSet?.weight ?? 0,
        ),
      );
    });
  }

  Future<void> _addExercise() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _AddExerciseDialog(),
    );
    if (name == null || !mounted) return;

    final normalizedName = name.toLowerCase();
    if (_exercises.any(
      (exercise) => exercise.name.trim().toLowerCase() == normalizedName,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('That exercise is already in this workout.')),
      );
      return;
    }

    final previous = _latestExerciseFor(name);
    final setCount =
        previous == null || previous.sets.isEmpty ? 3 : previous.sets.length;
    final exercise = LoggedExercise(
      name: name,
      restSeconds: previous?.restSeconds ?? 90,
      sets: List.generate(setCount, (index) {
        final previousSet = previous == null || previous.sets.isEmpty
            ? null
            : previous.sets[index < previous.sets.length
                ? index
                : previous.sets.length - 1];
        return LoggedSet(
          reps: previousSet?.reps ?? 10,
          weight: previousSet?.weight ?? 0,
        );
      }),
    );
    setState(() {
      _exercises.add(exercise);
      _addedExercises.add(exercise);
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      _exercises[exerciseIndex].sets.removeAt(setIndex);
      if (_activeTimerExerciseIndex == exerciseIndex &&
          _activeTimerSetIndex != null) {
        if (_activeTimerSetIndex == setIndex) {
          _timer?.cancel();
          _activeTimerExerciseIndex = null;
          _activeTimerSetIndex = null;
          _secondsLeft = 0;
        } else if (_activeTimerSetIndex! > setIndex) {
          _activeTimerSetIndex = _activeTimerSetIndex! - 1;
        }
      }
    });
  }

  Future<void> _selectSessionDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _sessionDate.isAfter(now) ? now : _sessionDate,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select workout date',
    );
    if (date == null) return;
    setState(() => _sessionDate = date);
  }

  Future<void> _cancelWorkout() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: appSurface,
            title: const Text('Cancel workout?'),
            content: const Text(
              'Your current workout draft, including its sets and notes, '
              'will be discarded.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep workout'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Discard workout'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed && mounted) widget.onCancel();
  }

  Future<void> _saveSession() async {
    if (_saveDialogOpen) return;
    if (_exercises.every(
      (exercise) => exercise.sets.every((set) => !set.completed),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Complete at least one set before saving.')),
      );
      return;
    }
    var addExercisesToPlan = false;
    if (_addedExercises.isNotEmpty) {
      _saveDialogOpen = true;
      final choice = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: appSurface,
          title: const Text('Save added exercises?'),
          content: const Text(
            'Choose whether the exercises added during this workout should '
            'also become part of the current plan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Only this workout'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add to current plan'),
            ),
          ],
        ),
      );
      _saveDialogOpen = false;
      if (choice == null || !mounted) return;
      addExercisesToPlan = choice;
    }
    widget.onFinish(
      WorkoutRecord(
        planName: widget.plan.name,
        date: _sessionDate,
        exercises: _exercises,
        durationSeconds: _workoutStopwatch.elapsed.inSeconds,
      ),
      addExercisesToPlan,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: appBackground,
          title: Text(widget.plan.name),
          actions: [
            TextButton(
              onPressed: _cancelWorkout,
              child: const Text('Cancel'),
            ),
            TextButton(onPressed: _saveSession, child: const Text('Finish')),
          ],
        ),
        body: ListView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          children: [
            AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: appAccent),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Workout time',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    formatClock(_workoutElapsedSeconds),
                    key: const ValueKey('workout-elapsed-time'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: appSurface,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.calendar_month, color: appAccent),
                  title: const Text('Workout date'),
                  subtitle: Text(formatDate(_sessionDate)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _selectSessionDate,
                ),
              ),
            ),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: appAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _activeTimerExerciseIndex == null
                          ? 'Ready when you are'
                          : 'Resting · ${formatDuration(_secondsLeft)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (_activeTimerExerciseIndex != null)
                    TextButton(
                      onPressed: () {
                        _timer?.cancel();
                        setState(() {
                          _activeTimerExerciseIndex = null;
                          _activeTimerSetIndex = null;
                          _secondsLeft = 0;
                        });
                      },
                      child: const Text('Stop'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._exercises.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ActiveExerciseCard(
                      exercise: entry.value,
                      timerRunning: _activeTimerExerciseIndex == entry.key,
                      secondsLeft: _activeTimerExerciseIndex == entry.key
                          ? _secondsLeft
                          : null,
                      restingSetIndex: _activeTimerExerciseIndex == entry.key
                          ? _activeTimerSetIndex
                          : null,
                      onEditRest: () => _editRestTime(entry.key),
                      onStartTimer: () => _startTimer(
                        entry.key,
                        entry.value.restSeconds,
                      ),
                      onAddSet: () => _addSet(entry.key),
                      onRemoveSet: (setIndex) =>
                          _removeSet(entry.key, setIndex),
                      onSetCompleted: (setIndex, completed) =>
                          _onSetCompleted(entry.key, setIndex, completed),
                      onCommentChanged: (comment) {
                        entry.value.comment = comment;
                      },
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              key: const ValueKey('add-active-exercise'),
              onPressed: _addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add Exercise'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saveSession,
              icon: const Icon(Icons.check),
              label: const Text('Save workout'),
              style: FilledButton.styleFrom(
                backgroundColor: appAccent,
                foregroundColor: appBackground,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      );
}

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog();

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: appSurface,
        title: const Text('Add exercise'),
        content: TextField(
          key: const ValueKey('active-exercise-name'),
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Exercise name',
            prefixIcon: Icon(Icons.fitness_center_outlined),
          ),
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _submit,
            child: const Text('Add exercise'),
          ),
        ],
      );
}

class _ActiveExerciseCard extends StatelessWidget {
  const _ActiveExerciseCard({
    required this.exercise,
    required this.timerRunning,
    required this.secondsLeft,
    required this.restingSetIndex,
    required this.onEditRest,
    required this.onStartTimer,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onSetCompleted,
    required this.onCommentChanged,
    required this.onChanged,
  });

  final LoggedExercise exercise;
  final bool timerRunning;
  final int? secondsLeft;
  final int? restingSetIndex;
  final VoidCallback onEditRest;
  final VoidCallback onStartTimer;
  final VoidCallback onAddSet;
  final ValueChanged<int> onRemoveSet;
  final void Function(int setIndex, bool completed) onSetCompleted;
  final ValueChanged<String> onCommentChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: onEditRest,
                  tooltip: 'Edit rest timer',
                  icon: const Icon(Icons.tune, color: appMuted, size: 20),
                ),
              ],
            ),
            const Row(
              children: [
                Expanded(child: Text('SET', style: tableHeading)),
                Expanded(child: Text('KG', style: tableHeading)),
                Expanded(child: Text('REPS', style: tableHeading)),
                SizedBox(
                  width: 42,
                  child: Text('DONE',
                      style: tableHeading, textAlign: TextAlign.center),
                ),
              ],
            ),
            const SizedBox(height: 5),
            TextFormField(
              key: ObjectKey(exercise),
              initialValue: exercise.comment,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onChanged: onCommentChanged,
              decoration: const InputDecoration(
                labelText: 'Exercise notes',
                hintText: 'Add information during your workout',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 8),
            ...exercise.sets.asMap().entries.map(
                  (entry) => SetRow(
                    key: ObjectKey(entry.value),
                    number: entry.key + 1,
                    set: entry.value,
                    timerActive: restingSetIndex == entry.key,
                    onRemove: () => onRemoveSet(entry.key),
                    onCompletedChanged: (completed) =>
                        onSetCompleted(entry.key, completed),
                    onChanged: onChanged,
                  ),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddSet,
                icon: const Icon(Icons.add, size: 17),
                label: const Text('Add set'),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: timerRunning ? null : onStartTimer,
                  icon: Icon(
                    timerRunning
                        ? Icons.hourglass_bottom
                        : Icons.timer_outlined,
                    size: 17,
                  ),
                  label: Text(
                    timerRunning
                        ? formatDuration(secondsLeft ?? 0)
                        : 'Rest ${formatDuration(exercise.restSeconds)}',
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onEditRest,
                  icon: const Icon(Icons.edit_outlined, size: 15),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ],
        ),
      );
}
