import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';

class DateRangeBar extends StatelessWidget {
  const DateRangeBar({
    super.key,
    required this.start,
    required this.end,
    required this.onChanged,
    this.period,
    this.onPeriodChanged,
    this.periodOptions = const ['daily', 'weekly', 'monthly'],
  });

  final DateTime start;
  final DateTime end;
  final void Function(DateTime start, DateTime end) onChanged;
  final String? period;
  final ValueChanged<String>? onPeriodChanged;
  final List<String> periodOptions;

  static String formatApi(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _pick(BuildContext context, bool isStart) async {
    final initial = isStart ? start : end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    if (isStart) {
      onChanged(picked, end.isBefore(picked) ? picked : end);
    } else {
      onChanged(start.isAfter(picked) ? picked : start, picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy.MM.dd');
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (period != null && onPeriodChanged != null) ...[
          _PeriodChip(
            label: '일간',
            selected: period == 'daily',
            onTap: () => onPeriodChanged!('daily'),
          ),
          _PeriodChip(
            label: '주간',
            selected: period == 'weekly',
            onTap: () => onPeriodChanged!('weekly'),
          ),
          _PeriodChip(
            label: '월간',
            selected: period == 'monthly',
            onTap: () => onPeriodChanged!('monthly'),
          ),
          const SizedBox(width: 8),
        ],
        OutlinedButton(
          onPressed: () => _pick(context, true),
          child: Text(fmt.format(start)),
        ),
        const Text('~'),
        OutlinedButton(
          onPressed: () => _pick(context, false),
          child: Text(fmt.format(end)),
        ),
        TextButton(
          onPressed: () {
            final today = DateTime.now();
            onChanged(DateTime(today.year, today.month, today.day), today);
          },
          child: const Text('오늘'),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.secondary,
      onSelected: (_) => onTap(),
    );
  }
}
