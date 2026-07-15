import 'dart:async';
import 'package:flutter/material.dart';

class InHouseAdPlayerPage extends StatefulWidget {
  final String brandName;
  final int duration; // 초 단위 재생 시간
  final int reward; // 보상 포인트액

  const InHouseAdPlayerPage({
    super.key,
    required this.brandName,
    required this.duration,
    required this.reward,
  });

  @override
  State<InHouseAdPlayerPage> createState() => _InHouseAdPlayerPageState();
}

class _InHouseAdPlayerPageState extends State<InHouseAdPlayerPage> {
  Timer? _timer;
  late int _secondsRemaining;
  bool _isFinished = false;
  double _playbackProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.duration;
    _startAdTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // 1초 단위로 흐르는 광고 타이머 구동
  void _startAdTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 1) {
          _secondsRemaining--;
          // 비디오 진행 상태 바 계산 (0.0 ~ 1.0)
          _playbackProgress = 1.0 - (_secondsRemaining / widget.duration);
        } else {
          _secondsRemaining = 0;
          _playbackProgress = 1.0;
          _isFinished = true;
          _timer?.cancel();
        }
      });
    });
  }

  // 사용자가 강제로 뒤로 가려고 할 때 처리
  void _handleBackAttempt() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('광고를 끝까지 시청하셔야 ${widget.reward}P를 받을 수 있습니다!'),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PopScope를 사용하여 광고 시청 중 시스템 뒤로가기 버튼 차단 (Abuse 방지)
    return PopScope(
      canPop: _isFinished,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackAttempt();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black, // 몰입도 극대화를 위한 풀 블랙 배경
        body: SafeArea(
          child: Stack(
            children: [
              // 🎥 [시뮬레이션] 비디오 플레이어 영역
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9, // 영화 및 일반 비디오 표준 비율
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: Border.all(color: Colors.grey[800]!, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 가상 비디오 재생 애니메이션 모방
                        if (!_isFinished)
                          const CircularProgressIndicator(
                            color: Colors.orange,
                            strokeWidth: 2,
                          ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isFinished ? Icons.check_circle : Icons.play_circle_fill,
                              color: _isFinished ? Colors.green : Colors.orange.withOpacity(0.8),
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '[ ${widget.brandName} ] 광고 시청 중',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isFinished ? '시청이 완료되었습니다!' : '비디오 스트리밍 데이터를 수신하고 있습니다.',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ⏱️ [플로팅] 상단 제어 바 (타이머 & 닫기 버튼)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 좌측 상단: 타이머 안내 반투명 칩
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isFinished ? Icons.celebration : Icons.timer_outlined,
                            color: _isFinished ? Colors.greenAccent : Colors.orangeAccent,
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

                    // 우측 상단: 닫기 (X) 버튼 (시청 끝나기 전엔 비활성화 피드백)
                    GestureDetector(
                      onTap: () {
                        if (_isFinished) {
                          // 시청 성공 완료 신호(true)를 안고 부모 화면으로 복귀
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
                          _isFinished ? Icons.close : Icons.lock_outline,
                          color: _isFinished ? Colors.black : Colors.white54,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 📊 [플로팅] 하단 정보 제공 바 (진행 트랙바 & 안내 텍스트)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // 실시간 광고 트랙바 게이지
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
                          : '📢 영상을 끝까지 시청하시면 ${widget.reward}P가 즉시 적립됩니다.',
                      style: TextStyle(
                        color: _isFinished ? Colors.greenAccent : Colors.white70,
                        fontSize: 12,
                        fontWeight: _isFinished ? FontWeight.bold : FontWeight.normal,
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