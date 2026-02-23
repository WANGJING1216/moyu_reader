import 'package:flutter/material.dart';

import 'router.dart';

class MoyuReaderApp extends StatelessWidget {
  const MoyuReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '摸鱼阅读',
      debugShowCheckedModeBanner: false,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.reader,
    );
  }
}
