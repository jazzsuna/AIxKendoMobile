import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'analyze_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickVideo(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (video == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyzeScreen(videoPath: video.path),
      ),
    );
  }

  Future<void> _recordVideo(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 2),
    );
    if (video == null || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnalyzeScreen(videoPath: video.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0D1B4B),
              scheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 48),

                // ─── ロゴ・タイトル ───
                const Icon(
                  Icons.sports_martial_arts,
                  size: 72,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  '剣道素振り解析',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'AIxKendo Mobile',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 56),

                // ─── 採点項目 ───
                _InfoCard(
                  items: const [
                    ('肘の対称性',     '25%'),
                    ('振り上げ高さ',   '25%'),
                    ('肩の安定性',     '20%'),
                    ('腰の安定性',     '15%'),
                    ('動作の滑らかさ', '15%'),
                  ],
                ),

                const Spacer(),

                // ─── 動作ボタン ───
                _ActionButton(
                  icon: Icons.videocam,
                  label: '動画を撮影して解析',
                  onTap: () => _recordVideo(context),
                ),
                const SizedBox(height: 12),
                _ActionButton(
                  icon: Icons.video_library,
                  label: 'ギャラリーから選択',
                  onTap: () => _pickVideo(context),
                  outlined: true,
                ),

                const SizedBox(height: 16),
                Text(
                  'スマホ縦撮り・全身が映るよう撮影してください',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.45),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<(String, String)> items;

  const _InfoCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '採点項目',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.5),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    Text(
                      item.$2,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white38),
          minimumSize: const Size(double.infinity, 52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF3D5AFE),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
