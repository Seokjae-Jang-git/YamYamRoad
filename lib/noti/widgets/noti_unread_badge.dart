import 'package:flutter/material.dart';

import '../logic/noti_repository.dart';

class NotiUnreadBadge extends StatelessWidget {
  const NotiUnreadBadge({
    super.key,
    required this.count,
    required this.child,
    this.offset = const Offset(4, -4),
    this.backgroundColor = const Color(0xFFFF8A4C),
    this.foregroundColor = Colors.white,
  });

  final int count;
  final Widget child;
  final Offset offset;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;

    final displayCount = count > 99 ? '99+' : '$count';
    final semanticsCount = count > 99 ? '99개 이상' : '$count개';

    return Semantics(
      container: true,
      label: '읽지 않은 알림 $semanticsCount',
      child: Stack(
        alignment: Alignment.topRight,
        clipBehavior: Clip.none,
        children: [
          child,
          Transform.translate(
            offset: offset,
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  displayCount,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NotiUnreadBadgeStream extends StatefulWidget {
  const NotiUnreadBadgeStream({
    super.key,
    required this.userId,
    required this.child,
    this.repository,
    this.maxCount = 100,
    this.offset = const Offset(4, -4),
  }) : assert(maxCount > 0);

  final String userId;
  final Widget child;
  final NotiRepository? repository;
  final int maxCount;
  final Offset offset;

  @override
  State<NotiUnreadBadgeStream> createState() => _NotiUnreadBadgeStreamState();
}

class _NotiUnreadBadgeStreamState extends State<NotiUnreadBadgeStream> {
  late Stream<int> _unreadCountStream;

  @override
  void initState() {
    super.initState();
    _unreadCountStream = _createStream();
  }

  @override
  void didUpdateWidget(covariant NotiUnreadBadgeStream oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.repository != widget.repository ||
        oldWidget.maxCount != widget.maxCount) {
      _unreadCountStream = _createStream();
    }
  }

  Stream<int> _createStream() {
    final userId = widget.userId.trim();
    if (userId.isEmpty) return Stream<int>.value(0);

    final repository = widget.repository ?? FirestoreNotiRepository();
    return repository.watchUnreadCount(userId, maxCount: widget.maxCount);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _unreadCountStream,
      initialData: 0,
      builder: (context, snapshot) {
        return NotiUnreadBadge(
          count: snapshot.data ?? 0,
          offset: widget.offset,
          child: widget.child,
        );
      },
    );
  }
}
