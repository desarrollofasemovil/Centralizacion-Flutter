import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dio_client.dart';
import '../network_provider.dart';
import 'auth_api_service.dart';
import 'municipality_api_service.dart';
import 'tax_api_service.dart';
import 'pqrd_api_service.dart';
import 'generales_api_service.dart';
import 'google_api_service.dart';
import 'emails_api_service.dart';
import 'reminders_api_service.dart';
import 'payment_history_api_service.dart';
import 'fintech_api_service.dart';
import 'people_invitated_api_service.dart';
import 'tramites_api_service.dart';
import 'courses_api_service.dart';
import 'venues_api_service.dart';

/// Providers de los servicios Retrofit. Todos reutilizan el [Dio] único
/// (`dioProvider`) y fijan su base URL — equivalente a `ApiFactory.createService`.

final municipalityApiServiceProvider = Provider<MunicipalityApiService>(
  (ref) => MunicipalityApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.centralizacionApiUrl,
  ),
);

final authApiServiceProvider = Provider<AuthApiService>(
  (ref) => AuthApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.centralizacionApiUrl,
  ),
);

final taxApiServiceProvider = Provider<TaxApiService>(
  (ref) => TaxApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.taxApiUrl,
  ),
);

final paymentApiServiceProvider = Provider<PaymentApiService>(
  (ref) => PaymentApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.taxApiUrl,
  ),
);

final statusOfPaymentsApiServiceProvider = Provider<StatusOfPaymentsApiService>(
  (ref) => StatusOfPaymentsApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.taxApiUrl,
  ),
);

final pqrdApiServiceProvider = Provider<PqrdApiService>(
  (ref) => PqrdApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.pqrdApiUrl,
  ),
);

final procedureApplicationApiServiceProvider = Provider<ProcedureApplicationApiService>(
  (ref) => ProcedureApplicationApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.pqrdApiUrl,
  ),
);

final generalesApiServiceProvider = Provider<GeneralesApiService>(
  (ref) => GeneralesApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.autoliquidablesApiUrl,
  ),
);

final googleApiServiceProvider = Provider<GoogleApiService>(
  (ref) => GoogleApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.googleApiUrl,
  ),
);

final sendEmailsApiServiceProvider = Provider<SendEmailsApiService>(
  (ref) => SendEmailsApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.centralizacionApiUrl,
  ),
);

final remindersApiServiceProvider = Provider<RemindersApiService>(
  (ref) => RemindersApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.centralizacionApiUrl,
  ),
);

final paymentHistoryApiServiceProvider = Provider<PaymentHistoryApiService>(
  (ref) => PaymentHistoryApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.centralizacionApiUrl,
  ),
);

final fintechPaymentsApiServiceProvider = Provider<FintechPaymentsApiService>(
  (ref) => FintechPaymentsApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.centralizacionApiUrl,
  ),
);

final peopleInvitatedApiServiceProvider = Provider<PeopleInvitatedApiService>(
  (ref) => PeopleInvitatedApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.centralizacionApiUrl,
  ),
);

final tramitesApiServiceProvider = Provider<TramitesApiService>(
  (ref) => TramitesApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.centralizacionApiUrl,
  ),
);

final courseApiServiceProvider = Provider<CourseApiService>(
  (ref) => CourseApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.centralizacionApiUrl,
  ),
);

final venueApiServiceProvider = Provider<VenueApiService>(
  (ref) => VenueApiService(
    ref.watch(dioProvider),
    baseUrl: NetworkProvider.centralizacionApiUrl,
  ),
);

