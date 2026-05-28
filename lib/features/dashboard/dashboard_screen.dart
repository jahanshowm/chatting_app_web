import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:randomchat_admin/core/theme/app_colors.dart';
import 'package:randomchat_admin/data/admin_api.dart';
import 'package:randomchat_admin/data/models/admin_models.dart';
import 'package:randomchat_admin/shared/widgets/admin_shell.dart';
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

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: '대시보드',
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DateRangeBar(
                    start: _start,
                    end: _end,
                    period: _period,
                    onPeriodChanged: (p) {
                      setState(() => _period = p);
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
                  const SizedBox(height: 32),
                  Container(
                    height: 320,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _visitors.isEmpty
                        ? const Center(child: Text('접속자 데이터가 없습니다.'))
                        : BarChart(
                            BarChartData(
                              gridData: const FlGridData(show: true),
                              borderData: FlBorderData(show: false),
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
                                        width: 8,
                                      ),
                                      BarChartRodData(
                                        toY: _visitors[i].female.toDouble(),
                                        color: AppColors.female,
                                        width: 8,
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _TopTable(title: '신규가입 TOP5', rows: _signups, columns: const [
                        ('gender', '성별'),
                        ('name', '이름'),
                        ('birth_date', '생년월일'),
                        ('phone_number', '연락처'),
                        ('joined_at', '가입일'),
                      ])),
                      const SizedBox(width: 24),
                      Expanded(child: _TopTable(title: '결제 TOP5', rows: _payments, columns: const [
                        ('gender', '성별'),
                        ('name', '이름'),
                        ('phone_number', '연락처'),
                        ('product_name', '상품'),
                        ('paid_at', '결제일'),
                      ])),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _TopTable extends StatelessWidget {
  const _TopTable({required this.title, required this.rows, required this.columns});

  final String title;
  final List<Map<String, dynamic>> rows;
  final List<(String, String)> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                            child: Text('${row[c.$1] ?? '-'}'),
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
