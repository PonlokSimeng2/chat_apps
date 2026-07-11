enum MessageStatus {
  sending,     // Message is being sent to server
  sent,        // Message sent successfully to server
  delivered,   // Message delivered to other user
  read,        // Message read by other user
  failed,      // Message failed to send
}

extension MessageStatusExtension on MessageStatus {
  String get displayName {
    switch (this) {
      case MessageStatus.sending:
        return 'Sending...';
      case MessageStatus.sent:
        return 'Sent';
      case MessageStatus.delivered:
        return 'Delivered';
      case MessageStatus.read:
        return 'Read';
      case MessageStatus.failed:
        return 'Failed';
    }
  }

  bool get isPending => this == MessageStatus.sending;
  bool get isSuccessful => this == MessageStatus.sent || this == MessageStatus.delivered || this == MessageStatus.read;
  bool get hasFailed => this == MessageStatus.failed;
}