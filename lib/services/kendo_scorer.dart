import 'dart:math';
import '../models/frame_data.dart';
import '../models/score_result.dart';

/// 骨格フレームデータから素振りを採点するクラス。
/// Python版 analyzer.py の KendoScorer を Dart に移植。
class KendoScorer {
  final List<FrameData> frames;

  KendoScorer(List<FrameData> allFrames)
      : frames = allFrames.where((f) => f.hasJoints).toList();

  // ── ヘルパー ───────────────────────────────────────────

  /// 指定関節の座標時系列を返す（可視性0.5未満はNaN）
  List<double> _getSeries(String joint, String axis) {
    return frames.map((f) {
      final j = f.joints[joint];
      if (j == null || j.visibility < 0.5) return double.nan;
      return switch (axis) {
        'x' => j.x,
        'y' => j.y,
        'z' => j.z,
        _ => double.nan,
      };
    }).toList();
  }

  double _nanMean(List<double> vals) {
    final v = vals.where((e) => !e.isNaN).toList();
    if (v.isEmpty) return 0;
    return v.reduce((a, b) => a + b) / v.length;
  }

  double _nanStd(List<double> vals) {
    final v = vals.where((e) => !e.isNaN).toList();
    if (v.length < 2) return 0;
    final mean = v.reduce((a, b) => a + b) / v.length;
    final variance =
        v.map((e) => pow(e - mean, 2).toDouble()).reduce((a, b) => a + b) /
            v.length;
    return sqrt(variance);
  }

  double _nanMin(List<double> vals) {
    final v = vals.where((e) => !e.isNaN).toList();
    if (v.isEmpty) return 0;
    return v.reduce(min);
  }

  // ── 各評価指標 ─────────────────────────────────────────

  /// 両肘のY座標差の小ささ（対称性）
  (double, String) _scoreElbowSymmetry() {
    final le = _getSeries('left_elbow', 'y');
    final re = _getSeries('right_elbow', 'y');
    final n = min(le.length, re.length);
    final diffs = List.generate(
      n,
      (i) => le[i].isNaN || re[i].isNaN
          ? double.nan
          : (le[i] - re[i]).abs(),
    );
    final meanDiff = _nanMean(diffs);
    final score = (1.0 - meanDiff / 0.10).clamp(0.0, 1.0);
    final fb = score >= 0.8
        ? '両肘の高さがよく揃っています。'
        : '両肘の高さにばらつきがあります。左右均等に振るよう意識してください。';
    return (score, fb);
  }

  /// 振り上げ時の手首の最高点（Y座標は上が小さい）
  (double, String) _scoreWristRaise() {
    final lw = _getSeries('left_wrist', 'y');
    final rw = _getSeries('right_wrist', 'y');
    final n = min(lw.length, rw.length);
    final avg = List.generate(
      n,
      (i) => lw[i].isNaN || rw[i].isNaN
          ? double.nan
          : (lw[i] + rw[i]) / 2.0,
    );
    final wristMin = _nanMin(avg);
    final score = ((0.35 - wristMin) / 0.20).clamp(0.0, 1.0);
    final fb = score >= 0.7
        ? '十分な振り上げができています。'
        : '振り上げが浅い可能性があります。両手を頭上までしっかり振り上げましょう。';
    return (score, fb);
  }

  /// 肩のY座標ブレ（動作中の体幹安定性）
  (double, String) _scoreShoulderLevel() {
    final ls = _getSeries('left_shoulder', 'y');
    final rs = _getSeries('right_shoulder', 'y');
    final n = min(ls.length, rs.length);
    final avg = List.generate(
      n,
      (i) => ls[i].isNaN || rs[i].isNaN
          ? double.nan
          : (ls[i] + rs[i]) / 2.0,
    );
    final std = _nanStd(avg);
    final score = (1.0 - std / 0.05).clamp(0.0, 1.0);
    final fb = score >= 0.75
        ? '肩の位置が安定しており、体幹が使えています。'
        : '肩のブレが大きいです。腰を安定させ、体幹でコントロールする意識を持ちましょう。';
    return (score, fb);
  }

  /// 腰のY座標ブレ（上下動の小ささ）
  (double, String) _scoreHipStability() {
    final lh = _getSeries('left_hip', 'y');
    final rh = _getSeries('right_hip', 'y');
    final n = min(lh.length, rh.length);
    final avg = List.generate(
      n,
      (i) => lh[i].isNaN || rh[i].isNaN
          ? double.nan
          : (lh[i] + rh[i]) / 2.0,
    );
    final std = _nanStd(avg);
    final score = (1.0 - std / 0.04).clamp(0.0, 1.0);
    final fb = score >= 0.75
        ? '腰が安定した素振りです。'
        : '腰の上下動が気になります。重心を一定に保って振りましょう。';
    return (score, fb);
  }

  /// 手首速度の滑らかさ（加速度の分散が小さいほどスムーズ）
  (double, String) _scoreMotionSmoothness() {
    final lwY = _getSeries('left_wrist', 'y');
    final valid = lwY.where((v) => !v.isNaN).toList();
    if (valid.length < 3) {
      return (0.5, '動作データが不足しています。');
    }
    final vel = List.generate(valid.length - 1, (i) => valid[i + 1] - valid[i]);
    final acc = List.generate(vel.length - 1, (i) => vel[i + 1] - vel[i]);
    final accStd = _nanStd(acc);
    final score = (1.0 - accStd / 0.015).clamp(0.0, 1.0);
    final fb = score >= 0.7
        ? 'なめらかな素振りができています。'
        : '動作にぎこちなさがあります。力を抜いて流れるような振りを意識しましょう。';
    return (score, fb);
  }

  // ── 総合採点 ───────────────────────────────────────────

  ScoreResult score() {
    if (frames.isEmpty) {
      throw Exception('骨格検出できたフレームがありません。');
    }

    final evaluators = <String, (double, String) Function()>{
      'elbow_symmetry':    _scoreElbowSymmetry,
      'wrist_raise':       _scoreWristRaise,
      'shoulder_level':    _scoreShoulderLevel,
      'hip_stability':     _scoreHipStability,
      'motion_smoothness': _scoreMotionSmoothness,
    };

    final breakdown = <String, double>{};
    final feedback = <String>[];
    double total = 0.0;

    for (final entry in evaluators.entries) {
      final (s, fb) = entry.value();
      breakdown[entry.key] =
          double.parse((s * 100).toStringAsFixed(1));
      feedback.add(fb);
      total += s * scoreWeights[entry.key]!;
    }

    final duration =
        frames.last.timestamp - frames.first.timestamp;

    return ScoreResult(
      total: double.parse((total * 100).toStringAsFixed(1)),
      breakdown: breakdown,
      feedback: feedback,
      frameCount: frames.length,
      durationSec: double.parse(duration.toStringAsFixed(2)),
    );
  }
}
