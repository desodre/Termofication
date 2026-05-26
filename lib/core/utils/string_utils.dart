/// Mapa de normalização de caracteres acentuados do Português.
/// Remove acentos de vogais e converte ç para c.
const Map<String, String> _accentMap = {
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'í': 'i',
  'ï': 'i',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ú': 'u',
  'ü': 'u',
  'ç': 'c',
  'Á': 'A',
  'À': 'A',
  'Â': 'A',
  'Ã': 'A',
  'Ä': 'A',
  'É': 'E',
  'Ê': 'E',
  'Ë': 'E',
  'Í': 'I',
  'Ï': 'I',
  'Ó': 'O',
  'Ô': 'O',
  'Õ': 'O',
  'Ö': 'O',
  'Ú': 'U',
  'Ü': 'U',
  'Ç': 'C',
};

/// Remove acentos de vogais e converte ç/Ç para c/C.
String normalizePortuguese(String word) {
  final buffer = StringBuffer();
  for (int i = 0; i < word.length; i++) {
    final char = word[i];
    buffer.write(_accentMap[char] ?? char);
  }
  return buffer.toString();
}
