enum FakeChatRole { left, right }

class FakeChatMessage {
  const FakeChatMessage({
    required this.role,
    required this.text,
    required this.avatar,
    this.timestamp,
  });

  final FakeChatRole role;
  final String text;
  final String avatar;
  final String? timestamp;
}
