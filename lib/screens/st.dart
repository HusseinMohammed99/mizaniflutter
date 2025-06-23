import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'dart:math'; // Imported for the 'max' function

final formatter = NumberFormat("#,##0.00", "ar");

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

  bool isLoading = true; // 🔴 Manages the loading state
  String? _currentUserId; // 🔴 Stores the current user's ID

  @override
  void initState() {
    super.initState();
    _currentUserId =
        supabase.auth.currentUser?.id; // Get user ID when widget initializes
    if (_currentUserId == null) {
      // If no user is logged in, show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول لعرض الإحصائيات.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        isLoading = false; // No data to load, just show empty state
      });
    } else {
      fetchData(); // Load data only if a user is logged in
    }
  }

  // 🔴 Main data fetching function that relies on getSum()
  Future<void> fetchData() async {
    if (_currentUserId == null) {
      return; // Do not fetch data if no user is logged in
    }

    setState(() {
      isLoading = true; // Activate loading state
    });

    try {
      salary = await getSum('salaries');
      expenses = await getSum('expenses');
      saving = await getSum('saving');
      debts = await getSum('debts');
      credits = await getSum('credits'); // Added Credits here too

      net =
          salary -
          expenses -
          saving -
          debts -
          credits; // 🔴 Adjusted net calculation

      if (mounted) {
        setState(() {
          isLoading = false; // Deactivate loading state
        });
      }
    } on PostgrestException catch (e) {
      print('Error fetching statistics from Supabase: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب الإحصائيات: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false; // Deactivate loading on error
          // Reset values to zero on error
          salary = 0;
          expenses = 0;
          saving = 0;
          debts = 0;
          credits = 0;
          net = 0;
        });
      }
    } catch (e) {
      print('Error fetching statistics: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع أثناء جلب الإحصائيات: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false; // Deactivate loading on error
          // Reset values to zero on error
          salary = 0;
          expenses = 0;
          saving = 0;
          debts = 0;
          credits = 0;
          net = 0;
        });
      }
    }
  }

  // 🔴 Function to get the sum for each table, filtered by user_id
  Future<double> getSum(String table) async {
    if (_currentUserId == null) return 0; // If no user, sum is zero

    double total = 0;
    try {
      // 🔴 Filter the query by user_id
      final response = await supabase
          .from(table)
          .select('amount')
          .eq('user_id', _currentUserId!);
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
    } on PostgrestException catch (e) {
      print('Error fetching sum for $table: ${e.message}');
      // Don't show SnackBar here to avoid multiple messages if multiple errors occur
      // Error messages will be handled in fetchData()
    } catch (e) {
      print('Unexpected error fetching sum for $table: $e');
    }
    return total;
  }

  // 🔴 Helper function to create Pie Chart sections
  List<PieChartSectionData> showingSections() {
    final double total = salary + expenses + saving + debts + credits;
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1, // To show a complete circle
          title: 'لا توجد بيانات',
          color: Colors.grey,
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    return [
      if (salary > 0)
        PieChartSectionData(
          value: salary,
          title: "${(salary / total * 100).toStringAsFixed(1)}%",
          color: Colors.green,
          radius: 80, // Size of the slice in the pie chart
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          showTitle: true,
        ),
      if (expenses > 0)
        PieChartSectionData(
          value: expenses,
          title: "${(expenses / total * 100).toStringAsFixed(1)}%",
          color: Colors.red,
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          showTitle: true,
        ),
      if (saving > 0)
        PieChartSectionData(
          value: saving,
          title: "${(saving / total * 100).toStringAsFixed(1)}%",
          color: Colors.blue,
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          showTitle: true,
        ),
      if (debts > 0)
        PieChartSectionData(
          value: debts,
          title: "${(debts / total * 100).toStringAsFixed(1)}%",
          color: Colors.orange,
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          showTitle: true,
        ),
      if (credits > 0) // 🔴 Added Credits to Pie Chart
        PieChartSectionData(
          value: credits,
          title: "${(credits / total * 100).toStringAsFixed(1)}%",
          color: Colors.purple,
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          showTitle: true,
        ),
    ];
  }

  // 🔴 Helper function to create Bar Chart sections
  List<BarChartGroupData> showingGroups() => [
    BarChartGroupData(
      x: 0,
      barRods: [BarChartRodData(toY: salary, color: Colors.green, width: 16)],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 1,
      barRods: [BarChartRodData(toY: expenses, color: Colors.red, width: 16)],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 2,
      barRods: [BarChartRodData(toY: saving, color: Colors.blue, width: 16)],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 3,
      barRods: [BarChartRodData(toY: debts, color: Colors.orange, width: 16)],
      showingTooltipIndicators: [0],
    ),
    BarChartGroupData(
      x: 4,
      barRods: [
        BarChartRodData(toY: credits, color: Colors.purple, width: 16),
      ], // 🔴 Added Credits to Bar Chart
      showingTooltipIndicators: [0],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      // If no user, display a message instead of the chart
      return Scaffold(
        appBar: AppBar(
          title: const Text("تحليل البيانات المالية"),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'يرجى تسجيل الدخول لعرض الإحصائيات.',
            style: TextStyle(fontSize: 18, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

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
        child: SingleChildScrollView(
          // 🔴 Using SingleChildScrollView to handle content overflow
          child: Column(
            children: [
              Text(
                "صافي الدخل/الربح: ${formatter.format(net)} د.ع", // 🔴 Using formatter
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Pie Chart
              const Text(
                "النسب المئوية (الراتب، المصروف، الادخار، الدين، الدائن)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections:
                        showingSections(), // 🔴 Using helper function to create sections
                    centerSpaceRadius: 40, // Size of the center space
                    // 🔴 sectionsProvider removed as it is not a valid parameter for PieChartData
                    borderData: FlBorderData(show: false), // Hide borders
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bar Chart
              const Text(
                "المقارنة العامة (الراتب، المصروف، الادخار، الدين، الدائن)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 250, // 🔴 Increased height for Bar Chart
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            Widget text;
                            switch (value.toInt()) {
                              case 0: // 🔴 Changed indices to match Array
                                text = const Text(
                                  "راتب",
                                  style: TextStyle(fontSize: 12),
                                );
                                break;
                              case 1:
                                text = const Text(
                                  "مصروف",
                                  style: TextStyle(fontSize: 12),
                                );
                                break;
                              case 2:
                                text = const Text(
                                  "ادخار",
                                  style: TextStyle(fontSize: 12),
                                );
                                break;
                              case 3:
                                text = const Text(
                                  "دين",
                                  style: TextStyle(fontSize: 12),
                                );
                                break;
                              case 4:
                                text = const Text(
                                  "دائن",
                                  style: TextStyle(fontSize: 12),
                                ); // 🔴 Added "Dain"
                                break;
                              default:
                                text = const Text(
                                  "",
                                  style: TextStyle(fontSize: 12),
                                );
                                break;
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: text,
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups:
                        showingGroups(), // 🔴 Using helper function to create sections
                    gridData: FlGridData(show: false), // Hide grid lines
                    alignment: BarChartAlignment.spaceAround,
                    maxY:
                        [
                          salary,
                          expenses,
                          saving,
                          debts,
                          credits,
                        ].reduce((a, b) => a > b ? a : b) *
                        1.2, // 🔴 Dynamically set max Y value
                    minY: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
