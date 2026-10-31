import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/game_service.dart';
import '../../services/models.dart';

/// Top 10 do `board/current` (atualizado na revelação) e a sua linha.
class LeaderboardView extends StatelessWidget {
  const LeaderboardView({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<Board?>(
      stream: games.board(gameId),
      builder: (context, snap) {
        final top = snap.data?.top10 ?? const [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Placar', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            const Text(
              '+1 por máquina encontrada · +3 cada vez que acharam '
              'que sua resposta era da máquina',
            ),
            const SizedBox(height: 16),
            StreamBuilder<Player?>(
              stream: games.me(gameId),
              builder: (context, me) => me.data == null
                  ? const SizedBox.shrink()
                  : Card(
                      color: AppColors.felt,
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text('Você: ${me.data!.nickname}'),
                        subtitle: Text(
                          '${me.data!.correctGuesses} máquinas encontradas · '
                          'enganou ${me.data!.timesFooled}×',
                        ),
                        trailing: Text(
                          '${me.data!.score}',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            if (top.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('O placar aparece depois da primeira revelação.'),
              ),
            for (final (i, p) in top.indexed)
              ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(p.nickname),
                trailing: Text('${p.score}', style: theme.textTheme.titleLarge),
              ),
          ],
        );
      },
    );
  }
}
