import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/admin_notification_model.dart';
import '../customs/customicon.dart';
import 'reported_reviews_page.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({Key? key}) : super(key: key);

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _databaseService = DatabaseService();
  List<AdminNotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _databaseService.getAdminNotifications();
      if (mounted) {
        setState(() {
          _notifications = data
              .map((notification) =>
                  AdminNotificationModel.fromMap(notification))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bildirimler yüklenirken hata oluştu: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(AdminNotificationModel notification) async {
    try {
      await _databaseService.markNotificationAsRead(notification.id);
      if (mounted) {
        setState(() {
          final index = _notifications.indexOf(notification);
          if (index != -1) {
            _notifications[index] = AdminNotificationModel(
              id: notification.id,
              type: notification.type,
              content: notification.content,
              isRead: true,
              createdAt: notification.createdAt,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Bildirim durumu güncellenirken hata oluştu: $e')),
        );
      }
    }
  }

  String _getTimeDifference(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} yıl önce';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} ay önce';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    }
    return 'Az önce';
  }

  String _getNotificationMessage(AdminNotificationModel notification) {
    if (notification.type == 'review_report') {
      return 'Bir yorum şikayet edildi';
    }
    return 'Yeni bildirim';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bildirimler',
          style: TextStyle(
            color: Color(0xFF8A0C27),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFEDEFE8),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? const Center(child: Text('Bildirim bulunmuyor'))
              : ListView.builder(
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    return Card(
                      color: notification.isRead
                          ? null
                          : Colors.blue.withOpacity(0.1),
                      child: ListTile(
                        leading: const CustomIcon(
                          iconData: Icons.report_problem,
                          iconColor: Color(0xFF8A0C27),
                        ),
                        title: Text(_getNotificationMessage(notification)),
                        subtitle:
                            Text(_getTimeDifference(notification.createdAt)),
                        trailing: notification.isRead
                            ? null
                            : Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue,
                                ),
                              ),
                        onTap: () async {
                          if (!notification.isRead) {
                            await _markAsRead(notification);
                          }
                          if (mounted && notification.type == 'review_report') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ReportedReviewsPage(),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
