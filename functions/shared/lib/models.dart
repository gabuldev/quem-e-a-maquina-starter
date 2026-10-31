/// Modelos compartilhados entre servidor e app: configuração do jogo,
/// presets e os status gravados no Firestore (como `enum.name`).
library;

import 'limits.dart';

/// Fica em `games/{id}.config`. Tempos em segundos.
class GameConfig {
  const GameConfig({
    required this.answerSecs,
    required this.voteSecs,
    required this.revealSecs,
    required this.ballotsPerVoter,
    required this.impostorsPerRound,
    required this.minHumanAnswers,
    required this.maxChars,
  });

  final int answerSecs;
  final int voteSecs;
  final int revealSecs;
  final int ballotsPerVoter;
  final int impostorsPerRound;
  final int minHumanAnswers;
  final int maxChars;

  factory GameConfig.fromMap(Map<String, dynamic> map) => GameConfig(
    // `num` porque o Firestore pode devolver int ou double.
    answerSecs: (map['answerSecs'] as num).toInt(),
    voteSecs: (map['voteSecs'] as num).toInt(),
    revealSecs: (map['revealSecs'] as num).toInt(),
    ballotsPerVoter: (map['ballotsPerVoter'] as num).toInt(),
    impostorsPerRound: (map['impostorsPerRound'] as num).toInt(),
    minHumanAnswers: (map['minHumanAnswers'] as num).toInt(),
    maxChars: (map['maxChars'] as num).toInt(),
  );

  Map<String, dynamic> toMap() => {
    'answerSecs': answerSecs,
    'voteSecs': voteSecs,
    'revealSecs': revealSecs,
    'ballotsPerVoter': ballotsPerVoter,
    'impostorsPerRound': impostorsPerRound,
    'minHumanAnswers': minHumanAnswers,
    'maxChars': maxChars,
  };
}

/// Presets do `createGame`. O admin escolhe pelo nome (`GamePreset.values.byName`).
enum GamePreset {
  /// Workshop: rodadas curtas, todo mundo na mesma sala.
  sala(
    GameConfig(
      answerSecs: 120,
      voteSecs: 90,
      revealSecs: 30,
      ballotsPerVoter: 5,
      impostorsPerRound: 6,
      minHumanAnswers: 3,
      maxChars: maxAnswerChars,
    ),
  ),

  /// Evento: rodadas longas, gente entrando e saindo entre palestras.
  devfest(
    GameConfig(
      answerSecs: 480,
      voteSecs: 480,
      revealSecs: 240,
      ballotsPerVoter: 5,
      impostorsPerRound: 6,
      minHumanAnswers: 3,
      maxChars: maxAnswerChars,
    ),
  );

  const GamePreset(this.config);

  final GameConfig config;
}

/// `games/{id}.status`.
enum GameStatus { lobby, running, paused, ended }

/// `rounds/{id}.status`. Ordem do ciclo: answering → voting → revealing → closed.
enum RoundStatus { answering, voting, revealing, closed, cancelled }
