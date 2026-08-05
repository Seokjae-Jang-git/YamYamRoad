import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'logic/recommendation_api_client.dart';
import 'models/recommendation_models.dart';
import '../road/course_detail_screen.dart';
import '../road/models/road.dart';

typedef RecommendationLoader =
    Future<RecommendationResult> Function({
      required String userId,
      String? currentRegionId,
      double? userLat,
      double? userLng,
    });

enum AiRecommendationScope { place, course, both }

enum _ConversationStep { chooseScope, chooseBasis, loading, result, error }

enum _RecommendationBasis { currentLocation, visitHistory }

abstract final class _AiRecommendationTokens {
  static const background = Color(0xFFFFFAF5);
  static const accent = Color(0xFFFF855F);
  static const surface = Colors.white;
  static const primaryText = Color(0xFF3F332D);
  static const secondaryText = Color(0xFF7A6C64);
  static const guideBackground = Color(0xFFFFEFE7);
  static const guideText = Color(0xFF6F574B);
  static const errorBackground = Color(0xFFFFECE9);
  static const errorText = Color(0xFFB34A3B);
  static const softAccent = Color(0xFFFFF6F0);
  static const softAccentBorder = Color(0xFFFFD7C5);
  static const optionText = Color(0xFF5F493E);
  static const divider = Color(0xFFF0E6DF);
  static const cardBorder = Color(0xFFF0E2D8);

  static const pageHorizontalPadding = 18.0;
  static const listBottomPadding = 20.0;
  static const actionTopPadding = 14.0;
  static const actionBottomPadding = 16.0;
  static const cardPadding = 16.0;
  static const contentGap = 12.0;
  static const controlGap = 10.0;
  static const choiceGap = 8.0;
  static const compactGap = 7.0;
  static const tinyGap = 4.0;
  static const reasonBottomGap = 3.0;
  static const sectionContentGap = 13.0;
  static const chatBubbleHorizontalPadding = 15.0;
  static const chatBubbleVerticalPadding = 12.0;
  static const chipHorizontalPadding = 6.0;
  static const chipVerticalPadding = 8.0;
  static const itemDividerHeight = 24.0;
  static const primaryActionHeight = 48.0;
  static const messageMaxWidth = 310.0;
  static const loadingIndicatorSize = 16.0;
  static const actionLoadingIndicatorSize = 17.0;
  static const choiceIconSize = 17.0;
  static const sectionIconSize = 19.0;
  static const actionIconSize = 19.0;
  static const cardRadius = 18.0;
  static const panelRadius = 16.0;
  static const controlRadius = 14.0;
  static const messageTailRadius = 5.0;

