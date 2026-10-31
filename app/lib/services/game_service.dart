/// Tudo que o app conversa com o backend: callables (escrita) e
/// snapshots (leitura). As telas não tocam em Firebase direto.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

import '../core/firebase.dart';
import '../env.dart';
import 'models.dart';

/// Erro de callable já em português para mostrar na tela.
class GameError implements Exception {
  GameError(this.code, this.message);

  /// `failed-precondition`, `resource-exhausted`, `not-found`...
  final String code;
  final String message;

  @override
  String toString() => message;
}

class GameService {
  GameService._();
  static final instance = GameService._();

  final _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _game(String id) =>
      _db.doc('games/$id');
  DocumentReference<Map<String, dynamic>> _round(String g, String r) =>
      _db.doc('games/$g/rounds/$r');

  // ------------------------------------------------------------ callables

  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, Object?>? data,
  ]) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallableFromUrl(functionUrl(name))
          .call<Map<String, dynamic>>(data);
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      // A mensagem do servidor já é para gente; tira o " [400]" do fim.
      final message = (e.message ?? '').replaceFirst(
        RegExp(r'\s*\[\d+\]$'),
        '',
      );
      throw GameError(e.code, message.isEmpty ? _fallback(e.code) : message);
    }
  }

  static String _fallback(String code) => switch (code) {
    'unauthenticated' => 'Sessão expirou. Recarregue a página.',
    'permission-denied' => 'Sem permissão para isso.',
    'not-found' => 'Não encontrado.',
    'resource-exhausted' => 'Limite atingido.',
    'unavailable' || 'internal' => 'O servidor tropeçou. Tente de novo.',
    _ => 'Algo deu errado ($code).',
  };

  /// Devolve `(gameId, nickname)`; o nickname pode voltar com "(2)".
  Future<({String gameId, String nickname})> joinGame(
    String code,
    String nickname,
  ) async {
    final r = await _call('joinGame', {'code': code, 'nickname': nickname});
    return (gameId: r['gameId'] as String, nickname: r['nickname'] as String);
  }

  Future<void> submitAnswer(String gameId, String roundId, String text) =>
      _call('submitAnswer', {
        'gameId': gameId,
        'roundId': roundId,
        'text': text,
      });

  Future<Ballot> getBallot(String gameId, String roundId) async {
    final r = await _call('getBallot', {'gameId': gameId, 'roundId': roundId});
    return Ballot(r['ballotId'] as String, [
      for (final c in (r['cards'] as List).cast<Map>())
        BallotCard(c['answerId'] as String, c['text'] as String),
    ]);
  }

  Future<void> castVote(
    String gameId,
    String roundId,
    String ballotId,
    String answerId,
  ) => _call('castVote', {
    'gameId': gameId,
    'roundId': roundId,
    'ballotId': ballotId,
    'answerId': answerId,
  });

  Future<void> submitPrompt(String text) =>
      _call('submitPrompt', {'text': text});

  Future<void> registerDeployment(String url, {String? gameId}) =>
      _call('registerDeployment', {'url': url, 'gameId': ?gameId});

  /// O que o telão chama a cada 30 s. É `onRequest`, não callable.
  Future<void> tick(String gameId) async {
    try {
      await http.get(Uri.parse('${functionUrl('tick')}?game=$gameId'));
    } catch (_) {
      // Telão não pode cair por um tick perdido; o próximo resolve.
    }
  }

  // ---------------------------------------------------------------- admin

  Future<String> createGame(String name, String preset) async {
    final r = await _call('createGame', {'name': name, 'preset': preset});
    return r['gameId'] as String;
  }

  Future<void> startGame(String id) => _call('startGame', {'gameId': id});
  Future<void> pauseGame(String id) => _call('pauseGame', {'gameId': id});
  Future<void> resumeGame(String id) => _call('resumeGame', {'gameId': id});
  Future<void> endGame(String id) => _call('endGame', {'gameId': id});
  Future<void> adminHide(String gameId, String roundId, String answerId) =>
      _call('adminHide', {
        'gameId': gameId,
        'roundId': roundId,
        'answerId': answerId,
      });

  // ------------------------------------------------------------- leituras

  Stream<Game?> game(String id) =>
      _game(id).snapshots().map((s) => s.exists ? Game(s.id, s.data()!) : null);

  Stream<Round?> round(String gameId, String roundId) => _round(
    gameId,
    roundId,
  ).snapshots().map((s) => s.exists ? Round(s.id, s.data()!) : null);

  Stream<Board?> board(String gameId) => _game(gameId)
      .collection('board')
      .doc('current')
      .snapshots()
      .map((s) => s.exists ? Board(s.data()!) : null);

  Stream<Player?> me(String gameId) => _game(gameId)
      .collection('players')
      .doc(currentUid)
      .snapshots()
      .map((s) => s.exists ? Player(s.id, s.data()!) : null);

  Future<bool> isPlayer(String gameId) async =>
      (await _game(gameId).collection('players').doc(currentUid).get()).exists;

  Stream<List<Player>> players(String gameId) => _game(gameId)
      .collection('players')
      .orderBy('joinedAt')
      .snapshots()
      .map((q) => [for (final d in q.docs) Player(d.id, d.data())]);

  /// As cédulas do próprio jogador (as rules só deixam ler as suas).
  Stream<List<BallotDoc>> myBallots(String gameId, String roundId) =>
      _round(gameId, roundId)
          .collection('ballots')
          .where('voterUid', isEqualTo: currentUid)
          .snapshots()
          .map((q) => [for (final d in q.docs) BallotDoc(d.id, d.data())]);

  /// Todas as respostas da rodada. Só depois da revelação (rules).
  Future<Map<String, Answer>> answers(String gameId, String roundId) async {
    final q = await _round(gameId, roundId).collection('answers').get();
    return {for (final d in q.docs) d.id: Answer(d.id, d.data())};
  }

  /// Admin: respostas da rodada em andamento, para ocultar alguma.
  Stream<List<Answer>> liveAnswers(String gameId, String roundId) =>
      _round(gameId, roundId)
          .collection('answers')
          .snapshots()
          .map((q) => [for (final d in q.docs) Answer(d.id, d.data())]);

  /// Rodadas já reveladas, mais recentes primeiro.
  Future<List<Round>> revealedRounds(String gameId) async {
    final q = await _game(gameId)
        .collection('rounds')
        .where('status', whereIn: ['revealing', 'closed'])
        .get();
    return [for (final d in q.docs) Round(d.id, d.data())]
      ..sort((a, b) => b.number.compareTo(a.number));
  }

  /// A resposta do jogador numa rodada já revelada, se houver.
  Future<Answer?> myAnswer(String gameId, String roundId) async {
    final q = await _round(gameId, roundId)
        .collection('answers')
        .where('authorUid', isEqualTo: currentUid)
        .limit(1)
        .get();
    return q.docs.isEmpty ? null : Answer(q.docs.first.id, q.docs.first.data());
  }

  /// O prompt que o jogador já enviou (só o dono lê).
  Future<String?> myPrompt() async =>
      (await _db.doc('prompts/$currentUid').get()).data()?['text'] as String?;

  Stream<List<Deployment>> deployments(String gameId) => _db
      .collection('deployments')
      .where('gameId', isEqualTo: gameId)
      .snapshots()
      .map((q) => [for (final d in q.docs) Deployment(d.data())]);
}

/// Atalho usado pelas telas: `games.joinGame(...)`.
GameService get games => GameService.instance;
