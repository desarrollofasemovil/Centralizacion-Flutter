import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/flavor/flavor_config.dart';
import 'package:tramiapp_flutter/core/flavor/flavors.dart';

/// `FlavorConfig.appIdentifier` viaja como `X-App-Id` y la API lo compara con
/// las apps registradas: si se desalinea del `applicationId` real, la app ve el
/// catálogo de otro banco sin ningún error visible. Este test lee los
/// `productFlavors` de Gradle para que no puedan desviarse.
void main() {
  test('appIdentifier de cada flavor == applicationId de Gradle', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final flavorBlock = RegExp(
      r'create\("(\w+)"\)\s*\{[^}]*?applicationId\s*=\s*"([^"]+)"',
      dotAll: true,
    );
    final gradleIds = {
      for (final m in flavorBlock.allMatches(gradle)) m.group(1)!: m.group(2)!,
    };

    const configs = [flavorMunicipios, flavorManizales];
    expect(
      gradleIds.keys.toSet(),
      {for (final c in configs) c.flavor.name},
      reason: 'Cada flavor de Gradle debe tener su FlavorConfig y viceversa.',
    );
    for (final FlavorConfig config in configs) {
      expect(
        config.appIdentifier,
        gradleIds[config.flavor.name],
        reason: 'Flavor ${config.flavor.name}',
      );
    }
  });
}