  static const appBarTitleStyle = TextStyle(
    color: primaryText,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );
  static const appBarSubtitleStyle = TextStyle(
    color: secondaryText,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
  static const captionStyle = TextStyle(
    color: secondaryText,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );
  static const bodyStyle = TextStyle(
    color: secondaryText,
    fontSize: 12,
    height: 1.5,
  );
  static const sectionTitleStyle = TextStyle(
    color: primaryText,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
  static const recommendationTitleStyle = TextStyle(
    color: primaryText,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const guideBodyStyle = TextStyle(
    color: guideText,
    fontSize: 12,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );
  static const chatBodyStyle = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );
  static const emptyStateStyle = TextStyle(color: secondaryText, fontSize: 13);
  static const reasonLabelStyle = TextStyle(
    color: secondaryText,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
  static const choiceLabelStyle = TextStyle(
    color: optionText,
    fontWeight: FontWeight.w600,
  );
  static const loadingLabelStyle = TextStyle(
    color: secondaryText,
    fontSize: 13,
  );
  static const actionLabelStyle = TextStyle(fontWeight: FontWeight.w700);
}

class AiRecommendationPage extends StatefulWidget {
  const AiRecommendationPage({
    super.key,
    required this.userId,
    this.currentRegionId,
    this.userLat,
    this.userLng,
    this.recommendationLoader,
  });

  final String userId;
  final String? currentRegionId;
  final double? userLat;
  final double? userLng;
  final RecommendationLoader? recommendationLoader;

  @override
  State<AiRecommendationPage> createState() => _AiRecommendationPageState();
}

class _AiRecommendationPageState extends State<AiRecommendationPage> {
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: '안녕하세요! 취향과 방문 기록을 바탕으로 디저트 장소와 코스를 찾아드릴게요.',
      isUser: false,
    ),
    const _ChatMessage(text: '어떤 추천이 필요하세요?', isUser: false),
  ];

  _ConversationStep _step = _ConversationStep.chooseScope;
  AiRecommendationScope? _selectedScope;
  _RecommendationBasis? _selectedBasis;
  RecommendationResult? _result;
  String? _errorMessage;
  String? _openingCourseId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectScope(AiRecommendationScope scope) {
    setState(() {
      _selectedScope = scope;
      _messages
        ..add(_ChatMessage(text: _scopePrompt(scope), isUser: true))
        ..add(
          const _ChatMessage(text: '좋아요. 어떤 기준을 더 중요하게 볼까요?', isUser: false),
        );
      _step = _ConversationStep.chooseBasis;
    });
    _scrollToBottom();
  }

  Future<void> _requestRecommendations(_RecommendationBasis basis) async {
    if (_step == _ConversationStep.loading) return;

    setState(() {
      _selectedBasis = basis;
      _messages.add(_ChatMessage(text: _basisPrompt(basis), isUser: true));
      _step = _ConversationStep.loading;
      _result = null;
      _errorMessage = null;
    });
    _scrollToBottom();

    try {
      final useCurrentLocation = basis == _RecommendationBasis.currentLocation;
      var userLat = widget.userLat;
      var userLng = widget.userLng;
      if (useCurrentLocation && (userLat == null || userLng == null)) {
        final position = await _loadCurrentPosition();
        userLat = position.latitude;
        userLng = position.longitude;
      }
      final recommendationLoader =
          widget.recommendationLoader ??
          RecommendationApiClient().fetchRecommendations;
      final result = await recommendationLoader(
        userId: widget.userId,
        currentRegionId: useCurrentLocation ? widget.currentRegionId : null,
        userLat: useCurrentLocation ? userLat : null,
        userLng: useCurrentLocation ? userLng : null,
      );
      if (!mounted) return;

      setState(() {
        _result = result;
        _messages.add(
          const _ChatMessage(text: '추천을 준비했어요. 추천한 이유를 알려드릴게요.', isUser: false),
        );
        _step = _ConversationStep.result;
      });
    } on RecommendationException catch (error) {
      _showRecommendationError(error.message);
    } catch (_) {
      _showRecommendationError('추천을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.');
    }
    _scrollToBottom();
  }

  Future<Position> _loadCurrentPosition() async {
    final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isServiceEnabled) {
      throw const RecommendationException(
        'location_service_disabled',
        '현재 위치 추천을 사용하려면 휴대폰의 위치 서비스를 켜 주세요.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const RecommendationException(
        'location_permission_denied',
        '현재 위치 추천을 사용하려면 위치 권한이 필요합니다.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const RecommendationException(
        'location_permission_denied_forever',
        '앱 설정에서 위치 권한을 허용한 후 다시 시도해 주세요.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } on TimeoutException {
      throw const RecommendationException(
        'location_timeout',
        '현재 위치를 확인하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  Future<void> _openCourseDetail(String courseId) async {
    if (_openingCourseId != null) return;
    setState(() => _openingCourseId = courseId);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('road')
          .doc(courseId)
          .get();
      if (!mounted) return;
      if (!snapshot.exists) {
        _showCourseOpenError('추천한 코스를 찾을 수 없습니다.');
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              CourseDetailScreen(road: Road.fromFirestore(snapshot)),
        ),
      );
    } on FirebaseException {
      if (mounted) {
        _showCourseOpenError('코스 정보를 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _openingCourseId = null);
      }
    }
  }

  void _showCourseOpenError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showRecommendationError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _messages.add(_ChatMessage(text: message, isUser: false, isError: true));
      _step = _ConversationStep.error;
    });
  }

  void _restartConversation() {
    setState(() {
      _messages
        ..clear()
        ..add(
          const _ChatMessage(text: '다시 추천해 드릴게요. 어떤 추천이 필요하세요?', isUser: false),
        );
      _selectedScope = null;
      _selectedBasis = null;
      _result = null;
      _errorMessage = null;
      _step = _ConversationStep.chooseScope;
    });
    _scrollToBottom();
  }

  void _retryRecommendation() {
    final basis = _selectedBasis;
    if (basis != null) {
      _requestRecommendations(basis);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  String _scopePrompt(AiRecommendationScope scope) {
    return switch (scope) {
      AiRecommendationScope.place => '가게를 추천해 줘.',
      AiRecommendationScope.course => '코스를 추천해 줘.',
      AiRecommendationScope.both => '가게와 코스를 모두 추천해 줘.',
    };
  }

  String _basisPrompt(_RecommendationBasis basis) {
    return switch (basis) {
      _RecommendationBasis.currentLocation => '현재 위치를 기반으로 추천해 줘.',
      _RecommendationBasis.visitHistory => '내 방문 기록을 중심으로 추천해 줘.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AiRecommendationTokens.background,
      appBar: AppBar(
        backgroundColor: _AiRecommendationTokens.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: _AiRecommendationTokens.primaryText,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI 추천', style: _AiRecommendationTokens.appBarTitleStyle),
            Text(
              '얌얌이가 취향에 맞춰 찾아드려요',
              style: _AiRecommendationTokens.appBarSubtitleStyle,
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  _AiRecommendationTokens.pageHorizontalPadding,
                  _AiRecommendationTokens.contentGap,
                  _AiRecommendationTokens.pageHorizontalPadding,
                  _AiRecommendationTokens.listBottomPadding,
                ),
                children: [
                  const _ConversationGuide(),
                  const SizedBox(
                    height: _AiRecommendationTokens.pageHorizontalPadding,
                  ),
                  for (final message in _messages)
                    _ChatBubble(
                      message: message,
                      accentColor: _AiRecommendationTokens.accent,
                      assistantColor: _AiRecommendationTokens.surface,
                      primaryTextColor: _AiRecommendationTokens.primaryText,
                    ),
                  if (_step == _ConversationStep.loading)
                    const _ThinkingBubble(),
                  if (_result != null && _selectedScope != null)
                    _RecommendationResultPanel(
                      result: _result!,
                      scope: _selectedScope!,
                      openingCourseId: _openingCourseId,
                      onOpenCourse: _openCourseDetail,
                    ),
                ],
              ),
            ),
            _buildConversationActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        _AiRecommendationTokens.pageHorizontalPadding,
        _AiRecommendationTokens.actionTopPadding,
        _AiRecommendationTokens.pageHorizontalPadding,
        _AiRecommendationTokens.actionBottomPadding,
      ),
      decoration: const BoxDecoration(
        color: _AiRecommendationTokens.surface,
        border: Border(top: BorderSide(color: _AiRecommendationTokens.divider)),
      ),
      child: switch (_step) {
        _ConversationStep.chooseScope => _ChoiceWrap(
          label: '추천할 대상을 골라주세요',
          choices: [
            _ConversationChoice(
              label: '가게 추천',
              icon: Icons.storefront_outlined,
              onTap: () => _selectScope(AiRecommendationScope.place),
            ),
            _ConversationChoice(
              label: '코스 추천',
              icon: Icons.route_outlined,
              onTap: () => _selectScope(AiRecommendationScope.course),
            ),
            _ConversationChoice(
              label: '둘 다 추천',
              icon: Icons.auto_awesome_outlined,
              onTap: () => _selectScope(AiRecommendationScope.both),
            ),
          ],
        ),
        _ConversationStep.chooseBasis => _ChoiceWrap(
          label: '추천 기준을 골라주세요',
          choices: [
            _ConversationChoice(
              label: '현재 위치 중심',
              icon: Icons.near_me_outlined,
              onTap: () =>
                  _requestRecommendations(_RecommendationBasis.currentLocation),
            ),
            _ConversationChoice(
              label: '방문 기록 중심',
              icon: Icons.history_rounded,
              onTap: () =>
                  _requestRecommendations(_RecommendationBasis.visitHistory),
            ),
          ],
        ),
        _ConversationStep.loading => const _LoadingAction(),
        _ConversationStep.result => _SingleActionButton(
          label: '다시 추천받기',
          icon: Icons.refresh_rounded,
          onPressed: _restartConversation,
        ),
        _ConversationStep.error => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage != null)
              Text(
                '서버 연결 상태를 확인한 뒤 다시 시도할 수 있어요.',
                style: _AiRecommendationTokens.captionStyle,
              ),
            const SizedBox(height: _AiRecommendationTokens.controlGap),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _restartConversation,
                    child: const Text('처음부터'),
                  ),
                ),
                const SizedBox(width: _AiRecommendationTokens.controlGap),
                Expanded(
                  child: FilledButton(
                    onPressed: _retryRecommendation,
                    style: FilledButton.styleFrom(
                      backgroundColor: _AiRecommendationTokens.accent,
                    ),
                    child: const Text('다시 시도'),
                  ),
                ),
              ],
            ),
          ],
        ),
      },
    );
  }
}

