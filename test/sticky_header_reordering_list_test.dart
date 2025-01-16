import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sticky_header_reordering_list/sticky_header_reordering_list.dart';

void main() {
  group('StickyHeaderReorderableList', () {
    testWidgets('creates a list with sections', (WidgetTester tester) async {
      final items = ['Apple', 'Banana', 'Cherry', 'Date'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StickyHeaderReorderableList<String>(
              items: items,
              sectionExtractor: (item) => item[0],
              headerBuilder: (context, section) => Text('Section $section'),
              itemBuilder: (context, item) => Text(item),
              isReorderable: false,
            ),
          ),
        ),
      );

      // Check the presence of header and item texts
      expect(find.text('Section A'), findsOneWidget);
      expect(find.text('Section B'), findsOneWidget);
      expect(find.text('Section C'), findsOneWidget);
      expect(find.text('Section D'), findsOneWidget);

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Date'), findsOneWidget);
    });
  });
}

class CustomItem {
  final String name;
  final int value;

  CustomItem(this.name, this.value);
}
