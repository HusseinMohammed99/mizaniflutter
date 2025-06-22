import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class ViewPageWidget extends StatefulWidget {
  final List<String> filterTypes;
  final VoidCallback? onDataChanged; // ⬅️ هذا الجديد

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

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      List<Map<String, dynamic>> allData = [];
      String table = '';

      if (widget.filterTypes.contains('الراتب')) {
        table = 'salaries';
      } else if (widget.filterTypes.contains('المصروف')) {
        table = 'expenses';
      } else if (widget.filterTypes.contains('الادخار')) {
        table = 'saving';
      } else if (widget.filterTypes.contains('الدين')) {
        table = 'debts';
      } else if (widget.filterTypes.contains('الدائن')) {
        table = 'credits';
      } else if (widget.filterTypes.contains('الكل')) {
        final salaries = await supabase.from('salaries').select();
        final expenses = await supabase.from('expenses').select();
        final saving = await supabase.from('saving').select();
        final debts = await supabase.from('debts').select();
        final credits = await supabase.from('credits').select();

        // أضف مفتاح 'table' لكل عنصر لتحديد مصدره لاحقاً
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

        setState(() {
          transactions = allData;
        });
        return;
      }

      if (table.isNotEmpty) {
        final response = await supabase.from(table).select();
        allData = List<Map<String, dynamic>>.from(
          response,
        ).map((e) => {...e, 'table': table}).toList();
      }

      setState(() {
        transactions = allData;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        transactions = [];
      });
    }
  }

  Future<void> deleteItem(int id, String table) async {
    try {
      await supabase.from(table).delete().eq('id', id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ تم الحذف بنجاح')));

      await loadData(); // ⬅️ تحدث البيانات بعد الحذف
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ خطأ أثناء الحذف: $e')));
    }
    if (widget.onDataChanged != null) {
      widget.onDataChanged!(); // ⬅️ إشعار الصفحة الرئيسية بالتحديث
    }
  }

  Future<void> editItem(
    int id,
    String table,
    Map<String, dynamic> newData,
  ) async {
    try {
      await supabase.from(table).update(newData).eq('id', id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ تم التعديل بنجاح')));

      await loadData(); // ⬅️ تحدث البيانات بعد التعديل
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ خطأ أثناء التعديل: $e')));
    }
    if (widget.onDataChanged != null) {
      widget.onDataChanged!(); // ⬅️ إشعار الصفحة الرئيسية بالتحديث
    }
  }

  void showEditDialog(Map<String, dynamic> item, String table) {
    final TextEditingController typeController = TextEditingController(
      text: item['note'] ?? '', // 'note' or 'type'? Consistent naming is good.
    );
    final TextEditingController amountController = TextEditingController(
      text: item['amount'].toString(),
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل البيانات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: 'النوع'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'المبلغ'),
              keyboardType:
                  TextInputType.number, // ⬅️ تأكد من نوع لوحة المفاتيح
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final double? parsedAmount = double.tryParse(
                amountController.text,
              );

              // 🔴 هنا التعديل الرئيسي:
              // إذا كان عمود 'amount' في قاعدة البيانات هو 'bigint'، يجب تحويله إلى int.
              // إذا كان 'DOUBLE PRECISION' أو 'NUMERIC'، يمكن إرساله كـ double.
              // الافتراض هنا أنك تريد إرساله كـ int ليتوافق مع 'bigint'.
              final dynamic amountToSend;
              if (parsedAmount != null) {
                amountToSend = parsedAmount.toInt(); // تحويل إلى عدد صحيح
              } else {
                amountToSend = 0; // قيمة افتراضية إذا لم يتمكن من التحويل
              }

              final newData = {
                // تأكد من أن المفتاح هنا يطابق اسم العمود في قاعدة البيانات.
                // في بعض الأحيان قد يكون 'type' أو 'note' أو غير ذلك.
                // بناءً على كودك السابق، يبدو أنه 'note' في الـ ListTile، ولكن في newData هو 'type'.
                // يرجى التحقق من اسم العمود الفعلي في قاعدة البيانات.
                'note': typeController
                    .text, // أو 'type': typeController.text، حسب اسم عمودك
                'amount': amountToSend,
              };
              editItem(item['id'], table, newData);
              Navigator.pop(context);
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
      child: transactions == null
          ? const Center(child: CircularProgressIndicator())
          : transactions!.isEmpty
          ? const Center(
              child: Text(
                'لا توجد بيانات',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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

                          return ListTile(
                            leading: const Icon(Icons.attach_money),
                            title: Text(
                              item['note'] ?? '',
                            ), // قد يكون 'note' أو 'name' أو 'description'
                            subtitle: Text(
                              // تأكد من أن مفاتيح البيانات هنا مطابقة للأسماء الفعلية في Supabase
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
