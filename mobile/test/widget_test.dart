import 'package:flutter_test/flutter_test.dart';
import 'package:library_mobile/main.dart';

void main() {
  testWidgets('LibraryApp smoke test displays placeholder home screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LibraryApp());
    await tester.pumpAndSettle();

    expect(find.text('Library Home'), findsWidgets);
    expect(
      find.text('Home screen placeholder. Feature screens will be added here.'),
      findsOneWidget,
    );
  });
}
