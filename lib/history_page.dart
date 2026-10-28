import 'package:flutter/material.dart';

import 'app_formatters.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'models.dart';
import 'workout_components.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({
    super.key,
    required this.records,
    required this.onDelete,
    required this.onSave,
    this.scrollController,
  });

  final List<WorkoutRecord> records;
  final ValueChanged<WorkoutRecord> onDelete;
  final Future<void> Function(WorkoutRecord) onSave;
  final ScrollController? scrollController;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  int _olderRecordsToShow = 0;
  DateTime _displayedMonth =
      DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final records = [...widget.records]
      ..sort((a, b) => b.date.compareTo(a.date));
    final cutoff = recentHistoryCutoff();
    final recentRecords =
        records.where((record) => !record.date.isBefore(cutoff)).toList();
    final olderRecords =
        records.where((record) => record.date.isBefore(cutoff)).toList();
    final visibleRecords = [
      ...recentRecords,
      ...olderRecords.take(_olderRecordsToShow),
    ];
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const BrandHeader(),
        const SizedBox(height: 30),
        const Text(
          'PAST WORKOUTS',
          style: TextStyle(
            fontSize: 34,
            height: 1.02,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.3,
          ),
        ),
        const SizedBox(height: 26),
        _WorkoutCalendar(
          records: widget.records,
          month: _displayedMonth,
          onMonthChanged: (month) => setState(() => _displayedMonth = month),
        ),
        const SizedBox(height: 24),
        const SectionTitle('WORKOUT HISTORY'),
        const SizedBox(height: 12),
        if (widget.records.isEmpty)
          const EmptyCard(
            icon: Icons.history,
            title: 'Your sessions will live here',
            subtitle: 'Finish your first workout to start your history.',
            action: '',
            onPressed: noOp,
          )
        else
          ...visibleRecords.map(
            (record) => _HistoryRecordCard(
              record: record,
              onDelete: () => widget.onDelete(record),
              onSave: widget.onSave,
            ),
          ),
        if (olderRecords.length > _olderRecordsToShow)
          Center(
            child: TextButton(
              onPressed: () => setState(
                () => _olderRecordsToShow += historyPageSize,
              ),
              child: Text(
                'Show more workouts '
                '(${olderRecords.length - _olderRecordsToShow} older)',
              ),
            ),
          ),
      ],
    );
  }
}

class _WorkoutCalendar extends StatelessWidget {
  const _WorkoutCalendar({
    required this.records,
    required this.month,
    required this.onMonthChanged,
  });

  final List<WorkoutRecord> records;
  final DateTime month;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    final recordsByDate = <DateTime, List<String>>{};
    for (final record in records) {
      final date =
          DateTime(record.date.year, record.date.month, record.date.day);
      recordsByDate.putIfAbsent(date, () => []).add(record.planName);
    }

