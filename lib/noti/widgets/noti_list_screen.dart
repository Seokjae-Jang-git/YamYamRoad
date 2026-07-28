import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/noti_controller.dart';
import '../logic/noti_repository.dart';
import '../models/noti_model.dart';

typedef NotiItemTapCallback = FutureOr<void> Function(NotiItem item);

abstract final class _NotiTokens {
  static const surface = Color(0xFFFFF9F2);
  static const primaryText = Color(0xFF4A3327);
  static const bodyText = Color(0xFF6F625B);
  static const secondaryText = Color(0xFF8C7C72);
  static const sectionText = Color(0xFF9B8D84);
  static const timeText = Color(0xFFB0A39B);
  static const disabledIcon = Color(0xFFD6C9C0);
  static const unreadIndicator = Color(0xFFFF8A4C);
  static const thumbnailPlaceholder = Color(0xFFEDE4DC);
  static const coral = Color(0xFFFF856F);
  static const softCoral = Color(0xFFFFE7DE);
  static const orange = Color(0xFFFF8A4C);
  static const softOrange = Color(0xFFFFE8D8);
  static const mint = Color(0xFF68B998);
  static const softMint = Color(0xFFE1F3EA);
  static const gold = Color(0xFFE4A73E);
  static const softGold = Color(0xFFFFF0C8);
  static const neutralIcon = Color(0xFF8C7C72);
  static const softNeutral = Color(0xFFEDE7E2);

  static const horizontalPadding = 20.0;
  static const tileVerticalPadding = 10.0;
  static const tileRadius = 14.0;
  static const typeIconSize = 42.0;
  static const typeGlyphSize = 20.0;
  static const unreadIndicatorSize = 5.0;
  static const thumbnailSize = 42.0;

  static const appBarTitleStyle = TextStyle(
    color: primaryText,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );
  static const titleStyle = TextStyle(
    color: primaryText,
    fontSize: 14,
    height: 1.35,
  );
  static const bodyStyle = TextStyle(
    color: bodyText,
    fontSize: 13,
    height: 1.35,
  );
  static const sectionStyle = TextStyle(
    color: sectionText,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const timeStyle = TextStyle(color: timeText, fontSize: 11);
  static const emptyStyle = TextStyle(color: secondaryText);
}

class NotiListScreen extends StatefulWidget {
  const NotiListScreen({
    super.key,
    required this.userId,
    this.repository,
    this.onNotificationTap,
  });

  final String userId;
  final NotiRepository? repository;
  final NotiItemTapCallback? onNotificationTap;

  @override
  State<NotiListScreen> createState() => _NotiListScreenState();
}

class _NotiListScreenState extends State<NotiListScreen> {
  late NotiController _controller;
  bool _isMarkingAllAsRead = false;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
  }

