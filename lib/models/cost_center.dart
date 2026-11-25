class CostCenter {
  final String id;
  final String code;
  final String name;
  final String? parentId;
  final bool isActive;

  const CostCenter({
    required this.id,
    required this.code,
    required this.name,
    this.parentId,
    this.isActive = true,
  });

  CostCenter copyWith({
    String? code,
    String? name,
    String? parentId,
    bool clearParent = false,
    bool? isActive,
  }) {
    return CostCenter(
      id: id,
      code: code ?? this.code,
      name: name ?? this.name,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'name': name,
        'parentId': parentId,
        'isActive': isActive,
      };

  factory CostCenter.fromJson(Map<String, dynamic> j) => CostCenter(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        parentId: j['parentId'] as String?,
        isActive: j['isActive'] as bool? ?? true,
      );
}
