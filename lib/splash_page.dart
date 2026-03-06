import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_page.dart';
import 'login_page.dart';
import 'sync/sync_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleIn;
  late final Animation<double> _fadeIn;

  late final AnimationController _zoomOutController;
  late final Animation<double> _extraZoom;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _zoomOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _extraZoom = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _zoomOutController, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    _timer = Timer(const Duration(milliseconds: 1600), () async {
      if (!mounted) return;
      await _playZoomOut();
      if (!mounted) return;
      await _goNext();
    });
  }

  Future<void> _goNext() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await SyncService.instance.syncNow();
      } catch (e) {
        debugPrint('Splash sync error: $e');
      }

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  Future<void> _playZoomOut() async {
    if (_zoomOutController.isAnimating) return;
    await _zoomOutController.forward(from: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _zoomOutController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF6F7FB), Color(0xFFF1F3F8)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeIn,
            child: ScaleTransition(
              scale: _scaleIn,
              child: AnimatedBuilder(
                animation: _extraZoom,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _extraZoom.value,
                    child: child,
                  );
                },
                child: Container(
                  width: 220,
                  height: 220,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(44),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}