import 'package:flutter/material.dart';
import 'package:mizaniflutter/compount/view_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SavingPage extends StatefulWidget {
  const SavingPage({super.key});

  @override
  State<SavingPage> createState() => _SavingPageState();
}

TextEditingController mycontroller = TextEditingController();
TextEditingController mytypecontroller = TextEditingController();
final userId = Supabase.instance.client.auth.currentUser?.id;

class _SavingPageState extends State<SavingPage> {
  Future<void> addExpense(String name) async {
    try {
      final response = await supabase.from('saving').insert({
        'user_id': userId,
        'amount': name,
        'note': mytypecontroller.text,
        'type': 'ادخار',
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('✅ تمت الإضافة بنجاح')));

      mycontroller.clear();
      mytypecontroller.clear();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ حدث خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("صفحة الادخار"), centerTitle: true),
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
                const SizedBox(width: 10), // مسافة بين الزر والحقل
                Expanded(
                  child: TextField(
                    controller: mycontroller,
                    decoration: InputDecoration(
                      labelText: "ادخر",
                      hintText: "أدخل  المبلغ",
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
                      labelText: "نوع الدخر",
                      hintText: "أدخل  نوع الدخل",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(child: ViewPageWidget(filterTypes: ['الادخار'])),
          ],
        ),
      ),
    );
  }
}
