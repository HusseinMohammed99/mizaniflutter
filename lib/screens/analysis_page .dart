import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // لتنسيق الأرقام
import 'dart:math'; // تم إضافة هذا الاستيراد لإصلاح خطأ 'max'

// تنسيق الأرقام للغة العربية مع فاصل آلاف
final NumberFormat currencyFormatter = NumberFormat("#,##0.00", "ar");

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

    // Safely parse the 'created_at' field.
    DateTime parsedCreatedAt;
    try {
      parsedCreatedAt = DateTime.parse(data['created_at']);
    } catch (e) {
      print('Error parsing created_at: ${data['created_at']} - $e');
      parsedCreatedAt = DateTime.now(); // Fallback to current time
    }

    return FinancialEntry(amount: parsedAmount, createdAt: parsedCreatedAt);
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
  double totalCredit = 0; // 🔴 إضافة إجمالي الائتمان

  // Data points for salary and expense trends over time (for the LineChart).
  List<FlSpot> salarySpots = [];
  List<FlSpot> expenseSpots = [];

  // Loading state indicator.
  bool isLoading = true;
  String? _currentUserId; // 🔴 لتخزين معرف المستخدم الحالي

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id; // جلب معرف المستخدم
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول لعرض التحليلات.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        isLoading = false; // لا يوجد تحميل لبيانات، فقط عرض حالة فارغة
      });
    } else {
      fetchData(); // Fetch data when the widget initializes.
    }
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
    if (_currentUserId == null) return; // لا تجلب بيانات إذا لا يوجد مستخدم

    setState(() {
      isLoading = true; // Set loading state to true
    });

    final from = getStartDate();
    final to = getEndDate();
    final String userId =
        _currentUserId!; // معرف المستخدم يجب أن يكون موجوداً هنا

    try {
      // Fetch salaries, filtered by user_id
      final List<FinancialEntry> salaries =
          (await supabase
                  .from('salaries')
                  .select('amount, created_at')
                  .eq('user_id', userId) // الفلترة هنا
                  .gte('created_at', from.toIso8601String())
                  .lte('created_at', to.toIso8601String()))
              .map((data) => FinancialEntry.fromMap(data))
              .toList();

      // Fetch expenses, filtered by user_id
      final List<FinancialEntry> expenses =
          (await supabase
                  .from('expenses')
                  .select('amount, created_at')
                  .eq('user_id', userId) // الفلترة هنا
                  .gte('created_at', from.toIso8601String())
                  .lte('created_at', to.toIso8601String()))
              .map((data) => FinancialEntry.fromMap(data))
              .toList();

      // Fetch savings, filtered by user_id
      final List<FinancialEntry> savings =
          (await supabase
                  .from('saving')
                  .select('amount, created_at')
                  .eq('user_id', userId) // الفلترة هنا
                  .gte('created_at', from.toIso8601String())
                  .lte('created_at', to.toIso8601String()))
              .map((data) => FinancialEntry.fromMap(data))
              .toList();

      // Fetch debts, filtered by user_id
      final List<FinancialEntry> debts =
          (await supabase
                  .from('debts')
                  .select('amount, created_at')
                  .eq('user_id', userId) // الفلترة هنا
                  .gte('created_at', from.toIso8601String())
                  .lte('created_at', to.toIso8601String()))
              .map((data) => FinancialEntry.fromMap(data))
              .toList();

      // Fetch credits, filtered by user_id
      final List<FinancialEntry> credits =
          (await supabase
                  .from('credits')
                  .select('amount, created_at')
                  .eq('user_id', userId) // الفلترة هنا
                  .gte('created_at', from.toIso8601String())
                  .lte('created_at', to.toIso8601String()))
              .map((data) => FinancialEntry.fromMap(data))
              .toList();

      // Calculate sums
      double sumSalary = salaries.fold(0, (sum, item) => sum + item.amount);
      double sumExpense = expenses.fold(0, (sum, item) => sum + item.amount);
      double sumSaving = savings.fold(0, (sum, item) => sum + item.amount);
      double sumDebt = debts.fold(0, (sum, item) => sum + item.amount);
      double sumCredit = credits.fold(0, (sum, item) => sum + item.amount);

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

      if (mounted) {
        setState(() {
          totalSalary = sumSalary;
          totalExpense = sumExpense;
          totalSaving = sumSaving;
          totalDebt = sumDebt;
          totalCredit = sumCredit;
          salarySpots = newSalarySpots;
          expenseSpots = newExpenseSpots;
          isLoading = false; // Data fetched, stop loading
        });
      }

      // Show warning if expenses exceed 70% of salary
      if (totalSalary > 0 && totalExpense > totalSalary * 0.7) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ تحذير: المصروفات تجاوزت 70% من الراتب'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } on PostgrestException catch (e) {
      // Handle Supabase specific errors
      if (mounted) {
        setState(() {
          isLoading = false; // Stop loading on error
          // Reset data on error
          totalSalary = 0;
          totalExpense = 0;
          totalSaving = 0;
          totalDebt = 0;
          totalCredit = 0;
          salarySpots = [];
          expenseSpots = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب البيانات: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Handle any other errors during data fetching.
      if (mounted) {
        setState(() {
          isLoading = false; // Stop loading on error
          // Reset data on error
          totalSalary = 0;
          totalExpense = 0;
          totalSaving = 0;
          totalDebt = 0;
          totalCredit = 0;
          salarySpots = [];
          expenseSpots = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع أثناء جلب البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper widget to display a summary card.
  Widget _summaryCard(String title, double value, Color color) {
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
              currencyFormatter.format(value), // 🔴 استخدام currencyFormatter
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

  @override
  Widget build(BuildContext context) {
    // في حال عدم وجود مستخدم، اعرض رسالة مناسبة بدلاً من المخططات
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('تحليل البيانات المالية')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'يرجى تسجيل الدخول لعرض تحليلاتك المالية.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Calculate saving percentage relative to total salary.
    double savingPercent = totalSalary > 0
        ? (totalSaving / totalSalary) * 100
        : 0;

    // Calculate remaining funds after expenses and savings, debts, and credits.
    double remainingFunds =
        totalSalary - totalExpense - totalSaving - totalDebt + totalCredit;

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
                    'توزيع الراتب والمصروفات',
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
                          if (totalExpense > 0 && totalSalary > 0)
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
                          if (totalSaving > 0 && totalSalary > 0)
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
                          if (remainingFunds > 0 && totalSalary > 0)
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
                          // If totalSalary is 0 and there are expenses/savings/debts/credits, show a default section
                          if (totalSalary == 0 &&
                              (totalExpense > 0 ||
                                  totalSaving > 0 ||
                                  totalDebt > 0 ||
                                  totalCredit > 0))
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
                          // إذا كانت جميع القيم صفرية، اعرض "لا توجد بيانات" بشكل واضح
                          if (totalSalary == 0 &&
                              totalExpense == 0 &&
                              totalSaving == 0 &&
                              totalDebt == 0 &&
                              totalCredit == 0)
                            PieChartSectionData(
                              value: 1,
                              title: "لا توجد بيانات",
                              color: Colors.grey.shade300,
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                        // 🔴 تم إزالة sectionsProvider
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
                  Text(
                    'تطور الراتب والمصروف خلال ${selectedPeriod == 'شهر' ? 'الشهر الحالي' : 'السنة الحالية'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
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
                              interval: selectedPeriod == 'شهر' ? 5 : 1,
                              getTitlesWidget: (value, meta) {
                                if (selectedPeriod == 'شهر') {
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                } else {
                                  // 🔴 إزالة 'const' لأنها ليست ثابتة في وقت التصريف بسبب الوصول إلى index
                                  final months = [
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
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      months[value.toInt() - 1],
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          // Left titles (amount values).
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval:
                                  null, // Let FlChart determine optimal interval
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  currencyFormatter.format(value),
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                              reservedSize: 60, // Reserve more space for labels
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
                        // تحديد الـ min/max Y لقيم الراتب والمصروف
                        minY: 0,
                        // 🔴 استخدام dart:math.max بشكل صحيح
                        maxY:
                            max(
                              salarySpots.isNotEmpty
                                  ? salarySpots.map((e) => e.y).reduce(max)
                                  : 0.0,
                              expenseSpots.isNotEmpty
                                  ? expenseSpots.map((e) => e.y).reduce(max)
                                  : 0.0,
                            ) *
                            1.2, // 20% فوق أكبر قيمة
                        minX: selectedPeriod == 'شهر' ? 1 : 1, // بداية المحور X
                        maxX: selectedPeriod == 'شهر'
                            ? DateTime(
                                getStartDate().year,
                                getStartDate().month + 1,
                                0,
                              ).day.toDouble()
                            : 12, // نهاية المحور X
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
                      _summaryCard('إجمالي الراتب', totalSalary, Colors.green),
                      _summaryCard('إجمالي المصروف', totalExpense, Colors.red),
                      _summaryCard('إجمالي الادخار', totalSaving, Colors.blue),
                      _summaryCard('إجمالي الدين', totalDebt, Colors.orange),
                      _summaryCard(
                        'إجمالي الائتمان',
                        totalCredit,
                        Colors.purple,
                      ),
                      _summaryCard(
                        'صافي الرصيد',
                        remainingFunds,
                        remainingFunds >= 0 ? Colors.teal : Colors.deepOrange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
