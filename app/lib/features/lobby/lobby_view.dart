import 'package:flutter/material.dart';

import '../../services/game_service.dart';
import '../../services/models.dart';

/// Antes do `startGame`: quem já entrou, ao vivo.
class LobbyView extends StatelessWidget {
  const LobbyView({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<Player>>(
      stream: games.players(game.id),
      builder: (context, snap) {
        final players = snap.data ?? const [];
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(game.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text('Código ${game.id}', style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
            const Text('Esperando o jogo começar…'),
            const SizedBox(height: 24),
            Text(
              '${players.length} ${players.length == 1 ? 'jogador' : 'jogadores'}',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in players) Chip(label: Text(p.nickname)),
              ],
            ),
          ],
        );
      },
    );
  }
}
