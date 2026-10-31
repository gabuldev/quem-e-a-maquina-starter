import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/game_service.dart';
import '../../services/models.dart';
import '../widgets/countdown.dart';
import '../widgets/playing_card.dart';

/// Fase `voting`: 4 cartas, 3 humanas e 1 máquina. Toque = voto.
class BallotScreen extends StatefulWidget {
  const BallotScreen({super.key, required this.game, required this.round});

  final Game game;
  final Round round;

  @override
  State<BallotScreen> createState() => _BallotScreenState();
}

class _BallotScreenState extends State<BallotScreen>
    with SingleTickerProviderStateMixin {
  /// Entrada em leque: as cartas saem do monte uma depois da outra.
  late final _deal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  Ballot? _ballot;
  String? _voted;
  var _loading = true;
  var _voting = false;
  String? _error;

  /// `resource-exhausted`: usou todas as cédulas da rodada.
  var _done = false;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    _deal.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ballot = await games.getBallot(widget.game.id, widget.round.id);
      if (!mounted) return;
      setState(() {
        _ballot = ballot;
        _voted = null;
      });
      _deal.forward(from: 0);
    } on GameError catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.code == 'resource-exhausted') {
          _done = true;
        } else {
          _error = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _vote(BallotCard card) async {
    final ballot = _ballot;
    if (ballot == null || _voted != null || _voting) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _voting = true;
      _voted = card.answerId;
    });
    try {
      await games.castVote(
        widget.game.id,
        widget.round.id,
        ballot.id,
        card.answerId,
      );
    } on GameError catch (e) {
      if (mounted) {
        setState(() {
          _voted = null;
          _error = e.message;
        });
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final limit = widget.game.config.ballotsPerVoter;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StreamBuilder<List<BallotDoc>>(
                stream: games.myBallots(widget.game.id, widget.round.id),
                builder: (context, snap) {
                  final used = snap.data?.length ?? 0;
                  return Text(
                    'Cédula $used de $limit',
                    style: theme.textTheme.titleMedium,
                  );
                },
              ),
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
          const SizedBox(height: 4),
          Text(
            _voted == null
                ? 'Toque na carta que você acha que a máquina escreveu.'
                : 'Voto registrado. A revelação vem quando o tempo acabar.',
          ),
          const SizedBox(height: 12),
          Expanded(child: _body()),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          if (_voted != null && !_done)
            FilledButton.icon(
              onPressed: _loading || _voting ? null : _next,
              icon: const Icon(Icons.style),
              label: const Text('Pedir outra cédula'),
            ),
        ],
      ),
    );
  }

  Widget _body() {
    if (_done) {
      return const Center(
        child: Text(
          'Você usou todas as cédulas desta rodada.\nAguarde a revelação.',
          textAlign: TextAlign.center,
        ),
      );
    }
    final ballot = _ballot;
    if (ballot == null) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return Center(
        child: OutlinedButton(
          onPressed: _next,
          child: const Text('Tentar de novo'),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        // 2×2 no celular; 4 lado a lado em tela larga.
        final wide = box.maxWidth > 760;
        final cols = wide ? 4 : 2;
        const gap = 12.0;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        final h = wide
            ? box.maxHeight.clamp(0, 320).toDouble()
            : (box.maxHeight - gap) / 2;
        return Stack(
          children: [
            for (final (i, card) in ballot.cards.indexed)
              _dealt(
                index: i,
                left: (i % cols) * (w + gap),
                top: (i ~/ cols) * (h + gap),
                origin: Offset(box.maxWidth / 2 - w / 2, box.maxHeight),
                child: SizedBox(
                  width: w,
                  height: h,
                  child: PlayingCard(
                    text: card.text,
                    selected: _voted == card.answerId,
                    onTap: () => _vote(card),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Cada carta tem sua janela na animação (`Interval`): sai do monte
  /// embaixo, girada, e pousa no lugar dela.
  Widget _dealt({
    required int index,
    required double left,
    required double top,
    required Offset origin,
    required Widget child,
  }) {
    final curve = CurvedAnimation(
      parent: _deal,
      curve: Interval(
        index * 0.15,
        0.55 + index * 0.15,
        curve: Curves.easeOutBack,
      ),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final t = curve.value;
        final x = origin.dx + (left - origin.dx) * t;
        final y = origin.dy + (top - origin.dy) * t;
        return Positioned(
          left: x,
          top: y,
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.rotate(
              angle: (1 - t) * (index - 1.5) * 0.35,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
