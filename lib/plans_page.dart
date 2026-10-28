import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'app_widgets.dart';
import 'models.dart';

class PlansPage extends StatelessWidget {
  const PlansPage({
    super.key,
    required this.plans,
    required this.records,
    this.scrollController,
    required this.onAdd,
    required this.onEdit,
    required this.onStart,
    required this.onDelete,
  });

  final List<WorkoutPlan> plans;
  final List<WorkoutRecord> records;
  final ScrollController? scrollController;
  final VoidCallback onAdd;
  final ValueChanged<WorkoutPlan> onEdit;
  final ValueChanged<WorkoutPlan> onStart;
  final ValueChanged<WorkoutPlan> onDelete;

  @override
  Widget build(BuildContext context) {
    final totalTrainingSeconds = records.fold<int>(
      0,
      (total, record) => total + record.durationSeconds,
    );
    final totalTrainingMinutes = totalTrainingSeconds ~/ 60;
    return CustomScrollView(
      controller: scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const BrandHeader(),
              const SizedBox(height: 30),
              const Text(
                'WORKOUT PLANS',
                style: TextStyle(
                  fontSize: 34,
                  height: 1.02,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.3,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Progress at all cost.',
                style: TextStyle(color: appMuted, fontSize: 15),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      icon: Icons.event_available_outlined,
                      value: '${records.length}',
                      label: 'SESSIONS',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      icon: Icons.timer_outlined,
                      value: '$totalTrainingMinutes',
                      label: 'MINUTES TRAINED',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SectionTitle('YOUR PLANS'),
                  TextButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 19),
                    label: const Text('New plan'),
                    style: TextButton.styleFrom(foregroundColor: appAccent),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (plans.isEmpty)
                EmptyCard(
                  icon: Icons.add_circle_outline,
                  title: 'Start with a workout plan',
                  subtitle:
                      'Add your exercises, sets, reps and rest timer to get going.',
                  action: 'Create your first plan',
                  onPressed: onAdd,
                )
              else
                ...plans.map(
                  (plan) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PlanCard(
                      plan: plan,
                      onStart: () => onStart(plan),
                      onEdit: () => onEdit(plan),
                      onDelete: () => onDelete(plan),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
  });

  final WorkoutPlan plan;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: appSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.045)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    plan.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: appMuted),
                  color: appSurfaceRaised,
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit plan')),
                    PopupMenuItem(value: 'delete', child: Text('Delete plan')),
                  ],
                ),
              ],
            ),
            Text(
              '${plan.exercises.length} exercises  ·  '
              '${plan.exercises.fold<int>(0, (sum, item) => sum + item.sets)} sets',
              style: const TextStyle(color: appMuted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            if (plan.exercises.isEmpty)
              const Text('No exercises yet',
                  style: TextStyle(color: appMuted, fontSize: 13))
            else
              Text(
                plan.exercises.take(3).map((item) => item.name).join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            if (plan.exercises.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+ ${plan.exercises.length - 3} more',
                  style: const TextStyle(color: appMuted, fontSize: 11),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: plan.exercises.isEmpty ? null : onStart,
                icon: const Icon(Icons.play_arrow_rounded, size: 21),
                label: const Text('Start workout'),
                style: FilledButton.styleFrom(
                  backgroundColor: appAccent,
                  foregroundColor: appBackground,
                  disabledBackgroundColor: appSurfaceRaised,
                  disabledForegroundColor: appMuted,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ],
        ),
      );
}

class PlanEditorPage extends StatefulWidget {
  const PlanEditorPage({super.key, this.plan});

  final WorkoutPlan? plan;

  @override
  State<PlanEditorPage> createState() => _PlanEditorPageState();
}

class _PlanEditorPageState extends State<PlanEditorPage> {
  late final TextEditingController _nameController;
  late final List<ExercisePlan> _exercises;
  final _scrollController = ScrollController();
  final Map<ExercisePlan, FocusNode> _exerciseFocusNodes = {};
  final Map<ExercisePlan, GlobalKey> _exerciseFieldKeys = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.plan?.name ?? '');
    _exercises = widget.plan == null
        ? [ExercisePlan(name: '')]
        : widget.plan!.exercises
            .map((exercise) => ExercisePlan(
                  name: exercise.name,
                  sets: exercise.sets,
                  reps: exercise.reps,
                  restSeconds: exercise.restSeconds,
                ))
            .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    for (final focusNode in _exerciseFocusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _addExercise() {
    final exercise = ExercisePlan(name: '');
    final focusNode = FocusNode();
    final fieldKey = GlobalKey();
    _exerciseFocusNodes[exercise] = focusNode;
    _exerciseFieldKeys[exercise] = fieldKey;
    setState(() => _exercises.add(exercise));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) return;
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      if (!mounted) return;
      final fieldContext = fieldKey.currentContext;
      if (fieldContext == null) return;
      await Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 200),
        alignment: 1,
      );
      if (mounted) focusNode.requestFocus();
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final exercises = _exercises
        .where((exercise) => exercise.name.trim().isNotEmpty)
        .toList();
    if (name.isEmpty || exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add a plan name and at least one exercise.')),
      );
      return;
    }
    Navigator.pop(
      context,
      WorkoutPlan(
        id: widget.plan?.id,
        name: name,
        exercises: exercises,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: appBackground,
          title: Text(widget.plan == null ? 'New plan' : 'Edit plan'),
          actions: [
            TextButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
        body: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            const SectionTitle('PLAN NAME'),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g. Pull day'),
            ),
            const SizedBox(height: 26),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionTitle('EXERCISES'),
                TextButton.icon(
                  onPressed: _addExercise,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add exercise'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._exercises.asMap().entries.map(
                  (entry) => _ExerciseEditorCard(
                    key: ObjectKey(entry.value),
                    index: entry.key,
                    exercise: entry.value,
                    focusNode: _exerciseFocusNodes[entry.value],
                    fieldKey: _exerciseFieldKeys[entry.value],
                    onChanged: () => setState(() {}),
                    onRemove: () =>
                        setState(() => _exercises.remove(entry.value)),
                  ),
                ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('add-exercise-bottom'),
                onPressed: _addExercise,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add exercise'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: appAccent,
                foregroundColor: appBackground,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text('Save plan'),
            ),
          ],
        ),
      );
}

