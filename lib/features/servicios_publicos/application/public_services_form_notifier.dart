import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/fintech_api_service.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/models/tax_dto.dart';
import '../../auth/application/auth_providers.dart';

class PublicServicesFormParam {
  final String factura;
  final String valor;
  final String fechaVencimiento;

  const PublicServicesFormParam({
    required this.factura,
    required this.valor,
    required this.fechaVencimiento,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicServicesFormParam &&
          runtimeType == other.runtimeType &&
          factura == other.factura &&
          valor == other.valor &&
          fechaVencimiento == other.fechaVencimiento;

  @override
  int get hashCode => Object.hash(factura, valor, fechaVencimiento);
}

class PublicServicesFormState {
  final bool isLoading;
  final FintechPayerDTO pagador;
  final String factura;
  final int valorPagar;
  final String fechaVencimiento;
  final FintechTransactionResponseDTO? transactionResponse;
  final String? errorMessage;

  const PublicServicesFormState({
    this.isLoading = false,
    required this.pagador,
    required this.factura,
    required this.valorPagar,
    required this.fechaVencimiento,
    this.transactionResponse,
    this.errorMessage,
  });

  PublicServicesFormState copyWith({
    bool? isLoading,
    FintechPayerDTO? pagador,
    String? factura,
    int? valorPagar,
    String? fechaVencimiento,
    FintechTransactionResponseDTO? transactionResponse,
    String? errorMessage,
  }) {
    return PublicServicesFormState(
      isLoading: isLoading ?? this.isLoading,
      pagador: pagador ?? this.pagador,
      factura: factura ?? this.factura,
      valorPagar: valorPagar ?? this.valorPagar,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      transactionResponse: transactionResponse ?? this.transactionResponse,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PublicServicesFormNotifier extends Notifier<PublicServicesFormState> {
  final PublicServicesFamilyParam familyParam;
  PublicServicesFormNotifier(this.familyParam);

  FintechPaymentsApiService get _fintechApi => ref.read(fintechPaymentsApiServiceProvider);
  int get _municipalityId => familyParam.municipalityId;

  @override
  PublicServicesFormState build() {
    final user = ref.read(sessionProvider);
    final initialPayer = user != null
        ? FintechPayerDTO(
            tipoDocumento: user.documentTypeId,
            documento: user.nationalId,
            primerNombre: user.firstName,
            segundoNombre: user.middleName ?? "",
            primerApellido: user.lastName,
            segundoApellido: user.secondLastName ?? "",
            direccion: user.address,
            telefono: user.phoneNumber,
            email: user.email,
            nombreCompleto: "${user.firstName} ${user.lastName}".trim(),
          )
        : const FintechPayerDTO(
            documento: "",
            tipoDocumento: 1,
            nombreCompleto: "",
            primerNombre: "",
            segundoNombre: "",
            primerApellido: "",
            segundoApellido: "",
            telefono: "",
            email: "",
            direccion: "",
          );

    return PublicServicesFormState(
      pagador: initialPayer,
      factura: familyParam.param.factura,
      valorPagar: int.tryParse(familyParam.param.valor) ?? 0,
      fechaVencimiento: familyParam.param.fechaVencimiento,
    );
  }

  void setUserData(UserDTO user) {
    state = state.copyWith(
      pagador: FintechPayerDTO(
        tipoDocumento: user.documentTypeId,
        documento: user.nationalId,
        primerNombre: user.firstName,
        segundoNombre: user.middleName ?? "",
        primerApellido: user.lastName,
        segundoApellido: user.secondLastName ?? "",
        direccion: user.address,
        telefono: user.phoneNumber,
        email: user.email,
        nombreCompleto: "${user.firstName} ${user.lastName}".trim(),
      ),
    );
  }

  void updatePayerField(FintechPayerDTO Function(FintechPayerDTO) updater) {
    state = state.copyWith(pagador: updater(state.pagador));
  }

  bool isFormValid() {
    final p = state.pagador;
    return (p.documento?.trim().isNotEmpty ?? false) &&
        (p.primerNombre?.trim().isNotEmpty ?? false) &&
        (p.primerApellido?.trim().isNotEmpty ?? false) &&
        (p.direccion?.trim().isNotEmpty ?? false) &&
        (p.telefono?.trim().isNotEmpty ?? false) &&
        (p.email?.trim().isNotEmpty ?? false);
  }

  Future<void> submitTransaction() async {
    if (!isFormValid()) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    final fullName = "${state.pagador.primerNombre} ${state.pagador.primerApellido}".trim();
    final updatedPayer = state.pagador.copy(nombreCompleto: fullName);

    final body = FintechTransactionRequestDTO(
      idTramite: 1,
      pagador: updatedPayer,
      valorPagar: state.valorPagar,
      factura: state.factura,
      referencia: state.factura,
      descripcion: "Pago de Servicio Público - Factura ${state.factura}",
      fuentePago: 2,
      tipoImplementacion: 1,
      estadoUrl: true,
      url: "",
    );

    try {
      final response = await _fintechApi.transactionFintech(_municipalityId, body);
      state = state.copyWith(
        isLoading: false,
        transactionResponse: response,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Error al realizar transacción: ${e.toString()}",
      );
    }
  }

  void clearResponse() {
    state = state.copyWith(transactionResponse: null, errorMessage: null);
  }
}

// Extension to allow copyWith / copy on FintechPayerDTO to avoid compile issues
extension FintechPayerDTOExtension on FintechPayerDTO {
  FintechPayerDTO copy({
    String? documento,
    int? tipoDocumento,
    String? nombreCompleto,
    int? dv,
    String? primerNombre,
    String? segundoNombre,
    String? primerApellido,
    String? segundoApellido,
    String? telefono,
    String? email,
    String? direccion,
  }) {
    return FintechPayerDTO(
      documento: documento ?? this.documento,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      dv: dv ?? this.dv,
      primerNombre: primerNombre ?? this.primerNombre,
      segundoNombre: segundoNombre ?? this.segundoNombre,
      primerApellido: primerApellido ?? this.primerApellido,
      segundoApellido: segundoApellido ?? this.segundoApellido,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
    );
  }
}

final publicServicesFormNotifierProvider = NotifierProvider.autoDispose.family<
    PublicServicesFormNotifier, PublicServicesFormState, PublicServicesFamilyParam>(PublicServicesFormNotifier.new);

class PublicServicesFamilyParam {
  final int municipalityId;
  final PublicServicesFormParam param;

  const PublicServicesFamilyParam({
    required this.municipalityId,
    required this.param,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PublicServicesFamilyParam &&
          runtimeType == other.runtimeType &&
          municipalityId == other.municipalityId &&
          param == other.param;

  @override
  int get hashCode => Object.hash(municipalityId, param);
}
