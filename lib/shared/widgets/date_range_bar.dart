import 'package:flutter/material.dart';
import 'package:randomchat_admin/shared/utils/admin_date_format.dart';
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

  static String formatApi(DateTime d) => formatYmdApi(d);

  /// 리스트 일자와 동일한 yy.mm.dd 표기
  static String formatDisplay(DateTime d) {
    final y = (d.year % 100).toString().padLeft(2, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y.$m.$day';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isValidRange(DateTime start, DateTime end) {
    return !_dateOnly(start).isAfter(_dateOnly(end));
  }

  static void showInvalidRangeMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('시작일은 종료일보다 미래일 수 없습니다.')),
    );
  }

  Future<void> _pick(BuildContext context, bool isStart) async {
    final initial = isStart ? start : end;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;

    final nextStart = isStart ? picked : start;
    final nextEnd = isStart ? end : picked;
    if (!isValidRange(nextStart, nextEnd)) {
      if (context.mounted) showInvalidRangeMessage(context);
      return;
    }
    onChanged(nextStart, nextEnd);
  }

  @override
  Widget build(BuildContext context) {
    final rangeInvalid = !isValidRange(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
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
              child: Text(formatDisplay(start)),
            ),
            const Text('~'),
            OutlinedButton(
              onPressed: () => _pick(context, false),
              child: Text(formatDisplay(end)),
            ),
            TextButton(
              onPressed: () {
                final today = DateTime.now();
                final d = DateTime(today.year, today.month, today.day);
                onChanged(d, d);
              },
              child: const Text('오늘'),
            ),
          ],
        ),
        if (rangeInvalid)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              '시작일은 종료일보다 미래일 수 없습니다.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
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
    return Material(
      color: selected ? AppColors.periodSelected : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? AppColors.periodSelected : AppColors.border,
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