class _ExerciseEditorCard extends StatelessWidget {
  const _ExerciseEditorCard({
    super.key,
    required this.index,
    required this.exercise,
    this.focusNode,
    this.fieldKey,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final ExercisePlan exercise;
  final FocusNode? focusNode;
  final GlobalKey? fieldKey;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => AppCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'EXERCISE ${index + 1}',
                    style: const TextStyle(
                      color: appMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, color: appMuted),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            TextFormField(
              key: fieldKey,
              initialValue: exercise.name,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.words,
              onChanged: (value) => exercise.name = value,
              decoration: const InputDecoration(
                hintText: 'Exercise name',
                prefixIcon: Icon(Icons.fitness_center_outlined),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _NumberStepper(
                    label: 'SETS',
                    value: exercise.sets,
                    minimum: 1,
                    maximum: 20,
                    onChanged: (value) {
                      exercise.sets = value;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberStepper(
                    label: 'REPS',
                    value: exercise.reps,
                    minimum: 1,
                    maximum: 100,
                    onChanged: (value) {
                      exercise.reps = value;
                      onChanged();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NumberStepper(
                    label: 'REST · SEC',
                    value: exercise.restSeconds,
                    minimum: 0,
                    maximum: 3600,
                    step: 15,
                    onChanged: (value) {
                      exercise.restSeconds = value;
                      onChanged();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _NumberStepper extends StatelessWidget {
  const _NumberStepper({
    required this.label,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final int minimum;
  final int maximum;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: appMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: appSurfaceRaised,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _StepButton(
                  icon: Icons.remove,
                  onPressed: value - step < minimum
                      ? null
                      : () => onChanged(value - step),
                ),
                Expanded(
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
                _StepButton(
                  icon: Icons.add,
                  onPressed: value + step > maximum
                      ? null
                      : () => onChanged(value + step),
                ),
              ],
            ),
          ),
        ],
      );
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 30,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          iconSize: 15,
          color: appAccent,
          disabledColor: appMuted.withValues(alpha: 0.35),
          icon: Icon(icon),
        ),
      );
}
