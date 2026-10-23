import 'package:carteira_app/main.dart';
import 'package:carteira_app/app_services.dart';
import 'package:carteira_core/carteira_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login screen shows the brand, two fields and a button', (
    tester,
  ) async {
    final services = _services();
    await tester.pumpWidget(CarteiraApp(services: services));
    await tester.pumpAndSettle();
    expect(find.text('Carteira'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('login failure is shown on the login screen', (tester) async {
    await tester.pumpWidget(CarteiraApp(services: _services()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'wrong@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
  });

  testWidgets('successful login opens the home screen', (tester) async {
    await tester.pumpWidget(CarteiraApp(services: _services()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'ana@carteira.dev');
    await tester.enterText(find.byType(TextField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Ana!'), findsOneWidget);
    expect(find.text('Saldo do mês'), findsOneWidget);
  });

  testWidgets('a restored session opens the home screen', (tester) async {
    final storage = InMemorySessionStorage(
      Session(token: 'persisted-token', user: SampleData.user),
    );
    await tester.pumpWidget(CarteiraApp(services: _services(storage: storage)));
    await tester.pumpAndSettle();

    expect(find.text('Olá, Ana!'), findsOneWidget);
  });
}

AppServices _services({SessionStorage? storage}) => AppServices(
  auth: InMemoryAuthRepository(storage: storage),
  users: InMemoryUserRepository(),
  transactions: InMemoryTransactionRepository(),
);
