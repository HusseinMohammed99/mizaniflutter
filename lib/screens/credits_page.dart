import 'package:flutter/material.dart';
import 'package:mizaniflutter/compount/view_page.dart';

class CreditsPage extends StatefulWidget {
  const CreditsPage({super.key});

  @override
  State<CreditsPage> createState() => _CreditsPageState();
}

TextEditingController mycontroller = TextEditingController();
TextEditingController mytypecontroller = TextEditingController();

class _CreditsPageState extends State<CreditsPage> {
  Future<void> addExpense(String name) async {
    try {
      final response = await supabase.from('credits').insert({
        'amount': name,
        'note': mytypecontroller.text,
        'type': 'مدين',
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
      appBar: AppBar(title: const Text("صفحة الدائن"), centerTitle: true),
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
                      labelText: "دائن",
                      hintText: "أدخل المبلغ ",
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
                      labelText: "نوع دائن",
                      hintText: "أدخل نوع دائن",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Expanded(child: ViewPageWidget(filterTypes: ['دائن'])),
          ],
        ),
      ),
    );
  }
}
