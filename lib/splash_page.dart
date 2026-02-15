import 'dart:async';
import 'package:flutter/material.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleIn;
  late final Animation<double> _fadeIn;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // เข้าแบบเด้งนิดๆ
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // รอให้เห็นโลโก้ก่อน แล้วค่อย “ขยายใหญ่ขึ้น” แล้วไปหน้า login
    _timer = Timer(const Duration(milliseconds: 1600), () async {
      // ขยายใหญ่ขึ้นตอนท้าย (zoom out)
      await _controller.animateTo(
        1.0,
        duration: const Duration(milliseconds: 0),
      );

      if (!mounted) return;

      await Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) => const _GoLoginRoute(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _playZoomOut() async {
    // เพิ่มเอฟเฟกต์ขยายใหญ่ขึ้นแบบเนียนๆ
    final zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    final zoom = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: zoomController, curve: Curves.easeOutCubic),
    );

    // เล่นแบบ overlay ด้วย setState ผ่าน AnimatedBuilder
    // ทำง่ายสุด: ใช้ showGeneralDialog ทับ (แต่ไม่จำเป็น)
    // เลยใช้วิธีปรับ scale ด้วย AnimatedBuilder แทนด้านล่าง (ดู build)
    _extraZoom = zoom;
    _extraZoomController = zoomController;

    if (mounted) setState(() {});
    await zoomController.forward();
  }

  AnimationController? _extraZoomController;
  Animation<double>? _extraZoom;

  @override
  Widget build(BuildContext context) {
    final extraZoom = _extraZoom;

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
                animation: extraZoom ?? const AlwaysStoppedAnimation(1.0),
                builder: (context, child) {
                  final s = (extraZoom?.value ?? 1.0);
                  return Transform.scale(scale: s, child: child);
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

/// Route ไปหน้า login จริงของคุณ (ใช้ชื่อ route ก็ได้)
// ถ้าคุณใช้ pushReplacementNamed('/login') ให้เปลี่ยนด้านล่างเป็น LoginPage() ได้เลย
class _GoLoginRoute extends StatelessWidget {
  const _GoLoginRoute();

  @override
  Widget build(BuildContext context) {
    // ✅ ไปหน้า login ด้วย named route เดิมของคุณ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed('/login');
    });
    return const SizedBox.shrink();
  }
}
