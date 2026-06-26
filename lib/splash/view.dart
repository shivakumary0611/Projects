import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cric_snap/home.dart';
import 'package:cric_snap/teams/view_model.dart';
import 'package:cric_snap/players/view_model.dart';
import 'package:cric_snap/match/view_model.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  String _loadingMessage = 'Starting Cric Snap...';
  bool _showTextAndSpinner = false;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  Future<void> _startLoading() async {
    // Slight delay before displaying the loading text/spinner to let the logo fade-in run first
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _showTextAndSpinner = true;
    });

    final startTime = DateTime.now();

    try {
      if (!mounted) return;
      setState(() => _loadingMessage = 'Initializing database...');
      final teamViewModel = context.read<TeamViewModel>();
      final playerViewModel = context.read<PlayerViewModel>();
      final matchesViewModel = context.read<MatchesViewModel>();

      if (!mounted) return;
      setState(() => _loadingMessage = 'Loading team statistics...');
      await teamViewModel.loadTeams();

      if (!mounted) return;
      setState(() => _loadingMessage = 'Loading registered players...');
      await playerViewModel.loadPlayers();

      if (!mounted) return;
      setState(() => _loadingMessage = 'Synchronizing matches...');
      await matchesViewModel.loadMatches();

      if (!mounted) return;
      setState(() => _loadingMessage = 'Pitch is ready!');
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMessage = 'Almost ready...');
      }
    }

    final elapsed = DateTime.now().difference(startTime);
    // Ensure the splash stays visible for at least 2.5 seconds for a premium and smooth transition
    final remaining = const Duration(milliseconds: 2500) - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }

    if (!mounted) return;

    // Navigate to HomeView with a premium fade-in transition
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F4C3A), // Dark Emerald Green
              Color(0xFF082B20), // Deeper Forest Green
              Color(0xFF03140F), // Very deep near-black green
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main centered content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Static Logo matching the native splash screen layout
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 25,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFBA08).withValues(alpha: 0.25), // Gold glow
                            blurRadius: 30,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(70),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Animate title and tagline fading in to prevent sudden layout jump
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 800),
                      opacity: _showTextAndSpinner ? 1.0 : 0.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Gold Gradient App Title
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFFFFD700), // Gold
                                Color(0xFFFFA500), // Orange-Gold
                                Color(0xFFFF8C00), // Dark Orange
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text(
                              'Cric Snap',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tagline
                          Text(
                            'Capture & Relive Every Moment',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.65),
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom loader & loading message
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60.0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: _showTextAndSpinner ? 1.0 : 0.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Custom styled circular spinner
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFFFFBA08), // Gold/Yellow matching secondary color
                            ),
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Animated Switcher for cycling loading status text
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: Text(
                            _loadingMessage,
                            key: ValueKey<String>(_loadingMessage),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
