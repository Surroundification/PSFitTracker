import 'package:flutter/material.dart';

import 'app_formatters.dart';
import 'app_theme.dart';
import 'models.dart';

const tableHeading = TextStyle(
  color: appMuted,
  fontSize: 9,
  fontWeight: FontWeight.w800,
  letterSpacing: 0.5,
);

class SetRow extends StatefulWidget {
  const SetRow({
    super.key,
    required this.number,
    required this.set,
    this.onCompletedChanged,
    required this.onChanged,
    this.readOnly = false,
    this.completionReadOnly = false,
    this.timerActive = false,
    this.onRemove,
  });

  final int number;
  final LoggedSet set;
  final ValueChanged<bool>? onCompletedChanged;
  final VoidCallback onChanged;
  final bool readOnly;
  final bool completionReadOnly;
  final bool timerActive;
  final VoidCallback? onRemove;

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final TextEditingController _repsController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(text: '${widget.set.reps}');
    _weightController = TextEditingController(
      text: widget.set.weight == 0 ? '' : formatWeight(widget.set.weight),
    );
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${widget.number}'.padLeft(2, '0'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  if (widget.timerActive) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.hourglass_bottom,
                        color: appAccent, size: 14),
                  ],
                  if (widget.onRemove != null)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          tooltip: 'Remove set ${widget.number}',
                          onPressed: widget.onRemove,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(
                              width: 32, height: 32),
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: appMuted,
                            size: 17,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: widget.readOnly
                  ? _ReadOnlySetValue(
                      widget.set.weight != 0
                          ? formatWeight(widget.set.weight)
                          : '—',
                    )
                  : _CompactNumberField(
                      controller: _weightController,
                      hint: 'kg',
                      decimal: true,
                      onChanged: (value) {
                        widget.set.weight =
                            double.tryParse(value.replaceAll(',', '.')) ?? 0;
                        widget.onChanged();
                      },
                    ),
            ),
            Expanded(
              child: widget.readOnly
                  ? _ReadOnlySetValue('${widget.set.reps}')
                  : _CompactNumberField(
                      controller: _repsController,
                      hint: 'reps',
                      onChanged: (value) {
                        widget.set.reps = int.tryParse(value) ?? 0;
                        widget.onChanged();
                      },
                    ),
            ),
            SizedBox(
              width: 42,
              child: Checkbox(
                value: widget.set.completed,
                onChanged: widget.readOnly || widget.completionReadOnly
                    ? null
                    : (value) {
                        final completed = value ?? false;
                        widget.set.completed = completed;
                        final onCompletedChanged = widget.onCompletedChanged;
                        if (onCompletedChanged == null) {
                          widget.onChanged();
                        } else {
                          onCompletedChanged(completed);
                        }
                      },
                activeColor: appAccent,
                checkColor: appBackground,
              ),
            ),
          ],
        ),
      );
}

class _ReadOnlySetValue extends StatelessWidget {
  const _ReadOnlySetValue(this.value);

  final String value;

  @override
  Widget build(BuildContext context) => Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      );
}

class _CompactNumberField extends StatelessWidget {
  const _CompactNumberField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool decimal;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.numberWithOptions(
            decimal: decimal,
            signed: decimal,
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: appMuted, fontSize: 12),
            filled: true,
            fillColor: appSurfaceRaised,
            contentPadding: const EdgeInsets.symmetric(vertical: 9),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      );
}

class RestTimerDialog extends StatefulWidget {
  const RestTimerDialog({super.key, required this.initialSeconds});

  final int initialSeconds;

  @override
  State<RestTimerDialog> createState() => _RestTimerDialogState();
}

class _RestTimerDialogState extends State<RestTimerDialog> {
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSeconds;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: appSurface,
        title: const Text('Rest timer'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed:
                  _seconds < 15 ? null : () => setState(() => _seconds -= 15),
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              formatDuration(_seconds),
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            IconButton(
              onPressed:
                  _seconds > 3585 ? null : () => setState(() => _seconds += 15),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _seconds),
            child: const Text('Set timer'),
          ),
        ],
      );
}
