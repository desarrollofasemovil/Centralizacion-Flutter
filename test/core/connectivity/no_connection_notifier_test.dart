import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/connectivity/connectivity_observer.dart';
import 'package:tramiapp_flutter/core/connectivity/connectivity_status.dart';
import 'package:tramiapp_flutter/core/connectivity/no_connection_notifier.dart';

class _FakeObserver implements ConnectivityObserver {
  _FakeObserver(this.controller);

  final StreamController<ConnectivityStatus> controller;

  @override
  Stream<ConnectivityStatus> observe() => controller.stream;

  @override
  Future<ConnectivityStatus> current() async => ConnectivityStatus.available;
}

Future<void> _wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late StreamController<ConnectivityStatus> controller;
  late ProviderContainer container;

  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          noConnectionDebounceProvider
              .overrideWithValue(const Duration(milliseconds: 20)),
          connectivityObserverProvider
              .overrideWithValue(_FakeObserver(controller)),
        ],
      );

  setUp(() => controller = StreamController<ConnectivityStatus>());

  tearDown(() async {
    container.dispose();
    await controller.close();
  });

  bool visible() => container.read(noConnectionDialogProvider);

  test('sin conexión sostenida muestra el diálogo solo tras el debounce',
      () async {
    container = makeContainer();
    container.listen(noConnectionDialogProvider, (_, _) {});

    controller.add(ConnectivityStatus.unavailable);
    await _wait(5);
    expect(visible(), isFalse);

    await _wait(60);
    expect(visible(), isTrue);
  });

  test('recuperar la red antes del debounce cancela la aparición', () async {
    container = makeContainer();
    container.listen(noConnectionDialogProvider, (_, _) {});

    controller.add(ConnectivityStatus.unavailable);
    await _wait(5);
    controller.add(ConnectivityStatus.available);
    await _wait(60);

    expect(visible(), isFalse);
  });

  test('intermitencia reinicia la ventana', () async {
    container = makeContainer();
    container.listen(noConnectionDialogProvider, (_, _) {});

    controller.add(ConnectivityStatus.unavailable);
    await _wait(12);
    controller.add(ConnectivityStatus.available);
    await _wait(3);
    controller.add(ConnectivityStatus.unavailable);
    // Han pasado >20 ms desde la primera pérdida pero <20 ms desde la última.
    await _wait(10);
    expect(visible(), isFalse);

    await _wait(60);
    expect(visible(), isTrue);
  });

  test('available con el diálogo visible lo oculta de inmediato', () async {
    container = makeContainer();
    container.listen(noConnectionDialogProvider, (_, _) {});

    controller.add(ConnectivityStatus.unavailable);
    await _wait(60);
    expect(visible(), isTrue);

    controller.add(ConnectivityStatus.available);
    await _wait(5);
    expect(visible(), isFalse);
  });

  test('arranque sin red (primera emisión unavailable) muestra el diálogo',
      () async {
    // La emisión ocurre antes de que el notifier exista.
    controller.add(ConnectivityStatus.unavailable);
    container = makeContainer();
    container.listen(noConnectionDialogProvider, (_, _) {});
    await _wait(5);
    expect(visible(), isFalse);

    await _wait(60);
    expect(visible(), isTrue);
  });

  test('show() lo muestra sin debounce y dismiss() lo oculta', () {
    container = makeContainer();
    container.listen(noConnectionDialogProvider, (_, _) {});

    container.read(noConnectionDialogProvider.notifier).show();
    expect(visible(), isTrue);

    container.read(noConnectionDialogProvider.notifier).dismiss();
    expect(visible(), isFalse);
  });
}
