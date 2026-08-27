// GENERATED CODE - DO NOT MODIFY BY HAND
//
// Fork note: hand-edited to round-trip the `actionButtons` field. Keep in sync
// with the `NotificationSettings` model if you ever regenerate.

part of 'notification_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationSettings _$NotificationSettingsFromJson(
        Map<String, dynamic> json) =>
    $checkedCreate(
      'NotificationSettings',
      json,
      ($checkedConvert) {
        final val = NotificationSettings(
          title: $checkedConvert('title', (v) => v as String),
          body: $checkedConvert('body', (v) => v as String),
          stopButton: $checkedConvert('stopButton', (v) => v as String?),
          icon: $checkedConvert('icon', (v) => v as String?),
          actionButtons: $checkedConvert(
            'actionButtons',
            (v) =>
                (v as List<dynamic>?)
                    ?.map((e) => NotificationActionButton.fromJson(
                        e as Map<String, dynamic>))
                    .toList() ??
                const [],
          ),
        );
        return val;
      },
    );

Map<String, dynamic> _$NotificationSettingsToJson(
        NotificationSettings instance) =>
    <String, dynamic>{
      'title': instance.title,
      'body': instance.body,
      if (instance.stopButton case final value?) 'stopButton': value,
      if (instance.icon case final value?) 'icon': value,
      if (instance.actionButtons.isNotEmpty)
        'actionButtons':
            instance.actionButtons.map((e) => e.toJson()).toList(),
    };
