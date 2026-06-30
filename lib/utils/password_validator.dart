/// Password rules: 8+ chars, letter, digit, symbol.
class PasswordValidator {
  PasswordValidator._();

  static final _symbol =
      RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-\[\]\\;/+=~`']''');

  static String? validate(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return 'Include at least one letter.';
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Include at least one number.';
    }
    if (!_symbol.hasMatch(password)) {
      return 'Include at least one symbol (!@#\$…).';
    }
    return null;
  }

  static int strengthScore(String password) {
    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Za-z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (_symbol.hasMatch(password)) score++;
    return score.clamp(0, 4);
  }

  static String strengthLabel(int score) {
    if (score <= 1) return 'Weak password';
    if (score <= 2) return 'Medium password';
    if (score == 3) return 'Good password';
    return 'Strong password';
  }
}
