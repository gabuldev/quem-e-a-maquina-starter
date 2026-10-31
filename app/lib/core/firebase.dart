/// Inicialização do Firebase: um projeto só, login anônimo, emuladores
/// opcionais.
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../env.dart';
import '../firebase_options.dart';

Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Um projeto Firebase é o mundo: ninguém deve rodar `flutterfire configure`.
  assert(
    Firebase.app().options.projectId == projectId,
    'firebase_options.dart aponta para o projeto errado',
  );

  if (useEmulator) {
    // No web, o firebase_auth_web só liga o emulador de auth de forma
    // confiável em debug: em release ele restaura o usuário salvo antes e o
    // `useAuthEmulator` falha calado, mandando o login para a produção.
    if (!kDebugMode) {
      throw StateError('EMULATOR=true só com `flutter run` (debug).');
    }
    await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    // Functions não precisa: env.functionUrl já devolve a URL local.
  }
}

/// O `uid` anônimo é a identidade do jogador. Fica salvo no navegador, então
/// recarregar a página não cria um jogador novo.
Future<User> ensureSignedIn() async {
  final auth = FirebaseAuth.instance;
  return auth.currentUser ?? (await auth.signInAnonymously()).user!;
}

String get currentUid => FirebaseAuth.instance.currentUser!.uid;
