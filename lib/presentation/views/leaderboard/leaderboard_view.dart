import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/leaderboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../../core/utils/helpers.dart';
import '../../../data/models/report_model.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart' as error_widget;

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  late final LeaderboardController _controller;
  late final AuthController _authController;
  bool _initialLoadAttempted = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<LeaderboardController>();
    _authController = Get.find<AuthController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attemptInitialLoad();
    });
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
            const Text('Leaderboard'),
          ],
        ),
      ),
      body: Obx(() {
        if (_authController.shop == null && !_authController.isLoading) {
          return error_widget.ErrorDisplayWidget(
            message: 'Shop not found. Please sign in again.',
            onRetry: () => _authController.checkAuthStatus(),
          );
        }

        if (_controller.isLoading && _controller.leaderboard.isEmpty) {
          return const LoadingWidget();
        }

        if (_controller.errorMessage.isNotEmpty &&
            _controller.leaderboard.isEmpty) {
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
                  'Sales Accountability Leaderboard',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ranked by points (closed won × 10). Freelance & office staff only. Status and safety fund for This month.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),

                // Period filter chips (readable text: contrast for selected/unselected)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LeaderboardPeriod.values.map((p) {
                    final isSelected = _controller.period == p;
                    return FilterChip(
                      label: Text(
                        p.label,
                        style: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        _controller.setPeriod(p);
                        _loadLeaderboard();
                      },
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      selectedColor: theme.colorScheme.primary,
                      checkmarkColor: theme.colorScheme.onPrimary,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Rankings card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rankings',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rank, count, conversion %, points'
                          '${_controller.period == LeaderboardPeriod.thisMonth ? '; status and safety fund' : ''}'
                          '${_controller.period != LeaderboardPeriod.allTime ? ' (${_controller.period.label})' : ''}.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_controller.isLoading &&
                            _controller.leaderboard.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_controller.leaderboard.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.emoji_events_outlined,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Closed – Won in this period',
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Try another time range or check back later.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _controller.leaderboard.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final entry = _controller.leaderboard[index];
                              final showStatusAndSafety =
                                  _controller.period ==
                                  LeaderboardPeriod.thisMonth;
                              return _LeaderboardTile(
                                entry: entry,
                                theme: theme,
                                showStatusAndSafety: showStatusAndSafety,
                              );
                            },
                          ),
                      ],
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

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final ThemeData theme;
  final bool showStatusAndSafety;

  const _LeaderboardTile({
    required this.entry,
    required this.theme,
    this.showStatusAndSafety = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final rankColor = _rankColor(entry.rank);
    final surface = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerLow;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      elevation: isDark ? 0 : 1,
      shadowColor: Colors.black.withOpacity(0.06),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Rank + Name & Role only
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: rankColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: rankColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: entry.rank <= 3
                      ? Icon(_rankIcon(entry.rank), size: 26, color: rankColor)
                      : Text(
                          '${entry.rank}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: rankColor,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        Helpers.safeDisplayString(entry.staffName),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Helpers.safeDisplayString(
                          entry.role,
                        ).replaceAll('_', ' '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Metrics in a 2x2 grid so they don’t crowd one row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:
                    (isDark
                            ? theme.colorScheme.surface
                            : theme.colorScheme.surfaceContainerHighest)
                        .withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetric(
                          theme,
                          'Total Leads',
                          '${entry.totalAssignedLeads}',
                        ),
                      ),
                      Expanded(
                        child: _buildMetric(
                          theme,
                          'Closed Won',
                          '${entry.conversions}',
                          bold: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetric(
                          theme,
                          'Conversion %',
                          '${entry.conversionRate.toStringAsFixed(1)}%',
                        ),
                      ),
                      Expanded(
                        child: _buildMetric(
                          theme,
                          'Points',
                          '${entry.points}',
                          bold: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showStatusAndSafety &&
                (entry.status != null || entry.safetyFundEligible != null)) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (entry.status != null)
                    Chip(
                      label: Text(
                        Helpers.safeDisplayString(entry.status!),
                        style: theme.textTheme.labelSmall,
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  if (entry.safetyFundEligible != null)
                    Text(
                      entry.safetyFundEligible!
                          ? 'Safety: Eligible'
                          : 'Safety: Not eligible',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(
    ThemeData theme,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Color _rankColor(int rank) {
    if (rank == 1) return Colors.amber.shade700;
    if (rank == 2) return Colors.grey.shade600;
    if (rank == 3) return Colors.brown.shade600;
    return Colors.grey.shade500;
  }

  IconData _rankIcon(int rank) {
    if (rank == 1) return Icons.emoji_events;
    if (rank == 2) return Icons.emoji_events;
    if (rank == 3) return Icons.emoji_events;
    return Icons.emoji_events;
  }
}
