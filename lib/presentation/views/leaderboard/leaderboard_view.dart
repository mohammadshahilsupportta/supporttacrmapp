import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/leaderboard_controller.dart';
import '../../controllers/auth_controller.dart';
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
                  'Closed Won Leaderboard',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ranked by Closed – Won. Who closed the most deals — visible to all staff.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),

                // Period filter chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: LeaderboardPeriod.values.map((p) {
                    final isSelected = _controller.period == p;
                    return FilterChip(
                      label: Text(p.label),
                      selected: isSelected,
                      onSelected: (_) {
                        _controller.setPeriod(p);
                        _loadLeaderboard();
                      },
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
                            Icon(Icons.trending_up, color: theme.colorScheme.primary),
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
                          'All team members ranked by Closed – Won count'
                          '${_controller.period != LeaderboardPeriod.allTime ? ' (${_controller.period.label})' : ''}.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_controller.isLoading && _controller.leaderboard.isNotEmpty)
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
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 24,
                              columns: const [
                                DataColumn(label: Text('Rank')),
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Role')),
                                DataColumn(
                                  label: Text('Closed – Won'),
                                  numeric: true,
                                ),
                              ],
                              rows: _controller.leaderboard.map((entry) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _RankIcon(rank: entry.rank),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${entry.rank}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(entry.staffName)),
                                    DataCell(
                                      Chip(
                                        label: Text(
                                          entry.role.replaceAll('_', ' '),
                                          style: theme.textTheme.labelSmall,
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        '${entry.conversions}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
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

class _RankIcon extends StatelessWidget {
  final int rank;

  const _RankIcon({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank == 1) {
      return Icon(Icons.emoji_events, size: 22, color: Colors.amber.shade700);
    }
    if (rank == 2) {
      return Icon(Icons.emoji_events, size: 22, color: Colors.grey.shade500);
    }
    if (rank == 3) {
      return Icon(Icons.emoji_events, size: 22, color: Colors.brown.shade400);
    }
    return const SizedBox.shrink();
  }
}
