enum SiteDecision { allow, block, ask }

/// A per-website permission decision. This is deliberately separate from the
/// Android OS permission: granting the OS camera permission never grants a
/// website camera access on its own.
class SitePermission {
  const SitePermission({
    this.id,
    required this.host,
    required this.permission,
    required this.decision,
  });

  final int? id;
  final String host;
  final String permission;
  final SiteDecision decision;

  Map<String, Object?> toMap() => {
        'id': id,
        'host': host,
        'permission': permission,
        'decision': decision.name,
      };

  factory SitePermission.fromMap(Map<String, Object?> map) => SitePermission(
        id: map['id'] as int?,
        host: map['host'] as String? ?? '',
        permission: map['permission'] as String? ?? '',
        decision: SiteDecision.values.firstWhere(
          (value) => value.name == (map['decision'] as String? ?? 'ask'),
          orElse: () => SiteDecision.ask,
        ),
      );
}
