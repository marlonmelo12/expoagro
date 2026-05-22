import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Test FaIcon widget with FontAwesomeIcons.cow', (WidgetTester tester) async {
    final cowIcon = FontAwesomeIcons.cow;
    
    // Attempt to build FaIcon
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FaIcon(cowIcon),
        ),
      ),
    );
    await tester.pump();
  });
}
