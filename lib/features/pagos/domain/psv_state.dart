class PsvFormState {
  final String documentType;
  final String documentNumber;
  final String fullName;
  final String email;
  final String phone;

  final String invoiceNumber;
  final int amount;
  final String description;

  final String selectedBank;

  const PsvFormState({
    this.documentType = 'CC',
    this.documentNumber = '',
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.invoiceNumber = '',
    this.amount = 0,
    this.description = '',
    this.selectedBank = '',
  });

  PsvFormState copyWith({
    String? documentType,
    String? documentNumber,
    String? fullName,
    String? email,
    String? phone,
    String? invoiceNumber,
    int? amount,
    String? description,
    String? selectedBank,
  }) {
    return PsvFormState(
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      selectedBank: selectedBank ?? this.selectedBank,
    );
  }
}
