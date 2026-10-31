import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/game_service.dart';

/// Contagem regressiva até `phaseEndsAt`. Quem decide a virada de fase é o
/// servidor; aqui é só o relógio na tela.
///
/// Se o prazo passar e a fase não virar (telão fechado, por exemplo), pede
/// um `tick` depois de alguns segundos sorteados, para 100 celulares não
/// baterem no servidor no mesmo instante.
class Countdown extends StatefulWidget {
  const Countdown({super.key, required this.endsAt, this.gameId, this.style});

  final DateTime? endsAt;

  /// Com o id do jogo, o relógio cutuca o servidor quando o prazo vence.
  final String? gameId;
  final TextStyle? style;

  @override
  State<Countdown> createState() => _CountdownState();
}

class _CountdownState extends State<Countdown> {
  late final Timer _timer;
  Timer? _nudge;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
      _maybeNudge();
    });
  }

  @override
  void didUpdateWidget(Countdown old) {
    super.didUpdateWidget(old);
    // Fase nova (ou prazo estendido): cancela a cutucada pendente.
    if (old.endsAt != widget.endsAt) {
      _nudge?.cancel();
      _nudge = null;
    }
  }

  void _maybeNudge() {
    final end = widget.endsAt;
    final gameId = widget.gameId;
    if (end == null || gameId == null || _nudge != null) return;
    if (DateTime.now().isBefore(end)) return;
    final delay = Duration(seconds: 5 + Random().nextInt(10));
    _nudge = Timer(delay, () => games.tick(gameId));
  }

  @override
  void dispose() {
    _timer.cancel();
    _nudge?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final end = widget.endsAt;
    final left = end == null ? Duration.zero : end.difference(DateTime.now());
    final secs = left.isNegative ? 0 : left.inSeconds;
    final text = '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';
    final urgent = secs <= 10;
    return Text(
      text,
      style: (widget.style ?? Theme.of(context).textTheme.titleLarge)?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        color: urgent ? Colors.redAccent : null,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
