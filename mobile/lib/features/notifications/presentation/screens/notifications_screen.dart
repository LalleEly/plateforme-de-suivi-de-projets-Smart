import 'package:flutter/material.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final notifications = await ApiService.getNotifications();
      setState(() { _notifications = notifications; _loading = false; });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = apiErrorMessage(e, fallback: 'Impossible de charger les notifications');
      });
    }
  }

  Future<void> _markAsRead(NotificationModel n) async {
    if (n.read) return;
    try {
      await ApiService.markNotificationAsRead(n.id);
      _load();
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsAsRead();
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor: context.colors.bg2,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.text1),
        title: Text('Notifications',
            style: TextStyle(color: context.colors.text1, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text('Tout marquer comme lu',
                style: TextStyle(fontSize: 12, color: context.colors.accent)),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.accent))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: TextStyle(color: context.colors.text2)))
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none_rounded,
                              size: 48, color: context.colors.text3),
                          const SizedBox(height: 12),
                          Text('Aucune notification',
                              style: TextStyle(color: context.colors.text2)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: context.colors.accent,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (_, i) {
                          final n = _notifications[i];
                          return InkWell(
                            onTap: () => _markAsRead(n),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: n.read
                                      ? context.colors.bg2
                                      : context.colors.accent.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: n.read
                                          ? context.colors.border
                                          : context.colors.accent.withOpacity(0.3),
                                      width: 0.5)),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!n.read)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4, right: 8),
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                          color: context.colors.accent,
                                          shape: BoxShape.circle),
                                    ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(n.title,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: context.colors.text1)),
                                        if (n.message != null) ...[
                                          const SizedBox(height: 2),
                                          Text(n.message!,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: context.colors.text2)),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
