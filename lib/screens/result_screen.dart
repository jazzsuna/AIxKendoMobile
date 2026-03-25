import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/score_result.dart';
import 'home_screen.dart';

/// 採点結果画面
class ResultScreen extends StatelessWidget {
  final ScoreResult result;

  const ResultScreen({super.key, required this.result});

  Color _scoreColor(double score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFB300);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B4B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('解析結果'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TotalScoreCard(
                score: result.total,
                color: _scoreColor(result.total),
                frameCount: result.frameCount,
                durationSec: result.durationSec,
              ),

              const SizedBox(height: 20),

              // 項目別バーチャート
              _SectionTitle(title: '項目別スコア'),
              const SizedBox(height: 12),
              _BreakdownChart(
                breakdown: result.breakdown,
                scoreColor: _scoreColor,
              ),

              const SizedBox(height: 20),

              // フィードバック
              _SectionTitle(title: 'フィードバック'),
              const SizedBox(height: 12),
              _FeedbackList(
                labels: scoreLabels,
                breakdown: result.breakdown,
                feedback: result.feedback,
                scoreColor: _scoreColor,
              ),

              const SizedBox(height: 32),

              // もう一度ボタン
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (_) => false,
                  ),
                  icon: const Icon(Icons.replay),
                  label: const Text('もう一度解析する'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3D5AFE),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 総合スコアカード ────────────────────────────────────────

class _TotalScoreCard extends StatelessWidget {
  final double score;
  final Color color;
  final int frameCount;
  final double durationSec;

  const _TotalScoreCard({
    required this.score,
    required this.color,
    required this.frameCount,
    required this.durationSec,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            '総合スコア',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${score.toInt()}',
            style: TextStyle(
              color: color,
              fontSize: 72,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          Text(
            '/ 100',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MetaChip(label: '${frameCount}フレーム'),
              const SizedBox(width: 8),
              _MetaChip(label: '${durationSec.toStringAsFixed(1)}秒'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
    );
  }
}

// ── 項目別バーチャート ────────────────────────────────────────

class _BreakdownChart extends StatelessWidget {
  final Map<String, double> breakdown;
  final Color Function(double) scoreColor;

  const _BreakdownChart({
    required this.breakdown,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    final keys = scoreLabels.keys.toList();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 25,
                getTitlesWidget: (v, _) => Text(
                  '${v.toInt()}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= keys.length) return const SizedBox();
                  final label = scoreLabels[keys[idx]] ?? '';
                  // 短縮表示
                  final short = label.length > 5 ? '${label.substring(0, 4)}…' : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      short,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 9,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            horizontalInterval: 25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withOpacity(0.08),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: keys.asMap().entries.map((entry) {
            final score = breakdown[entry.value] ?? 0;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: score,
                  color: scoreColor(score),
                  width: 28,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── フィードバックリスト ────────────────────────────────────────

class _FeedbackList extends StatelessWidget {
  final Map<String, String> labels;
  final Map<String, double> breakdown;
  final List<String> feedback;
  final Color Function(double) scoreColor;

  const _FeedbackList({
    required this.labels,
    required this.breakdown,
    required this.feedback,
    required this.scoreColor,
  });

  @override
  Widget build(BuildContext context) {
    final keys = labels.keys.toList();
    return Column(
      children: List.generate(keys.length, (i) {
        if (i >= feedback.length) return const SizedBox();
        final key = keys[i];
        final score = breakdown[key] ?? 0;
        final color = scoreColor(score);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              // スコアバッジ
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${score.toInt()}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels[key] ?? key,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feedback[i],
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── セクションタイトル ────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );
  }
}
