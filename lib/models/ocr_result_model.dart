class OcrWord {
  final String text;
  final double left;
  final double top;
  final double width;
  final double height;

  OcrWord({
    required this.text,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}

class OcrResult {
  final String text;
  final List<OcrWord> words;

  OcrResult({
    required this.text,
    required this.words,
  });
}
