import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:randomchat_admin/core/navigation/admin_menu.dart';
import 'package:randomchat_admin/core/navigation/admin_screen_specs.dart';
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
  late DateTime _end = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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

  double get _chartMaxY {
    if (_visitors.isEmpty) return 10;
    var max = 0;
    for (final p in _visitors) {
      if (p.male > max) max = p.male;
      if (p.female > max) max = p.female;
    }
    return (max + 2).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return AdminContentArea(
      screenId: dashboardSpec.id,
      subtitle: dashboardSpec.subtitle,
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
                  _end = DateTime(today.year, today.month, today.day);
                } else if (p == 'monthly') {
                  _start = DateTime(today.year, today.month, 1);
                  _end = DateTime(today.year, today.month, today.day);
                } else {
                  final d = DateTime(today.year, today.month, today.day);
                  _start = d;
                  _end = d;
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
                    height: 360,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                              : LineChart(
                                  LineChartData(
                                    minX: 0,
                                    maxX: (_visitors.length - 1).toDouble(),
                                    minY: 0,
                                    maxY: _chartMaxY,
                                    gridData: const FlGridData(show: true),
                                    borderData: FlBorderData(show: false),
                                    lineTouchData: LineTouchData(
                                      enabled: true,
                                      handleBuiltInTouches: true,
                                      touchSpotThreshold: 24,
                                      touchTooltipData: LineTouchTooltipData(
                                        fitInsideHorizontally: true,
                                        getTooltipItems: (touchedSpots) {
                                          if (touchedSpots.isEmpty) return [];
                                          final spot = touchedSpots.first;
                                          final i = spot.spotIndex >= 0
                                              ? spot.spotIndex
                                              : spot.x.round();
                                          if (i < 0 || i >= _visitors.length) {
                                            return List<LineTooltipItem?>.filled(
                                              touchedSpots.length,
                                              null,
                                            );
                                          }
                                          final point = _visitors[i];
                                          final male =
                                              point.male.toString().padLeft(2, '0');
                                          final female =
                                              point.female.toString().padLeft(2, '0');
                                          final text = '남성 : $male명 여성 : $female명';
                                          const style = TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          );
                                          return touchedSpots.asMap().entries.map((e) {
                                            if (e.key == 0) {
                                              return LineTooltipItem(text, style);
                                            }
                                            return null;
                                          }).toList();
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
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: [
                                          for (var i = 0; i < _visitors.length; i++)
                                            FlSpot(i.toDouble(), _visitors[i].male.toDouble()),
                                        ],
                                        isCurved: true,
                                        color: AppColors.male,
                                        barWidth: 2,
                                        dotData: const FlDotData(show: true),
                                      ),
                                      LineChartBarData(
                                        spots: [
                                          for (var i = 0; i < _visitors.length; i++)
                                            FlSpot(i.toDouble(), _visitors[i].female.toDouble()),
                                        ],
                                        isCurved: true,
                                        color: AppColors.female,
                                        barWidth: 2,
                                        dotData: const FlDotData(show: true),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _TopTable(
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
                  const SizedBox(height: 24),
                  _TopTable(
                    title: '결제 현황',
                    screenLink: '/payments',
                    rows: _payments,
                    columns: const [
                      ('gender', '성별'),
                      ('name', '이름'),
                      ('phone_number', '휴대폰번호'),
                      ('product_name', '상품명'),
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
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const Spacer(),
              OutlinedButton(
                onPressed: () => adminNavigate(ref, screenLink),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                ),
                child: const Text('더보기'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '내역이 없습니다.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            Table(
              border: TableBorder.all(color: AppColors.border, width: 0.5),
              columnWidths: {
                for (var i = 0; i < columns.length; i++) i: const FlexColumnWidth(),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: AppColors.inputBg),
                  children: columns
                      .map(
                        (c) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text(
                            c.$2,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      )
                      .toList(),
                ),
                ...rows.map(
                  (row) => TableRow(
                    children: columns.map((c) {
                      final text = formatCell?.call(c.$1, row, fmt) ?? '${row[c.$1] ?? '-'}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: c.$1 == 'gender'
                            ? _GenderText(value: text)
                            : Text(text, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _GenderText extends StatelessWidget {
  const _GenderText({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    Color? color;
    if (value.contains('남')) color = AppColors.male;
    if (value.contains('여')) color = AppColors.female;
    return Text(
      value,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.text,
      ),
    );
  }
}
