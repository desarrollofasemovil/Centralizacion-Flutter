import '../../../core/api/services/tax_api_service.dart';
import '../../../core/api/services/fintech_api_service.dart';
import '../../../core/models/tax_dto.dart';
import '../domain/tax.dart';
import '../domain/payment_gateway_info.dart';

class TaxRepository {
  final TaxApiService _taxApi;
  final PaymentApiService _paymentApi;
  final FintechPaymentsApiService _fintechApi;

  TaxRepository(this._taxApi, this._paymentApi, this._fintechApi);

  Future<List<Tax>> getTaxes({
    required String entityCode,
    required String queryData,
    required String queryField,
    required int taxId,
  }) async {
    final request = TaxQueryRequestDTO(
      entityCode: entityCode,
      queryData: queryData,
      queryField: queryField,
      taxId: taxId,
      invoice: '',
    );
    final response = await _taxApi.getTaxes(request);
    final infoList = response.information;
    if (infoList == null) return [];

    return infoList.map((dto) {
      return Tax(
        entity: dto.entity,
        entityCode: dto.entityCode,
        document: dto.document,
        name: dto.name,
        taxName: dto.taxName,
        taxId: dto.taxId,
        value: dto.value,
        invoice: dto.facturaCode,
        reference: dto.reference,
        dueDate: dto.dueDate,
        pdfUrltoApi: dto.detail?.url,
        portalUrl: dto.detail?.portalUrl,
        queryField: queryField,
      );
    }).toList();
  }

  Future<PaymentGatewayInfo> createTransaction({
    required Tax tax,
    required String email,
    required String bankName,
    required int municipalityId,
    required String integrationType,
  }) async {
    if (bankName.toLowerCase() == 'coopcentral') {
      return _processFintechTransaction(tax, email, municipalityId, integrationType);
    } else {
      return _processBancolombiaTransaction(tax, email);
    }
  }

  Future<PaymentGatewayInfo> _processBancolombiaTransaction(Tax tax, String email) async {
    final request = BancolombiaGatewayRequestDTO(
      reference: tax.reference,
      invoice: tax.reference,
      municipalityCode: tax.entityCode,
      documentType: 'CC',
      identification: tax.document,
      name: tax.name,
      total: tax.value,
      taxId: tax.taxId,
      email: email,
      phone: '',
      paymentSource: 2,
      implementationType: 1,
    );
    final res = await _paymentApi.createTransaction(request);
    return PaymentGatewayInfo(url: res.url);
  }

  Future<PaymentGatewayInfo> _processFintechTransaction(
    Tax tax,
    String email,
    int municipalityId,
    String integrationType,
  ) async {
    final names = tax.name.split(' ');
    final primerNombre = names.isNotEmpty ? names.first : tax.name;
    final primerApellido = names.length > 1 ? names.last : '';
    final idTramiteParseado = int.tryParse(integrationType) ?? 0;

    final payer = FintechPayerDTO(
      documento: tax.document,
      tipoDocumento: 1,
      nombreCompleto: tax.name,
      primerNombre: primerNombre,
      primerApellido: primerApellido,
      telefono: '',
      email: email,
      direccion: '',
    );

    final request = FintechTransactionRequestDTO(
      idTramite: idTramiteParseado,
      pagador: payer,
      valorPagar: tax.value,
      factura: tax.invoice.isNotEmpty ? tax.invoice : tax.reference,
      referencia: tax.reference,
      descripcion: 'Pago de impuesto: ${tax.taxName}',
      url: '',
    );

    final res = await _fintechApi.transactionFintech(municipalityId, request);
    final urlPago = res.result?.url;

    if (res.isSuccess && urlPago != null && urlPago.isNotEmpty) {
      return PaymentGatewayInfo(url: urlPago);
    } else {
      final errorMsg = res.message ?? 'Error desconocido en pasarela Fintech';
      throw Exception(errorMsg);
    }
  }

  Future<String> getInvoicePdfUrl(Tax tax) async {
    final request = TaxQueryRequestDTO(
      entityCode: tax.entityCode,
      queryData: tax.document,
      queryField: tax.queryField,
      taxId: tax.taxId,
      invoice: tax.invoice,
    );
    final response = await _taxApi.downloadInvoice(request);
    final cleanResponse = response.replaceAll('"', '');
    return 'http://apidatamovil.1cero1.com/$cleanResponse';
  }
}
