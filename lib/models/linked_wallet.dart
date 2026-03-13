class LinkedWallet {
  final String address;
  final String label;
  final DateTime addedAt;
  final bool isPrimary;
  final bool isActive;
  final bool monitoringEnabled; // Deprecated: using isActive driven by PRO

  LinkedWallet({
    required this.address,
    required this.label,
    required this.addedAt,
    this.isPrimary = false,
    this.isActive = true,
    this.monitoringEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'address': address,
        'label': label,
        'addedAt': addedAt.toIso8601String(),
        'isPrimary': isPrimary,
        'isActive': isActive,
        'monitoringEnabled': monitoringEnabled,
      };

  factory LinkedWallet.fromJson(Map<String, dynamic> json) => LinkedWallet(
        address: json['address'] ?? '',
        label: json['label'] ?? '',
        addedAt: json['addedAt'] != null
            ? DateTime.parse(json['addedAt'])
            : DateTime.now(),
        isPrimary: json['isPrimary'] ?? false,
        isActive: json['isActive'] ?? true,
        monitoringEnabled: json['monitoringEnabled'] ?? true,
      );

  LinkedWallet copyWith({
    String? address,
    String? label,
    DateTime? addedAt,
    bool? isPrimary,
    bool? isActive,
    bool? monitoringEnabled,
  }) {
    return LinkedWallet(
      address: address ?? this.address,
      label: label ?? this.label,
      addedAt: addedAt ?? this.addedAt,
      isPrimary: isPrimary ?? this.isPrimary,
      isActive: isActive ?? this.isActive,
      monitoringEnabled: monitoringEnabled ?? this.monitoringEnabled,
    );
  }
}
