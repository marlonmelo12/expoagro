import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expoagro_app/main.dart';

// Pixel transparente 1x1 em PNG para mock de imagens NetworkImage
final List<int> transparentImage = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
];

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return MockHttpClientRequest();
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return MockHttpClientResponse();
  }
}

class MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  int get contentLength => transparentImage.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  testWidgets('AgroManager shell and navigation test', (WidgetTester tester) async {
    // 1. Build our app and trigger a frame.
    await tester.pumpWidget(const SimuladorViabilidadeApp());
    await tester.pump();

    // 2. Verify that the Dashboard screen renders initially
    expect(find.text('AgroHub'), findsOneWidget);
    expect(find.text('Olá, Produtor'), findsNWidgets(2));
    expect(find.text('TOTAL DE MATRIZES'), findsOneWidget);

    // 3. Navigate to the Catálogo tab (tab at index 2)
    final catalogoTab = find.byIcon(Icons.library_books);
    expect(catalogoTab, findsOneWidget);
    await tester.tap(catalogoTab);
    await tester.pumpAndSettle();

    // Verify we are on Catálogo
    expect(find.text('Rem Torixoréu FIV'), findsOneWidget);

    // Tap on the first simulation button to open Simulador
    final simularBtn = find.text('Gerar Simulação').first;
    await tester.tap(simularBtn);
    await tester.pumpAndSettle();

    // 4. Verify that the AI Simulator screen is now visible and active
    expect(find.text('Simulador de Acasalamento'), findsOneWidget);
    expect(find.text('Top-5 Melhores Matrizes'), findsOneWidget);
  });
}
