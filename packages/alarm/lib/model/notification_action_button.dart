import 'package:equatable/equatable.dart';

/// A custom action button rendered on the alarm notification.
///
/// **Fork addition.** The upstream `alarm` package only supports a single
/// [NotificationSettings.stopButton]. This app needs richer actions on the
/// notification itself (e.g. "Sem vzel" / "Bom preskočil" for medication
/// reminders, "Razumem" for appointments) so the user can act without opening
/// the full-screen alarm UI.
///
/// **Android only.** On iOS the wire field is ignored and the notification
/// falls back to [NotificationSettings.stopButton].
///
/// When a button is tapped the native side stops the alarm and records the
/// [id]. The app drains those records via
/// `Alarm.consumePendingNotificationActions()`.
class NotificationActionButton extends Equatable {
  /// Creates a notification action button.
  const NotificationActionButton({required this.id, required this.text});

  /// Rebuilds an instance from its JSON representation.
  factory NotificationActionButton.fromJson(Map<String, dynamic> json) =>
      NotificationActionButton(
        id: json['id'] as String,
        text: json['text'] as String,
      );

  /// Stable identifier reported back to the app when the button is tapped.
  ///
  /// The app uses this to decide what to do (mark taken, skip, acknowledge).
  final String id;

  /// The label shown on the notification action.
  final String text;

  /// Converts this instance to a JSON object.
  Map<String, dynamic> toJson() => <String, dynamic>{'id': id, 'text': text};

  @override
  List<Object?> get props => [id, text];
}
