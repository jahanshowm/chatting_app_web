import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_common.dart';
import 'package:randomchat_admin/shared/widgets/admin_page_frame.dart';
import 'package:randomchat_admin/shared/widgets/date_range_bar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _period = 'daily';
  late DateTime _start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _end = DateTime.now();
  List<VisitorChartPoint> _visitors = [];
  List<Map<String, dynamic>> _signups = [];
  List<Map<String, dynamic>> _payments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = ref.read(adminApiProvider);
    try {
      final results = await Future.wait([
        api.visitors(
          period: _period,
          startDate: DateRangeBar.formatApi(_start),
          endDate: DateRangeBar.formatApi(_end),
        ),
        api.recentSignups(),
        api.recentPayments(),
      ]);
      if (!mounted) return;
      setState(() {
        _visitors = results[0] as List<VisitorChartPoint>;
        _signups = results[1] as List<Map<String, dynamic>>;
        _payments = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _resetSearch() {
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    setState(() {
      _period = 'daily';
      _start = d;
      _end = d;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AdminContentArea(
      toolbar: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DateRangeBar(
            start: _start,
            end: _end,
            period: _period,
            onPeriodChanged: (p) {
              final today = DateTime.now();
              setState(() {
                _period = p;
                if (p == 'weekly') {
                  _start = DateTime(today.year, today.month, today.day)
                      .subtract(const Duration(days: 6));
                  _end = today;
                } else if (p == 'monthly') {
                  _start = DateTime(today.year, today.month, 1);
                  _end = today;
                } else {
                  _start = DateTime(today.year, today.month, today.day);
                  _end = today;
                }
              });
              _load();
            },
            onChanged: (s, e) {
              setState(() {
                _start = s;
                _end = e;
              });
              _load();
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _resetSearch, child: const Text('초기화')),
          ),
        ],
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 340,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('접속자 현황', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _LegendDot(color: AppColors.male, label: '남성'),
                            const SizedBox(width: 16),
                            _LegendDot(color: AppColors.female, label: '여성'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _visitors.isEmpty
                              ? const Center(child: Text('접속자 데이터가 없습니다.'))
                              : BarChart(
                                  BarChartData(
                                    gridData: const FlGridData(show: true),
                                    borderData: FlBorderData(show: false),
                                    barTouchData: BarTouchData(
                                      enabled: true,
                                      touchTooltipData: BarTouchTooltipData(
                                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                          if (rodIndex != 0) return null;
                                          if (groupIndex < 0 || groupIndex >= _visitors.length) {
                                            return null;
                                          }
                                          final point = _visitors[groupIndex];
                                          return BarTooltipItem(
                                            '${point.label}\n남성 : ${point.male}명\n여성 : ${point.female}명',
                                            const TextStyle(color: Colors.white, fontSize: 12),
                                          );
                                        },
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (v, _) {
                                            final i = v.toInt();
                                            if (i < 0 || i >= _visitors.length) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(top: 8),
                                              child: Text(
                                                _visitors[i].label,
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: true, reservedSize: 36),
                                      ),
                                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    ),
                                    barGroups: [
                                      for (var i = 0; i < _visitors.length; i++)
                                        BarChartGroupData(
                                          x: i,
                                          barRods: [
                                            BarChartRodData(
                                              toY: _visitors[i].male.toDouble(),
                                              color: AppColors.male,
                                              width: 10,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                            ),
                                            BarChartRodData(
                                              toY: _visitors[i].female.toDouble(),
                                              color: AppColors.female,
                                              width: 10,
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TopTable(
                          title: '신규가입 현황',
                          screenLink: '/members/new',
                          rows: _signups,
                          columns: const [
                            ('gender', '성별'),
                            ('name', '이름'),
                            ('birth_date', '생년월일'),
                            ('phone_number', '휴대폰번호'),
                            ('joined_at', '가입일'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _TopTable(
                          title: '결제 현황',
                          screenLink: '/payments',
                          rows: _payments,
                          columns: const [
                            ('gender', '성별'),
                            ('name', '이름'),
                            ('phone_number', '휴대폰번호'),
                            ('product_name', '상품'),
                            ('paid_at', '결제일'),
                          ],
                          formatCell: (key, row, fmt) {
                            if (key == 'product_name') {
                              return formatProductWithAmount(
                                row['product_name']?.toString(),
                                row['amount'],
                                fmt,
                              );
                            }
                            return '${row[key] ?? '-'}';
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _TopTable extends ConsumerWidget {
  const _TopTable({
    required this.title,
    required this.screenLink,
    required this.rows,
    required this.columns,
    this.formatCell,
  });

  final String title;
  final String screenLink;
  final List<Map<String, dynamic>> rows;
  final List<(String, String)> columns;
  final String Function(String key, Map<String, dynamic> row, NumberFormat fmt)? formatCell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () => adminNavigate(ref, screenLink),
                child: const Text('더보기'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Table(
            columnWidths: {for (var i = 0; i < columns.length; i++) i: const FlexColumnWidth()},
            children: [
              TableRow(
                decoration: const BoxDecoration(color: AppColors.tableHeader),
                children: columns
                    .map((c) => Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(c.$2, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ))
                    .toList(),
              ),
              ...rows.map(
                (row) => TableRow(
                  children: columns
                      .map((c) => Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              formatCell?.call(c.$1, row, fmt) ?? '${row[c.$1] ?? '-'}',
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
