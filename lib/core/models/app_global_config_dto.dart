import 'package:json_annotation/json_annotation.dart';

part 'app_global_config_dto.g.dart';

@JsonSerializable()
class AppGlobalConfigDTO {
  /// El estado: 'operational', 'maintenance', 'server_error', 'force_update'
  @JsonKey(name: 'status')
  final String status;

  /// Título del modal/card
  @JsonKey(name: 'title')
  final String title;

  /// Cuerpo del mensaje
  @JsonKey(name: 'message')
  final String message;

  /// false = Bloqueo total (pantalla roja)
  /// true = Solo aviso informativo (toast o modal cerrable)
  @JsonKey(name: 'dismissible')
  final bool dismissible;

  /// Opcional: Versión mínima requerida (útil para obligar a actualizar)
  @JsonKey(name: 'min_version_code')
  final int minVersionCode;

  AppGlobalConfigDTO({
    this.status = "operational",
    this.title = "",
    this.message = "",
    this.dismissible = true,
    this.minVersionCode = 0,
  });

  factory AppGlobalConfigDTO.fromJson(Map<String, dynamic> json) =>
      _$AppGlobalConfigDTOFromJson(json);

  Map<String, dynamic> toJson() => _$AppGlobalConfigDTOToJson(this);
}