class _ConversationGuide extends StatelessWidget {
  const _ConversationGuide();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_AiRecommendationTokens.actionTopPadding),
      decoration: BoxDecoration(
        color: _AiRecommendationTokens.guideBackground,
        borderRadius: BorderRadius.circular(
          _AiRecommendationTokens.panelRadius,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates_outlined,
            color: _AiRecommendationTokens.accent,
          ),
          SizedBox(width: _AiRecommendationTokens.controlGap),
          Expanded(
            child: Text(
              '선택한 조건과 실제 사용자 기록을 함께 반영해 추천해요.',
              style: _AiRecommendationTokens.guideBodyStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final bool isError;
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.message,
    required this.accentColor,
    required this.assistantColor,
    required this.primaryTextColor,
  });

  final _ChatMessage message;
  final Color accentColor;
  final Color assistantColor;
  final Color primaryTextColor;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isUser
        ? accentColor
        : message.isError
        ? _AiRecommendationTokens.errorBackground
        : assistantColor;
    final textColor = message.isUser
        ? _AiRecommendationTokens.surface
        : message.isError
        ? _AiRecommendationTokens.errorText
        : primaryTextColor;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: _AiRecommendationTokens.messageMaxWidth,
        ),
        margin: const EdgeInsets.only(
          bottom: _AiRecommendationTokens.controlGap,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: _AiRecommendationTokens.chatBubbleHorizontalPadding,
          vertical: _AiRecommendationTokens.chatBubbleVerticalPadding,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(_AiRecommendationTokens.cardRadius),
            topRight: const Radius.circular(_AiRecommendationTokens.cardRadius),
            bottomLeft: Radius.circular(
              message.isUser
                  ? _AiRecommendationTokens.cardRadius
                  : _AiRecommendationTokens.messageTailRadius,
            ),
            bottomRight: Radius.circular(
              message.isUser
                  ? _AiRecommendationTokens.messageTailRadius
                  : _AiRecommendationTokens.cardRadius,
            ),
          ),
          border: message.isUser
              ? null
              : Border.all(color: _AiRecommendationTokens.divider),
        ),
        child: Text(
          message.text,
          style: _AiRecommendationTokens.chatBodyStyle.copyWith(
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: _AiRecommendationTokens.contentGap),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _AiRecommendationTokens.surface,
            borderRadius: BorderRadius.all(
              Radius.circular(_AiRecommendationTokens.cardRadius),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _AiRecommendationTokens.cardPadding,
              vertical: _AiRecommendationTokens.contentGap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: _AiRecommendationTokens.loadingIndicatorSize,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: _AiRecommendationTokens.controlGap),
                Text('취향을 분석하고 있어요...'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RecommendationResultPanel extends StatelessWidget {
  const _RecommendationResultPanel({
    required this.result,
    required this.scope,
    required this.openingCourseId,
    required this.onOpenCourse,
  });

  final RecommendationResult result;
  final AiRecommendationScope scope;
  final String? openingCourseId;
  final Future<void> Function(String courseId) onOpenCourse;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (scope != AiRecommendationScope.course)
          _RecommendationSection(
            label: '가게',
            icon: Icons.storefront_outlined,
            items: _placeItems(),
          ),
        if (scope == AiRecommendationScope.both)
          const SizedBox(height: _AiRecommendationTokens.contentGap),
        if (scope != AiRecommendationScope.place)
          _RecommendationSection(
            label: '코스',
            icon: Icons.route_outlined,
            items: _courseItems(),
          ),
      ],
    );
  }

  List<_RecommendationDisplayItem> _placeItems() {
    if (result.placeRecommendations.isNotEmpty) {
      return result.placeRecommendations
          .take(3)
          .map(
            (item) => _RecommendationDisplayItem(
              title: item.name,
              address: item.address,
              reasons: item.reasons,
            ),
          )
          .toList(growable: false);
    }
    final message = result.message.place;
    if (message.recommendation != null) {
      return [
        _RecommendationDisplayItem(
          title: message.recommendation!,
          reasons: message.reasons,
        ),
      ];
    }
    return const [];
  }

  List<_RecommendationDisplayItem> _courseItems() {
    if (result.courseRecommendations.isNotEmpty) {
      return result.courseRecommendations
          .take(3)
          .map(
            (item) => _RecommendationDisplayItem(
              title: item.title,
              reasons: item.reasons,
              actionLabel: openingCourseId == item.courseId
                  ? '불러오는 중...'
                  : '코스 자세히 보기',
              onAction: openingCourseId == null
                  ? () => onOpenCourse(item.courseId)
                  : null,
            ),
          )
          .toList(growable: false);
    }
    final message = result.message.course;
    if (message.recommendation != null) {
      return [
        _RecommendationDisplayItem(
          title: message.recommendation!,
          reasons: message.reasons,
        ),
      ];
    }
    return const [];
  }
}

