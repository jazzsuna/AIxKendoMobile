/// 1フレーム分の関節データ
class JointData {
  final double x;          // 正規化X座標 (0.0〜1.0)
  final double y;          // 正規化Y座標 (0.0〜1.0, 上が小さい)
  final double z;          // 相対深度
  final double visibility; // 可視性スコア (0.0〜1.0)

  const JointData({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });
}

/// フレーム単位の骨格データ
class FrameData {
  final int frameIndex;
  final double timestamp; // 秒
  final Map<String, JointData> joints;

  const FrameData({
    required this.frameIndex,
    required this.timestamp,
    required this.joints,
  });

  bool get hasJoints => joints.isNotEmpty;
}

/// 解析対象の関節名とML Kit PoseLandmarkType インデックスの対応
const Map<String, int> keyJointIndices = {
  'left_shoulder':  11,
  'right_shoulder': 12,
  'left_elbow':     13,
  'right_elbow':    14,
  'left_wrist':     15,
  'right_wrist':    16,
  'left_hip':       23,
  'right_hip':      24,
  'left_knee':      25,
  'right_knee':     26,
};
