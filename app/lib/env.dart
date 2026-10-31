/// Endereços do backend. Callables em Dart são chamadas **pela URL**
/// (`httpsCallableFromUrl`), não pelo nome.
library;

/// `flutter run -d chrome --dart-define=EMULATOR=true` aponta tudo para os
/// emuladores locais (auth 9099, firestore 8080, functions 5001).
const useEmulator = bool.fromEnvironment('EMULATOR');

const projectId = 'who-is-the-machine';
const region = 'southamerica-east1';

/// Sufixo que o Cloud Run dá aos serviços deste projeto nesta região.
const _cloudRunHash = 'duckgnyuha-rj';

/// URL de uma function pelo nome. O Cloud Run só aceita minúsculas, então
/// `joinGame` vira `https://joingame-duckgnyuha-rj.a.run.app`.
String functionUrl(String name) => useEmulator
    ? 'http://127.0.0.1:5001/$projectId/$region/${name.toLowerCase()}'
    : 'https://${name.toLowerCase()}-$_cloudRunHash.a.run.app';

/// Modelo do laboratório: o mesmo que gera os impostores no servidor.
const impostorModel = 'gemini-3.8-flash';