    final firstDay = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingDays = firstDay.weekday - DateTime.monday;
    final now = DateTime.now();
    final weekCount = (leadingDays + daysInMonth + 6) ~/ 7;
    final monthDays = List<DateTime?>.generate(
      weekCount * 7,
      (index) {
        final day = index - leadingDays + 1;
        if (day < 1 || day > daysInMonth) return null;
        return DateTime(month.year, month.month, day);
      },
    );

    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: 16,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionTitle('WORKOUT CALENDAR'),
              ),
              IconButton(
                key: const ValueKey('previous-calendar-month'),
                tooltip: 'Previous month',
                visualDensity: VisualDensity.compact,
                onPressed: () => onMonthChanged(
                  DateTime(month.year, month.month - 1),
                ),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                '${_monthName(month.month)} ${month.year}',
                key: const ValueKey('history-calendar-month'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                key: const ValueKey('next-calendar-month'),
                tooltip: 'Next month',
                visualDensity: VisualDensity.compact,
                onPressed: () => onMonthChanged(
                  DateTime(month.year, month.month + 1),
                ),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: const [
              'M',
              'T',
              'W',
              'T',
              'F',
              'S',
              'S',
            ]
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          color: appMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 5),
          for (var week = 0; week < weekCount; week++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var weekday = 0; weekday < 7; weekday++)
                  Expanded(
                    child: _CalendarDay(
                      date: monthDays[week * 7 + weekday],
                      workoutNames:
                          recordsByDate[monthDays[week * 7 + weekday]],
                      isToday: monthDays[week * 7 + weekday] != null &&
                          monthDays[week * 7 + weekday]!.year == now.year &&
                          monthDays[week * 7 + weekday]!.month == now.month &&
                          monthDays[week * 7 + weekday]!.day == now.day,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _monthName(int month) => const [
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
      ][month - 1];
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.workoutNames,
    required this.isToday,
  });

  final DateTime? date;
  final List<String>? workoutNames;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox(height: 52);

    final workouts = workoutNames ?? const <String>[];
    return Container(
      key: isToday ? const ValueKey('history-calendar-today') : null,
      height: 52,
      margin: const EdgeInsets.all(1),
      padding: const EdgeInsets.fromLTRB(3, 3, 2, 2),
      decoration: BoxDecoration(
        color: isToday
            ? appAccent.withValues(alpha: 0.18)
            : workouts.isEmpty
                ? Colors.transparent
                : appAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
        border: isToday ? Border.all(color: appAccent, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${date!.day}',
            style: TextStyle(
              color: isToday || workouts.isNotEmpty ? appAccent : appMuted,
              fontSize: 10,
              fontWeight: isToday ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
          if (workouts.isNotEmpty)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  for (final name in workouts.take(2))
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        height: 1.1,
                      ),
                    ),
                  if (workouts.length > 2)
                    Text(
                      '+${workouts.length - 2}',
                      style: const TextStyle(
                        color: appMuted,
                        fontSize: 7,
                        height: 1.1,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryRecordCard extends StatefulWidget {
  const _HistoryRecordCard({
    required this.record,
    required this.onDelete,
    required this.onSave,
  });

  final WorkoutRecord record;
  final VoidCallback onDelete;
  final Future<void> Function(WorkoutRecord) onSave;

  @override
  State<_HistoryRecordCard> createState() => _HistoryRecordCardState();
}

class _HistoryRecordCardState extends State<_HistoryRecordCard> {
  WorkoutRecord? _draft;

  bool get _isEditing => _draft != null;

  void _startEditing() {
    setState(() {
      _draft = WorkoutRecord.fromJson(
        Map<String, dynamic>.from(widget.record.toJson()),
      );
    });
  }

  void _cancelEditing() {
    setState(() => _draft = null);
  }

  Future<void> _saveEditing() async {
    final draft = _draft;
    if (draft == null) return;
    await widget.onSave(draft);
    if (!mounted) return;
    setState(() => _draft = null);
  }

  @override
  Widget build(BuildContext context) {
    final record = _draft ?? widget.record;
    final completedExercises = record.exercises
        .where((exercise) => exercise.sets.any((set) => set.completed))
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: appSurface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: ValueKey(
              'history-record-${widget.record.id}-expanded-$_isEditing',
            ),
            initiallyExpanded: _isEditing,
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: appAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.fitness_center, color: appAccent),
            ),
            title: Text(
              widget.record.planName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  formatDate(widget.record.date),
                  if (record.durationSeconds > 0)
                    formatWorkoutDuration(record.durationSeconds),
                  '${completedExercises.length} exercises',
                  '${record.completedSets} sets',
                ].join('  ·  '),
                style: const TextStyle(color: appMuted, fontSize: 11),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isEditing)
                  IconButton(
                    key: const ValueKey('cancel-edit-workout'),
                    tooltip: 'Cancel workout edits',
                    onPressed: _cancelEditing,
                    icon: const Icon(Icons.close, color: appMuted),
                  )
                else
                  IconButton(
                    key: const ValueKey('edit-history-workout'),
                    tooltip: 'Edit workout',
                    onPressed: _startEditing,
                    icon: const Icon(Icons.edit_outlined, color: appMuted),
                  ),
                IconButton(
                  tooltip: 'Delete workout',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, color: appMuted),
                ),
              ],
            ),
            children: [
              ...completedExercises.map(
                (exercise) => _ReadOnlyExerciseCard(
                  exercise: exercise,
                  editing: _isEditing,
                ),
              ),
              if (_isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancelEditing,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('save-history-workout'),
                          onPressed: _saveEditing,
                          child: const Text('Save changes'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyExerciseCard extends StatelessWidget {
  const _ReadOnlyExerciseCard({
    required this.exercise,
    required this.editing,
  });

  final LoggedExercise exercise;
  final bool editing;

  @override
  Widget build(BuildContext context) => AppCard(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(14),
        radius: 16,
        raised: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            if (editing)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextFormField(
                  key: ObjectKey(exercise),
                  initialValue: exercise.comment,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) => exercise.comment = value,
                  decoration: const InputDecoration(
                    labelText: 'Exercise notes',
                    hintText: 'Add notes for this exercise',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
              )
            else if (exercise.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                exercise.comment,
                style: const TextStyle(color: appMuted, height: 1.4),
              ),
            ],
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(child: Text('SET', style: tableHeading)),
                Expanded(child: Text('KG', style: tableHeading)),
                Expanded(child: Text('REPS', style: tableHeading)),
                SizedBox(
                  width: 42,
                  child: Text(
                    'DONE',
                    style: tableHeading,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ...exercise.sets
                .where((set) => set.completed)
                .toList()
                .asMap()
                .entries
                .map(
                  (entry) => SetRow(
                    key: ObjectKey(entry.value),
                    number: entry.key + 1,
                    set: entry.value,
                    onChanged: noOp,
                    readOnly: !editing,
                    completionReadOnly: editing,
                  ),
                ),
          ],
        ),
      );
}
