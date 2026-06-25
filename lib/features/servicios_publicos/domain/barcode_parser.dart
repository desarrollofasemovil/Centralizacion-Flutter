class BarcodeData {
  final String ean;
  final String factura;
  final String valor;
  final String fechaVencimiento;
  final String rawCode;

  BarcodeData({
    required this.ean,
    required this.factura,
    required this.valor,
    required this.fechaVencimiento,
    required this.rawCode,
  });
}

class BarcodeParser {
  BarcodeData? parse(String rawCode) {
    try {
      String safeCode = rawCode
          .replaceAll('\u001D', '*')
          .replaceAll('\u001C', '*')
          .replaceAll('(', '*')
          .replaceAll(')', '*');

      safeCode = safeCode.split('').where((char) => RegExp(r'[0-9*]').hasMatch(char)).join('');

      while (safeCode.contains('**')) {
        safeCode = safeCode.replaceAll('**', '*');
      }

      // 1. Identificar AI 415 (EAN)
      final start415 = safeCode.indexOf('415');
      if (start415 == -1) return null;

      // Consumir exactamente 13 dígitos para el EAN
      int idx = start415 + 3;
      String ean = '';
      while (idx < safeCode.length && ean.length < 13) {
        final c = safeCode[idx];
        if (RegExp(r'\d').hasMatch(c)) {
          ean += c;
        }
        idx++;
      }
      if (ean.length != 13) return null;

      // 2. Identificar AI 8020 (Factura) posterior a EAN
      final start8020 = safeCode.indexOf('8020', idx);
      if (start8020 == -1) return null;
      final end8020 = start8020 + 4;

      // 3. Buscar AI 96 (Fecha de vencimiento) yyyyMMdd desde el final
      int start96 = -1;
      String fecha = '';
      int searchIdx = safeCode.length - 10;
      while (searchIdx >= end8020) {
        final possible96 = safeCode.indexOf('96', searchIdx);
        if (possible96 != -1) {
          String dateDigits = '';
          int dIdx = possible96 + 2;
          while (dIdx < safeCode.length && dateDigits.length < 8) {
            final c = safeCode[dIdx];
            if (RegExp(r'\d').hasMatch(c)) dateDigits += c;
            dIdx++;
          }
          if (dateDigits.length == 8) {
            bool extraDigits = false;
            while (dIdx < safeCode.length) {
              if (RegExp(r'\d').hasMatch(safeCode[dIdx])) {
                extraDigits = true;
                break;
              }
              dIdx++;
            }
            if (!extraDigits) {
              start96 = possible96;
              fecha = dateDigits;
              break;
            }
          }
        }
        searchIdx--;
      }

      if (start96 == -1 || fecha.isEmpty) return null;

      // 4. Seccionar la parte media entre el final de 8020 y el inicio de 96
      if (end8020 >= start96) return null;
      final middleSection = safeCode.substring(end8020, start96);

      // Buscar AI 3900 (Valor) de forma robusta
      int index3900 = -1;
      final star3900Idx = middleSection.indexOf('*3900');
      if (star3900Idx != -1) {
        index3900 = star3900Idx + 1; // Saltamos el '*'
      } else {
        final last3900Idx = middleSection.lastIndexOf('3900');
        if (last3900Idx != -1) {
          index3900 = last3900Idx;
        }
      }

      if (index3900 == -1) return null;

      // Extraer número de factura
      final facturaRaw = middleSection.substring(0, index3900).replaceAll('*', '');
      if (facturaRaw.isEmpty) return null;

      // Extraer valor de pago
      final valorRaw = middleSection.substring(index3900 + 4).replaceAll('*', '');
      if (valorRaw.isEmpty) return null;
      final valor = valorRaw.replaceFirst(RegExp(r'^0+'), '');
      final finalValor = valor.isEmpty ? '0' : valor;

      return BarcodeData(
        ean: ean,
        factura: facturaRaw,
        valor: finalValor,
        fechaVencimiento: fecha,
        rawCode: rawCode,
      );
    } catch (_) {
      return null;
    }
  }

  bool isDateValid(String? fechaStr) {
    try {
      if (fechaStr != null && fechaStr.length == 8) {
        final year = int.parse(fechaStr.substring(0, 4));
        final month = int.parse(fechaStr.substring(4, 6));
        final day = int.parse(fechaStr.substring(6, 8));

        final inputDate = DateTime(year, month, day);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Date is valid if it's today or in the future
        return inputDate.isAfter(today) ||
            (inputDate.year == today.year &&
                inputDate.month == today.month &&
                inputDate.day == today.day);
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
