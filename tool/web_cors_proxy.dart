// Proxy CORS para desarrollo local en `flutter run -d chrome`.
//
// El backend (apicentralizate.1cero1.com y compañía) no envía headers CORS
// (`Access-Control-Allow-Origin`) ni responde bien al preflight `OPTIONS`
// (405). El navegador bloquea esas respuestas antes de que Dart las vea, así
// que no hay forma de arreglarlo desde el cliente Dio. Este proxy corre en
// localhost, reenvía la petición tal cual al backend real y le agrega los
// headers CORS a la respuesta. Solo se usa en debug web
// (`NetworkProvider._proxied`); release, móvil y desktop llaman siempre
// directo al backend real, sin pasar por aquí.
//
// Uso:
//   dart run tool/web_cors_proxy.dart
//   flutter run -d chrome   # en otra terminal
//
// La URL destino va embebida en el path: una petición a
// http://localhost:8899/https://apicentralizate.1cero1.com/api/Department
// se reenvía tal cual a https://apicentralizate.1cero1.com/api/Department.
import 'dart:io';

const _port = 8899;

const _hopByHopRequestHeaders = {
  'host',
  'connection',
  'content-length',
  'transfer-encoding',
  'accept-encoding', // dejamos que HttpClient negocie su propia compresión
};

const _hopByHopResponseHeaders = {
  'connection',
  'content-length',
  'transfer-encoding',
  'content-encoding', // el body que copiamos ya viene descomprimido
};

void _addCorsHeaders(HttpResponse response, HttpRequest request) {
  response.headers
    ..set('Access-Control-Allow-Origin', request.headers.value('origin') ?? '*')
    ..set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS')
    ..set(
      'Access-Control-Allow-Headers',
      request.headers.value('access-control-request-headers') ?? '*',
    )
    ..set('Access-Control-Allow-Credentials', 'true')
    ..set('Access-Control-Max-Age', '3600');
}

Future<void> main() async {
  final client = HttpClient();
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
  stdout.writeln('web_cors_proxy escuchando en http://localhost:$_port');

  await for (final request in server) {
    _addCorsHeaders(request.response, request);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      continue;
    }

    final targetPath = request.uri.path.replaceFirst('/', '');
    final rawTarget = Uri.tryParse(
      request.uri.query.isEmpty ? targetPath : '$targetPath?${request.uri.query}',
    );
    if (rawTarget == null || !rawTarget.isAbsolute) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('URL destino inválida: $targetPath');
      await request.response.close();
      continue;
    }
    // La baseUrl proxied ya trae un `/` final y los endpoints Retrofit suelen
    // empezar también con `/`, así que el path reconstruido llega con `//`.
    // Lo colapsamos para no mandarle al backend real una ruta que no existe.
    final target = rawTarget.replace(
      path: rawTarget.path.replaceAll(RegExp(r'/+'), '/'),
    );

    try {
      final proxied = await client.openUrl(request.method, target);
      request.headers.forEach((name, values) {
        if (_hopByHopRequestHeaders.contains(name.toLowerCase())) return;
        for (final value in values) {
          proxied.headers.add(name, value);
        }
      });
      await proxied.addStream(request);
      final backendResponse = await proxied.close();

      request.response.statusCode = backendResponse.statusCode;
      backendResponse.headers.forEach((name, values) {
        if (_hopByHopResponseHeaders.contains(name.toLowerCase())) return;
        if (name.toLowerCase().startsWith('access-control-')) return;
        for (final value in values) {
          request.response.headers.add(name, value);
        }
      });
      await request.response.addStream(backendResponse);
      await request.response.close();
    } catch (e) {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('Error reenviando a $target: $e');
      await request.response.close();
    }
  }
}
