import 'package:citoyen_plus/features/feed/presentation/pages/feed_page.dart';
import 'package:flutter/material.dart';

class AccueilView extends StatelessWidget {
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onProfilePressed;

  const AccueilView({
    super.key,
    this.onNotificationPressed,
    this.onSearchPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return FeedPage(
      onNotificationPressed: onNotificationPressed,
      onSearchPressed: onSearchPressed,
      onProfilePressed: onProfilePressed,
    );
  }
}
