import 'package:cric_snap/home.dart';
import 'package:cric_snap/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('Home shows title and Quick Match action', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: appProviders,
        child: const MaterialApp(home: HomeView()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Cric Snap'), findsOneWidget);
    expect(find.text('Quick Match'), findsOneWidget);
  });
}
