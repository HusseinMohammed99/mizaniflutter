import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Represents a financial entry with amount and creation date.
class FinancialEntry {
  final double amount;
  final DateTime createdAt;

  FinancialEntry({required this.amount, required this.createdAt});

  // Factory constructor to parse data from Supabase response.
  factory FinancialEntry.fromMap(Map<String, dynamic> data) {
    // Safely parse the 'amount' field. It might come as num or string from Supabase.
    double parsedAmount;
    if (data['amount'] is String) {
      parsedAmount = double.tryParse(data['amount']) ?? 0.0;
    } else if (data['amount'] is num) {
      parsedAmount = (data['amount'] as num).toDouble();
    } else {
      parsedAmount = 0.0; // Default to 0.0 if type is unexpected
    }

    return FinancialEntry(
      amount: parsedAmount,
      createdAt: DateTime.parse(data['created_at']),
    );
  }
}

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  // Supabase client instance.
  final supabase = Supabase.instance.client;

  // Currently selected period for data analysis ('شهر' for month, 'سنة' for year).
  String selectedPeriod = 'شهر';

  // Aggregated financial data for the selected period.
  double totalSalary = 0;
  double totalExpense = 0;
  double totalSaving = 0;
  double totalDebt = 0;

  // Data points for salary and expense trends over time (for the LineChart).
  List<FlSpot> salarySpots = [];
  List<FlSpot> expenseSpots = [];

  // Loading state indicator.
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch data when the widget initializes.
    fetchData();
  }

  // Determines the start date for data fetching based on the selected period.
  DateTime getStartDate() {
    final now = DateTime.now();
    if (selectedPeriod == 'شهر') {
      // Start of the current month.
      return DateTime(now.year, now.month, 1);
    } else {
      // Start of the current year.
      return DateTime(now.year, 1, 1);
    }
  }

  // Determines the end date for data fetching based on the selected period.
  DateTime getEndDate() {
    final now = DateTime.now();
    if (selectedPeriod == 'شهر') {
      // End of the current month (last day, 23:59:59).
      return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else {
      // End of the current year (last day, 23:59:59).
      return DateTime(now.year, 12, 31, 23, 59, 59);
    }
  }

  // Helper function to process raw financial data into FlSpot lists.
  List<FlSpot> _processDataToSpots(
    List<FinancialEntry> data,
    DateTime fromDate,
    String periodType,
  ) {
    Map<int, double> aggregatedMap = {};
    if (periodType == 'شهر') {
      // Aggregate by day for monthly view.
      for (var entry in data) {
        int day = entry.createdAt.day;
        aggregatedMap[day] = (aggregatedMap[day] ?? 0) + entry.amount;
      }
      // Create spots for all days in the month, even if no data exists.
      int daysInMonth = DateTime(fromDate.year, fromDate.month + 1, 0).day;
      return List.generate(
        daysInMonth,
        (index) =>
            FlSpot((index + 1).toDouble(), aggregatedMap[index + 1] ?? 0),
      );
    } else {
      // Aggregate by month for yearly view.
      for (var entry in data) {
        int month = entry.createdAt.month;
        aggregatedMap[month] = (aggregatedMap[month] ?? 0) + entry.amount;
      }
      // Create spots for all 12 months, even if no data exists.
      return List.generate(
        12,
        (index) =>
            FlSpot((index + 1).toDouble(), aggregatedMap[index + 1] ?? 0),
      );
    }
  }

  // Fetches financial data from Supabase for the selected period.
  Future<void> fetchData() async {
    setState(() {
      isLoading = true; // Set loading state to true
    });

    final from = getStartDate();
    final to = getEndDate();

    try {
      // Fetch salaries
      final List<FinancialEntry> salaries =
          (await supabase
                  .from('salaries')
                  .select('amount, created_at')
                  .gte('created_at', from.toIso8601String())
                  .lte('created_at', to.toIso8601String()))
              .map((data) => FinancialEntry.fromMap(data))
              .toList();

      // Fetch expenses
      final List<FinancialEntry> expenses =
          (await supabase
                  .from('expenses')
                  .select('amount, created_at')
                  .gte('created_at', from.toIso8601String())
                  .lte('created_at', to.toIso8601String()))
              .map((data) => FinancialEntry.fromMap(data))
              .toList();

      // Fetch savings
      final List<FinancialEntry> savings =
          (await supabase
                  .from('saving')
                  .select('amount')
                  .gte('created_at', from.toIso8601String())
                  .lte('created_at', to.toIso8601String()))
              .map((data) => FinancialEntry.fromMap(data))
              .toList();

      // Fetch debts
      final List<FinancialEntry> debts =
          (await supabase
                  .from('debts')
                  .select('amount')
                  .gte('created_at', from.toIso8601String())
                  .lte('created_at', to.toIso8601String()))
              .map((data) => FinancialEntry.fromMap(data))
              .toList();

      // Calculate sums
      double sumSalary = salaries.fold(0, (sum, item) => sum + item.amount);
      double sumExpense = expenses.fold(0, (sum, item) => sum + item.amount);
      double sumSaving = savings.fold(0, (sum, item) => sum + item.amount);
      double sumDebt = debts.fold(0, (sum, item) => sum + item.amount);

      // Process data for line chart spots
      List<FlSpot> newSalarySpots = _processDataToSpots(
        salaries,
        from,
        selectedPeriod,
      );
      List<FlSpot> newExpenseSpots = _processDataToSpots(
        expenses,
        from,
        selectedPeriod,
      );

      setState(() {
        totalSalary = sumSalary;
        totalExpense = sumExpense;
        totalSaving = sumSaving;
        totalDebt = sumDebt;
        salarySpots = newSalarySpots;
        expenseSpots = newExpenseSpots;
        isLoading = false; // Data fetched, stop loading
      });

      // Show warning if expenses exceed 70% of salary
      if (totalSalary > 0 && totalExpense > totalSalary * 0.7) {
        if (mounted) {
          // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ تحذير: المصروفات تجاوزت 70% من الراتب'),
            ),
          );
        }
      }
    } catch (e) {
      // Handle any errors during data fetching.
      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          isLoading = false; // Stop loading on error
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ في جلب البيانات: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate saving percentage relative to total salary.
    double savingPercent = totalSalary > 0
        ? (totalSaving / totalSalary) * 100
        : 0;

    // Calculate remaining funds after expenses and savings.
    double remainingFunds = totalSalary - totalExpense - totalSaving;

    return Scaffold(
      appBar: AppBar(title: const Text('تحليل البيانات المالية')),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Show loading indicator
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Period selection chips.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('شهر'),
                        selected: selectedPeriod == 'شهر',
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              selectedPeriod = 'شهر';
                              fetchData(); // Refetch data for the new period
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 10),
                      ChoiceChip(
                        label: const Text('سنة'),
                        selected: selectedPeriod == 'سنة',
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              selectedPeriod = 'سنة';
                              fetchData(); // Refetch data for the new period
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Title for the Pie Chart
                  const Text(
                    'توزيع الراتب',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // PieChart showing salary distribution (Expenses, Savings, Remaining).
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: [
                          // Expense slice
                          if (totalExpense > 0)
                            PieChartSectionData(
                              value: totalExpense,
                              title:
                                  "المصروف\n${(totalExpense / totalSalary * 100).toStringAsFixed(1)}%",
                              color: Colors.red,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          // Saving slice
                          if (totalSaving > 0)
                            PieChartSectionData(
                              value: totalSaving,
                              title:
                                  "الادخار\n${(totalSaving / totalSalary * 100).toStringAsFixed(1)}%",
                              color: Colors.blue,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          // Remaining funds slice
                          if (remainingFunds > 0)
                            PieChartSectionData(
                              value: remainingFunds,
                              title:
                                  "المتبقي\n${(remainingFunds / totalSalary * 100).toStringAsFixed(1)}%",
                              color: Colors.green,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          // If totalSalary is 0 and there are expenses/savings, show a default section
                          if (totalSalary == 0 &&
                              (totalExpense > 0 || totalSaving > 0))
                            PieChartSectionData(
                              value: 1, // A small placeholder value
                              title: "لا يوجد راتب",
                              color: Colors.grey,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Display saving percentage.
                  Text(
                    "نسبة الادخار من الراتب: ${savingPercent.toStringAsFixed(2)}%",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title for the Line Chart
                  const Text(
                    'تطور الراتب والمصروف',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // LineChart showing salary and expense trends over time.
                  SizedBox(
                    height: 400,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        titlesData: FlTitlesData(
                          // Bottom titles (days or months).
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1, // Show all day/month labels
                              getTitlesWidget: (value, meta) {
                                // Format labels based on selected period.
                                if (selectedPeriod == 'شهر') {
                                  return Text("${value.toInt()}");
                                } else {
                                  const months = [
                                    '',
                                    'يناير',
                                    'فبراير',
                                    'مارس',
                                    'أبريل',
                                    'مايو',
                                    'يونيو',
                                    'يوليو',
                                    'أغسطس',
                                    'سبتمبر',
                                    'أكتوبر',
                                    'نوفمبر',
                                    'ديسمبر',
                                  ];
                                  return Text(months[value.toInt()]);
                                }
                              },
                            ),
                          ),
                          // Left titles (amount values).
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              // Set interval to null to let FlChart determine optimal interval
                              interval: null,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                              reservedSize: 40, // Reserve space for labels
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: const Color(0xff37434d),
                            width: 1,
                          ),
                        ),
                        // Define salary and expense lines.
                        lineBarsData: [
                          LineChartBarData(
                            spots: salarySpots,
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                          ),
                          LineChartBarData(
                            spots: expenseSpots,
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Legend for the line chart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 16, height: 16, color: Colors.green),
                      const SizedBox(width: 4),
                      const Text('الراتب'),
                      const SizedBox(width: 16),
                      Container(width: 16, height: 16, color: Colors.red),
                      const SizedBox(width: 4),
                      const Text('المصروف'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Summary cards displaying aggregated values.
                  Wrap(
                    spacing: 10, // Horizontal spacing
                    runSpacing: 10, // Vertical spacing
                    alignment: WrapAlignment.center,
                    children: [
                      _summaryCard(
                        'صافي الراتب',
                        totalSalary.toStringAsFixed(2),
                        Colors.green,
                      ),
                      _summaryCard(
                        'المصروف',
                        totalExpense.toStringAsFixed(2),
                        Colors.red,
                      ),
                      _summaryCard(
                        'الادخار',
                        totalSaving.toStringAsFixed(2),
                        Colors.blue,
                      ),
                      _summaryCard(
                        'الدين',
                        totalDebt.toStringAsFixed(2),
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  // Helper widget to display a summary card.
  Widget _summaryCard(String title, String value, Color color) {
    return Card(
      elevation: 4, // Add subtle shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ), // Rounded corners
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
