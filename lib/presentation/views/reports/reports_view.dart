import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/report_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;
import '../../../data/models/user_model.dart';
import '../../widgets/stats_card_widget.dart';

class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final ReportController _controller = Get.find<ReportController>();
  final AuthController _authController = Get.find<AuthController>();
  bool _initialLoadAttempted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptInitialLoad();
    });
  }

  void _attemptInitialLoad() {
    if (_authController.shop != null && !_initialLoadAttempted) {
      _initialLoadAttempted = true;
      _loadReports();
    }

    // Listen for shop changes
    ever(_authController.shopRx, (shop) {
      if (shop != null && !_initialLoadAttempted) {
        _initialLoadAttempted = true;
        _loadReports();
      }
    });
  }

  Future<void> _loadReports() async {
    if (_authController.shop != null) {
      await _controller.loadStats(_authController.shop!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = _authController.user;

    // Check if user has admin role (shop_owner or admin)
    final isAdmin = user != null &&
        (user.role == UserRole.shopOwner || user.role == UserRole.admin);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reports')),
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reports are only available to shop owners and admins.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.bar_chart, size: 28),
            const SizedBox(width: 12),
            const Text('Reports'),
          ],
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading && _controller.stats.isEmpty) {
          return const LoadingWidget();
        }

        if (_controller.errorMessage.isNotEmpty && _controller.stats.isEmpty) {
          return error_widget.ErrorDisplayWidget(
            message: _controller.errorMessage,
            onRetry: _loadReports,
          );
        }

        final summary = _controller.summary;
        final stats = _controller.stats;

        return RefreshIndicator(
          onRefresh: _loadReports,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Staff performance analytics and insights',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Summary Cards
                if (summary != null)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      StatsCardWidget(
                        title: 'Total Staff',
                        value: summary.totalStaff.toString(),
                        subtitle: 'Active team members',
                        icon: Icons.people,
                        iconColor: Colors.blue,
                      ),
                      StatsCardWidget(
                        title: 'Total Conversions',
                        value: summary.totalConversions.toString(),
                        subtitle: 'All time conversions',
                        icon: Icons.trending_up,
                        iconColor: Colors.green,
                      ),
                      StatsCardWidget(
                        title: 'Avg. Conversion Rate',
                        value: '${summary.avgConversionRate.toStringAsFixed(1)}%',
                        subtitle: 'Across all staff',
                        icon: Icons.bar_chart,
                        iconColor: Colors.orange,
                      ),
                      StatsCardWidget(
                        title: 'Top Performer',
                        value: summary.topPerformer?.staffName ?? '-',
                        subtitle: summary.topPerformer != null
                            ? '${summary.topPerformer!.conversions} conversions (${summary.topPerformer!.conversionRate.toStringAsFixed(1)}%)'
                            : 'No conversions yet',
                        icon: Icons.emoji_events,
                        iconColor: Colors.amber,
                      ),
                    ],
                  ),
                const SizedBox(height: 24),

                // Staff Performance Table
                Text(
                  'Staff Performance',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Performance metrics for each team member',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 16),

                if (stats.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No staff members found',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 24,
                        columns: [
                          const DataColumn(label: Text('Staff Member')),
                          const DataColumn(label: Text('Role')),
                          const DataColumn(
                            label: Text('Leads'),
                            numeric: true,
                          ),
                          const DataColumn(
                            label: Text('Conversions'),
                            numeric: true,
                          ),
                          const DataColumn(
                            label: Text('Rate'),
                            numeric: true,
                          ),
                          const DataColumn(
                            label: Text('Avg. Days'),
                            numeric: true,
                          ),
                          const DataColumn(
                            label: Text('This Month'),
                            numeric: true,
                          ),
                          const DataColumn(label: Text('Status')),
                        ],
                        rows: stats.map((stat) {
                          final conversionRateColor = stat.conversionRate >= 20
                              ? Colors.green
                              : stat.conversionRate >= 10
                                  ? Colors.orange
                                  : Colors.grey;

                          return DataRow(
                            cells: [
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      stat.staffName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      stat.staffEmail,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Chip(
                                  label: Text(
                                    stat.role.replaceAll('_', ' '),
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              DataCell(Text(stat.totalLeadsAssigned.toString())),
                              DataCell(
                                Text(
                                  stat.totalConversions.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (stat.conversionRate >= 20)
                                      Icon(
                                        Icons.arrow_upward,
                                        size: 14,
                                        color: Colors.green,
                                      )
                                    else if (stat.conversionRate > 0)
                                      Icon(
                                        Icons.arrow_downward,
                                        size: 14,
                                        color: Colors.orange,
                                      ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${stat.conversionRate.toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: conversionRateColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Text(
                                  stat.avgDaysToConvert != null
                                      ? '${stat.avgDaysToConvert!.toStringAsFixed(1)} days'
                                      : '-',
                                ),
                              ),
                              DataCell(
                                Text(stat.conversionsThisMonth.toString()),
                              ),
                              DataCell(
                                Chip(
                                  label: Text(
                                    stat.isActive ? 'Active' : 'Inactive',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: stat.isActive
                                      ? Colors.green.shade50
                                      : Colors.grey.shade200,
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

