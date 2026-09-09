import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

/// Plays the intro once while local storage and dependencies load.
final class StartupApp extends StatefulWidget {
  const StartupApp({required this.initialize, super.key});

  final Future<Widget> Function() initialize;

  @override
  State<StartupApp> createState() => _StartupAppState();
}

final class _StartupAppState extends State<StartupApp>
    with SingleTickerProviderStateMixin {
  final _animationFinished = Completer<void>();
  late final AnimationController _controller;
  Timer? _animationTimeout;
  late final Future<Widget> _application = _load();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _finishAnimation();
      });
    // A broken asset must not prevent an otherwise initialized app from opening.
    _animationTimeout = Timer(const Duration(seconds: 10), _finishAnimation);
  }

  void _finishAnimation() {
    _animationTimeout?.cancel();
    if (!_animationFinished.isCompleted) _animationFinished.complete();
  }

  @override
  void dispose() {
    _animationTimeout?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<Widget> _load() async {
    final results = await Future.wait<Object>([
      widget.initialize(),
      _animationFinished.future.then((_) => true),
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
                    child: Semantics(
                      label: 'Orbytis Atlas',
                      image: true,
                      child: Lottie.asset(
                      'assets/animations/startup.json',
                      controller: _controller,
                      repeat: false,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      onLoaded: (composition) {
                        _controller.duration = composition.duration;
                        _controller.forward();
                      },
                      errorBuilder: (_, _, _) {
                        _finishAnimation();
                        return const Text('Orbytis Atlas', style: TextStyle(color: Colors.white));
                      },
                    ),
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