class _RecommendationDisplayItem {
  const _RecommendationDisplayItem({
    required this.title,
    required this.reasons,
    this.address = '',
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final List<String> reasons;
  final String address;
  final String? actionLabel;
  final VoidCallback? onAction;
}

class _RecommendationSection extends StatelessWidget {
  const _RecommendationSection({
    required this.label,
    required this.icon,
    required this.items,
  });

  final String label;
  final IconData icon;
  final List<_RecommendationDisplayItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(_AiRecommendationTokens.cardPadding),
      decoration: BoxDecoration(
        color: _AiRecommendationTokens.surface,
        borderRadius: BorderRadius.circular(_AiRecommendationTokens.cardRadius),
        border: Border.all(color: _AiRecommendationTokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: _AiRecommendationTokens.sectionIconSize,
                color: _AiRecommendationTokens.accent,
              ),
              const SizedBox(width: _AiRecommendationTokens.compactGap),
              Text(
                '$label 추천',
                style: _AiRecommendationTokens.sectionTitleStyle,
              ),
            ],
          ),
          const SizedBox(height: _AiRecommendationTokens.sectionContentGap),
          if (items.isEmpty)
            const Text(
              '조건에 맞는 추천 결과가 없습니다.',
              style: _AiRecommendationTokens.emptyStateStyle,
            )
          else
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0)
                const Divider(
                  height: _AiRecommendationTokens.itemDividerHeight,
                ),
              Text(
                '추천: ${items[index].title}',
                style: _AiRecommendationTokens.recommendationTitleStyle,
              ),
              if (items[index].address.isNotEmpty) ...[
                const SizedBox(height: _AiRecommendationTokens.tinyGap),
                Text(
                  '주소: ${items[index].address}',
                  style: _AiRecommendationTokens.bodyStyle.copyWith(
                    color: _AiRecommendationTokens.secondaryText,
                  ),
                ),
              ],
              const SizedBox(height: _AiRecommendationTokens.compactGap),
              _RecommendationReasons(reasons: items[index].reasons),
              if (items[index].actionLabel != null) ...[
                const SizedBox(height: _AiRecommendationTokens.controlGap),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: items[index].onAction,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(items[index].actionLabel!),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _AiRecommendationTokens.accent,
                      side: const BorderSide(
                        color: _AiRecommendationTokens.softAccentBorder,
                      ),
                    ),
                  ),
                ),
              ],
            ],
        ],
      ),
    );
  }
}

