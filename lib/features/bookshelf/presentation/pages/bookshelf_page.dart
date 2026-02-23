import 'package:flutter/material.dart';

class BookshelfPage extends StatelessWidget {
  const BookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7),
        surfaceTintColor: const Color(0xFFF2F2F7),
        title: const Text('我的书架'),
      ),
      body: const Center(child: Text('我的书架（P0仅菜单入口）')),
    );
  }
}
