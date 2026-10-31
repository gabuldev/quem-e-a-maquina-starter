import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared/limits.dart';

import '../../services/game_service.dart';
import '../game/game_screen.dart';

/// Entrada: código do jogo (vem do QR em `?game=`) e nickname.
/// Quem já entrou neste navegador vai direto para o jogo.
class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  late final _code = TextEditingController(text: widget.initialCode);
  final _nickname = TextEditingController();
  final _form = GlobalKey<FormState>();
  var _busy = false;
  var _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _resume();
  }

  /// Recarregou a página com `?game=` e já é jogador: pula a entrada.
  Future<void> _resume() async {
    final code = widget.initialCode;
    if (code != null && code.length == 4) {
      try {
        if (await games.isPlayer(code.toUpperCase())) {
          _open(code.toUpperCase());
          return;
        }
      } catch (_) {
        // Código que não existe cai no formulário normal.
      }
    }
    if (mounted) setState(() => _checking = false);
  }

  void _open(String gameId) {
    // Deixa o código na URL: recarregar volta para o mesmo jogo.
    SystemNavigator.routeInformationUpdated(
      uri: Uri(path: '/', queryParameters: {'game': gameId}),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(gameId: gameId)),
    );
  }

  Future<void> _join() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final r = await games.joinGame(_code.text.trim(), _nickname.text.trim());
      if (!mounted) return;
      if (r.nickname != _nickname.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Já tinha alguém assim: você é ${r.nickname}.'),
          ),
        );
      }
      _open(r.gameId);
    } on GameError catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.smart_toy_outlined, size: 72),
                  const SizedBox(height: 12),
                  Text(
                    'Quem é a máquina?',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Responda como gente. Ache a IA no meio das respostas.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _code,
                    decoration: const InputDecoration(
                      labelText: 'Código do jogo',
                    ),
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 4,
                    validator: (v) => (v ?? '').trim().length == 4
                        ? null
                        : 'O código tem 4 letras.',
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nickname,
                    decoration: const InputDecoration(
                      labelText: 'Seu nickname',
                    ),
                    maxLength: maxNicknameChars,
                    autofocus: widget.initialCode != null,
                    onFieldSubmitted: (_) => _join(),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Escolha um nickname.'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _join,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
