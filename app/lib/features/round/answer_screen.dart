import 'package:flutter/material.dart';
import 'package:shared/limits.dart';

import '../../services/game_service.dart';
import '../../services/models.dart';
import '../widgets/countdown.dart';

/// Fase `answering`: a pergunta, um campo de 140 caracteres, o relógio.
class AnswerScreen extends StatefulWidget {
  const AnswerScreen({super.key, required this.game, required this.round});

  final Game game;
  final Round round;

  @override
  State<AnswerScreen> createState() => _AnswerScreenState();
}

/// Rodadas já respondidas nesta aba. O cliente não pode ler as respostas
/// antes da revelação, então quem lembra é a memória (ou o servidor, que
/// recusa a segunda resposta).
final _answered = <String>{};

class _AnswerScreenState extends State<AnswerScreen> {
  final _text = TextEditingController();
  var _busy = false;
  String? _error;

  bool get _sent => _answered.contains(widget.round.id);

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await games.submitAnswer(widget.game.id, widget.round.id, text);
      _answered.add(widget.round.id);
    } on GameError catch (e) {
      if (e.message.contains('já respondeu')) {
        _answered.add(widget.round.id);
      } else {
        _error = e.message;
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Text(
              'Rodada ${widget.round.number}',
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            Countdown(endsAt: widget.round.phaseEndsAt, gameId: widget.game.id),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          widget.round.question,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        if (_sent)
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.check_circle,
                color: Colors.greenAccent,
              ),
              title: const Text('Resposta enviada'),
              subtitle: Text(
                '${widget.round.humanCount} respostas até agora. '
                'Quando o tempo acabar, começa a votação.',
              ),
            ),
          )
        else ...[
          TextField(
            controller: _text,
            maxLength: maxAnswerChars,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              hintText:
                  'Responda como você responderia. A IA vai tentar imitar.',
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          FilledButton(
            onPressed: _busy ? null : _send,
            child: _busy
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enviar'),
          ),
        ],
      ],
    );
  }
}