class _RecommendationReasons extends StatelessWidget {
  const _RecommendationReasons({required this.reasons});

  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    if (reasons.isEmpty) {
      return const Text(
        '이용 기록과 현재 조건을 종합해 추천했어요.',
        style: _AiRecommendationTokens.bodyStyle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('이유', style: _AiRecommendationTokens.reasonLabelStyle),
        const SizedBox(height: _AiRecommendationTokens.tinyGap),
        for (final reason in reasons)
          Padding(
            padding: const EdgeInsets.only(
              bottom: _AiRecommendationTokens.reasonBottomGap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: _AiRecommendationTokens.bodyStyle),
                Expanded(
                  child: Text(reason, style: _AiRecommendationTokens.bodyStyle),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ConversationChoice {
  const _ConversationChoice({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({required this.label, required this.choices});

  final String label;
  final List<_ConversationChoice> choices;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _AiRecommendationTokens.captionStyle),
        const SizedBox(height: _AiRecommendationTokens.controlGap),
        Wrap(
          spacing: _AiRecommendationTokens.choiceGap,
          runSpacing: _AiRecommendationTokens.choiceGap,
          children: [
            for (final choice in choices)
              Semantics(
                button: true,
                label: choice.label,
                child: ActionChip(
                  avatar: Icon(
                    choice.icon,
                    size: _AiRecommendationTokens.choiceIconSize,
                    color: _AiRecommendationTokens.accent,
                  ),
                  label: Text(choice.label),
                  onPressed: choice.onTap,
                  backgroundColor: _AiRecommendationTokens.softAccent,
                  side: const BorderSide(
                    color: _AiRecommendationTokens.softAccentBorder,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: _AiRecommendationTokens.chipHorizontalPadding,
                    vertical: _AiRecommendationTokens.chipVerticalPadding,
                  ),
                  labelStyle: _AiRecommendationTokens.choiceLabelStyle,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LoadingAction extends StatelessWidget {
  const _LoadingAction();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox.square(
          dimension: _AiRecommendationTokens.actionLoadingIndicatorSize,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: _AiRecommendationTokens.controlGap),
        Text(
          '추천 결과를 불러오는 중입니다',
          style: _AiRecommendationTokens.loadingLabelStyle,
        ),
      ],
    );
  }
}

class _SingleActionButton extends StatelessWidget {
  const _SingleActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _AiRecommendationTokens.primaryActionHeight,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _AiRecommendationTokens.accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              _AiRecommendationTokens.controlRadius,
            ),
          ),
        ),
        icon: Icon(icon, size: _AiRecommendationTokens.actionIconSize),
        label: Text(label, style: _AiRecommendationTokens.actionLabelStyle),
      ),
    );
  }
}
