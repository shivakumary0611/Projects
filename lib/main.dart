import 'package:cric_snap/providers/app_providers.dart';
import 'package:cric_snap/splash/view.dart';
import 'package:cric_snap/widget/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Future.delayed(const Duration(seconds: 1));

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  static const double _tabletBreakpoint = 600;

  void _setOrientationLock(BuildContext context) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortestSide >= _tabletBreakpoint;

    SystemChrome.setPreferredOrientations(
      isTablet
          ? [
              DeviceOrientation.portraitUp,
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : [DeviceOrientation.portraitUp],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: appProviders,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        builder: (context, child) {
          _setOrientationLock(context);
          return child!;
        },
        home: const SplashView(),
      ),
    );
  }
}