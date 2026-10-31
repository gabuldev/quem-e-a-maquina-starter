import 'package:flutter/material.dart';
import 'package:shared/models.dart';

import '../../services/game_service.dart';
import '../../services/models.dart';
import '../lab/lab_screen.dart';
import '../leaderboard/leaderboard_view.dart';
import '../lobby/lobby_view.dart';
import '../my_cards/my_cards_view.dart';
import '../round/answer_screen.dart';
import '../round/ballot_screen.dart';
import '../round/reveal_screen.dart';

/// O jogo de um jogador. A aba "Jogo" troca de tela sozinha conforme
/// `games/{id}.status` e `rounds/{current}.status`: o servidor muda a
/// fase, o snapshot chega, a tela muda. Ninguém aperta "próximo".
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  var _tab = 0;

  /// Muda a cada vez que a aba "Minhas" é aberta: recarrega as cartas.
  var _myCardsVisit = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _PhaseView(gameId: widget.gameId),
      LeaderboardView(gameId: widget.gameId),
      MyCardsView(key: ValueKey(_myCardsVisit), gameId: widget.gameId),
      LabScreen(gameId: widget.gameId),
    ];
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<Player?>(
          stream: games.me(widget.gameId),
          builder: (context, snap) {
            final me = snap.data;
            return Text(
              me == null
                  ? 'Quem é a máquina?'
                  : '${me.nickname} · ${me.score} pts',
            );
          },
        ),
      ),
      body: SafeArea(
        child: IndexedStack(index: _tab, children: tabs),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() {
          if (i == 2 && _tab != 2) _myCardsVisit++;
          _tab = i;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.style), label: 'Jogo'),
          NavigationDestination(icon: Icon(Icons.leaderboard), label: 'Placar'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Minhas'),
          NavigationDestination(icon: Icon(Icons.science), label: 'Lab'),
        ],
      ),
    );
  }
}

class _PhaseView extends StatelessWidget {
  const _PhaseView({required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Game?>(
      stream: games.game(gameId),
      builder: (context, snap) {
        final game = snap.data;
        if (snap.hasError) return _StreamError(error: snap.error!);
        if (game == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return switch (game.status) {
          GameStatus.lobby => LobbyView(game: game),
          GameStatus.ended => _Message(
            icon: Icons.flag,
            title: 'Fim de jogo',
            body: 'Obrigado por jogar! Veja o placar final na aba Placar.',
          ),
          GameStatus.running || GameStatus.paused => Column(
            children: [
              if (game.status == GameStatus.paused)
                MaterialBanner(
                  content: const Text('Jogo pausado. O relógio volta já já.'),
                  leading: const Icon(Icons.pause_circle),
                  actions: [const SizedBox.shrink()],
                ),
              Expanded(child: _RoundView(game: game)),
            ],
          ),
        };
      },
    );
  }
}

class _RoundView extends StatelessWidget {
  const _RoundView({required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    final roundId = game.currentRoundId;
    if (roundId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<Round?>(
      stream: games.round(game.id, roundId),
      builder: (context, snap) {
        final round = snap.data;
        if (snap.hasError) return _StreamError(error: snap.error!);
        if (round == null) {
          return const Center(child: CircularProgressIndicator());
        }
        // A key troca a cada fase: cada tela nasce com estado limpo.
        final key = ValueKey('${round.id}-${round.status.name}');
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          // Só a tela nova aparece (com fade); sem as duas sobrepostas.
          layoutBuilder: (current, previous) => current ?? const SizedBox(),
          child: switch (round.status) {
            RoundStatus.answering => AnswerScreen(
              key: key,
              game: game,
              round: round,
            ),
            RoundStatus.voting => BallotScreen(
              key: key,
              game: game,
              round: round,
            ),
            RoundStatus.revealing || RoundStatus.closed => RevealScreen(
              key: key,
              game: game,
              round: round,
            ),
            RoundStatus.cancelled => _Message(
              key: key,
              icon: Icons.hourglass_empty,
              title: 'Rodada cancelada',
              body: 'Pouca gente respondeu. A próxima pergunta já vem.',
            ),
          },
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

/// Erro de leitura (rules, rede). Melhor mostrar do que girar para sempre.
class _StreamError extends StatelessWidget {
  const _StreamError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Não deu para carregar: $error', textAlign: TextAlign.center),
    ),
  );
}
