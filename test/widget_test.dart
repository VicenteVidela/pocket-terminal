import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_terminal/main.dart';

void main() {
  testWidgets('connection form rejects missing details', (tester) async {
    await tester.pumpWidget(const PocketTerminal());
    expect(find.text('Hostname'), findsOneWidget);
    await tester.tap(find.text('Connect'));
    await tester.pump();
    expect(
      find.text('Enter a host, valid port, username and password.'),
      findsOneWidget,
    );
  });
}
