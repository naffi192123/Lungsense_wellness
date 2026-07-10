import 'package:flutter_test/flutter_test.dart';
import 'package:lungsense_wellness/main.dart';

void main() {
  testWidgets('App renders Phase 0 skeleton test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const LungSenseApp());
    await tester.pumpAndSettle();

    // Verify that the skeleton renders with expected text.
    expect(find.text('LungSense Wellness'), findsOneWidget);
    expect(find.text('Phase 0: Architecture Ready'), findsOneWidget);
  });
}
