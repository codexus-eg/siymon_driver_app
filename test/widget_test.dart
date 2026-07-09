import 'package:flutter_test/flutter_test.dart';
import 'package:siymon_driver_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SiymonApp());
  });
}
