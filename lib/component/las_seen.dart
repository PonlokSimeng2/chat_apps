String formatLastSeenShort(DateTime? lastSeenAt) {
  if (lastSeenAt == null) return '';
  final now = DateTime.now().toUtc();
  final lastSeen = lastSeenAt.toUtc();
  Duration difference = now.difference(lastSeen);

  if (difference.isNegative) difference = difference.abs();

  if (difference.inMinutes < 1) return 'now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inDays < 1) return '${difference.inHours}h';
  if (difference.inDays < 7) return '${difference.inDays}d';
  return '${lastSeenAt.day}/${lastSeenAt.month}';
}
