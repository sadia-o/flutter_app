class AdministratorContact {
  final String id;
  final String name;
  final String roleLabel;
  final String email;
  final String? phoneNumber;

  const AdministratorContact({
    required this.id,
    required this.name,
    required this.roleLabel,
    required this.email,
    this.phoneNumber,
  });
}
