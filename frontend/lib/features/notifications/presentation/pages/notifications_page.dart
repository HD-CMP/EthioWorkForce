import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/notifications_remote_datasource.dart';
import '../../../admin/data/datasources/admin_remote_datasource.dart';
import '../../../admin/data/models/registration_request.dart';
import '../bloc/notifications_bloc.dart';
import '../bloc/notifications_event.dart';
import '../bloc/notifications_state.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final AdminRemoteDatasource _adminDatasource;
  List<RegistrationRequestResponse> _pendingRequests = [];
  bool _isLoadingRequests = true;
  bool _isSuperAdmin = false;

  @override
  void initState() {
    super.initState();
    _adminDatasource = AdminRemoteDatasource(getIt<Dio>());
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _checkUserRole();
    await _loadPendingRequests();
  }

  Future<void> _checkUserRole() async {
    try {
      final dio = await DioClient.createDio();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await dio.get(
        '/users/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      
      if (mounted) {
        setState(() {
          _isSuperAdmin = response.data['role'] == 'SUPER_ADMIN';
        });
      }
    } catch (e) {
    }
  }

  Future<void> _loadPendingRequests() async {
    if (!_isSuperAdmin) {
      if (mounted) {
        setState(() => _isLoadingRequests = false);
      }
      return;
    }
    
    try {
      final requests = await _adminDatasource.getPendingRequests();
      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRequests = false;
        });
      }
    }
  }

  Future<void> _handleApproval(int requestId, bool approved) async {
    try {
      final approval = RegistrationApproval(
        requestId: requestId,
        approved: approved,
        approvalNotes: approved ? 'Approved via notifications' : 'Rejected via notifications',
      );

      await _adminDatasource.approveRequest(approval);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approved ? 'Request approved successfully' : 'Request rejected'),
            backgroundColor: approved ? Colors.green : Colors.orange,
          ),
        );
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsBloc(
        datasource: NotificationsRemoteDatasource(getIt<Dio>()),
      )..add(const FetchNotificationsEvent()),
      child: _NotificationsPageContent(
        pendingRequests: _pendingRequests,
        isLoadingRequests: _isLoadingRequests,
        isSuperAdmin: _isSuperAdmin,
        onApproval: _handleApproval,
        onRefresh: _loadPendingRequests,
      ),
    );
  }
}

class _NotificationsPageContent extends StatelessWidget {
  final List<RegistrationRequestResponse> pendingRequests;
  final bool isLoadingRequests;
  final bool isSuperAdmin;
  final Function(int, bool) onApproval;
  final VoidCallback onRefresh;

  const _NotificationsPageContent({
    required this.pendingRequests,
    required this.isLoadingRequests,
    required this.isSuperAdmin,
    required this.onApproval,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              final hasUnread = state is NotificationsLoaded &&
                  state.notifications.any((n) => !n.isRead);

              return IconButton(
                icon: const Icon(Icons.mark_chat_read),
                tooltip: 'Mark all as read',
                onPressed: hasUnread
                    ? () {
                        context
                            .read<NotificationsBloc>()
                            .add(const MarkAllAsReadEvent());
                      }
                    : null,
              );
            },
          ),
        ],
      ),
      body: BlocListener<NotificationsBloc, NotificationsState>(
        listener: (context, state) {
          if (state is NotificationsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is NotificationsLoaded) {
              final hasContent = state.notifications.isNotEmpty || (isSuperAdmin && pendingRequests.isNotEmpty);
              
              if (!hasContent) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  onRefresh();
                  context
                      .read<NotificationsBloc>()
                      .add(const FetchNotificationsEvent());
                },
                child: ListView.builder(
                  itemCount: 1 + (isSuperAdmin && pendingRequests.isNotEmpty ? 1 : 0) + state.notifications.length,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildSystemStatsCard(context, state.notifications);
                    }
                    
                    if (isSuperAdmin && index == 1 && pendingRequests.isNotEmpty) {
                      return _buildPendingRequestsSection(context);
                    }
                    
                    final notificationIndex = index - 1 - (isSuperAdmin && pendingRequests.isNotEmpty ? 1 : 0);
                    final notification = state.notifications[notificationIndex];
                    return _buildNotificationItem(
                      context,
                      notification: notification,
                      onTap: () {
                        if (!notification.isRead) {
                          context.read<NotificationsBloc>().add(
                                MarkAsReadEvent([notification.id]),
                              );
                        }
                      },
                      onDismiss: () {
                        context.read<NotificationsBloc>().add(
                              DeleteNotificationEvent(notification.id),
                            );
                      },
                    );
                  },
                ),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Pull to refresh'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<NotificationsBloc>()
                          .add(const FetchNotificationsEvent());
                    },
                    child: const Text('Load Notifications'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSystemStatsCard(BuildContext context, List notifications) {
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final todayNotifications = notifications.where((n) {
      final now = DateTime.now();
      return n.createdAt.year == now.year &&
             n.createdAt.month == now.month &&
             n.createdAt.day == now.day;
    }).length;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'System Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total',
                    notifications.length.toString(),
                    Icons.notifications,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Unread',
                    unreadCount.toString(),
                    Icons.mark_email_unread,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Today',
                    todayNotifications.toString(),
                    Icons.today,
                    Colors.green,
                  ),
                ),
                if (isSuperAdmin)
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Pending',
                      pendingRequests.length.toString(),
                      Icons.pending_actions,
                      Colors.red,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.withOpacity(0.2), Colors.orange.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pending_actions, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Approvals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                    Text(
                      '${pendingRequests.length} registration request${pendingRequests.length != 1 ? 's' : ''} awaiting review',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ...pendingRequests.map((request) => _buildPendingRequestCard(context, request)).toList(),
        const Divider(height: 1, thickness: 2),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Other Notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingRequestCard(BuildContext context, RegistrationRequestResponse request) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Icon(Icons.person_add, color: Colors.orange[800]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '@${request.username} • ${request.role}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (request.email != null || request.phoneNumber != null) ...[
              const SizedBox(height: 12),
              if (request.email != null)
                Row(
                  children: [
                    Icon(Icons.email, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(request.email!, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              if (request.phoneNumber != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(request.phoneNumber!, style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                ),
            ],
            if (request.siteNames != null && request.siteNames!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sites: ${request.siteNames!.join(', ')}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => onApproval(request.id, false),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[300]!),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => onApproval(request.id, true),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'registration_request':
        return Icons.person_add;
      case 'registration_approved':
      case 'registration_rejected':
        return Icons.how_to_reg;
      case 'worker_added':
        return Icons.people;
      case 'attendance_marked':
        return Icons.check_circle;
      case 'payroll_processed':
        return Icons.attach_money;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required notification,
    required VoidCallback onTap,
    required VoidCallback onDismiss,
  }) {
    final timeAgo = _formatTimeAgo(notification.createdAt);

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: notification.isRead ? 1 : 4,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: notification.isRead
                ? Colors.grey[400]
                : Theme.of(context).colorScheme.primary,
            child: Icon(
              _getIconForType(notification.type),
              color: Colors.white,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight:
                        notification.isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: onTap,
        ),
      ),
    );
  }
}
