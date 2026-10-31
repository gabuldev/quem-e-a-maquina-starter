/// Limites de tamanho de texto. O app usa no contador do campo; o servidor
/// valida de novo (o cliente nunca é confiável).
library;

/// Resposta da rodada, humana ou impostor. O servidor corta o impostor aqui.
const maxAnswerChars = 140;

/// Nickname, único por jogo.
const maxNicknameChars = 20;

/// Prompt do impostor enviado pelo `submitPrompt`.
const maxPromptChars = 600;
