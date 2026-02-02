import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/coordinator_leaderboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/report_model.dart';
import '../../../data/models/user_model.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;

class CoordinatorLeaderboardView extends StatefulWidget {
  const CoordinatorLeaderboardView({super.key});

  @override
  State<CoordinatorLeaderboardView> createState() => _CoordinatorLeaderboardViewState();
}

class _CoordinatorLeaderboardViewState extends State<CoordinatorLeaderboardView> {
  late final CoordinatorLeaderboardController _controller;
  late final AuthController _authController;
  bool _initialLoadAttempted = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<CoordinatorLeaderboardController>();
    _authController = Get.find<AuthController>();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attemptInitialLoad());
  }

  void _attemptInitialLoad() {
    if (_authController.shop != null && !_initialLoadAttempted) {
      _initialLoadAttempted = true;
      _loadLeaderboard();
    }
  }

  Future<void> _loadLeaderboard() async {
    if (_authController.shop != null) {
      await _controller.loadLeaderboard(_authController.shop!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.emoji_events, size: 28, color: Colors.amber.shade700),
            const SizedBox(width: 12),
            const Text('Coordinator Leaderboard'),
          ],
        ),
      ),
      body: Obx(() {
        final user = _authController.user;
        if (user == null || user.role != UserRole.crmCoordinator) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Only CRM coordinators can view this page.',
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (_authController.shop == null && !_authController.isLoading) {
          return error_widget.ErrorDisplayWidget(
            message: 'Shop not found. Please sign in again.',
            onRetry: () => _authController.checkAuthStatus(),
          );
        }

        if (_controller.isLoading && _controller.leaderboard.isEmpty) {
          return const LoadingWidget();
        }

        if (_controller.errorMessage.isNotEmpty && _controller.leaderboard.isEmpty) {
          return error_widget.ErrorDisplayWidget(
            message: _controller.errorMessage,
            onRetry: _loadLeaderboard,
          );
        }

        return RefreshIndicator(
          onRefresh: _loadLeaderboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coordinator Leaderboard',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ranked by ordinary points (leads added). Total leads, converted, and star points shown.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CoordinatorLeaderboardPeriod.values.map((p) {
                    final isSelected = _controller.period == p;
                    return FilterChip(
                      label: Text(
                        p.label,
                        style: TextStyle(
                          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        _controller.setPeriod(p);
                        _loadLeaderboard();
                      },
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      selectedColor: theme.colorScheme.primary,
                      checkmarkColor: theme.colorScheme.onPrimary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                // Section: CRM Coordinators — clear heading block
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.groups_outlined, size: 22, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            'CRM Coordinators',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Total leads added, converted (closed won), star points (10 per conversion), and ordinary points in the selected period.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_controller.isLoading && _controller.leaderboard.isNotEmpty)
                  const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                else if (_controller.leaderboard.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'No coordinator data for this period.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _controller.leaderboard.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final e = _controller.leaderboard[index];
                      return _CoordinatorTile(theme: theme, entry: e);
                    },
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _CoordinatorTile extends StatelessWidget {
  final ThemeData theme;
  final CoordinatorLeaderboardEntry entry;

  const _CoordinatorTile({required this.theme, required this.entry});

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? theme.colorScheme.surfaceContainerHigh : theme.colorScheme.surfaceContainerLow;
    final rankColor = _rankColor(entry.rank);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row: rank + name
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: rankColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: rankColor.withValues(alpha: 0.5), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: entry.rank <= 3
                      ? Icon(_rankIcon(entry.rank), size: 22, color: rankColor)
                      : Text(
                          '${entry.rank}',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: rankColor),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    Helpers.safeDisplayString(entry.staffName),
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Metrics row: labeled values so they stay arranged
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (isDark ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerHighest).withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(child: _metricCell(theme, 'Leads', '${entry.totalLeads}')),
                  Expanded(child: _metricCell(theme, 'Conv', '${entry.converted}')),
                  Expanded(child: _metricCell(theme, 'Stars', '${entry.starPoints}', valueColor: Colors.amber.shade700)),
                  Expanded(child: _metricCell(theme, 'Points', '${entry.ordinaryPoints}', bold: true)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCell(ThemeData theme, String label, String value, {Color? valueColor, bool bold = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  IconData _rankIcon(int rank) => Icons.emoji_events;

  Color _rankColor(int rank) {
    if (rank == 1) return Colors.amber.shade700;
    if (rank == 2) return Colors.grey.shade600;
    if (rank == 3) return Colors.brown.shade600;
    return Colors.grey.shade500;
  }
}
