/// A saved login. Only ever persisted through VaultService (secure storage).
class Credential {
  Credential({
    required this.id,
    required this.host,
    required this.username,
    required this.password,
    required this.createdAt,
  });

  final String id;
  final String host;
  final String username;
  final String password;
  final int createdAt;

  Credential copyWith({String? host, String? username, String? password}) =>
      Credential(
        id: id,
        host: host ?? this.host,
        username: username ?? this.username,
        password: password ?? this.password,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'host': host,
        'username': username,
        'password': password,
        'createdAt': createdAt,
      };

  factory Credential.fromJson(Map<String, dynamic> json) => Credential(
        id: json['id'] as String? ?? '',
        host: json['host'] as String? ?? '',
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        createdAt: json['createdAt'] as int? ?? 0,
      );
}
