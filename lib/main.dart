import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'datasources/local/habito_local_datasource.dart';
import 'datasources/local/meta_local_datasource.dart';
import 'datasources/local/registro_local_datasource.dart';
import 'datasources/remote/api_client.dart';
import 'models/usuario_sessao.dart';
import 'repositories/lifeup_repository.dart';
import 'screens/habito_detail_screen.dart';
import 'screens/habito_form_screen.dart';
import 'screens/habitos_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/meta_form_screen.dart';
import 'screens/metas_list_screen.dart';
import 'screens/perfil_screen.dart';
import 'screens/register_screen.dart';
import 'screens/registro_form_screen.dart';
import 'screens/registros_list_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/sync_screen.dart';
import 'services/sessao_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LifeUpApp());
}

class LifeUpApp extends StatefulWidget {
  const LifeUpApp({super.key});

  @override
  State<LifeUpApp> createState() => _LifeUpAppState();
}

class _LifeUpAppState extends State<LifeUpApp> {
  late final ApiClient _api;
  late final LifeUpRepository _repository;
  late final SessaoService _sessao;
  UsuarioSessao? _usuario;

  @override
  void initState() {
    super.initState();
    _api = ApiClient();
    _repository = LifeUpRepository(
      habitoLocal: HabitoSqfliteDatasource(),
      metaLocal: MetaSqfliteDatasource(),
      registroLocal: RegistroSqfliteDatasource(),
      apiClient: _api,
    );
    _sessao = SessaoService(_api);
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: _api,
      repository: _repository,
      sessao: _sessao,
      usuario: _usuario,
      onUsuarioChanged: (u) => setState(() => _usuario = u),
      child: MaterialApp(
        title: 'LifeUp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/home': (_) => const MainShellScreen(),
          '/habitos': (_) => const HabitosListScreen(),
          '/habitos/form': (context) {
            final id = ModalRoute.of(context)?.settings.arguments as String?;
            return HabitoFormScreen(habitoId: id);
          },
          '/habitos/detalhe': (context) {
            final id = ModalRoute.of(context)!.settings.arguments as String;
            return HabitoDetailScreen(habitoId: id);
          },
          '/metas': (_) => const MetasListScreen(),
          '/metas/form': (context) {
            final id = ModalRoute.of(context)?.settings.arguments as String?;
            return MetaFormScreen(metaId: id);
          },
          '/registros': (_) => const RegistrosListScreen(),
          '/registros/form': (_) => const RegistroFormScreen(),
          '/sync': (_) => const SyncScreen(),
          '/perfil': (_) => const PerfilScreen(),
        },
      ),
    );
  }
}
