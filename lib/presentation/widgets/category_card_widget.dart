import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';

class CategoryCardWidget extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int? usageCount;

  const CategoryCardWidget({
    super.key,
    required this.category,
    this.onEdit,
    this.onDelete,
    this.usageCount,
  });

  Color _getCategoryColor() {
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        return Color(
          int.parse(category.color!.replaceFirst('#', '0xFF')),
        );
      } catch (e) {
        return Colors.indigo;
      }
    }
    return Colors.indigo;
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor();
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: null, // Only edit via the edit icon
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 40,
                    decoration: BoxDecoration(
                      color: categoryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (category.description != null &&
                                  category.description!.isNotEmpty)
                              ? category.description!
                              : 'No description',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null || onDelete != null)
                    const SizedBox(width: 8),
                  if (onEdit != null || onDelete != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onEdit != null)
                          _ActionIcon(
                            icon: Icons.edit_rounded,
                            color: theme.colorScheme.primary,
                            onTap: onEdit,
                          ),
                        if (onEdit != null && onDelete != null)
                          const SizedBox(width: 8),
                        if (onDelete != null)
                          _ActionIcon(
                            icon: Icons.delete_rounded,
                            color: theme.colorScheme.error,
                            onTap: onDelete,
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (usageCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '$usageCount ${usageCount == 1 ? 'lead' : 'leads'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionIcon({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }
}

