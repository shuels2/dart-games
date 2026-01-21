class User {
  final String bearerToken;
  final String? userId;
  final String? email;

  User({
    required this.bearerToken,
    this.userId,
    this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'bearerToken': bearerToken,
      'userId': userId,
      'email': email,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      bearerToken: json['bearerToken'] as String,
      userId: json['userId'] as String?,
      email: json['email'] as String?,
    );
  }

  User copyWith({
    String? bearerToken,
    String? userId,
    String? email,
  }) {
    return User(
      bearerToken: bearerToken ?? this.bearerToken,
      userId: userId ?? this.userId,
      email: email ?? this.email,
    );
  }
}
