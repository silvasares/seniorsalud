import 'package:flutter_test/flutter_test.dart';
import 'package:seniorsalud/app.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const SeniorSaludApp());
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.text('SeniorSalud'), findsWidgets);
  });
}
