import 'package:flutter/material.dart';

import '../../services/game_service.dart';
import '../../services/models.dart';

/// Suas respostas nas rodadas já reveladas: quantas cédulas cada uma
/// apareceu e quantas vezes foi apontada como máquina.
class MyCardsView extends StatefulWidget {
  const MyCardsView({super.key, required this.gameId});

  final String gameId;

  @override
  State<MyCardsView> createState() => _MyCardsViewState();
}

class _MyCardsViewState extends State<MyCardsView> {
  late Future<List<(Round, Answer?)>> _future = _load();

  Future<List<(Round, Answer?)>> _load() async {
    final rounds = await games.revealedRounds(widget.gameId);
    return [
      for (final r in rounds) (r, await games.myAnswer(widget.gameId, r.id)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _future = _load());
        await _future;
      },
      child: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          final items = snap.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Text('Minhas cartas', style: theme.textTheme.headlineSmall),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _future = _load()),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (items == null)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                const Text('Aparecem aqui depois da primeira revelação.'),
              for (final (round, answer) in items ?? const <(Round, Answer?)>[])
                Card(
                  child: ListTile(
                    title: Text(answer?.text ?? 'Você não respondeu.'),
                    subtitle: Text(
                      'Rodada ${round.number} · ${round.question}',
                    ),
                    trailing: answer == null
                        ? null
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${answer.picks} '),
                                  const Icon(Icons.smart_toy, size: 16),
                                ],
                              ),
                              Text(
                                'em ${answer.appearances} cédulas',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
