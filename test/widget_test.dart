import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_up_av2_app/screens/login_screen.dart';
import 'package:life_up_av2_app/screens/register_screen.dart';
import 'package:life_up_av2_app/widgets/empty_state.dart';
import 'package:life_up_av2_app/widgets/password_field.dart';
import 'package:life_up_av2_app/widgets/sync_badge.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

void _setPhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  testWidgets('LoginScreen renderiza marca, campos e ações', (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    expect(find.text('LifeUp'), findsWidgets);
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('Criar conta'), findsOneWidget);
  });

  testWidgets('LoginScreen valida campos obrigatórios', (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(_wrap(const LoginScreen()));
    await tester.ensureVisible(find.text('Entrar'));
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Mínimo 3 caracteres'), findsOneWidget);
    expect(find.text('Mínimo 4 caracteres'), findsOneWidget);
  });

  testWidgets('RegisterScreen valida nome obrigatório', (tester) async {
    _setPhoneSurface(tester);
    await tester.pumpWidget(_wrap(const RegisterScreen()));
    await tester.ensureVisible(find.text('Cadastrar'));
    await tester.tap(find.text('Cadastrar'));
    await tester.pump();
    expect(find.text('Obrigatório'), findsOneWidget);
  });

  testWidgets('SyncBadge mostra ícone de pendente', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SyncBadge(sincronizado: false))),
    );
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
  });

  testWidgets('SyncBadge mostra ícone sincronizado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SyncBadge(sincronizado: true))),
    );
    expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
  });

  testWidgets('PasswordField alterna visibilidade da senha', (tester) async {
    final ctrl = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            child: PasswordField(controller: ctrl),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });

  testWidgets('EmptyState renderiza título e subtítulo', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.checklist_rounded,
            title: 'Nenhum hábito ainda',
            subtitle: 'Toque em + para criar o primeiro.',
          ),
        ),
      ),
    );
    expect(find.text('Nenhum hábito ainda'), findsOneWidget);
    expect(find.text('Toque em + para criar o primeiro.'), findsOneWidget);
    expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
  });
}
