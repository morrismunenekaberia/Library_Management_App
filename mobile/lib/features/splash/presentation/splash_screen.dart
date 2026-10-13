import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/router/app_router.dart';

/// Video splash screen shown once on application cold start.
///
/// Plays assets/video/splash.mp4 full screen (Fit: cover) inside a solid colored box
/// matching the video background (#D7D5D6). Runs session restoration concurrently.
/// Navigates with a fade transition to the target screen once both the video completes
/// (or is skipped) and the session restore finishes.
class SplashScreen extends StatefulWidget {
  final Future<void>? sessionRestoreFuture;

  const SplashScreen({
    super.key,
    this.sessionRestoreFuture,
  });

  /// The sampled background color matching the video (#D7D5D6).
  static const Color backgroundColor = Color(0xFFD7D5D6);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  VideoPlayerController? _controller;
  bool _isVideoFinishedOrSkipped = false;
  bool _isSessionRestored = false;
  bool _hasNavigated = false;
  late final Future<void> _restoreFuture;

  @override
  void initState() {
    super.initState();
    // Cold start splash has been viewed for this process lifetime
    AppRouter.splashSeen = true;

    // Use passed future or fetch from AuthController
    final authController = context.read<AuthController>();
    _restoreFuture = widget.sessionRestoreFuture ?? authController.restoreSession();

    _restoreFuture.then((_) {
      if (mounted) {
        _isSessionRestored = true;
        _checkAndNavigate();
      }
    }).catchError((_) {
      if (mounted) {
        _isSessionRestored = true;
        _checkAndNavigate();
      }
    });

    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final controller = VideoPlayerController.asset('assets/video/splash.mp4');
      _controller = controller;

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await controller.setVolume(0.0);
      await controller.setLooping(false);

      controller.addListener(_videoListener);

      setState(() {});
      await controller.play();
    } catch (_) {
      // If the video fails to load or play, do not block the app
      if (mounted) {
        _isVideoFinishedOrSkipped = true;
        _checkAndNavigate();
      }
    }
  }

  void _videoListener() {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.hasError) {
      _isVideoFinishedOrSkipped = true;
      _checkAndNavigate();
      return;
    }

    final position = controller.value.position;
    final duration = controller.value.duration;

    if (duration > Duration.zero && position >= duration) {
      _isVideoFinishedOrSkipped = true;
      _checkAndNavigate();
    }
  }

  void _skip() {
    if (_isVideoFinishedOrSkipped) return;
    _isVideoFinishedOrSkipped = true;
    _controller?.pause();
    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    if (!mounted || _hasNavigated) return;

    if (_isVideoFinishedOrSkipped && _isSessionRestored) {
      _hasNavigated = true;
      final authController = context.read<AuthController>();
      final destination = authController.isAuthenticated
          ? AppRouter.homeRoute
          : AppRouter.loginRoute;

      context.go(destination);
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final isInitialized = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: SplashScreen.backgroundColor,
      body: ColoredBox(
        color: SplashScreen.backgroundColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: controller.value.size.width,
                    height: controller.value.size.height,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0, right: 16.0),
                  child: TextButton(
                    onPressed: _skip,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black87,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
