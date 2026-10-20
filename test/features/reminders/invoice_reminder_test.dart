import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/models/municipality_procedure.dart';
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/core/notifications/local_reminder_scheduler.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/impuestos/domain/tax.dart';
import 'package:tramiapp_flutter/features/reminders/application/reminders_notifier.dart';
import 'package:tramiapp_flutter/features/reminders/domain/reminders_state.dart';

import '../../helpers/fake_local_reminder_scheduler.dart';

Tax _taxDue(DateTime dueDate) => Tax(
  entity: 'Alcaldía',
  entityCode: '05030',
  document: '123',
  name: 'Ana',
  taxName: 'Predial',
  taxId: 1,
  value: 25000,
  invoice: 'FAC-1',
  reference: 'REF',
  dueDate: DateFormat('dd/MM/yyyy').format(dueDate),
  queryField: '',
);

DateTime get _today {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

final _procedure = MunicipalityProcedure.fromJson({
  'id': 500,
  'integrationType': '',
  'isActive': true,
  'procedures': {
    'id': 230,
    'name': 'Impuesto Predial Unificado',
    'code': 'PREDIAL',
    'kind': 'TAX',
    'externalId': 1,
  },
});

class _NoSession extends SessionNotifier {
  @override
  UserDTO? build() => null;
}

void main() {
  group('Tax.isReminderEligible', () {
    test('vence mañana o después: sí', () {
      expect(
        _taxDue(_today.add(const Duration(days: 1))).isReminderEligible,
        isTrue,
      );
      expect(
        _taxDue(_today.add(const Duration(days: 40))).isReminderEligible,
        isTrue,
      );
    });

    test('vence hoy: no, ya no hay margen para avisar antes', () {
      expect(_taxDue(_today).isReminderEligible, isFalse);
    });

    test('vencida: no', () {
      expect(
        _taxDue(_today.subtract(const Duration(days: 3))).isReminderEligible,
        isFalse,
      );
    });

    test('fecha que no se entiende: no', () {
      const tax = Tax(
        entity: '',
        entityCode: '',
        document: '',
        name: '',
        taxName: '',
        taxId: 1,
        value: 0,
        invoice: '',
        reference: '',
        dueDate: 'sin fecha',
        queryField: '',
      );
      expect(tax.isReminderEligible, isFalse);
    });
  });

  group('defaultInvoiceReminderOffset', () {
    final now = DateTime(2026, 10, 20, 9);

    test('con margen, avisa 1 día antes', () {
      expect(
        defaultInvoiceReminderOffset(DateTime(2026, 11, 5, 8), now: now),
        ReminderOffset.oneDay,
      );
    });

    test('si 1 día antes ya pasó, avisa a la hora del evento', () {
      // Vence mañana a las 8:00 y ya son las 9:00: un día antes sería ayer.
      expect(
        defaultInvoiceReminderOffset(DateTime(2026, 10, 21, 8), now: now),
        ReminderOffset.none,
      );
    });
  });

  group('prefillFromInvoice', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(_NoSession.new),
          sharedPreferencesProvider.overrideWithValue(prefs),
          localReminderSchedulerProvider.overrideWithValue(
            FakeLocalReminderScheduler(),
          ),
        ],
      );
      addTearDown(container.dispose);
    });

    test('deja el formulario lleno para solo confirmar', () {
      final due = _today.add(const Duration(days: 30));
      final notifier = container.read(remindersNotifierProvider.notifier);

      notifier.prefillFromInvoice(
        procedure: _procedure,
        name: 'Pagar Predial',
        dueDate: due,
      );
      // Abrir el modal no debe pisar lo precargado.
      notifier.toggleModal(true);

      final form = container.read(remindersNotifierProvider).formState;
      expect(form.customName, 'Pagar Predial');
      expect(form.selectedProcedure, _procedure);
      expect(
        form.selectedDateMillis,
        DateTime.utc(due.year, due.month, due.day).millisecondsSinceEpoch,
      );
      expect(form.selectedTime, const TimeOfDay(hour: 8, minute: 0));
      expect(form.offset, ReminderOffset.oneDay);
      expect(form.origin, ReminderOrigin.invoice);
      expect(form.isModalVisible, isTrue);
    });

    test('al cerrar el modal el formulario vuelve al de la Home', () {
      final notifier = container.read(remindersNotifierProvider.notifier);
      notifier.prefillFromInvoice(
        procedure: _procedure,
        name: 'Pagar Predial',
        dueDate: _today.add(const Duration(days: 30)),
      );

      notifier.toggleModal(false);

      final form = container.read(remindersNotifierProvider).formState;
      expect(form.origin, ReminderOrigin.general);
      expect(form.offset, ReminderOffset.none);
      expect(form.customName, isEmpty);
    });
  });
}
