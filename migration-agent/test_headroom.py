"""
Script de validación de compresión de contexto del agente de migración.

Verifica que la compresión funciona correctamente y muestra métricas
de reducción de tokens en diferentes tipos de contenido.

Uso:
    python test_headroom.py
"""

from headroom_config import compress_tool_output, get_stats, reset_stats


def test_code_compression():
    """Prueba compresión de código fuente Kotlin."""
    kotlin_code = '''data class UserDTO(
    val id: String,
    val nombre: String,
    val email: String,
    val telefono: String?,
    val direccion: DireccionDTO?,
    val fechaRegistro: Long,
    val activo: Boolean,
    val rol: String,
    val municipio: MunicipioDTO,
    val documento: String,
    val tipoDocumento: String
) {
    companion object {
        fun fromJson(json: Map<String, Any?>): UserDTO {
            return UserDTO(
                id = json["id"] as? String ?: "",
                nombre = json["nombre"] as? String ?: "",
                email = json["email"] as? String ?: "",
                telefono = json["telefono"] as? String,
                direccion = json["direccion"]?.let { DireccionDTO.fromJson(it as Map<String, Any?>) },
                fechaRegistro = json["fecha_registro"] as? Long ?: 0L,
                activo = json["activo"] as? Boolean ?: true,
                rol = json["rol"] as? String ?: "user",
                municipio = MunicipioDTO.fromJson(json["municipio"] as? Map<String, Any?> ?: emptyMap()),
                documento = json["documento"] as? String ?: "",
                tipoDocumento = json["tipo_documento"] as? String ?: "CC"
            )
        }
    }
}

// Clase para dirección del usuario
data class DireccionDTO(
    val id: String,
    val direccion: String,
    val barrio: String?,
    val ciudad: String,
    val departamento: String,
    val codigoPostal: String?,
    val latitud: Double?,
    val longitud: Double?
)

// Modelo de municipio con configuración
data class MunicipioDTO(
    val id: String,
    val nombre: String,
    val departamento: String,
    val codigo: String,
    val activo: Boolean,
    val configuracion: ConfiguracionMunicipioDTO?
)

// Configuración visual del municipio
data class ConfiguracionMunicipioDTO(
    val colorPrimario: String,
    val colorSecundario: String,
    val escudoUrl: String?,
    val nombreCorto: String,
    val permitePagos: Boolean,
    val permiteTramites: Boolean
)'''
    print("=== Test: Compresión de código Kotlin ===")
    compressed = compress_tool_output(kotlin_code, content_type="code")
    stats = get_stats()
    print(f"Original: {len(kotlin_code)} chars ({len(kotlin_code)//4} tokens aprox)")
    print(f"Comprimido: {len(compressed)} chars ({len(compressed)//4} tokens aprox)")
    savings = 100 - (len(compressed) / len(kotlin_code) * 100)
    print(f"Reducción: {savings:.1f}%")
    print(f"Primeras 200 chars comprimidos:")
    print(compressed[:200])
    print("...")
    print()


def test_log_compression():
    """Prueba compresión de logs/salida de comandos."""
    dart_output = '''Analyzing user_dto.dart...

  error - The getter 'fromJson' isn't defined for the type 'UserDTO'. - lib/core/models/user_dto.dart:25:20 - undefined_getter
  error - The method 'fromJson' isn't defined for the type 'DireccionDTO'. - lib/core/models/user_dto.dart:28:35 - undefined_method
  warning - Unused import 'dart:convert'. - lib/core/models/user_dto.dart:1:8 - unused_import
  warning - Unused import 'package:json_annotation/json_annotation.dart'. - lib/core/models/user_dto.dart:2:8 - unused_import
  info - Missing concrete implementation of 'UserDTO.toJson' in 'UserDTO'. - lib/core/models/user_dto.dart:3:7 - missing_override
  error - The parameter 'json' of 'UserDTO.fromJson' can't have a value of 'null'. - lib/core/models/user_dto.dart:25:45 - invalid_assignment
  error - Too many positional arguments: 0 expected, but 1 found. - lib/core/models/user_dto.dart:30:15 - extra_positional_arguments
  warning - The variable 'resultado' is declared but never used. - lib/core/models/user_dto.dart:42:9 - unused_local_variable
  error - Type 'dynamic' can't be assigned to type 'String'. - lib/core/models/user_dto.dart:55:20 - invalid_assignment
  info - The import of 'dart:async' is unnecessary. - lib/core/models/user_dto.dart:5:8 - unnecessary_import
  error - The getter 'nombre' isn't defined for the type 'Map'. - lib/core/models/user_dto.dart:60:30 - undefined_getter
  warning - Avoid print() calls in production code. - lib/core/models/user_dto.dart:70:5 - avoid_print
  error - The class 'DireccionDTO' can't be used as a type in this context. - lib/core/models/user_dto.dart:75:20 - type_not_found
  info - Consider removing unnecessary imports to improve performance. - lib/core/models/user_dto.dart:1:1 - unnecessary_imports
  error - The method 'map' can't be unconditionally invoked because the receiver can be 'null'. - lib/core/models/user_dto.dart:80:10 - nullable_member_invocation
  warning - Naming non-constant variables starting with '_' is discouraged. - lib/core/models/user_dto.dart:85:9 - non_constant_identifier_names'''
    print("=== Test: Compresión de logs dart analyze ===")
    compressed = compress_tool_output(dart_output, content_type="log")
    stats = get_stats()
    print(f"Original: {len(dart_output)} chars ({len(dart_output)//4} tokens aprox)")
    print(f"Comprimido: {len(compressed)} chars ({len(compressed)//4} tokens aprox)")
    savings = 100 - (len(compressed) / len(dart_output) * 100)
    print(f"Reducción: {savings:.1f}%")
    print(f"Contenido comprimido:")
    print(compressed)
    print()


def test_small_content():
    """Prueba que contenido pequeño no se comprime."""
    small = "OK: dart analyze no encontró errores."
    print("=== Test: Contenido pequeño (no se comprime) ===")
    compressed = compress_tool_output(small, content_type="log")
    print(f"Original: {len(small)} chars")
    print(f"Comprimido: {len(compressed)} chars")
    print(f"Igual: {small == compressed}")
    print()


if __name__ == "__main__":
    reset_stats()
    test_code_compression()
    test_log_compression()
    test_small_content()

    stats = get_stats()
    print("=== Resumen de compresión ===")
    print(f"Total compresiones: {stats['compressions']}")
    print(f"Tokens antes: {stats['total_before']}")
    print(f"Tokens después: {stats['total_after']}")
    print(f"Tokens ahorrados: {stats['total_saved']}")
    print(f"Ahorro total: {stats['savings_pct']}%")
