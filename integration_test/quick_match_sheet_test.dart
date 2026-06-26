import 'package:cric_snap/home.dart';
import 'package:cric_snap/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Quick Match bottom sheet shows Team A before Team B', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: appProviders,
        child: const MaterialApp(home: HomeView()),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('home_quick_match_card')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Team A'), findsWidgets);
    expect(find.textContaining('Team B'), findsWidgets);
    expect(find.byKey(const Key('quick_match_start_button')), findsOneWidget);

    final teamAText = tester.getTopLeft(find.textContaining('Team A').first);
    final teamBText = tester.getTopLeft(find.textContaining('Team B').first);
    expect(teamAText.dy, lessThanOrEqualTo(teamBText.dy));
  });
}
