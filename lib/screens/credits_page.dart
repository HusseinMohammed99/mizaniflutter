import 'package:flutter/material.dart';
import 'package:mizaniflutter/compount/view_page.dart'; // تأكد من المسار الصحيح لـ ViewPageWidget
import 'package:supabase_flutter/supabase_flutter.dart';

// الوصول إلى عميل Supabase المهيأ عالمياً
final supabase = Supabase.instance.client;

class CreditsPage extends StatefulWidget {
  const CreditsPage({super.key});

  @override
  State<CreditsPage> createState() => _CreditsPageState();
}

class _CreditsPageState extends State<CreditsPage> {
  // 🔴 متحكمات حقول الإدخال يجب أن تكون داخل حالة الـ Widget (_CreditsPageState)
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _creditorNameController =
      TextEditingController(); // تم تغيير الاسم ليكون 'creditor_name'

  String? _currentUserId; // لتخزين معرف المستخدم الحالي
  bool _isLoadingAdd = false; // حالة تحميل لعملية إضافة الائتمان
  String _selectedCurrencyCode =
      'IQD'; // لتخزين العملة التي تم جلبها من جدول الرواتب

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id; // جلب معرف المستخدم
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول لإدارة الائتمانات.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } else {
      _loadCurrency(); // 🔴 تحميل العملة المحفوظة للمستخدم
    }
  }

  @override
  void dispose() {
    // 🔴 يجب التخلص من المتحكمات عند التخلص من الـ Widget
    _amountController.dispose();
    _creditorNameController.dispose();
    super.dispose();
  }

  // 🔴 دالة لتحميل العملة المحفوظة للمستخدم من جدول 'salaries'
  Future<void> _loadCurrency() async {
    if (_currentUserId == null) return;

    try {
      final List<Map<String, dynamic>> response = await supabase
          .from('salaries')
          .select('currency_type')
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false) // جلب أحدث إدخال للراتب
          .limit(1);

      if (mounted) {
        setState(() {
          if (response.isNotEmpty) {
            _selectedCurrencyCode =
                (response[0]['currency_type'] as String?) ?? 'IQD';
          } else {
            _selectedCurrencyCode =
                'IQD'; // استخدام الافتراضي إذا لم يتم العثور على راتب
          }
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل العملة: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _selectedCurrencyCode = 'IQD'; // fallback
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع في تحميل العملة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _selectedCurrencyCode = 'IQD'; // fallback
    }
  }

  // 🔴 دالة لإضافة الائتمان مع العملة
  Future<void> _addCredit() async {
    // تم تغيير الاسم ليكون أكثر دقة
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول لإضافة ائتمان.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoadingAdd = true; // تفعيل حالة التحميل
    });

    final String amountText = _amountController.text.trim();
    final double? amountValue = double.tryParse(amountText);
    final String creditorName = _creditorNameController.text
        .trim(); // استخدام _creditorNameController

    if (amountValue == null || amountValue <= 0 || creditorName.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء إدخال مبلغ صحيح واسم الدائن.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        _isLoadingAdd = false;
      });
      return;
    }

    try {
      await supabase.from('credits').insert({
        'user_id': _currentUserId!,
        'amount': amountValue, // 🔴 تمرير كـ double (تأكد من نوع العمود في DB)
        'creditor_name': creditorName, // 🔴 حفظ اسم الدائن
        // 'type': 'مدين', // هذا العمود ربما غير موجود في جدول credits، أو يمكن أن يكون 'type' هو 'creditor_name'
        'currency_type': _selectedCurrencyCode, // 🔴 حفظ العملة المحفوظة هنا
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تمت الإضافة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _amountController.clear();
      _creditorNameController.clear();
      setState(() {});
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في إضافة الائتمان: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ حدث خطأ غير متوقع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAdd = false; // تعطيل حالة التحميل دائماً
        });
      }
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
                    onPressed: _isLoadingAdd
                        ? null
                        : _addCredit, // 🔴 استدعاء _addCredit
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: _isLoadingAdd
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.add, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 10), // مسافة بين الزر والحقل
                Expanded(
                  child: TextField(
                    controller:
                        _amountController, // 🔴 استخدام _amountController
                    keyboardType: TextInputType.number, // لوحة مفاتيح رقمية
                    decoration: InputDecoration(
                      labelText: "المبلغ",
                      hintText: "أدخل المبلغ",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller:
                        _creditorNameController, // 🔴 استخدام _creditorNameController
                    decoration: InputDecoration(
                      labelText: "اسم الدائن", // تغيير التسمية إلى "اسم الدائن"
                      hintText: "أدخل اسم الدائن",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // مسافة بين حقول الإدخال وقائمة العرض
            Expanded(child: ViewPageWidget(filterTypes: const ['الدائن'])),
          ],
        ),
      ),
    );
  }
}
