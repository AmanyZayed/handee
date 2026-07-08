/// AI-assisted composition modes on the Recognize camera.
enum AslAiMode {
  detect,
  buildSentence,
  buildWord,
}

extension AslAiModeLabel on AslAiMode {
  String get label {
    switch (this) {
      case AslAiMode.detect:
        return 'Detect';
      case AslAiMode.buildSentence:
        return 'Sentence';
      case AslAiMode.buildWord:
        return 'Word';
    }
  }

  String get hint {
    switch (this) {
      case AslAiMode.detect:
        return 'Live sign detection';
      case AslAiMode.buildSentence:
        return 'Sign words — builds a sentence';
      case AslAiMode.buildWord:
        return 'Spell letters — builds a word';
    }
  }
}
