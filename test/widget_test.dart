import 'package:flutter_test/flutter_test.dart';
import 'package:disease_prediction_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(isLoggedIn: false));

    // Verify that login screen is presented.
    expect(find.text('ASHA Worker Portal'), findsOneWidget);
  });
}
