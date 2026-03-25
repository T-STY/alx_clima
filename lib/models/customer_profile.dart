class CustomerProfile {
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? notes;

  const CustomerProfile({
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.notes,
  });

  CustomerProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) {
    return CustomerProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }
}
