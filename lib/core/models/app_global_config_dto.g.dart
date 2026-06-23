// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_global_config_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppGlobalConfigDTO _$AppGlobalConfigDTOFromJson(Map<String, dynamic> json) =>
    AppGlobalConfigDTO(
      status: json['status'] as String? ?? "operational",
      title: json['title'] as String? ?? "",
      message: json['message'] as String? ?? "",
      dismissible: json['dismissible'] as bool? ?? true,
      minVersionCode: (json['min_version_code'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AppGlobalConfigDTOToJson(AppGlobalConfigDTO instance) =>
    <String, dynamic>{
      'status': instance.status,
      'title': instance.title,
      'message': instance.message,
      'dismissible': instance.dismissible,
      'min_version_code': instance.minVersionCode,
    };
