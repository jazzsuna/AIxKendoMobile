/// 素振り採点結果
class ScoreResult {
  final double total;                 // 総合スコア (0〜100)
  final Map<String, double> breakdown; // 項目別スコア (0〜100)
  final List<String> feedback;         // フィードバックメッセージ
  final int frameCount;               // 解析フレーム数
  final double durationSec;           // 動作時間 (秒)

  const ScoreResult({
    required this.total,
    required this.breakdown,
    required this.feedback,
    required this.frameCount,
    required this.durationSec,
  });
}

/// 採点項目の日本語ラベル
const Map<String, String> scoreLabels = {
  'elbow_symmetry':    '肘の対称性',
  'wrist_raise':       '振り上げ高さ',
  'shoulder_level':    '肩の安定性',
  'hip_stability':     '腰の安定性',
  'motion_smoothness': '動作の滑らかさ',
};

/// 各項目のウェイト (合計1.0)
const Map<String, double> scoreWeights = {
  'elbow_symmetry':    0.25,
  'wrist_raise':       0.25,
  'shoulder_level':    0.20,
  'hip_stability':     0.15,
  'motion_smoothness': 0.15,
};
