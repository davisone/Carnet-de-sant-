import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:carnet_sante_animaux/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const CarnetSanteApp());

    expect(find.text('Carnet de Santé Animaux'), findsOneWidget);
  });
}
