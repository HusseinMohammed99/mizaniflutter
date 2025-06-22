// lib/bar/side_bar.dart

import 'package:flutter/material.dart';
import 'package:mizaniflutter/main.dart'; // تأكد من المسار الصحيح لـ themeModeNotifier و saveThemeMode
import 'package:mizaniflutter/screens/analysis_page%20.dart';
import 'package:mizaniflutter/screens/credits_page.dart';
import 'package:mizaniflutter/screens/debts_page.dart';
import 'package:mizaniflutter/screens/deposid_page.dart';
import 'package:mizaniflutter/screens/expand_page.dart';
import 'package:mizaniflutter/screens/home_page.dart';
import 'package:mizaniflutter/screens/saving_page.dart';
import 'package:mizaniflutter/screens/st.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  int mycurrentIndex = 0;

  final List<Widget> mylist = [
    const HomePage(),
    const DeposidPage(),
    const ExpandPage(),
    const SavingPage(),
    const DebtsPage(),
    const CreditsPage(),
    const AnalysisPage(),
    const StatisticsPage(),
  ];

  TextEditingController MY =
      TextEditingController(); // هذا المتحكم غير مستخدم حالياً، يمكن حذفه إذا لم يكن له استخدام لاحقاً

  // دالة لتبديل الثيم وحفظه
  void _toggleAndSaveTheme() {
    ThemeMode newThemeMode;
    // تحديد الوضع الجديد بناءً على الوضع الحالي
    if (themeModeNotifier.value == ThemeMode.dark) {
      newThemeMode = ThemeMode.light;
    } else if (themeModeNotifier.value == ThemeMode.light) {
      newThemeMode = ThemeMode.system;
    } else {
      // ThemeMode.system
      newThemeMode = ThemeMode.dark;
    }

    // تحديث الـ ValueNotifier لتطبيق الثيم الجديد فوراً
    themeModeNotifier.value = newThemeMode;
    // حفظ الثيم الجديد في SharedPreferences
    saveThemeMode(newThemeMode);

    // يمكنك إضافة رسالة تأكيد مؤقتة للمستخدم إذا أردت
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم تبديل الثيم إلى: ${newThemeMode.toString().split('.').last}',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NavigationRail(
          selectedIndex: mycurrentIndex,
          onDestinationSelected: (int index) {
            // التحقق مما إذا كان الزر المختار هو زر تبديل الثيم
            // إذا كان فهرس الزر هو فهرس زر تبديل الثيم (وهو آخر عنصر في القائمة)
            if (index == mylist.length) {
              // mylist.length يمثل الفهرس التالي لآخر عنصر في mylist
              _toggleAndSaveTheme(); // استدعاء دالة تبديل وحفظ الثيم
            } else {
              // وإلا، قم بتغيير الصفحة المعروضة
              setState(() {
                mycurrentIndex = index;
              });
            }
          },
          labelType: NavigationRailLabelType.all,
          selectedIconTheme: const IconThemeData(
            // استخدام اللون الأخضر الداكن من الشعار
            color: Color(0xFF2D6A4F), // HEX: #2D6A4F
          ),
          unselectedIconTheme: IconThemeData(
            // استخدام لون رمادي أغمق ليتناسق مع لوحة الألوان
            color: Colors.grey[600], // مثال: رمادي أغمق قليلاً
          ),
          // 🔴 تم إزالة خاصية hoverColor لأنها غير معرفة في NavigationRail
          // يمكنك تعيين لون الخلفية لشريط التنقل ليتناسب مع الثيم
          backgroundColor: Theme.of(context).cardColor, // أو أي لون آخر تختاره
          // إضافة الوجهات الديناميكية وزر تبديل الثيم
          destinations: [
            const NavigationRailDestination(
              icon: Icon(Icons.home),
              label: Text('Home'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.money),
              label: Text('Money'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.shopping_cart),
              label: Text('Expenses'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.monetization_on_outlined),
              label: Text('Saveing'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.credit_card),
              label: Text('Debts'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.nest_cam_wired_stand_outlined),
              label: Text('Credits'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.analytics),
              label: Text('Analysis'),
            ),
            const NavigationRailDestination(
              icon: Icon(Icons.bar_chart),
              label: Text('Statistics'),
            ),
            // إضافة وجهة لزر تبديل الثيم في نهاية القائمة
            NavigationRailDestination(
              // استخدم ValueListenableBuilder لضمان تحديث الأيقونة عند تغيير الثيم
              icon: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, currentThemeMode, child) {
                  // عرض أيقونة الوضع الفاتح إذا كان الثيم داكناً، والعكس صحيح
                  return Icon(
                    currentThemeMode == ThemeMode.dark
                        ? Icons
                              .light_mode // أيقونة الوضع الفاتح
                        : Icons.dark_mode, // أيقونة الوضع الداكن
                  );
                },
              ),
              label: const Text('Mode'), // تسمية لزر تبديل الوضع
            ),
          ],
        ),
        // المحتوى الرئيسي الذي يتغير بناءً على التحديد
        Expanded(child: mylist[mycurrentIndex]),
      ],
    );
  }
}
