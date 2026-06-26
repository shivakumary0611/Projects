import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  /// Optional small brand image shown beside the title (e.g. home screen logo).
  final String? brandAssetPath;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.brandAssetPath,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      titleSpacing: brandAssetPath == null ? null : 0,
      title: Row(
        children: [
          if (brandAssetPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                brandAssetPath!,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 36,
                    height: 36,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.sports_cricket,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
