/// Prompt do impostor. Mesmo código no servidor (impostores reais) e no app
/// (laboratório), para o laboratório ser espelho fiel do jogo.
library;

/// Monta o texto enviado ao Gemini a partir do estilo escrito pelo jogador.
String buildImpostorPrompt({
  required String userPrompt,
  required String question,
}) =>
    '''
Você está participando de um jogo. Responda a pergunta abaixo como uma pessoa real responderia,
em no máximo 140 caracteres, em português do Brasil. Não explique, não use aspas, não assine,
não diga que é uma IA.

Estilo e personalidade, definidos pelo jogador:
${userPrompt.trim()}

Pergunta: ${question.trim()}
''';

/// Schema da saída estruturada (`responseSchema`), no formato JSON da REST.
const impostorSchema = {
  'type': 'object',
  'properties': {
    'answer': {'type': 'string'},
  },
  'required': ['answer'],
};
