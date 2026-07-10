import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_wellness/main.dart';

void main() {
  testWidgets('App renders SplashPage and transitions to Login after delay', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LungSenseApp());
    await tester.pump(); // Trigger initial build

    // Verify that the Splash screen feature labels are displayed
    expect(find.text('Daily Tracking'), findsOneWidget);
    expect(find.text('Lung Score'), findsOneWidget);
    expect(find.text('Smart Insights'), findsOneWidget);
    expect(find.text('Powered by'), findsOneWidget);

    // Fast-forward the virtual test clock by 3 seconds to complete the splash timer
    await tester.pump(const Duration(seconds: 3));
    // Let GoRouter complete its transition frames
    await tester.pumpAndSettle();

    // Verify that it navigated successfully to the Login screen placeholder
    expect(find.text('Login Screen Placeholder (Phase 2)'), findsOneWidget);
  });
}
