/// Helyettesítő a nem webes környezetekhez (pl. tesztek).
library;

Future<bool> shareOrDownloadTextFile({
  required String fileName,
  required String content,
}) async {
  throw UnsupportedError('A fájlmentés csak a webes változatban érhető el.');
}

Future<String?> pickTextFile() async {
  throw UnsupportedError('A fájlmegnyitás csak a webes változatban érhető el.');
}
