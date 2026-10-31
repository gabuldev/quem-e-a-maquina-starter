import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme.dart';
import '../../services/game_service.dart';
import '../../services/models.dart';
import '../widgets/countdown.dart';

/// Telão: `/board?game=DASH`, em tela cheia no projetor. Lê só
/// `board/current` (mais a rodada, para a contagem de respostas, e os
/// deployments). É também o "relógio" do jogo: chama `tick` a cada 30 s
/// e logo depois de cada prazo vencer.
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.gameId});

  final String gameId;

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  late final Timer _heartbeat;
  Timer? _atDeadline;
  DateTime? _scheduledFor;

  @override
  void initState() {
    super.initState();
    games.tick(widget.gameId);
    _heartbeat = Timer.periodic(
      const Duration(seconds: 30),
      (_) => games.tick(widget.gameId),
    );
  }

  /// Agenda um tick 1 s depois do prazo, para a virada não esperar o
  /// próximo batimento de 30 s.
  void _scheduleDeadline(DateTime? endsAt) {
    if (endsAt == null || endsAt == _scheduledFor) return;
    _scheduledFor = endsAt;
    _atDeadline?.cancel();
    final wait = endsAt.difference(DateTime.now()) + const Duration(seconds: 1);
    _atDeadline = Timer(
      wait.isNegative ? Duration.zero : wait,
      () => games.tick(widget.gameId),
    );
  }

  @override
  void dispose() {
    _heartbeat.cancel();
    _atDeadline?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.table,
      body: StreamBuilder<Board?>(
        stream: games.board(widget.gameId),
        builder: (context, snap) {
          final board = snap.data;
          if (board == null) {
            return Center(
              child: Text(
                snap.connectionState == ConnectionState.waiting
                    ? 'Carregando…'
                    : 'Jogo ${widget.gameId} não encontrado.',
              ),
            );
          }
          _scheduleDeadline(
            board.gameStatus == 'running' ? board.phaseEndsAt : null,
          );
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(board: board, gameId: widget.gameId),
                const SizedBox(height: 24),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _Main(board: board, gameId: widget.gameId),
                      ),
                      const SizedBox(width: 32),
                      Expanded(flex: 2, child: _Top10(board: board)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Deployments(gameId: widget.gameId),
              ],
            ),
          );
        },
      ),
    );
  }
}

String joinUrl(String gameId) => '${Uri.base.origin}/?game=$gameId';

class _Header extends StatelessWidget {
  const _Header({required this.board, required this.gameId});

  final Board board;
  final String gameId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        const Icon(Icons.smart_toy, size: 48, color: AppColors.machine),
        const SizedBox(width: 16),
        Text(
          'Quem é a máquina?',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        if (board.gameStatus == 'paused')
          const Chip(label: Text('PAUSADO'), avatar: Icon(Icons.pause)),
        const SizedBox(width: 16),
        Text(
          '${board.playerCount} jogadores · código $gameId',
          style: theme.textTheme.headlineSmall,
        ),
      ],
    );
  }
}

class _Main extends StatelessWidget {
  const _Main({required this.board, required this.gameId});

  final Board board;
  final String gameId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final big = theme.textTheme.displayMedium?.copyWith(
      fontWeight: FontWeight.bold,
    );

    if (board.gameStatus == 'lobby') {
      return Row(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: QrImageView(data: joinUrl(gameId), size: 320),
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Entre pelo QR', style: big),
                const SizedBox(height: 16),
                SelectableText(
                  joinUrl(gameId),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                Text('Código', style: theme.textTheme.titleLarge),
                Text(
                  gameId,
                  style: theme.textTheme.displayLarge?.copyWith(
                    letterSpacing: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (board.gameStatus == 'ended') {
      return Center(child: Text('Fim de jogo!', style: big));
    }

    final phase = board.phase;
    final header = Row(
      children: [
        Text(switch (phase) {
          'answering' => 'Rodada ${board.roundNumber} · respondam!',
          'voting' => 'Rodada ${board.roundNumber} · votem!',
          _ => 'Rodada ${board.roundNumber} · revelação',
        }, style: theme.textTheme.headlineMedium),
        const Spacer(),
        Countdown(
          endsAt: board.phaseEndsAt,
          style: theme.textTheme.displaySmall,
        ),
      ],
    );

    if (phase == 'revealing') {
      final reveal = board.lastReveal ?? const {};
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 24),
          Text(board.question ?? '', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 32),
          Text(
            'A resposta humana que mais pareceu máquina:',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (reveal['mostFoolingText'] == null)
            Text('Ninguém caiu desta vez.', style: big)
          else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '"${reveal['mostFoolingText']}"',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '— ${reveal['mostFoolingNickname']} · '
              '${reveal['mostFoolingPicks']} pessoas acharam que era a IA',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.accent,
              ),
            ),
          ],
          const Spacer(),
          Text(
            '${reveal['votes'] ?? 0} votos nesta rodada',
            style: theme.textTheme.titleLarge,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const Spacer(),
        Text(board.question ?? '', style: big),
        const Spacer(),
        if (phase == 'answering' && board.roundId != null)
          StreamBuilder<Round?>(
            stream: games.round(gameId, board.roundId!),
            builder: (context, snap) => Text(
              '${snap.data?.humanCount ?? 0} respostas',
              style: theme.textTheme.headlineMedium,
            ),
          )
        else
          Text(
            '${board.voteCount} votos computados',
            style: theme.textTheme.headlineMedium,
          ),
      ],
    );
  }
}

class _Top10 extends StatelessWidget {
  const _Top10({required this.board});

  final Board board;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.felt,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Top 10', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),
          if (board.top10.isEmpty) const Text('Depois da primeira revelação.'),
          for (final (i, p) in board.top10.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${i + 1}.',
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      p.nickname,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  Text(
                    '${p.score}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Deployments extends StatelessWidget {
  const _Deployments({required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Deployment>>(
      stream: games.deployments(gameId),
      builder: (context, snap) {
        final list = snap.data ?? const [];
        if (list.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final d in list)
              Chip(
                avatar: const Icon(Icons.public, size: 18),
                label: Text(
                  '${d.nickname ?? ''} ${Uri.parse(d.url).host}'.trim(),
                ),
              ),
          ],
        );
      },
    );
  }
}
