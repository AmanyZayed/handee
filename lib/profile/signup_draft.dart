/// Sign-up data passed through human check → Firebase account creation.
class SignUpDraft {
  const SignUpDraft({
    required this.username,
    required this.email,
    required this.password,
    required this.phone,
  });

  final String username;
  final String email;
  final String password;
  final String phone;
}
