/// An action button tap that happened on an alarm notification.
///
/// **Fork addition.** Produced when the user taps a
/// [NotificationActionButton] on the native Android notification. The native
/// side records these (so they survive the app being killed) and the app
/// drains them through `Alarm.consumePendingNotificationActions()`.
class NotificationActionEvent {
  /// Creates a notification action event.
  const NotificationActionEvent({
    required this.alarmId,
    required this.actionId,
  });

  /// The id of the alarm whose notification button was tapped.
  final int alarmId;

  /// The [NotificationActionButton.id] of the tapped button.
  final String actionId;

  @override
  String toString() =>
      'NotificationActionEvent(alarmId: $alarmId, actionId: $actionId)';
}
