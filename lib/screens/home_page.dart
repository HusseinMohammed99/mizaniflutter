// mizaniflutter/screens/home_page.dart

import 'package:flutter/material.dart';
import 'package:mizaniflutter/compount/card_widget.dart';
import 'package:mizaniflutter/compount/view_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final formatter = NumberFormat("#,##0.00", "ar");
TextEditingController t = TextEditingController(); // يستخدم لعرض رسالة التحذير

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

  String? _currentUserId; // 🔴 لتخزين معرف المستخدم الحالي

  @override
  void initState() {
    super.initState();
    _currentUserId =
        supabase.auth.currentUser?.id; // جلب معرف المستخدم عند تهيئة الـ Widget
    if (_currentUserId == null) {
      // إذا لم يكن هناك مستخدم مسجل دخول، اعرض رسالة
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول لعرض بياناتك المالية.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      // يمكن تعيين القيم إلى صفر أو إظهار حالة فارغة
      setState(() {
        totalSalary = 0;
        totalExpense = 0;
        netSalary = 0;
        saving = 0;
        debts = 0;
        credits = 0;
      });
    } else {
      fetchTotals(); // تحميل البيانات فقط إذا كان هناك مستخدم
    }
  }

  // 🔴 دالة جلب الإجماليات التي تقوم بفلترة البيانات حسب user_id
  Future<void> fetchTotals() async {
    if (_currentUserId == null) return; // لا تحمل بيانات إذا لا يوجد مستخدم

    final String userId =
        _currentUserId!; // معرف المستخدم يجب أن يكون موجوداً هنا

    try {
      // 🔴 فلترة جميع الاستعلامات حسب user_id
      final salaries = await supabase
          .from('salaries')
          .select('amount')
          .eq('user_id', userId);
      final expenses = await supabase
          .from('expenses')
          .select('amount')
          .eq('user_id', userId);
      final savingData = await supabase
          .from('saving')
          .select('amount')
          .eq('user_id', userId);
      final debtsData = await supabase
          .from('debts')
          .select('amount')
          .eq('user_id', userId);
      final creditsData = await supabase
          .from('credits')
          .select('amount')
          .eq('user_id', userId);

      double calculatedTotalSalary = 0;
      double calculatedTotalExpense = 0;
      double calculatedTotalSaving = 0;
      double calculatedTotalDebts = 0;
      double calculatedTotalCredits = 0;

      // 🔴 استخدام for-in loop لتحويل القيم بأمان
      for (var item in salaries) {
        final amt = item['amount'];
        if (amt is num) {
          calculatedTotalSalary += amt.toDouble();
        } else if (amt is String) {
          calculatedTotalSalary += double.tryParse(amt) ?? 0;
        }
      }

      for (var item in expenses) {
        final amt = item['amount'];
        if (amt is num) {
          calculatedTotalExpense += amt.toDouble();
        } else if (amt is String) {
          calculatedTotalExpense += double.tryParse(amt) ?? 0;
        }
      }

      for (var item in savingData) {
        final amt = item['amount'];
        if (amt is num) {
          calculatedTotalSaving += amt.toDouble();
        } else if (amt is String) {
          calculatedTotalSaving += double.tryParse(amt) ?? 0;
        }
      }

      for (var item in debtsData) {
        final amt = item['amount'];
        if (amt is num) {
          calculatedTotalDebts += amt.toDouble();
        } else if (amt is String) {
          calculatedTotalDebts += double.tryParse(amt) ?? 0;
        }
      }

      for (var item in creditsData) {
        final amt = item['amount'];
        if (amt is num) {
          calculatedTotalCredits += amt.toDouble();
        } else if (amt is String) {
          calculatedTotalCredits += double.tryParse(amt) ?? 0;
        }
      }

      // Show warning if expenses exceed 70% of salary
      if (calculatedTotalSalary > 0 &&
          calculatedTotalExpense > calculatedTotalSalary * 0.7) {
        if (mounted) {
          t.text = '⚠️ تحذير: المصروفات تجاوزت 70% من الراتب';
        }
      } else {
        if (mounted) {
          t.text = ''; // مسح التحذير إذا لم يكن هناك تجاوز
        }
      }

      final calculatedNetSalary =
          calculatedTotalSalary -
          calculatedTotalExpense -
          calculatedTotalSaving -
          calculatedTotalDebts -
          calculatedTotalCredits;

      if (mounted) {
        // 🔴 تحقق من mounted قبل setState
        setState(() {
          totalSalary = calculatedTotalSalary;
          totalExpense = calculatedTotalExpense;
          saving = calculatedTotalSaving;
          debts = calculatedTotalDebts;
          credits = calculatedTotalCredits;
          netSalary = calculatedNetSalary;
        });
      }
    } on PostgrestException catch (e) {
      // 🔴 التعامل مع أخطاء Supabase
      print('Error fetching totals from Supabase: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في جلب الإجماليات: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // تعيين القيم إلى صفر في حالة الخطأ
      if (mounted) {
        setState(() {
          totalSalary = 0;
          totalExpense = 0;
          netSalary = 0;
          saving = 0;
          debts = 0;
          credits = 0;
          t.text = 'خطأ في تحميل البيانات.';
        });
      }
    } catch (e) {
      print('Error fetching totals: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع أثناء جلب الإجماليات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // تعيين القيم إلى صفر في حالة الخطأ
      if (mounted) {
        setState(() {
          totalSalary = 0;
          totalExpense = 0;
          netSalary = 0;
          saving = 0;
          debts = 0;
          credits = 0;
          t.text = 'خطأ في تحميل البيانات.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        height: 50,
        child: Center(
          // 🔴 توسيط رسالة التحذير
          child: Text(
            t.text,
            style: TextStyle(
              color: t.text.startsWith('⚠️')
                  ? Colors.orange
                  : Colors.black, // لون التحذير
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
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
                filterTypes: const ['الكل'], // 🔴 يمكن تغيير الفلتر هنا
                onDataChanged:
                    fetchTotals, // تحديث الإجماليات عند تغيير البيانات في ViewPageWidget
              ),
            ),
          ],
        ),
      ),
    );
  }
}
