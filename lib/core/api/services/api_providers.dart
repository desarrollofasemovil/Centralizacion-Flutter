import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dio_client.dart';
import '../network_provider.dart';
import 'auth_api_service.dart';
import 'municipality_api_service.dart';

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
