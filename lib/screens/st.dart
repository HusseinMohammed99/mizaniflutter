import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final supabase = Supabase.instance.client;

  double salary = 0;
  double expenses = 0;
  double saving = 0;
  double debts = 0;
  double credits = 0;
  double net = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    salary = await getSum('salaries');
    expenses = await getSum('expenses');
    saving = await getSum('saving');
    debts = await getSum('debts');
    credits = await getSum('credits');

    net = salary - expenses - saving - debts;

    setState(() {
      isLoading = false;
    });
  }

  Future<double> getSum(String table) async {
    final response = await supabase.from(table).select('amount');
    double total = 0;
    for (var item in response) {
      final amt = item['amount'];
      if (amt != null) {
        if (amt is num) {
          total += amt.toDouble();
        } else if (amt is String) {
          total += double.tryParse(amt) ?? 0;
        }
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("تحليل البيانات المالية"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "صافي الراتب: ${net.toStringAsFixed(2)} د.ع",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),

            // Pie Chart
            const Text(
              "النسب المئوية",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: salary,
                      title: "راتب",
                      color: Colors.green,
                    ),
                    PieChartSectionData(
                      value: expenses,
                      title: "مصروف",
                      color: Colors.red,
                    ),
                    PieChartSectionData(
                      value: saving,
                      title: "ادخار",
                      color: Colors.blue,
                    ),
                    PieChartSectionData(
                      value: debts,
                      title: "دين",
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Bar Chart
            const Text(
              "المقارنة العامة",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          switch (value.toInt()) {
                            case 1.0:
                              return const Text("راتب");
                            case 1:
                              return const Text("مصروف");
                            case 2:
                              return const Text("ادخار");
                            case 3:
                              return const Text("دين");
                            case 4:
                              return const Text("دائن");
                            default:
                              return const Text("");
                          }
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(toY: salary, color: Colors.green),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(toY: expenses, color: Colors.red),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(toY: saving, color: Colors.blue),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(toY: debts, color: Colors.orange),
                      ],
                    ),
                    BarChartGroupData(
                      x: 4,
                      barRods: [
                        BarChartRodData(toY: credits, color: Colors.purple),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
