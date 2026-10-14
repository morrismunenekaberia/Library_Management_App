import 'dart:async';
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
  final Duration minDuration;

  const SplashScreen({
    super.key,
    this.sessionRestoreFuture,
    this.minDuration = const Duration(seconds: 5),
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
  late final DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
        _checkAndNavigate(immediate: true);
      }
    }
  }

  void _videoListener() {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.hasError) {
      _isVideoFinishedOrSkipped = true;
      _checkAndNavigate(immediate: true);
      return;
    }

    final position = controller.value.position;
    final duration = controller.value.duration;

    // Check if the video reached the end.
    // video_player events can fire with slight rounding discrepancies near the end,
    // or when playback pauses at the end. We check both threshold and isPlaying state.
    if (duration > Duration.zero) {
      final isNearEnd = position >= duration ||
          (duration - position).inMilliseconds <= 100;
      final stoppedAtEnd = !controller.value.isPlaying &&
          position >= duration - const Duration(milliseconds: 300);

      if (isNearEnd || stoppedAtEnd) {
        _isVideoFinishedOrSkipped = true;
        _checkAndNavigate();
      }
    }
  }

  Timer? _delayTimer;

  void _skip() {
    if (_hasNavigated) return;
    _delayTimer?.cancel();
    _delayTimer = null;
    _isVideoFinishedOrSkipped = true;
    _controller?.pause();
    _checkAndNavigate(immediate: true);
  }

  void _checkAndNavigate({bool immediate = false}) {
    if (!mounted || _hasNavigated) return;

    if (_isVideoFinishedOrSkipped && _isSessionRestored) {
      if (immediate || widget.minDuration == Duration.zero) {
        _delayTimer?.cancel();
        _delayTimer = null;
        _doNavigate();
        return;
      }

      if (_delayTimer != null) return;

      final elapsed = DateTime.now().difference(_startTime);
      final remaining = widget.minDuration - elapsed;
      if (remaining <= Duration.zero) {
        _doNavigate();
      } else {
        _delayTimer = Timer(remaining, () {
          if (mounted && !_hasNavigated) {
            _doNavigate();
          }
        });
      }
    }
  }

  void _doNavigate() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    AppRouter.splashSeen = true;
    final authController = context.read<AuthController>();
    final destination = authController.isAuthenticated
        ? AppRouter.homeRoute
        : AppRouter.loginRoute;

    context.go(destination);
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
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
