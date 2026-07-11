import 'package:flutter/material.dart';
import 'las_seen.dart';

/// Shows a green "online" dot, or a gray "last seen" pill,
/// positioned at the bottom-right of an avatar.
class OnlineStatusBadge extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeenAt;
  final double avatarSize;

  const OnlineStatusBadge({
    super.key,
    required this.isOnline,
    required this.lastSeenAt,
    required this.avatarSize,
  });

  @override
  Widget build(BuildContext context) {
    if (isOnline) {
      return Container(
        width: avatarSize * 0.285,
        height: avatarSize * 0.285,
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(avatarSize * 0.143),
          border: Border.all(color: const Color(0xFF111827), width: 2),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: avatarSize * 0.12,
        vertical: avatarSize * 0.04,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(avatarSize * 0.14),
        border: Border.all(color: const Color(0xFF111827), width: 2),
      ),
      child: Text(
        formatLastSeenShort(lastSeenAt),
        style: TextStyle(
          color: Colors.white,
          fontSize: avatarSize * 0.14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
