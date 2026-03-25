# AIxKendo Mobile — 剣道素振り解析 スマートフォン版

Python版 AIxKendoClaude と同じコンセプトをFlutterで実装したスマートフォンアプリ。
Google ML Kit (MediaPipe) による姿勢推定とルールベース採点で、スマホ撮影動画を解析します。

---

## 採点項目

| 項目 | ウェイト | 評価内容 |
|---|---|---|
| 肘の対称性 | 25% | 左右の肘の高さのそろい |
| 振り上げ高さ | 25% | 手首が頭上まで届いているか |
| 肩の安定性 | 20% | 動作中の肩ブレの小ささ |
| 腰の安定性 | 15% | 腰の上下動の小ささ |
| 動作の滑らかさ | 15% | 手首速度の加速度ばらつき |

---

## セットアップ

### 1. Flutter のインストール

```
https://docs.flutter.dev/get-started/install
```

Windowsの場合は公式インストーラー (flutter_windows_x.x.x-stable.zip) を展開し、
PATHに `flutter/bin` を追加してください。

確認:
```bash
flutter doctor
```

### 2. プロジェクトの初期化

このフォルダで `flutter create` を実行してベースファイルを生成:

```bash
cd C:\src\AIxKendoMobile
flutter create . --project-name aikendo_mobile --org com.example
```

> lib/main.dart が上書きされるので、実行後に以下を行う:
>
> ```bash
> git checkout lib/main.dart lib/models lib/services lib/screens
> ```
>
> または、flutter create 後に lib/ フォルダを本リポジトリのファイルで上書きしてください。

### 3. 依存パッケージのインストール

```bash
flutter pub get
```

### 4. Android の設定

`android/app/src/main/AndroidManifest.xml` のパーミッション部分が既に含まれています。
`flutter create` 生成ファイルと手動マージが必要な場合は、このリポジトリの AndroidManifest.xml を参照してください。

### 5. iOS の設定（Macが必要）

`ios/Runner/Info.plist` にカメラ・フォトライブラリの権限キーが含まれています。
`flutter create` 生成ファイルに上記3つのキーを追加してください:

- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`
- `NSMicrophoneUsageDescription`

---

## 実行

```bash
# Androidデバイス/エミュレーターで実行
flutter run

# iOSシミュレーターで実行（Mac必須）
flutter run -d ios

# APKビルド（Androidのみ）
flutter build apk --release
```

---

## アーキテクチャ

```
lib/
├── main.dart                   # アプリエントリーポイント
├── models/
│   ├── frame_data.dart         # フレーム・関節データ
│   └── score_result.dart       # 採点結果・定数
├── services/
│   ├── video_processor.dart    # 動画→骨格抽出 (ffmpeg + ML Kit)
│   └── kendo_scorer.dart       # 素振り採点エンジン (Python版ポート)
└── screens/
    ├── home_screen.dart        # ホーム (動画選択)
    ├── analyze_screen.dart     # 解析進捗表示
    └── result_screen.dart      # 採点結果・フィードバック
```

### 処理フロー

```
動画選択 (image_picker)
  ↓
ffmpeg でフレーム展開 (15fps)
  ↓
Google ML Kit Pose Detection (各フレーム)
  ↓
KendoScorer で採点 (Python版と同アルゴリズム)
  ↓
ResultScreen でスコア・フィードバック表示
```

---

## 使用ライブラリ

| ライブラリ | 用途 |
|---|---|
| google_mlkit_pose_detection | MediaPipeベースの姿勢推定 |
| ffmpeg_kit_flutter_min_gpl | 動画フレーム展開 |
| image_picker | カメラ撮影・ギャラリー選択 |
| fl_chart | 採点結果バーチャート |
| path_provider | 一時ファイルパス |

---

## ロードマップ

```
フェーズ 0 (現在)
  完了 姿勢推定 (Google ML Kit)
  完了 ルールベース採点 v1
  完了 採点結果・フィードバック表示

フェーズ 1
  □ リアルタイムカメラ解析 (camera + ML Kit stream mode)
  □ 骨格オーバーレイ描画
  □ Claude API連携コーチングコメント

フェーズ 2
  □ 採点結果の履歴保存
  □ 機械学習採点モデル
  □ 参照動画との比較
```

---

## サンプル動画

`assets/videos/suburi.mp4` にサンプル動画が含まれています。
ギャラリー選択時にアプリ内から参照することはできませんが、
テスト用途では Android の `/sdcard/` にコピーして使用できます。
