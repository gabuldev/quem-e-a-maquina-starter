import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/game_service.dart';
import '../../services/models.dart';

/// `/admin`: login por email e senha (usuário com a claim `admin`), criar
/// jogo, começar, pausar, encerrar e ocultar respostas ao vivo.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, this.gameId});

  final String? gameId;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController(text: 'Workshop');
  final _open = TextEditingController();
  var _preset = 'sala';
  String? _gameId;
  bool? _isAdmin;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _gameId = widget.gameId;
    _checkClaim();
  }

  User? get _user => FirebaseAuth.instance.currentUser;

  Future<void> _checkClaim() async {
    final user = _user;
    if (user == null || user.isAnonymous) {
      setState(() => _isAdmin = false);
      return;
    }
    // `true` força token novo: a claim pode ter sido gravada agora há pouco.
    final token = await user.getIdTokenResult(true);
    if (mounted) setState(() => _isAdmin = token.claims?['admin'] == true);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on GameError catch (e) {
      _snack(e.message);
    } on FirebaseAuthException catch (e) {
      _snack('Login falhou: ${e.code}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _select(String gameId) {
    SystemNavigator.routeInformationUpdated(
      uri: Uri(path: '/admin', queryParameters: {'game': gameId}),
    );
    setState(() => _gameId = gameId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          if (_isAdmin == true)
            TextButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                await _checkClaim();
              },
              child: Text('Sair (${_user?.email})'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: switch (_isAdmin) {
            null => const CircularProgressIndicator(),
            false => _login(),
            true => _panel(),
          },
        ),
      ),
    );
  }

  Widget _login() => ListView(
    padding: const EdgeInsets.all(24),
    shrinkWrap: true,
    children: [
      if (_user != null && !_user!.isAnonymous)
        Text('${_user!.email} não tem a claim admin.'),
      TextField(
        controller: _email,
        decoration: const InputDecoration(labelText: 'Email'),
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _password,
        decoration: const InputDecoration(labelText: 'Senha'),
        obscureText: true,
        onSubmitted: (_) => _signIn(),
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _busy ? null : _signIn,
        child: const Text('Entrar'),
      ),
    ],
  );

  void _signIn() => _run(() async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _email.text.trim(),
      password: _password.text,
    );
    await _checkClaim();
  });

  Widget _panel() {
    final gameId = _gameId;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Novo jogo', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _preset,
              items: const [
                DropdownMenuItem(value: 'sala', child: Text('sala (4 min)')),
                DropdownMenuItem(
                  value: 'devfest',
                  child: Text('devfest (20 min)'),
                ),
              ],
              onChanged: (v) => setState(() => _preset = v!),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      _select(
                        await games.createGame(_name.text.trim(), _preset),
                      );
                    }),
              child: const Text('Criar'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _open,
                decoration: const InputDecoration(
                  labelText: 'Abrir jogo existente',
                ),
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (v) => _select(v.trim().toUpperCase()),
              ),
            ),
          ],
        ),
        const Divider(height: 48),
        if (gameId != null)
          _GameControls(gameId: gameId, busy: _busy, run: _run),
      ],
    );
  }
}

class _GameControls extends StatelessWidget {
  const _GameControls({
    required this.gameId,
    required this.busy,
    required this.run,
  });

  final String gameId;
  final bool busy;
  final Future<void> Function(Future<void> Function()) run;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<Game?>(
      stream: games.game(gameId),
      builder: (context, snap) {
        final game = snap.data;
        if (game == null) return Text('Jogo $gameId não encontrado.');
        final status = game.status.name;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${game.name} · $gameId · $status',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            SelectableText('Jogadores: ${Uri.base.origin}/?game=$gameId'),
            SelectableText('Telão: ${Uri.base.origin}/board?game=$gameId'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: busy || status != 'lobby'
                      ? null
                      : () => run(() => games.startGame(gameId)),
                  child: const Text('Começar'),
                ),
                OutlinedButton(
                  onPressed: busy || status != 'running'
                      ? null
                      : () => run(() => games.pauseGame(gameId)),
                  child: const Text('Pausar'),
                ),
                OutlinedButton(
                  onPressed: busy || status != 'paused'
                      ? null
                      : () => run(() => games.resumeGame(gameId)),
                  child: const Text('Retomar'),
                ),
                OutlinedButton(
                  onPressed: busy || status == 'ended'
                      ? null
                      : () => run(() => games.endGame(gameId)),
                  child: const Text('Encerrar'),
                ),
                OutlinedButton(
                  onPressed: () => run(() => games.tick(gameId)),
                  child: const Text('Tick'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (game.currentRoundId case final roundId?)
              _LiveAnswers(gameId: gameId, roundId: roundId, run: run),
          ],
        );
      },
    );
  }
}

/// Respostas da rodada atual, ao vivo, com botão de ocultar. As rules
/// liberam `answers` para o admin em qualquer fase.
class _LiveAnswers extends StatelessWidget {
  const _LiveAnswers({
    required this.gameId,
    required this.roundId,
    required this.run,
  });

  final String gameId;
  final String roundId;
  final Future<void> Function(Future<void> Function()) run;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Answer>>(
      stream: games.liveAnswers(gameId, roundId),
      builder: (context, snap) {
        final answers = snap.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Respostas da rodada (${answers.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (snap.hasError) Text('${snap.error}'),
            for (final a in answers)
              ListTile(
                leading: Icon(a.isImpostor ? Icons.smart_toy : Icons.person),
                title: Text(
                  a.text,
                  style: a.moderation == 'hidden'
                      ? const TextStyle(decoration: TextDecoration.lineThrough)
                      : null,
                ),
                subtitle: Text('${a.appearances} aparições · ${a.picks} picks'),
                trailing: a.moderation == 'hidden'
                    ? const Text('oculta')
                    : IconButton(
                        tooltip: 'Ocultar',
                        icon: const Icon(Icons.visibility_off),
                        onPressed: () =>
                            run(() => games.adminHide(gameId, roundId, a.id)),
                      ),
              ),
          ],
        );
      },
    );
  }
}
