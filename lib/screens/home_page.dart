// mizaniflutter/screens/home_page.dart

import 'package:flutter/material.dart';
import 'package:mizaniflutter/compount/card_widget.dart';
import 'package:mizaniflutter/compount/view_page.dart';
// import 'package:mizaniflutter/main.dart'; // 🔴 لم نعد بحاجة لهذا الاستيراد هنا
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final formatter = NumberFormat("#,##0.00", "ar");
TextEditingController t = TextEditingController();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  double totalSalary = 0;
  double totalExpense = 0;
  double netSalary = 0;
  double saving = 0;
  double debts = 0;
  double credits = 0;

  @override
  void initState() {
    super.initState();
    fetchTotals();
  }

  Future<void> fetchTotals() async {
    try {
      final salaries = await supabase.from('salaries').select('amount');
      final expenses = await supabase.from('expenses').select('amount');
      final savingData = await supabase.from('saving').select('amount');
      final debtsData = await supabase.from('debts').select('amount');
      final creditsData = await supabase.from('credits').select('amount');

      double totalSalary = 0;
      double totalExpense = 0;
      double totalSaving = 0;
      double totalDebts = 0;
      double totalCredits = 0;

      for (var item in salaries) {
        final amt = item['amount'];
        if (amt is num) {
          totalSalary += amt.toDouble();
        } else if (amt is String) {
          totalSalary += double.tryParse(amt) ?? 0;
        }
      }

      for (var item in expenses) {
        final amt = item['amount'];
        if (amt is num) {
          totalExpense += amt.toDouble();
        } else if (amt is String) {
          totalExpense += double.tryParse(amt) ?? 0;
        }
      }

      for (var item in savingData) {
        final amt = item['amount'];
        if (amt is num) {
          totalSaving += amt.toDouble();
        } else if (amt is String) {
          totalSaving += double.tryParse(amt) ?? 0;
        }
      }

      for (var item in debtsData) {
        final amt = item['amount'];
        if (amt is num) {
          totalDebts += amt.toDouble();
        } else if (amt is String) {
          totalDebts += double.tryParse(amt) ?? 0;
        }
      }

      for (var item in creditsData) {
        final amt = item['amount'];
        if (amt is num) {
          totalCredits += amt.toDouble();
        } else if (amt is String) {
          totalCredits += double.tryParse(amt) ?? 0;
        }
      }
      // Show warning if expenses exceed 70% of salary
      if (totalSalary > 0 && totalExpense > totalSalary * 0.7) {
        if (mounted) {
          t.text = '⚠️ تحذير: المصروفات تجاوزت 70% من الراتب';
          // Check if the widget is still in the tree
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('⚠️ تحذير: المصروفات تجاوزت 70% من الراتب'),
          //   ),
          // );
        }
      }
      final netSalary =
          totalSalary - totalExpense - totalSaving - totalDebts - totalCredits;

      setState(() {
        this.totalSalary = totalSalary;
        this.totalExpense = totalExpense;
        saving = totalSaving;
        debts = totalDebts;
        credits = totalCredits;
        this.netSalary = netSalary;
      });
    } catch (e) {
      print('Error fetching totals: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(height: 50, child: Text(t.text)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  CardWidget(
                    textname: "صافي الراتب",
                    textMony: formatter.format(netSalary),
                  ),
                  CardWidget(
                    textname: "الادخار",
                    textMony: formatter.format(saving),
                  ),
                  CardWidget(
                    textname: "المصروف",
                    textMony: formatter.format(totalExpense),
                  ),
                  CardWidget(
                    textname: "الراتب",
                    textMony: formatter.format(totalSalary),
                  ),
                  CardWidget(
                    textname: "الدين",
                    textMony: formatter.format(debts),
                  ),
                  CardWidget(
                    textname: "الائتمان",
                    textMony: formatter.format(credits),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ViewPageWidget(
                filterTypes: ['الكل'],
                onDataChanged: fetchTotals,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
