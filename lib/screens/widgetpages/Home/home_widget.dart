// lib/screens/widgetpages/Home/home_widget.dart

import 'package:flutter/material.dart';
import 'package:mizaniflutter/bar/side_bar.dart'; // استيراد SideBar

class HomeWidgest extends StatefulWidget {
  const HomeWidgest({super.key});

  @override
  State<HomeWidgest> createState() => _HomeWidgestState();
}

class _HomeWidgestState extends State<HomeWidgest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔴 وضع SideBar مباشرة في الـ body
      // بما أن SideBar نفسه يحتوي على NavigationRail ويدير عرض الصفحات.
      body: const SideBar(),

      // 🔴 لا يوجد bottomNavigationBar هنا بعد الآن
    );
  }
}
