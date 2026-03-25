import 'dart:io';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import '../models/frame_data.dart';

/// 動画ファイルから骨格フレームデータを抽出するサービス。
///
/// 処理フロー:
///   1. ffprobe で動画サイズを取得
///   2. ffmpeg でフレームをJPEGに展開 (デフォルト15fps)
///   3. Google ML Kit Pose Detection で各フレームを推定
///   4. 座標を正規化 (0.0〜1.0) して FrameData に変換
class VideoProcessor {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    ),
  );

  /// [videoPath] のフルパスを受け取り、骨格フレームリストを返す。
  /// [onProgress] は (進捗0.0〜1.0, ステータス文字列) を通知する。
  Future<List<FrameData>> processVideo(
    String videoPath, {
    void Function(double progress, String status)? onProgress,
    double fps = 15.0,
  }) async {
    // 1. 動画サイズ取得
    onProgress?.call(0.02, '動画情報を取得中...');
    final (width, height) = await _getVideoDimensions(videoPath);

    // 2. フレーム展開先ディレクトリを準備
    final tmpDir = await getTemporaryDirectory();
    final framesDir = Directory('${tmpDir.path}/kendo_frames_${DateTime.now().millisecondsSinceEpoch}');
    framesDir.createSync(recursive: true);

    try {
      onProgress?.call(0.05, 'フレームを抽出中...');
      await _extractFrames(videoPath, framesDir.path, fps);

      // 3. フレームファイル一覧を取得（名前順）
      final frameFiles = framesDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.jpg'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      if (frameFiles.isEmpty) {
        throw Exception('フレームの展開に失敗しました。動画ファイルを確認してください。');
      }

      onProgress?.call(0.15, '骨格を検出中 (0/${frameFiles.length}フレーム)');

      // 4. 各フレームを姿勢推定
      final frames = <FrameData>[];
      for (int i = 0; i < frameFiles.length; i++) {
        final file = frameFiles[i];
        final inputImage = InputImage.fromFilePath(file.path);
        final poses = await _poseDetector.processImage(inputImage);

        final joints = <String, JointData>{};
        if (poses.isNotEmpty) {
          final pose = poses.first;
          for (final entry in keyJointIndices.entries) {
            final landmarkType = PoseLandmarkType.values[entry.value];
            final lm = pose.landmarks[landmarkType];
            if (lm != null) {
              joints[entry.key] = JointData(
                // ピクセル座標を正規化
                x: (lm.x / width).clamp(0.0, 1.0),
                y: (lm.y / height).clamp(0.0, 1.0),
                z: lm.z,
                visibility: lm.likelihood,
              );
            }
          }
        }

        frames.add(FrameData(
          frameIndex: i,
          timestamp: i / fps,
          joints: joints,
        ));

        if (i % 5 == 0 || i == frameFiles.length - 1) {
          final progress = 0.15 + (i / frameFiles.length) * 0.80;
          onProgress?.call(
            progress,
            '骨格を検出中 ($i/${frameFiles.length}フレーム)',
          );
        }
      }

      onProgress?.call(1.0, '完了');
      return frames;
    } finally {
      // 一時ファイルを削除
      if (framesDir.existsSync()) {
        framesDir.deleteSync(recursive: true);
      }
      await _poseDetector.close();
    }
  }

  /// ffprobe で動画の幅・高さを取得する
  Future<(double, double)> _getVideoDimensions(String videoPath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(videoPath);
      final info = session.getMediaInformation();
      final streams = info?.getStreams();
      if (streams != null) {
        for (final stream in streams) {
          final w = stream.getWidth();
          final h = stream.getHeight();
          if (w != null && h != null) {
            return (w.toDouble(), h.toDouble());
          }
        }
      }
    } catch (_) {}
    // フォールバック: スマホ縦撮り想定
    return (1080.0, 1920.0);
  }

  /// ffmpeg でフレームをJPEG展開する
  Future<void> _extractFrames(
    String videoPath,
    String outputDir,
    double fps,
  ) async {
    final cmd =
        '-i "$videoPath" -vf fps=$fps -q:v 3 "$outputDir/frame_%04d.jpg"';
    final session = await FFmpegKit.execute(cmd);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw Exception('ffmpegエラー: $logs');
    }
  }
}
