# Setup Instructions for Background Notifications

## 1. Install Dependencies

Run these commands in your terminal:

```bash
cd /home/tim/Lekec/lekec
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## 2. Test the Implementation

### Add a medication:
1. Open the app
2. Click the FAB (+ button)
3. Choose "Dodaj novo zdravilo"
4. Enter medication name (e.g., "Lekadol")
5. Select type (e.g., "Tablete")
6. Click "Naprej"
7. Choose "Enkrat dnevno" or "Dvakrat dnevno"
8. Click "Naprej"
9. Set start date (today)
10. Set first intake time (e.g., 5 minutes from now for testing)
11. Set quantity
12. Click "Shrani"

### Check the database:
```bash
# View generated intake entries
sqlite3 ~/Lekec/lekec/build/app/outputs/flutter-apk/lekec.db \
  "SELECT * FROM medication_intake_logs ORDER BY scheduled_time;"

# Check scheduled notifications (from app logs)
flutter logs | grep NotificationService
```

## 3. How It Works

### On App Start:
1. **IntakeScheduleGenerator** generates intake entries for next 30 days
2. **NotificationService** schedules Android notifications for next 7 days
3. **BackgroundTaskService** sets up periodic tasks:
   - Daily: Generate new intake entries
   - Every 6 hours: Reschedule notifications

### Background Tasks (even when app is closed):
- **Workmanager** runs scheduled tasks
- Regenerates intake entries if needed
- Reschedules notifications to keep them current

### Notifications:
- Shows: "Vzemite zdravilo Lekadol" with dosage
- Appears at exact scheduled time
- Works even if app is closed
- Sound + vibration

## 4. Important Notes

### Old Entries:
- **NOT deleted** - they serve as logs
- Can query them later for history/statistics
- `wasTaken` field tracks if user took medication

### Database Schema Used:
- `medications` - medication details
- `medication_plans` - user's medication schedules
- `medication_schedule_rules` - timing rules (daily, weekly, etc.)
- `medication_intake_logs` - actual scheduled times (generated from rules)

### Supported Schedule Types:
- **daily**: Same time(s) every day
- **weekly**: Specific days of week + times
- **dayInterval**: Every N days
- **cyclic**: N days on, M days off
- **asNeeded**: No scheduled reminders

## 5. Future Enhancements

Things you can add:
- [ ] Mark intake as taken (update `wasTaken` field)
- [ ] Snooze notification
- [ ] View intake history
- [ ] Statistics/adherence tracking
- [ ] Multiple users
- [ ] Export logs
- [ ] Notification customization (sound, vibration pattern)

## 6. Debugging

### View logs:
```bash
flutter logs | grep -E "(IntakeScheduler|NotificationService|BackgroundTask)"
```

### Test notification immediately:
Add this test button in developer settings to trigger a test notification 1 minute from now.

### Check pending notifications:
The app logs show how many notifications are scheduled on startup.
