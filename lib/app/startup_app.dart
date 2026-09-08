import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Displays the supplied artwork while local storage and dependencies load.
final class StartupApp extends StatefulWidget {
  const StartupApp({required this.initialize, super.key});

  final Future<Widget> Function() initialize;

  @override
  State<StartupApp> createState() => _StartupAppState();
}

final class _StartupAppState extends State<StartupApp> {
  late final Future<Widget> _application = _load();

  Future<Widget> _load() async {
    final results = await Future.wait<Object>([
      widget.initialize(),
      Future<bool>.delayed(const Duration(milliseconds: 1200), () => true),
    ]);
    return results.first as Widget;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _application,
      builder: (context, snapshot) {
        if (snapshot.hasData) return snapshot.requireData;
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.black,
              systemNavigationBarColor: Colors.black,
            ),
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/hover_atlas.png',
                      fit: BoxFit.contain,
                      width: double.infinity,
                      semanticLabel: 'Orbytis Atlas',
                    ),
                  ),
                  if (snapshot.hasError)
                    const SafeArea(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Não foi possível iniciar o aplicativo. Feche e abra novamente.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
