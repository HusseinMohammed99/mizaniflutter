import 'package:flutter/material.dart';
import 'package:mizaniflutter/compount/view_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeposidPage extends StatefulWidget {
  final VoidCallback? onDataChanged; // ✅ دالة التحديث

  const DeposidPage({super.key, this.onDataChanged});

  @override
  State<DeposidPage> createState() => _DeposidPageState();
}

TextEditingController mycontroller = TextEditingController();
TextEditingController mytypecontroller = TextEditingController();

class _DeposidPageState extends State<DeposidPage> {
  final supabase = Supabase.instance.client;

  Future<void> addExpense(String name) async {
    try {
      await supabase.from('salaries').insert({
        'amount': name,
        'note': mytypecontroller.text,
        'type': 'إيداع',
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ تمت الإضافة بنجاح')));

      mycontroller.clear();
      mytypecontroller.clear();

      // ✅ تحديث الصفحة الرئيسية
      if (widget.onDataChanged != null) {
        widget.onDataChanged!();
      }

      setState(() {
        ViewPageWidget;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('❌ حدث خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("صفحة إيداع"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  height: 50,
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      addExpense(mycontroller.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: mycontroller,
                    decoration: InputDecoration(
                      labelText: "الراتب",
                      hintText: "أدخل المبلغ",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: mytypecontroller,
                    decoration: InputDecoration(
                      labelText: "نوع الراتب",
                      hintText: "أدخل نوع الراتب",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(child: ViewPageWidget(filterTypes: ['الراتب'])),
          ],
        ),
      ),
    );
  }
}
