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
import '../../../../core/utils/app_snackbar.dart';

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
        if (approved) {
          AppSnackBar.showSuccess(context, 'Request approved successfully');
        } else {
          AppSnackBar.showWarning(context, 'Request rejected');
        }
        _loadPendingRequests();
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error: ${e.toString()}');
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
      backgroundColor: const Color(0xFFF4F7F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFF007A3D),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, size: 22, color: Colors.white),
            SizedBox(width: 10),
            Text('Notifications', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        actions: [
          BlocBuilder<NotificationsBloc, NotificationsState>(
            builder: (context, state) {
              final hasUnread = state is NotificationsLoaded &&
                  state.notifications.any((n) => !n.isRead);

              return IconButton(
                icon: const Icon(Icons.done_all_rounded, color: Colors.white),
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
            AppSnackBar.showError(context, state.message);
          }
        },
        child: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF007A3D)),
              );
            }

            if (state is NotificationsLoaded) {
              final hasContent = state.notifications.isNotEmpty || (isSuperAdmin && pendingRequests.isNotEmpty);
              
              if (!hasContent) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 40, color: Color(0xFF007A3D)),
                      ),
                      const SizedBox(height: 20),
                      const Text('All caught up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                      const SizedBox(height: 8),
                      const Text('No notifications at this time', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: const Color(0xFF007A3D),
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
                  const Icon(Icons.refresh_rounded, size: 48, color: Color(0xFF9CA3AF)),
                  const SizedBox(height: 16),
                  const Text('Pull to refresh', style: TextStyle(color: Color(0xFF6B7280))),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<NotificationsBloc>()
                          .add(const FetchNotificationsEvent());
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Load Notifications'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007A3D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                Icon(Icons.dashboard, color: const Color(0xFF007A3D)),
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
                    const Color(0xFF1E3A5F),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Unread',
                    unreadCount.toString(),
                    Icons.mark_email_unread,
                    const Color(0xFFE65100),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Today',
                    todayNotifications.toString(),
                    Icons.today,
                    const Color(0xFF007A3D),
                  ),
                ),
                if (isSuperAdmin)
                  Expanded(
                    child: _buildStatItem(
                      context,
                      'Pending',
                      pendingRequests.length.toString(),
                      Icons.pending_actions,
                      const Color(0xFFB71C1C),
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
        color: Color.fromARGB(26, color.red, color.green, color.blue),
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
              color: const Color(0xFF6B7280),
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
              colors: [Color(0x33E65100), const Color(0x1AE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFBF360C),
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
                        color: const Color(0xFFBF360C),
                      ),
                    ),
                    Text(
                      '${pendingRequests.length} registration request${pendingRequests.length != 1 ? 's' : ''} awaiting review',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFE65100),
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
              color: const Color(0xFF374151),
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
        side: BorderSide(color: const Color(0x4DE65100), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFFF3E0),
                  child: Icon(Icons.person_add, color: const Color(0xFFBF360C)),
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
                          color: const Color(0xFF6B7280),
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
                    Icon(Icons.email, size: 16, color: const Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(request.email!, style: TextStyle(color: const Color(0xFF374151))),
                  ],
                ),
              if (request.phoneNumber != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: const Color(0xFF6B7280)),
                      const SizedBox(width: 8),
                      Text(request.phoneNumber!, style: TextStyle(color: const Color(0xFF374151))),
                    ],
                  ),
                ),
            ],
            if (request.siteNames != null && request.siteNames!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: const Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sites: ${request.siteNames!.join(', ')}',
                      style: TextStyle(color: const Color(0xFF374151)),
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
                    foregroundColor: const Color(0xFFB71C1C),
                    side: BorderSide(color: const Color(0xFFE57373)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => onApproval(request.id, true),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007A3D),
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
        color: const Color(0xFFB71C1C),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: notification.isRead ? 1 : 4,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: notification.isRead
                ? const Color(0xFF9CA3AF)
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
                  color: const Color(0xFF6B7280),
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
