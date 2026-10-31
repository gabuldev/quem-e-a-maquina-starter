import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Carta de baralho com flip 3D: `AnimationController` +
/// `Transform(Matrix4.rotationY)`. Sem engine de jogo.
///
/// [revealed] vira a carta. A frente é o texto da resposta; o verso
/// mostra se era humano ou máquina.
class PlayingCard extends StatefulWidget {
  const PlayingCard({
    super.key,
    required this.text,
    this.revealed = false,
    this.isImpostor = false,
    this.selected = false,
    this.footer,
    this.onTap,
  });

  final String text;
  final bool revealed;
  final bool isImpostor;

  /// A carta que o jogador apontou como máquina.
  final bool selected;

  /// Linha extra no verso (por exemplo, o nickname do autor).
  final String? footer;
  final VoidCallback? onTap;

  @override
  State<PlayingCard> createState() => _PlayingCardState();
}

class _PlayingCardState extends State<PlayingCard>
    with SingleTickerProviderStateMixin {
  late final _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
    value: widget.revealed ? 1 : 0,
  );

  @override
  void didUpdateWidget(PlayingCard old) {
    super.didUpdateWidget(old);
    if (widget.revealed != old.revealed) {
      widget.revealed ? _flip.forward() : _flip.reverse();
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (context, _) {
          final t = Curves.easeInOutBack.transform(_flip.value).clamp(0.0, 1.0);
          final angle = t * pi;
          final showBack = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // perspectiva
              ..rotateY(angle),
            child: showBack
                // O verso fica espelhado depois de 180°; desespelha.
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(pi),
                    child: _back(context),
                  )
                : _front(context),
          );
        },
      ),
    );
  }

  Widget _frame({required Widget child, required Color color, Color? border}) =>
      AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: border ?? Colors.black12,
            width: border == null ? 1 : 4,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 6),
              color: Colors.black38,
            ),
          ],
        ),
        child: child,
      );

  Widget _front(BuildContext context) => _frame(
    color: AppColors.card,
    border: widget.selected ? AppColors.accent : null,
    child: Center(
      child: Text(
        widget.text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.ink, fontSize: 17, height: 1.3),
      ),
    ),
  );

  Widget _back(BuildContext context) {
    final color = widget.isImpostor ? AppColors.machine : AppColors.human;
    return _frame(
      color: color,
      border: widget.selected ? AppColors.accent : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isImpostor ? Icons.smart_toy : Icons.person,
            size: 36,
            color: Colors.white,
          ),
          const SizedBox(height: 4),
          Text(
            widget.isImpostor ? 'MÁQUINA' : 'HUMANO',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              widget.text,
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          if (widget.footer != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.footer!,
              style: const TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
