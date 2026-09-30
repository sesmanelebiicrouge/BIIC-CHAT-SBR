import 'package:flutter_test/flutter_test.dart';
import 'package:biic_chat_sbr/main.dart';

void main() {
  testWidgets('BIIC CHAT app reaches the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BIICChatApp());
    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pump();

    expect(find.text('BIIC CHAT'), findsOneWidget);
    expect(find.text('BIENVENUE SUR BIIC CHAT'), findsOneWidget);
  });
}
