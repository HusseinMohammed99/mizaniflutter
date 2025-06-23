import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // لتنسيق الأرقام

// الوصول إلى عميل Supabase
final supabase = Supabase.instance.client;

// خريطة لربط رموز العملات بالرموز المعروضة (نفس الخريطة المستخدمة في SalarySettingPage)
const Map<String, String> currencySymbols = {
  'IQD': 'د.ع', // دينار عراقي
  'USD': '\$', // دولار أمريكي
  'EUR': '€', // يورو
  'SAR': 'ر.س', // ريال سعودي
  'AED': 'د.إ', // درهم إماراتي
  'KWD': 'د.ك', // دينار كويتي
  // أضف المزيد حسب حاجتك
};

class ViewPageWidget extends StatefulWidget {
  final List<String> filterTypes;
  final VoidCallback? onDataChanged;

  const ViewPageWidget({
    super.key,
    required this.filterTypes,
    this.onDataChanged,
  });

  @override
  State<ViewPageWidget> createState() => _ViewPageWidgetState();
}

class _ViewPageWidgetState extends State<ViewPageWidget> {
  List<Map<String, dynamic>>? transactions;
  bool _isLoading = false; // لإدارة حالة التحميل
  String? _currentUserId; // لتخزين معرف المستخدم الحالي

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
            content: Text('الرجاء تسجيل الدخول لعرض بياناتك.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        transactions = []; // لا توجد بيانات لعرضها
      });
    } else {
      loadData(); // تحميل البيانات فقط إذا كان هناك مستخدم
    }
  }

  // دالة مساعدة لتنسيق المبلغ والعملة
  String _formatAmount(double amount, String currencyCode) {
    String symbol = currencySymbols[currencyCode] ?? currencyCode;
    final formatter = NumberFormat("#,##0.00 $symbol", "ar");
    return formatter.format(amount);
  }

  Future<void> loadData() async {
    if (_currentUserId == null) return; // لا تحمل بيانات إذا لا يوجد مستخدم

    setState(() {
      _isLoading = true; // تفعيل التحميل
    });

    try {
      List<Map<String, dynamic>> allData = [];
      String table = '';

      final String userId =
          _currentUserId!; // معرف المستخدم يجب أن يكون موجوداً هنا

      if (widget.filterTypes.contains('الراتب')) {
        table = 'salaries';
        final response = await supabase
            .from(table)
            .select(
              'id, amount, currency_type, created_at, updated_at, user_id',
            )
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        allData = List<Map<String, dynamic>>.from(
          response,
        ).map((e) => {...e, 'table': table}).toList();
      } else if (widget.filterTypes.contains('المصروف')) {
        table = 'expenses';
        final response = await supabase
            .from(table)
            .select('id, amount, note, type, created_at, updated_at, user_id')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        allData = List<Map<String, dynamic>>.from(
          response,
        ).map((e) => {...e, 'table': table}).toList();
      } else if (widget.filterTypes.contains('الادخار')) {
        table = 'saving';
        final response = await supabase
            .from(table)
            .select('id, amount, note, created_at, updated_at, user_id')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        allData = List<Map<String, dynamic>>.from(
          response,
        ).map((e) => {...e, 'table': table}).toList();
      } else if (widget.filterTypes.contains('الدين')) {
        table = 'debts';
        final response = await supabase
            .from(table)
            .select(
              'id, amount, note, debtor_name, created_at, updated_at, user_id',
            )
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        allData = List<Map<String, dynamic>>.from(
          response,
        ).map((e) => {...e, 'table': table}).toList();
      } else if (widget.filterTypes.contains('الدائن')) {
        table = 'credits';
        final response = await supabase
            .from(table)
            .select(
              'id, amount, note, creditor_name, created_at, updated_at, user_id',
            )
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        allData = List<Map<String, dynamic>>.from(
          response,
        ).map((e) => {...e, 'table': table}).toList();
      } else if (widget.filterTypes.contains('الكل')) {
        // جلب جميع البيانات وفلترتها حسب user_id
        final salaries = await supabase
            .from('salaries')
            .select(
              'id, amount, currency_type, created_at, updated_at, user_id',
            )
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        final expenses = await supabase
            .from('expenses')
            .select('id, amount, note, type, created_at, updated_at, user_id')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        final saving = await supabase
            .from('saving')
            .select('id, amount, note, created_at, updated_at, user_id')
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        final debts = await supabase
            .from('debts')
            .select(
              'id, amount, note, debtor_name, created_at, updated_at, user_id',
            )
            .eq('user_id', userId)
            .order('created_at', ascending: false);
        final credits = await supabase
            .from('credits')
            .select(
              'id, amount, note, creditor_name, created_at, updated_at, user_id',
            )
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        allData = [
          ...List<Map<String, dynamic>>.from(
            salaries,
          ).map((e) => {...e, 'table': 'salaries'}),
          ...List<Map<String, dynamic>>.from(
            expenses,
          ).map((e) => {...e, 'table': 'expenses'}),
          ...List<Map<String, dynamic>>.from(
            saving,
          ).map((e) => {...e, 'table': 'saving'}),
          ...List<Map<String, dynamic>>.from(
            debts,
          ).map((e) => {...e, 'table': 'debts'}),
          ...List<Map<String, dynamic>>.from(
            credits,
          ).map((e) => {...e, 'table': 'credits'}),
        ];
      }

      if (mounted) {
        setState(() {
          transactions = allData;
        });
      }
    } on PostgrestException catch (e) {
      print('Error loading data from Supabase: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          transactions = [];
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع أثناء التحميل: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          transactions = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> deleteItem(String id, String table) async {
    if (_currentUserId == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      await supabase
          .from(table)
          .delete()
          .eq('id', id)
          .eq('user_id', _currentUserId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم الحذف بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await loadData();
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ أثناء الحذف: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ غير متوقع أثناء الحذف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }
  }

  Future<void> editItem(
    String id,
    String table,
    Map<String, dynamic> newData,
  ) async {
    if (_currentUserId == null) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      await supabase
          .from(table)
          .update(newData)
          .eq('id', id)
          .eq('user_id', _currentUserId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم التعديل بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
      await loadData();
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ أثناء التعديل: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ غير متوقع أثناء التعديل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
    if (widget.onDataChanged != null) {
      widget.onDataChanged!();
    }
  }

  void showEditDialog(Map<String, dynamic> item, String table) {
    // 🔴 التحقق من نوع البيانات وضمان أنها String للعرض في TextField
    final TextEditingController noteController = TextEditingController(
      text: (table == 'salaries'
          ? item['note']?.toString()
          : item['note']?.toString() ??
                item['type']?.toString() ??
                item['debtor_name']?.toString() ??
                item['creditor_name']?.toString() ??
                ''),
    );
    final TextEditingController amountController = TextEditingController(
      text: (item['amount'] ?? 0.0).toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('تعديل البيانات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              // 🔴 تحديد labelText ديناميكياً بناءً على الجدول
              decoration: InputDecoration(
                labelText: table == 'salaries'
                    ? 'ملاحظة'
                    : table == 'debts'
                    ? 'اسم المدين'
                    : table == 'credits'
                    ? 'اسم الدائن'
                    : 'ملاحظة / نوع',
              ),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'المبلغ'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              // 🔴 تحويل المبلغ إلى double بأمان
              final double parsedAmount =
                  double.tryParse(amountController.text) ?? 0.0;
              final Map<String, dynamic> newData = {
                'amount': parsedAmount,
                'updated_at': DateTime.now()
                    .toIso8601String(), // تحديث وقت التعديل
              };

              // 🔴 التعامل مع الأعمدة الخاصة بكل جدول
              if (table == 'salaries') {
                // جدول salaries لا يحتوي على 'note' بشكل عام، ولديه 'currency_type'
                newData['currency_type'] =
                    item['currency_type'] ??
                    'IQD'; // الاحتفاظ بالعملة الأصلية أو الافتراضية
                // إذا أردت السماح بتعديل الملاحظة، أضف عمود 'note' في جدول 'salaries'
                // newData['note'] = noteController.text;
              } else if (table == 'expenses' || table == 'saving') {
                newData['note'] = noteController.text;
                if (table == 'expenses' && item.containsKey('type')) {
                  // إذا كان المصروف له 'type'، قد تحتاج لإضافة حقل منفصل له
                  newData['type'] = item['type']; // الاحتفاظ بالنوع الأصلي
                }
              } else if (table == 'debts') {
                newData['debtor_name'] =
                    noteController.text; // حقل الملاحظة يستخدم لاسم المدين
              } else if (table == 'credits') {
                newData['creditor_name'] =
                    noteController.text; // حقل الملاحظة يستخدم لاسم الدائن
              }

              editItem(item['id'].toString(), table, newData);
              Navigator.pop(dialogContext);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions == null || transactions!.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'لا توجد بيانات لعرضها.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  if (_currentUserId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'البيانات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.builder(
                        itemCount: transactions!.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = transactions![index];
                          final table = item['table'] ?? '';

                          String titleText = '';
                          String subtitleText = '';
                          // 🔴 تحويل المبلغ إلى double بأمان
                          final double amount =
                              double.tryParse(item['amount'].toString()) ?? 0.0;

                          if (table == 'salaries') {
                            final String currency =
                                item['currency_type'] as String? ?? 'IQD';
                            titleText = 'راتب';
                            subtitleText = _formatAmount(amount, currency);
                          } else if (table == 'expenses') {
                            final String note = item['note'] as String? ?? '';
                            final String type = item['type'] as String? ?? '';
                            titleText = type.isNotEmpty ? type : note;
                            subtitleText =
                                '${_formatAmount(amount, 'IQD')} - $note';
                          } else if (table == 'saving') {
                            final String note = item['note'] as String? ?? '';
                            titleText = 'ادخار';
                            subtitleText =
                                '${_formatAmount(amount, 'IQD')} - $note';
                          } else if (table == 'debts') {
                            final String debtorName =
                                item['debtor_name'] as String? ?? '';
                            titleText = 'دين على: $debtorName';
                            subtitleText = _formatAmount(amount, 'IQD');
                          } else if (table == 'credits') {
                            final String creditorName =
                                item['creditor_name'] as String? ?? '';
                            titleText = 'دائن لـ: $creditorName';
                            subtitleText = _formatAmount(amount, 'IQD');
                          } else {
                            titleText =
                                item['id']?.toString() ?? 'بيانات غير معروفة';
                            subtitleText = 'الجدول: $table';
                            if (item.containsKey('amount')) {
                              subtitleText += ' | المبلغ: ${item['amount']}';
                            }
                          }

                          return ListTile(
                            leading: const Icon(Icons.attach_money),
                            title: Text(titleText),
                            subtitle: Text(subtitleText),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  // 🔴 التأكد من أن الـ ID من نوع String
                                  onPressed: () => showEditDialog(item, table),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  // 🔴 التأكد من أن الـ ID من نوع String
                                  onPressed: () =>
                                      deleteItem(item['id'].toString(), table),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
