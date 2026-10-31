/// O laboratório de prompt: chama o Gemini **do cliente**, via Firebase AI
/// Logic, com o mesmo prompt que o servidor usa para gerar os impostores
/// de verdade (`package:shared/impostor_prompt.dart`).
///
/// No starter do workshop, o corpo de [ImpostorService.generate] vem vazio:
/// é o TODO 1 do participante.
library;

// ignore_for_file: unused_import

import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:shared/impostor_prompt.dart';
import 'package:shared/limits.dart';

import '../env.dart';

class ImpostorService {
  /// Responde [question] no estilo descrito em [userPrompt], como o
  /// impostor responderia no jogo. Devolve só o texto da resposta.
  Future<String> generate({
    required String userPrompt,
    required String question,
  }) async {
    // TODO 1: chame o Gemini via Firebase AI Logic com saída estruturada.
    //
    // Dicas:
    //  - FirebaseAI.googleAI().generativeModel(model: impostorModel, ...)
    //  - GenerationConfig(responseMimeType: 'application/json',
    //      responseJsonSchema: impostorSchema)
    //  - buildImpostorPrompt(userPrompt: ..., question: ...)
    //  - model.generateContent([Content.text(prompt)]) → response.text
    //  - jsonDecode e valide { "answer": String }; corte em maxAnswerChars
    throw UnimplementedError('TODO 1');
  }
}
