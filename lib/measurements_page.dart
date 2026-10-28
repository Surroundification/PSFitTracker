import 'package:flutter/material.dart';

import 'app_formatters.dart';
import 'app_theme.dart';
import 'app_widgets.dart';
import 'measurement_trends.dart';
import 'models.dart';

class BodyPage extends StatefulWidget {
  const BodyPage({
    super.key,
    required this.measurements,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    this.scrollController,
  });

  final List<BodyMeasurement> measurements;
  final VoidCallback onAdd;
  final ValueChanged<BodyMeasurement> onEdit;
  final ValueChanged<BodyMeasurement> onDelete;
  final ScrollController? scrollController;

  @override
  State<BodyPage> createState() => _BodyPageState();
}

class _BodyPageState extends State<BodyPage> {
  int _olderMeasurementsToShow = 0;

  @override
  Widget build(BuildContext context) {
    final sortedMeasurements = [...widget.measurements]
      ..sort((a, b) => b.date.compareTo(a.date));
    final latest = sortedMeasurements.isEmpty ? null : sortedMeasurements.first;
    final weightMeasurements = sortedMeasurements
        .where((measurement) => measurement.weight != null)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final averages = calculateWeightAverages(
      weightMeasurements,
      through: todayStart,
    );
    final currentAverage = averageWeightForDays(
      weightMeasurements,
      todayStart.subtract(const Duration(days: 6)),
      todayStart,
    );
    final previousAverage = averageWeightForDays(
      weightMeasurements,
      todayStart.subtract(const Duration(days: 13)),
      todayStart.subtract(const Duration(days: 7)),
    );
    final cutoff = recentHistoryCutoff();
    final recentMeasurements = sortedMeasurements
        .where((measurement) => !measurement.date.isBefore(cutoff))
        .toList();
    final olderMeasurements = sortedMeasurements
        .where((measurement) => measurement.date.isBefore(cutoff))
        .toList();
    final visibleMeasurements = [
      ...recentMeasurements,
      ...olderMeasurements.take(_olderMeasurementsToShow),
    ];
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      children: [
        const BrandHeader(),
        const SizedBox(height: 30),
        const Text(
          'MEASUREMENTS',
          style: TextStyle(
            fontSize: 34,
            height: 1.02,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.3,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Track the changes that matter to you.',
          style: TextStyle(color: appMuted, fontSize: 15),
        ),
        const SizedBox(height: 22),
        if (latest != null)
          AppCard(
            padding: const EdgeInsets.all(17),
            radius: 20,
            child: Row(
              children: [
                const Icon(Icons.insights_outlined, color: appAccent, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Latest check-in  ·  ${formatDate(latest.date)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        _WeightAverageCard(
          currentAverage: currentAverage,
          previousAverage: previousAverage,
          movingAverages: averages,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add measurements'),
            style: FilledButton.styleFrom(
              backgroundColor: appAccent,
              foregroundColor: appBackground,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 26),
        const SectionTitle('CHECK-INS'),
        const SizedBox(height: 12),
        if (widget.measurements.isEmpty)
          const EmptyCard(
            icon: Icons.monitor_weight_outlined,
            title: 'No measurements yet',
            subtitle:
                'Log body weight, waist or body fat whenever you want. All fields are optional.',
            action: '',
            onPressed: noOp,
          )
        else
          ...visibleMeasurements.map(
            (measurement) => AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatDate(measurement.date),
                          style: const TextStyle(
                            color: appMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit check-in',
                        onPressed: () => widget.onEdit(measurement),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                      IconButton(
                        tooltip: 'Delete check-in',
                        onPressed: () => widget.onDelete(measurement),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: appMuted,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (measurement.weight != null)
                        _MeasurementChip(
                            label: 'WEIGHT',
                            value: '${formatWeight(measurement.weight!)} kg'),
                      if (measurement.waist != null)
                        _MeasurementChip(
                            label: 'WAIST',
                            value: '${formatWeight(measurement.waist!)} cm'),
                      if (measurement.bodyFat != null)
                        _MeasurementChip(
                            label: 'BODY FAT',
                            value: '${formatWeight(measurement.bodyFat!)}%'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (olderMeasurements.length > _olderMeasurementsToShow)
          Center(
            child: TextButton(
              onPressed: () => setState(
                () => _olderMeasurementsToShow += historyPageSize,
              ),
              child: Text(
                'Show more check-ins '
                '(${olderMeasurements.length - _olderMeasurementsToShow} older)',
              ),
            ),
          ),
      ],
    );
  }
}

class _WeightAverageCard extends StatelessWidget {
  const _WeightAverageCard({
    required this.currentAverage,
    required this.previousAverage,
    required this.movingAverages,
  });

  final double? currentAverage;
  final double? previousAverage;
  final List<WeightAveragePoint> movingAverages;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(17),
        radius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle('7-DAY WEIGHT AVERAGE'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _WeightAverageValue(
                    label: 'PREVIOUS 7 DAYS',
                    average: previousAverage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _WeightAverageValue(
                    label: 'LAST 7 DAYS',
                    average: currentAverage,
                  ),
                ),
              ],
            ),
            if (previousAverage != null && currentAverage != null) ...[
              const SizedBox(height: 12),
              Text(
                '${formatWeight(currentAverage! - previousAverage!)} kg '
                '${currentAverage == previousAverage ? 'no change' : currentAverage! > previousAverage! ? 'up' : 'down'} '
                'compared with the previous week',
                style: const TextStyle(color: appMuted, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            const SectionTitle('7-DAY MOVING AVERAGE'),
            const SizedBox(height: 10),
            if (movingAverages.isEmpty)
              const SizedBox(
                height: 150,
                child: Center(
                  child: Text(
                    'Add weight check-ins to see your trend.',
                    style: TextStyle(color: appMuted),
                  ),
                ),
              )
            else ...[
              SizedBox(
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                  painter: _WeightAveragePainter(movingAverages),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatDate(movingAverages.first.date),
                    style: const TextStyle(color: appMuted, fontSize: 10),
                  ),
                  Text(
                    formatDate(movingAverages.last.date),
                    style: const TextStyle(color: appMuted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
}

class _WeightAverageValue extends StatelessWidget {
  const _WeightAverageValue({required this.label, required this.average});

  final String label;
  final double? average;

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
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            average == null ? '—' : '${formatWeight(average!)} kg',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      );
}

class _WeightAveragePainter extends CustomPainter {
  _WeightAveragePainter(this.points);

  final List<WeightAveragePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const chartPadding = EdgeInsets.fromLTRB(34, 8, 8, 10);
    final chart = chartPadding.deflateRect(Offset.zero & size);
    final values = points.map((point) => point.average).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final spread = maxValue - minValue;
    final rangePadding = spread == 0 ? 1.0 : spread * 0.15;
    final lower = minValue - rangePadding;
    final upper = maxValue + rangePadding;
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    const labelStyle = TextStyle(color: appMuted, fontSize: 9);
    final daySpan = points.last.date.difference(points.first.date).inDays;

    for (var line = 0; line < 3; line++) {
      final ratio = line / 2;
      final y = chart.top + chart.height * ratio;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final value = upper - (upper - lower) * ratio;
      final label = TextPainter(
        text: TextSpan(text: formatWeight(value), style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: chartPadding.left - 4);
      label.paint(canvas, Offset(0, y - label.height / 2));
    }

    final linePaint = Paint()
      ..color = appAccent
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final x = daySpan == 0
          ? chart.center.dx
          : chart.left +
              chart.width *
                  points[index].date.difference(points.first.date).inDays /
                  daySpan;
      final y = chart.bottom -
          (points[index].average - lower) / (upper - lower) * chart.height;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    final pointPaint = Paint()..color = appAccent;
    for (var index = 0; index < points.length; index++) {
      final x = daySpan == 0
          ? chart.center.dx
          : chart.left +
              chart.width *
                  points[index].date.difference(points.first.date).inDays /
                  daySpan;
      final y = chart.bottom -
          (points[index].average - lower) / (upper - lower) * chart.height;
      canvas.drawCircle(Offset(x, y), 3.5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightAveragePainter oldDelegate) =>
      oldDelegate.points != points;
}

class _MeasurementChip extends StatelessWidget {
  const _MeasurementChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        radius: 12,
        raised: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: appMuted, fontSize: 9, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class MeasurementForm extends StatefulWidget {
  const MeasurementForm({super.key, this.measurement});

  final BodyMeasurement? measurement;

  @override
  State<MeasurementForm> createState() => _MeasurementFormState();
}

class _MeasurementFormState extends State<MeasurementForm> {
  late final TextEditingController _weight;
  late final TextEditingController _waist;
  late final TextEditingController _bodyFat;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final measurement = widget.measurement;
    _weight = TextEditingController(
      text:
          measurement?.weight == null ? '' : formatWeight(measurement!.weight!),
    );
    _waist = TextEditingController(
      text: measurement?.waist == null ? '' : formatWeight(measurement!.waist!),
    );
    _bodyFat = TextEditingController(
      text: measurement?.bodyFat == null
          ? ''
          : formatWeight(measurement!.bodyFat!),
    );
    _date = measurement?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _weight.dispose();
    _waist.dispose();
    _bodyFat.dispose();
    super.dispose();
  }

  double? _read(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(now) ? now : _date,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select check-in date',
    );
    if (date != null) setState(() => _date = date);
  }

  void _save() {
    final weight = _read(_weight);
    final waist = _read(_waist);
    final bodyFat = _read(_bodyFat);
    if (weight == null && waist == null && bodyFat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one measurement.')),
      );
      return;
    }
    if ([weight, waist, bodyFat]
        .whereType<double>()
        .any((value) => value <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Measurements must be greater than zero.')),
      );
      return;
    }
    Navigator.pop(
      context,
      BodyMeasurement(
        id: widget.measurement?.id,
        date: _date,
        weight: weight,
        waist: waist,
        bodyFat: bodyFat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Check-in',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _selectDate,
                icon: const Icon(Icons.calendar_month),
                label: Text('Date · ${formatDate(_date)}'),
              ),
              const SizedBox(height: 12),
              _MeasurementField(
                label: 'BODY WEIGHT',
                unit: 'kg',
                controller: _weight,
              ),
              const SizedBox(height: 12),
              _MeasurementField(
                label: 'WAIST',
                unit: 'cm',
                controller: _waist,
              ),
              const SizedBox(height: 12),
              _MeasurementField(
                label: 'BODY FAT',
                unit: '%',
                controller: _bodyFat,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: appAccent,
                    foregroundColor: appBackground,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    widget.measurement == null
                        ? 'Save check-in'
                        : 'Save changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({
    required this.label,
    required this.unit,
    required this.controller,
  });

  final String label;
  final String unit;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(label),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '0.0',
              suffixText: unit,
            ),
          ),
        ],
      );
}
