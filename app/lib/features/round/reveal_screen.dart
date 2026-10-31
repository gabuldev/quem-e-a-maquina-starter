import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/firebase.dart';
import '../../core/theme.dart';
import '../../services/game_service.dart';
import '../../services/models.dart';
import '../widgets/countdown.dart';
import '../widgets/playing_card.dart';

/// Fase `revealing`: as cartas das suas cédulas viram todas juntas,
/// mostrando quem era humano e quem era máquina. Confete se acertou.
class RevealScreen extends StatefulWidget {
  const RevealScreen({super.key, required this.game, required this.round});

  final Game game;
  final Round round;

  @override
  State<RevealScreen> createState() => _RevealScreenState();
}

class _RevealScreenState extends State<RevealScreen> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 2));
  Map<String, Answer>? _answers;
  List<BallotDoc> _ballots = const [];
  var _flipped = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final gameId = widget.game.id;
    final roundId = widget.round.id;
    // As respostas só ficam legíveis agora (rules), por isso o get aqui.
    final answers = await games.answers(gameId, roundId);
    final ballots = await games.myBallots(gameId, roundId).first;
    if (!mounted) return;
    setState(() {
      _answers = answers;
      _ballots = ballots.where((b) => b.votedAnswerId != null).toList();
    });
    // Um respiro antes de virar, para dar suspense.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _flipped = true);
    if (_correct > 0) {
      HapticFeedback.heavyImpact();
      _confetti.play();
    }
  }

  int get _correct => _ballots
      .where((b) => _answers?[b.votedAnswerId]?.isImpostor ?? false)
      .length;

  Answer? get _mine =>
      _answers?.values.where((a) => a.authorUid == currentUid).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answers = _answers;
    final reveal = widget.round.reveal ?? const {};
    final mine = _mine;
    final points = _correct + (mine?.picks ?? 0) * 3;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Text('Revelação', style: theme.textTheme.titleMedium),
                const Spacer(),
                Countdown(
                  endsAt: widget.round.phaseEndsAt,
                  gameId: widget.game.id,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.round.question,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (answers == null)
              const Center(child: CircularProgressIndicator())
            else ...[
              _Summary(
                points: points,
                correct: _correct,
                ballots: _ballots.length,
                fooled: mine?.picks ?? 0,
                mine: mine,
              ),
              const SizedBox(height: 16),
              if (reveal['mostFoolingText'] != null)
                _MostFooling(reveal: reveal),
              const SizedBox(height: 16),
              for (final (i, ballot) in _ballots.indexed) ...[
                Text('Cédula ${i + 1}', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                _BallotReveal(
                  ballot: ballot,
                  answers: answers,
                  flipped: _flipped,
                ),
                const SizedBox(height: 16),
              ],
              if (_ballots.isEmpty) const Text('Você não votou nesta rodada.'),
            ],
          ],
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirectionality: BlastDirectionality.explosive,
          numberOfParticles: 30,
          colors: const [
            AppColors.accent,
            AppColors.machine,
            AppColors.human,
            Colors.white,
          ],
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.points,
    required this.correct,
    required this.ballots,
    required this.fooled,
    required this.mine,
  });

  final int points;
  final int correct;
  final int ballots;
  final int fooled;
  final Answer? mine;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('+$points pontos', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(
              'Achou a máquina em $correct de $ballots cédulas (+$correct).',
            ),
            if (mine != null)
              Text(
                fooled == 0
                    ? 'Ninguém achou que sua resposta era da máquina.'
                    : '$fooled ${fooled == 1 ? 'pessoa achou' : 'pessoas acharam'} '
                          'que sua resposta era da máquina (+${fooled * 3}).',
              ),
          ],
        ),
      ),
    );
  }
}

class _MostFooling extends StatelessWidget {
  const _MostFooling({required this.reveal});

  final Map<String, dynamic> reveal;

  @override
  Widget build(BuildContext context) {
    final picks = reveal['mostFoolingPicks'] ?? 0;
    return Card(
      color: AppColors.felt,
      child: ListTile(
        leading: const Icon(Icons.emoji_events, color: AppColors.accent),
        title: Text('"${reveal['mostFoolingText']}"'),
        subtitle: Text(
          'Resposta mais confundida com a máquina: '
          '${reveal['mostFoolingNickname'] ?? '?'} ($picks votos)',
        ),
      ),
    );
  }
}

class _BallotReveal extends StatelessWidget {
  const _BallotReveal({
    required this.ballot,
    required this.answers,
    required this.flipped,
  });

  final BallotDoc ballot;
  final Map<String, Answer> answers;
  final bool flipped;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth > 700 ? 4 : 2;
        return GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: [
            for (final id in ballot.answerIds)
              PlayingCard(
                text: answers[id]?.text ?? '(oculta)',
                isImpostor: answers[id]?.isImpostor ?? false,
                revealed: flipped,
                selected: id == ballot.votedAnswerId,
                footer: id == ballot.votedAnswerId ? 'seu voto' : null,
              ),
          ],
        );
      },
    );
  }
}
