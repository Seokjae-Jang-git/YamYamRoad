import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'models/in_house_ad_model.dart';

class InHouseAdPlayerPage extends StatefulWidget {
  final InHouseAdModel ad;

  const InHouseAdPlayerPage({
    super.key,
    required this.ad,
  });

  @override
  State<InHouseAdPlayerPage> createState() => _InHouseAdPlayerPageState();
}

class _InHouseAdPlayerPageState extends State<InHouseAdPlayerPage> {
  VideoPlayerController? _controller;
  Timer? _timer;
  late int _secondsRemaining;
  bool _isFinished = false;
  bool _hasError = false;
  double _playbackProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // videoDuration이 0 이하로 입력될 경우 0 나누기 오류 방지를 위해 최소 1초 보정
    _secondsRemaining = widget.ad.videoDuration <= 0 ? 1 : widget.ad.videoDuration;
    _initializeVideoPlayer();
  }

  // 🎥 정석 Dart Null-Safety 타입을 활용한 비디오 초기화
  Future<void> _initializeVideoPlayer() async {
    // 1) 지역 변수에 할당하여 Dart Type Promotion(타입 승격) 유도
    final videoUrl = widget.ad.videoUrl;

    // 2) videoUrl이 null이거나 빈 문자열인 경우 예외 정석 처리
    if (videoUrl == null || videoUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
      _startAdTimer();
      return;
    }

    try {
      // 3) videoUrl이 String으로 타입 승격되었으므로 안전하게 Uri.parse 전달
      final uri = Uri.parse(videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();

      if (!mounted) return;

      setState(() {});

      // 비디오 재생 시작
      _controller!.play();
      _startAdTimer();
    } catch (e) {
      debugPrint('비디오 로드 실패: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
      });
      // 네트워크 예외 발생 시에도 유저 보상 타이머는 정상 작동하도록 처리
      _startAdTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // 1초 단위로 흐르는 광고 타이머 구동
  void _startAdTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        final totalDuration = widget.ad.videoDuration <= 0 ? 1 : widget.ad.videoDuration;
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
          // 비디오 진행 상태 바 계산 (0.0 ~ 1.0)
          _playbackProgress = 1.0 - (_secondsRemaining / totalDuration);
        } else {
          _secondsRemaining = 0;
          _playbackProgress = 1.0;
          _isFinished = true;
          _timer?.cancel();
        }
      });
    });
  }

  // 사용자가 시청 도중 뒤로 가거나 X 버튼을 누를 때 팝업 처리
  Future<void> _handleBackAttempt() async {
    // 1. 비디오 및 타이머 일시정지
    _controller?.pause();
    _timer?.cancel();

    // 2. 이탈 확인 다이얼로그 출력
    final bool? shouldLeave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '광고 시청 중단',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          '지금 나가시면 ${widget.ad.rewardPoint}P를 받을 수 없습니다.\n정말 나가시겠습니까?',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // 이어서 보기
            child: const Text('이어서 보기', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // 나가기
            child: const Text('나가기', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (shouldLeave == true) {
      // 보상 없이 화면 종료 (false 전달)
      Navigator.pop(context, false);
    } else {
      // 비디오 및 타이머 재개
      if (_controller != null && _controller!.value.isInitialized) {
        _controller!.play();
      }
      _startAdTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope를 사용하여 광고 시청 중 시스템 뒤로가기 가로채기
    return PopScope(
      canPop: _isFinished,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _handleBackAttempt();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // 🎥 비디오 플레이어 영역
              Center(
                child: AspectRatio(
                  aspectRatio: (_controller != null && _controller!.value.isInitialized)
                      ? _controller!.value.aspectRatio
                      : 16 / 9,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: Border.all(color: Colors.grey[800]!, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 1) 비디오 로드 완료 및 정상 재생
                        if (_controller != null && _controller!.value.isInitialized)
                          VideoPlayer(_controller!)
                        // 2) 비디오 로드 실패 또는 URL이 없는 경우
                        else if (_hasError)
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber,
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '[ ${widget.ad.title} ]',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '영상을 불러올 수 없어 기본 시청으로 전환됩니다.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          )
                        // 3) 비디오 네트워크 데이터 수신 중
                        else
                          const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.orange,
                                strokeWidth: 2,
                              ),
                              SizedBox(height: 12),
                              Text(
                                '광고 비디오 스트리밍 데이터 수신 중...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ⏱️ 상단 제어 바
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isFinished
                                ? Icons.celebration
                                : Icons.timer_outlined,
                            color: _isFinished
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isFinished ? '시청 완료!' : '$_secondsRemaining초 후 보상 지급',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        if (_isFinished) {
                          Navigator.pop(context, true);
                        } else {
                          _handleBackAttempt();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isFinished
                              ? Colors.white.withOpacity(0.9)
                              : Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: _isFinished ? Colors.black : Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 📊 하단 정보 제공 바
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _playbackProgress,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isFinished ? Colors.greenAccent : Colors.orange,
                        ),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isFinished
                          ? '🎉 상단 우측의 X 버튼을 누르고 포인트를 적립 받으세요!'
                          : '📢 영상을 끝까지 시청하시면 ${widget.ad.rewardPoint}P가 즉시 적립됩니다.',
                      style: TextStyle(
                        color:
                        _isFinished ? Colors.greenAccent : Colors.white70,
                        fontSize: 12,
                        fontWeight:
                        _isFinished ? FontWeight.bold : FontWeight.normal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}