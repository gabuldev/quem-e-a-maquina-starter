import 'package:flutter/material.dart';
import 'package:shared/limits.dart';

import '../../core/theme.dart';
import '../../services/game_service.dart';
import '../../services/impostor_service.dart';

/// Laboratório de prompt: escreve o estilo do impostor, testa contra 3
/// perguntas com o Gemini do cliente e, quando gostar, manda para o jogo.
/// O servidor gera os impostores reais com o mesmo prompt.
class LabScreen extends StatefulWidget {
  const LabScreen({super.key, this.gameId});

  /// Com jogo, o deploy registrado aparece na grade daquele telão.
  final String? gameId;

  @override
  State<LabScreen> createState() => _LabScreenState();
}

const sampleQuestions = [
  'Descreva seu último bug em uma frase.',
  'Qual é a mentira mais contada em uma daily?',
  'O que "vou refatorar depois" realmente significa?',
];

class _LabScreenState extends State<LabScreen> {
  final _service = ImpostorService();
  final _prompt = TextEditingController();
  final _url = TextEditingController();
  final _results = <int, String>{};
  final _errors = <int, String>{};
  var _testing = false;
  var _sending = false;
  var _registering = false;

  @override
  void initState() {
    super.initState();
    games.myPrompt().then((text) {
      if (text != null && mounted && _prompt.text.isEmpty) _prompt.text = text;
    }).ignore();
  }

  Future<void> _test() async {
    final prompt = _prompt.text.trim();
    if (prompt.isEmpty) return;
    setState(() {
      _testing = true;
      _results.clear();
      _errors.clear();
    });
    await Future.wait([
      for (final (i, q) in sampleQuestions.indexed)
        _service
            .generate(userPrompt: prompt, question: q)
            .then((a) => _results[i] = a)
            .catchError((Object e) => _errors[i] = '$e')
            .whenComplete(() {
              if (mounted) setState(() {});
            }),
    ]);
    if (mounted) setState(() => _testing = false);
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await games.submitPrompt(_prompt.text.trim());
      _snack('Prompt enviado. Os próximos impostores podem sair dele.');
    } on GameError catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _register() async {
    setState(() => _registering = true);
    try {
      await games.registerDeployment(_url.text.trim(), gameId: widget.gameId);
      _snack('URL registrada. Olha o telão!');
    } on GameError catch (e) {
      _snack(e.message);
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Laboratório do impostor', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        const Text(
          'Descreva como a máquina deve escrever para parecer gente. '
          'Teste contra as perguntas abaixo e mande para o jogo.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _prompt,
          maxLength: maxPromptChars,
          // Habilita o "Usar no jogo" assim que tiver texto.
          onChanged: (_) => setState(() {}),
          minLines: 4,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Estilo e personalidade',
            hintText:
                'Ex.: dev cansado de sexta-feira, responde curto, sem '
                'pontuação, faz piada de deploy…',
          ),
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _testing ? null : _test,
                icon: const Icon(Icons.science),
                label: const Text('Testar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _sending || _prompt.text.trim().isEmpty
                    ? null
                    : _send,
                icon: const Icon(Icons.send),
                label: const Text('Usar no jogo'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (final (i, q) in sampleQuestions.indexed)
          Card(
            child: ListTile(
              title: Text(q, style: theme.textTheme.bodySmall),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _errors[i] != null
                    ? Text(
                        _errors[i]!,
                        style: TextStyle(color: theme.colorScheme.error),
                      )
                    : _results[i] != null
                    ? Text(_results[i]!, style: theme.textTheme.bodyLarge)
                    : _testing
                    ? const LinearProgressIndicator()
                    : const Text('—'),
              ),
              leading: const Icon(Icons.smart_toy, color: AppColors.machine),
            ),
          ),
        const Divider(height: 48),
        Text('Publicou seu app?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'URL do Hosting',
            hintText: 'https://meu-projeto.web.app',
          ),
        ),
        const SizedBox(height: 8),
        FilledButton.tonal(
          onPressed: _registering ? null : _register,
          child: const Text('Registrar no telão'),
        ),
      ],
    );
  }
}