  @override
  void didUpdateWidget(covariant NotiListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.repository != widget.repository) {
      _controller = _createController();
    }
  }

  NotiController _createController() {
    return NotiController(
      userId: widget.userId,
      repository: widget.repository ?? FirestoreNotiRepository(),
    );
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllAsRead) return;
    setState(() => _isMarkingAllAsRead = true);

    try {
      await _controller.markAllAsRead();
    } catch (_) {
      if (mounted) {
        _showError('알림을 읽음 처리하지 못했습니다.');
      }
    } finally {
      if (mounted) {
        setState(() => _isMarkingAllAsRead = false);
      }
    }
  }

  Future<void> _openNotification(NotiItem item) async {
    try {
      if (!item.isRead) {
        await _controller.markAsRead(item.id);
      }
      await widget.onNotificationTap?.call(item);
    } catch (_) {
      if (mounted) {
        _showError('알림을 여는 중 문제가 발생했습니다.');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _NotiTokens.surface,
      appBar: AppBar(
        backgroundColor: _NotiTokens.surface,
        foregroundColor: _NotiTokens.primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: const Text('알림', style: _NotiTokens.appBarTitleStyle),
        actions: [
          TextButton(
            onPressed: _isMarkingAllAsRead ? null : _markAllAsRead,
            child: _isMarkingAllAsRead
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('모두 읽음'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<NotiItem>>(
          stream: _controller.watchNotifications(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const _NotiMessage(
                icon: Icons.error_outline,
                message: '알림을 불러오지 못했습니다.',
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final notifications = snapshot.data!;
            if (notifications.isEmpty) {
              return const _NotiMessage(
                icon: Icons.notifications_none,
                message: '도착한 알림이 없습니다.',
              );
            }

            final groups = _groupNotifications(notifications);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                _NotiTokens.horizontalPadding,
                8,
                _NotiTokens.horizontalPadding,
                24,
              ),
              children: [
                if (groups.today.isNotEmpty) ...[
                  const _NotiSectionTitle('오늘'),
                  ...groups.today.map(_buildNotificationTile),
                ],
                if (groups.previous.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _NotiSectionTitle('이전'),
                  ...groups.previous.map(_buildNotificationTile),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotiItem item) {
    return _NotiTile(item: item, onTap: () => _openNotification(item));
  }
}

class _NotiTile extends StatelessWidget {
  const _NotiTile({required this.item, required this.onTap});

  final NotiItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final appearance = _NotiAppearance.fromType(item.type);
    final title = item.title.trim().isEmpty ? '새 알림' : item.title.trim();
    final body = item.body.trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_NotiTokens.tileRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: _NotiTokens.tileVerticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 8,
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: item.isRead
                        ? Colors.transparent
                        : _NotiTokens.unreadIndicator,
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox.square(
                    dimension: _NotiTokens.unreadIndicatorSize,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: _NotiTokens.typeIconSize,
              height: _NotiTokens.typeIconSize,
              decoration: BoxDecoration(
                color: appearance.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                appearance.icon,
                size: _NotiTokens.typeGlyphSize,
                color: appearance.foregroundColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NotiWordWrap(
                    text: title,
                    style: _NotiTokens.titleStyle.copyWith(
                      fontWeight: item.isRead
                          ? FontWeight.w500
                          : FontWeight.w700,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _NotiTokens.bodyStyle,
                    ),
                  ],
                  if (item.createdAt case final createdAt?) ...[
                    const SizedBox(height: 4),
                    Text(
                      _relativeTime(createdAt),
                      style: _NotiTokens.timeStyle,
                    ),
                  ],
                ],
              ),
            ),
            if (item.thumbnailUrl case final thumbnailUrl?) ...[
              const SizedBox(width: 10),
              _NotiThumbnail(imageUrl: thumbnailUrl),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotiSectionTitle extends StatelessWidget {
  const _NotiSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(title, style: _NotiTokens.sectionStyle),
    );
  }
}

class _NotiWordWrap extends StatelessWidget {
  const _NotiWordWrap({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final words = text.split(RegExp(r'\s+'));
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Wrap(
        spacing: 4,
        children: [
          for (final word in words)
            Text(
              word,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
        ],
      ),
    );
  }
}

class _NotiMessage extends StatelessWidget {
  const _NotiMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: _NotiTokens.typeIconSize,
            color: _NotiTokens.disabledIcon,
          ),
          const SizedBox(height: 12),
          Text(message, style: _NotiTokens.emptyStyle),
        ],
      ),
    );
  }
}

class _NotiThumbnail extends StatelessWidget {
  const _NotiThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        imageUrl,
        width: _NotiTokens.thumbnailSize,
        height: _NotiTokens.thumbnailSize,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const ColoredBox(
          color: _NotiTokens.thumbnailPlaceholder,
          child: SizedBox.square(dimension: _NotiTokens.thumbnailSize),
        ),
      ),
    );
  }
}

class _NotiAppearance {
  const _NotiAppearance({
    required this.icon,
    required this.foregroundColor,
    required this.backgroundColor,
  });

  final IconData icon;
  final Color foregroundColor;
  final Color backgroundColor;

  static _NotiAppearance fromType(NotiType type) {
    return switch (type) {
      NotiType.like => const _NotiAppearance(
        icon: Icons.favorite_border,
        foregroundColor: _NotiTokens.coral,
        backgroundColor: _NotiTokens.softCoral,
      ),
      NotiType.comment => const _NotiAppearance(
        icon: Icons.chat_bubble_outline,
        foregroundColor: _NotiTokens.orange,
        backgroundColor: _NotiTokens.softOrange,
      ),
      NotiType.scrap => const _NotiAppearance(
        icon: Icons.bookmark_border,
        foregroundColor: _NotiTokens.orange,
        backgroundColor: _NotiTokens.softOrange,
      ),
      NotiType.stamp => const _NotiAppearance(
        icon: Icons.check,
        foregroundColor: _NotiTokens.mint,
        backgroundColor: _NotiTokens.softMint,
      ),
      NotiType.badge => const _NotiAppearance(
        icon: Icons.workspace_premium_outlined,
        foregroundColor: _NotiTokens.orange,
        backgroundColor: _NotiTokens.softOrange,
      ),
      NotiType.point => const _NotiAppearance(
        icon: Icons.paid_outlined,
        foregroundColor: _NotiTokens.gold,
        backgroundColor: _NotiTokens.softGold,
      ),
      NotiType.unknown => const _NotiAppearance(
        icon: Icons.notifications_none,
        foregroundColor: _NotiTokens.neutralIcon,
        backgroundColor: _NotiTokens.softNeutral,
      ),
    };
  }
}

({List<NotiItem> today, List<NotiItem> previous}) _groupNotifications(
  List<NotiItem> notifications,
) {
  final now = DateTime.now();
  final today = <NotiItem>[];
  final previous = <NotiItem>[];

  for (final item in notifications) {
    final createdAt = item.createdAt?.toLocal();
    if (createdAt != null &&
        createdAt.year == now.year &&
        createdAt.month == now.month &&
        createdAt.day == now.day) {
      today.add(item);
    } else {
      previous.add(item);
    }
  }

  return (today: today, previous: previous);
}

String _relativeTime(DateTime createdAt) {
  final difference = DateTime.now().difference(createdAt.toLocal());
  if (difference.isNegative || difference.inMinutes < 1) return '방금 전';
  if (difference.inHours < 1) return '${difference.inMinutes}분 전';
  if (difference.inDays < 1) return '${difference.inHours}시간 전';
  return '${difference.inDays}일 전';
}
