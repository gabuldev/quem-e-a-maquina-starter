/// Leitura dos documentos do Firestore. O cliente só lê; quem escreve é o
/// servidor, então aqui não há `toMap`.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared/models.dart';

DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;
int _int(Object? v) => (v as num?)?.toInt() ?? 0;

class Game {
  Game(this.id, Map<String, dynamic> d)
    : name = d['name'] as String? ?? id,
      status = GameStatus.values.byName(d['status'] as String),
      config = GameConfig.fromMap(d['config'] as Map<String, dynamic>),
      currentRoundId = d['currentRoundId'] as String?;

  final String id;
  final String name;
  final GameStatus status;
  final GameConfig config;
  final String? currentRoundId;
}

class Round {
  Round(this.id, Map<String, dynamic> d)
    : number = _int(d['number']),
      question = d['question'] as String? ?? '',
      status = RoundStatus.values.byName(d['status'] as String),
      phaseEndsAt = _date(d['phaseEndsAt']),
      humanCount = _int(d['humanCount']),
      reveal = d['reveal'] as Map<String, dynamic>?;

  final String id;
  final int number;
  final String question;
  final RoundStatus status;
  final DateTime? phaseEndsAt;
  final int humanCount;

  /// Só existe a partir de `revealing`.
  final Map<String, dynamic>? reveal;
}

class Player {
  Player(this.uid, Map<String, dynamic> d)
    : nickname = d['nickname'] as String,
      score = _int(d['score']),
      correctGuesses = _int(d['correctGuesses']),
      timesFooled = _int(d['timesFooled']);

  final String uid;
  final String nickname;
  final int score;
  final int correctGuesses;
  final int timesFooled;
}

/// Carta da cédula: o servidor manda só id e texto, nunca quem escreveu.
class BallotCard {
  const BallotCard(this.answerId, this.text);
  final String answerId;
  final String text;
}

class Ballot {
  const Ballot(this.id, this.cards);
  final String id;
  final List<BallotCard> cards;
}

/// Cédula como está no Firestore (o dono pode ler a dele).
class BallotDoc {
  BallotDoc(this.id, Map<String, dynamic> d)
    : answerIds = (d['answerIds'] as List).cast<String>(),
      votedAnswerId = d['votedAnswerId'] as String?;

  final String id;
  final List<String> answerIds;
  final String? votedAnswerId;
}

/// Resposta completa. Legível só depois da revelação.
class Answer {
  Answer(this.id, Map<String, dynamic> d)
    : text = d['text'] as String,
      authorUid = d['authorUid'] as String?,
      isImpostor = d['isImpostor'] == true,
      appearances = _int(d['appearances']),
      picks = _int(d['picks']),
      moderation = d['moderation'] as String? ?? 'ok';

  final String id;
  final String text;
  final String? authorUid;
  final bool isImpostor;
  final int appearances;
  final int picks;
  final String moderation;
}

class Board {
  Board(Map<String, dynamic> d)
    : gameStatus = d['gameStatus'] as String? ?? 'lobby',
      name = d['name'] as String? ?? '',
      roundId = d['roundId'] as String?,
      roundNumber = _int(d['roundNumber']),
      question = d['question'] as String?,
      phase = d['phase'] as String?,
      phaseEndsAt = _date(d['phaseEndsAt']),
      playerCount = _int(d['playerCount']),
      voteCount = _int(d['voteCount']),
      top10 = [
        for (final e in (d['top10'] as List? ?? []).cast<Map>())
          (nickname: e['nickname'] as String, score: _int(e['score'])),
      ],
      lastReveal = d['lastReveal'] as Map<String, dynamic>?;

  final String gameStatus;
  final String name;
  final String? roundId;
  final int roundNumber;
  final String? question;
  final String? phase;
  final DateTime? phaseEndsAt;
  final int playerCount;
  final int voteCount;
  final List<({String nickname, int score})> top10;
  final Map<String, dynamic>? lastReveal;
}

class Deployment {
  Deployment(Map<String, dynamic> d)
    : url = d['url'] as String,
      nickname = d['nickname'] as String?;

  final String url;
  final String? nickname;
}
