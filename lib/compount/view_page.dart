import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

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
            .select()
            .eq('user_id', userId); // 🔴 فلترة حسب user_id
        allData = List<Map<String, dynamic>>.from(
          response,
        ).map((e) => {...e, 'table': table}).toList();
      } else if (widget.filterTypes.contains('المصروف')) {
        table = 'expenses';
        final response = await supabase
            .from(table)
            .select()
            .eq('user_id', userId); // 🔴 فلترة حسب user_id
        allData = List<Map<String, dynamic>>.from(
          response,
        ).map((e) => {...e, 'table': table}).toList();
      } else if (widget.filterTypes.contains('الادخار')) {
        table = 'saving';
        final response = await supabase
            .from(table)
            .select()
            .eq('user_id', userId); // 🔴 فلترة حسب user_id
        allData = List<Map<String, dynamic>>.from(
          response,
        ).map((e) => {...e, 'table': table}).toList();
      } else if (widget.filterTypes.contains('الدين')) {
        table = 'debts';
        final response = await supabase
            .from(table)
            .select()
            .eq('user_id', userId); // 🔴 فلترة حسب user_id
        allData = List<Map<String, dynamic>>.from(
          response,
        ).map((e) => {...e, 'table': table}).toList();
      } else if (widget.filterTypes.contains('الدائن')) {
        table = 'credits';
        final response = await supabase
            .from(table)
            .select()
            .eq('user_id', userId); // 🔴 فلترة حسب user_id
        allData = List<Map<String, dynamic>>.from(
          response,
        ).map((e) => {...e, 'table': table}).toList();
      } else if (widget.filterTypes.contains('الكل')) {
        // جلب جميع البيانات وفلترتها حسب user_id
        final salaries = await supabase
            .from('salaries')
            .select()
            .eq('user_id', userId);
        final expenses = await supabase
            .from('expenses')
            .select()
            .eq('user_id', userId);
        final saving = await supabase
            .from('saving')
            .select()
            .eq('user_id', userId);
        final debts = await supabase
            .from('debts')
            .select()
            .eq('user_id', userId);
        final credits = await supabase
            .from('credits')
            .select()
            .eq('user_id', userId);

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

  Future<void> deleteItem(int id, String table) async {
    if (_currentUserId == null) return; // لا تسمح بالحذف إذا لا يوجد مستخدم

    if (mounted) {
      setState(() {
        _isLoading = true; // تفعيل التحميل للحذف
      });
    }
    try {
      // 🔴 حذف السجل إذا كان الـ id متطابقاً وينتمي للمستخدم الحالي
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
      await loadData(); // تحدث البيانات بعد الحذف
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
    int id,
    String table,
    Map<String, dynamic> newData,
  ) async {
    if (_currentUserId == null) return; // لا تسمح بالتعديل إذا لا يوجد مستخدم

    if (mounted) {
      setState(() {
        _isLoading = true; // تفعيل التحميل للتعديل
      });
    }
    try {
      // 🔴 تحديث السجل إذا كان الـ id متطابقاً وينتمي للمستخدم الحالي
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
      await loadData(); // تحدث البيانات بعد التعديل
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
    final TextEditingController noteController = TextEditingController(
      text: item['note'] ?? '', // 'note' هو الاسم المتوقع للعمود
    );
    final TextEditingController amountController = TextEditingController(
      text: item['amount'].toString(),
    );

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        // استخدام dialogContext منفصل
        title: const Text('تعديل البيانات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'ملاحظة / نوع'),
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
            onPressed: () =>
                Navigator.pop(dialogContext), // استخدام dialogContext
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final double? parsedAmount = double.tryParse(
                amountController.text,
              );
              final dynamic amountToSend;
              if (parsedAmount != null) {
                // 🔴 إذا كان عمود 'amount' في قاعدة البيانات هو 'bigint'، حوله إلى int.
                // إذا كان 'DOUBLE PRECISION' أو 'NUMERIC'، يمكن إرساله كـ double.
                // الافتراض هنا أنك تريد إرساله كـ int ليتوافق مع 'bigint'.
                amountToSend = parsedAmount.toInt();
              } else {
                amountToSend = 0;
              }

              final newData = {
                'note': noteController
                    .text, // استخدم 'note' أو 'type' حسب اسم العمود الفعلي
                'amount': amountToSend,
              };
              editItem(item['id'], table, newData);
              Navigator.pop(dialogContext); // استخدام dialogContext
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
      child:
          _isLoading // عرض مؤشر التحميل عندما تكون البيانات قيد التحميل
          ? const Center(child: CircularProgressIndicator())
          : transactions == null ||
                transactions!
                    .isEmpty // التحقق من عدم وجود بيانات
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'لا توجد بيانات لعرضها.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  if (_currentUserId !=
                      null) // عرض معرف المستخدم فقط إذا كان موجوداً
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: SelectableText(
                            // لجعل الـ ID قابلاً للنسخ
                            'معرف المستخدم: \n${_currentUserId!}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.blueGrey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                      if (_currentUserId !=
                          null) // عرض معرف المستخدم في أعلى البطاقة
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          // child: SelectableText(
                          //   'معرف المستخدم: \n${_currentUserId!}',
                          //   textAlign: TextAlign.start,
                          //   style: const TextStyle(
                          //     fontSize: 14,
                          //     color: Colors.blueGrey,
                          //     fontWeight: FontWeight.bold,
                          //   ),
                          // ),
                        ),
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

                          return ListTile(
                            leading: const Icon(Icons.attach_money),
                            title: Text(item['note'] ?? ''),
                            subtitle: Text(
                              '${item['type'] ?? ''} - ${item['amount'] ?? ''} د.ع',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () => showEditDialog(item, table),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () =>
                                      deleteItem(item['id'], table),
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
