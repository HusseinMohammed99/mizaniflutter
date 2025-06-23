import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // لتنسيق الأرقام
import 'dart:math'; // لاستخدام max لتحديد أعلى قيمة للراتب في الشريط

// الوصول إلى عميل Supabase المهيأ عالمياً
final supabase = Supabase.instance.client;

// 🔴 خريطة لربط رموز العملات بالرموز المعروضة (يمكنك إضافة المزيد)
const Map<String, String> currencySymbols = {
  'IQD': 'د.ع', // دينار عراقي
  'USD': '\$', // دولار أمريكي
  'EUR': '€', // يورو
  'SAR': 'ر.س', // ريال سعودي
  'AED': 'د.إ', // درهم إماراتي
  'KWD': 'د.ك', // دينار كويتي
  // أضف المزيد حسب حاجتك
};

class SalarySettingPage extends StatefulWidget {
  const SalarySettingPage({super.key});

  @override
  State<SalarySettingPage> createState() => _SalarySettingPageState();
}

class _SalarySettingPageState extends State<SalarySettingPage> {
  final TextEditingController _salaryController = TextEditingController();
  bool _isLoading = false;
  String? _currentUserId; // لتخزين معرف المستخدم الحالي
  double _currentSalaryDisplay = 0.0; // لعرض الراتب الحالي بعد التحميل/الحفظ
  String _selectedCurrencyCode =
      'IQD'; // 🔴 رمز العملة المحدد افتراضياً (للتخزين)

  // 🔴 تنسيق العملة ديناميكياً
  NumberFormat get _currencyFormatter {
    String symbol =
        currencySymbols[_selectedCurrencyCode] ?? _selectedCurrencyCode;
    // يمكن تعديل التنسيق بناءً على العملة، مثلاً عدد المنازل العشرية
    return NumberFormat("#,##0.00 $symbol", "ar");
  }

  @override
  void initState() {
    super.initState();
    _currentUserId = supabase.auth.currentUser?.id; // جلب معرف المستخدم
    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء تسجيل الدخول لإدارة الراتب.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    } else {
      _loadSalary(); // تحميل الراتب الموجود
    }
  }

  @override
  void dispose() {
    _salaryController.dispose();
    super.dispose();
  }

  // دالة لتحميل الراتب الشهري والعملة للمستخدم من جدول 'salaries'
  Future<void> _loadSalary() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> response = await supabase
          .from('salaries')
          .select('id, amount, currency_type') // 🔴 جلب currency_type أيضاً
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false)
          .limit(1);

      if (mounted) {
        setState(() {
          if (response.isNotEmpty) {
            _salaryController.text = (response[0]['amount'] ?? 0.0).toString();
            _currentSalaryDisplay = (response[0]['amount'] ?? 0.0).toDouble();
            // 🔴 تحديث رمز العملة المحدد
            _selectedCurrencyCode =
                (response[0]['currency_type'] as String?) ?? 'IQD';
            // التأكد من أن رمز العملة موجود في الخريطة، وإلا نستخدم الافتراضي
            if (!currencySymbols.containsKey(_selectedCurrencyCode)) {
              _selectedCurrencyCode = 'IQD';
            }
          } else {
            _salaryController.text = '0.0';
            _currentSalaryDisplay = 0.0;
            _selectedCurrencyCode = 'IQD'; // تعيين افتراضي إذا لا يوجد سجل
          }
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل الراتب: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع في التحميل: $e'),
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
  }

  // دالة لحفظ الراتب الشهري والعملة في جدول 'salaries'
  Future<void> _saveSalary() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    final String salaryText = _salaryController.text.trim();
    final double? salaryValue = double.tryParse(salaryText);

    if (salaryValue == null || salaryValue < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('الرجاء إدخال راتب صحيح (رقم موجب).'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // 🔴 البحث عن سجل الراتب الموجود للمستخدم (الأحدث)
      final List<Map<String, dynamic>> existingSalaries = await supabase
          .from('salaries')
          .select('id') // نحتاج الـ ID لتحديث السجل الموجود
          .eq('user_id', _currentUserId!)
          .order('created_at', ascending: false)
          .limit(1);

      if (existingSalaries.isNotEmpty) {
        // 🔴 استخدام toString() لضمان التحويل إلى String بغض النظر عن النوع الأساسي
        final String salaryRecordId = existingSalaries[0]['id'].toString();
        await supabase
            .from('salaries')
            .update({
              'amount': salaryValue,
              'currency_type': _selectedCurrencyCode, // حفظ رمز العملة
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', salaryRecordId); // تحديث السجل باستخدام الـ ID الخاص به
      } else {
        // إذا لم يوجد سجل، قم بإدخال سجل جديد
        await supabase.from('salaries').insert({
          'user_id': _currentUserId!,
          'amount': salaryValue,
          'currency_type': _selectedCurrencyCode, // حفظ رمز العملة
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      if (mounted) {
        setState(() {
          _currentSalaryDisplay = salaryValue; // تحديث قيمة العرض
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الراتب بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حفظ الراتب: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع في الحفظ: $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إعداد الراتب الشهري'),
          centerTitle: true,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              'يرجى تسجيل الدخول لتحديد راتبك الشهري.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
    final textFieldWidth = cardWidth * 0.9;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إعداد الراتب الشهري',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.blueGrey,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blueGrey),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(35.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 80,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 35),

                            // 🔴 حقل إدخال الراتب الشهري
                            SizedBox(
                              width: textFieldWidth,
                              child: TextField(
                                controller: _salaryController,
                                decoration: InputDecoration(
                                  labelText: 'الراتب الشهري',
                                  hintText: 'ادخل راتبك الشهري',
                                  prefixIcon: const Icon(
                                    Icons.monetization_on_outlined,
                                    color: Colors.green,
                                  ),
                                  suffixText:
                                      currencySymbols[_selectedCurrencyCode], // 🔴 عرض رمز العملة المحدد ديناميكياً
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Theme.of(
                                        context,
                                      ).inputDecorationTheme.fillColor ??
                                      Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blueAccent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _currentSalaryDisplay =
                                        double.tryParse(value) ?? 0.0;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 🔴 قائمة منسدلة لاختيار العملة
                            SizedBox(
                              width: textFieldWidth,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCurrencyCode,
                                decoration: InputDecoration(
                                  labelText: 'نوع العملة',
                                  prefixIcon: const Icon(
                                    Icons.currency_exchange_outlined,
                                    color: Colors.blueGrey,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor:
                                      Theme.of(
                                        context,
                                      ).inputDecorationTheme.fillColor ??
                                      Colors.grey.shade100,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 12,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.blueAccent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                items: currencySymbols.keys.map((String code) {
                                  return DropdownMenuItem<String>(
                                    value: code,
                                    child: Text(
                                      '$code - ${currencySymbols[code]}',
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    setState(() {
                                      _selectedCurrencyCode = newValue;
                                    });
                                  }
                                },
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 35),

                            // 🔴 زر حفظ الراتب
                            SizedBox(
                              width: textFieldWidth,
                              child: ElevatedButton(
                                onPressed: _saveSalary,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  elevation: 8,
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                child: const Text("حفظ الراتب"),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // عرض الراتب الحالي بتنسيق جميل
                            Text(
                              'الراتب الحالي: ${_currencyFormatter.format(_currentSalaryDisplay)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blueGrey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
