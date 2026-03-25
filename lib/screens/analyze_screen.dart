import 'package:flutter/material.dart';
import '../services/video_processor.dart';
import '../services/kendo_scorer.dart';
import '../models/score_result.dart';
import 'result_screen.dart';

/// 動画解析の進捗を表示し、完了後に ResultScreen へ遷移する画面
class AnalyzeScreen extends StatefulWidget {
  final String videoPath;

  const AnalyzeScreen({super.key, required this.videoPath});

  @override
  State<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends State<AnalyzeScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  String _status = '準備中...';
  String? _error;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _runAnalysis();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    try {
      final processor = VideoProcessor();
      final frames = await processor.processVideo(
        widget.videoPath,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _status = status;
            });
          }
        },
      );

      if (!mounted) return;
      setState(() => _status = '採点中...');

      final scorer = KendoScorer(frames);
      final result = scorer.score();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('解析中'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: _error != null ? _buildError() : _buildProgress(),
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // アニメーション付きアイコン
        ScaleTransition(
          scale: _pulseAnim,
          child: const Icon(
            Icons.sports_martial_arts,
            size: 80,
            color: Color(0xFF3D5AFE),
          ),
        ),

        const SizedBox(height: 40),

        // プログレスバー
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 8,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF3D5AFE)),
          ),
        ),
        const SizedBox(height: 16),

        // 進捗パーセント
        Text(
          '${(_progress * 100).toInt()}%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // ステータスメッセージ
        Text(
          _status,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 48),

        Text(
          'AIが姿勢を分析しています\nしばらくお待ちください',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
        const SizedBox(height: 24),
        const Text(
          '解析エラー',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _error!,
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF3D5AFE),
          ),
          child: const Text('戻る'),
        ),
      ],
    );
  }
}
