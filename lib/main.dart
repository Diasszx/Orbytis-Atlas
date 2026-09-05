import 'package:flutter/material.dart';

import 'core/config/app_config.dart';

void main() {
  runApp(const OrbytisAtlasApp());
}

class OrbytisAtlasApp extends StatelessWidget {
  const OrbytisAtlasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Text('Orbytis Atlas'))),
    );
  }
}
