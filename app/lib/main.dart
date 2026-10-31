import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/firebase.dart';
import 'core/theme.dart';
import 'features/admin/admin_screen.dart';
import 'features/board/board_screen.dart';
import 'features/join/join_screen.dart';
import 'features/lab/lab_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // URLs limpas (`/board?game=DASH`) em vez de `/#/board`.
  usePathUrlStrategy();
  await initFirebase();

  final uri = Uri.base;
  final gameId = uri.queryParameters['game']?.trim().toUpperCase();
  // O admin entra com email; todo o resto, anônimo.
  if (uri.path != '/admin') await ensureSignedIn();

  Widget screenFor(String path) => switch (path) {
    '/board' when gameId != null => BoardScreen(gameId: gameId),
    '/admin' => AdminScreen(gameId: gameId),
    '/lab' => Scaffold(
      appBar: AppBar(title: const Text('Laboratório')),
      body: LabScreen(gameId: gameId),
    ),
    _ => JoinScreen(initialCode: gameId),
  };

  runApp(
    MaterialApp(
      title: 'Quem é a máquina?',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // A rota inicial vem da URL. Uma rota só (sem empilhar "/" embaixo),
      // e o nome dela mantém o `/admin` na barra de endereço.
      onGenerateInitialRoutes: (name) => [
        MaterialPageRoute(
          settings: RouteSettings(name: name),
          builder: (_) => screenFor(Uri.parse(name).path),
        ),
      ],
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) => screenFor(Uri.parse(settings.name ?? '/').path),
      ),
    ),
  );
}
