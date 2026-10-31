/// Atalho da moderação: barra o óbvio sem gastar uma chamada ao Gemini.
/// Não é exaustiva de propósito; o que passar daqui ainda vai para o modelo.
/// Fica no shared para o app poder fazer pré-checagem (bônus do workshop).
library;

/// Termos já normalizados (minúsculos, sem acento). Comparados por palavra
/// inteira, então "bicha" não barra "bichano". Palavrão leve fica de fora:
/// o `GAME.md` permite.
const blockedTerms = {
  // ódio e preconceito
  'viado', 'viadinho', 'bicha', 'traveco', 'sapatao', 'crioulo',
  'retardado', 'mongoloide', 'nigger', 'faggot',
  // assédio e violência sexual
  'vadia', 'arrombado', 'estupro', 'estuprar', 'pedofilo',
  // sexual explícito
  'buceta', 'piroca', 'xoxota', 'punheta',
};

final _url = RegExp(
  r'https?://|www\.|\b[a-z0-9-]+\.(com|net|org|io|dev|app|br|xyz|ly|gg|me)\b',
  caseSensitive: false,
);
final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');

const _accents = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'ê': 'e',
  'è': 'e',
  'ë': 'e',
  'í': 'i',
  'ì': 'i',
  'î': 'i',
  'ï': 'i',
  'ó': 'o',
  'ò': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ù': 'u',
  'û': 'u',
  'ü': 'u',
  'ç': 'c',
};

// Troca de letra por número/símbolo para fugir do filtro ("v1ad0").
const _leet = {
  '0': 'o',
  '1': 'i',
  '3': 'e',
  '4': 'a',
  '5': 's',
  '@': 'a',
  r'$': 's',
};

/// Motivo do bloqueio, ou `null` se o atalho não viu nada.
String? blocklistReason(String text) {
  // Link e email olham o texto cru; a normalização abaixo estraga o `@`.
  if (_url.hasMatch(text)) return 'link';
  if (_email.hasMatch(text)) return 'dados pessoais (email)';

  final normalized = text
      .toLowerCase()
      .split('')
      .map((c) => _accents[c] ?? _leet[c] ?? c)
      .join();
  final words = normalized.split(RegExp(r'[^a-z]+'));
  for (final word in words) {
    if (blockedTerms.contains(word)) return 'termo bloqueado';
  }
  return null;
}
