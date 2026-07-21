import 'package:flutter/material.dart';

/// 문의 이미지 등 탭 시 전체화면 확대(핀치 줌)
abstract final class FullscreenImageViewer {
  static Future<void> show(BuildContext context, {required String imageUrl}) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => _FullscreenImageDialog(imageUrl: imageUrl),
    );
  }
}

class _FullscreenImageDialog extends StatelessWidget {
  const _FullscreenImageDialog({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 0.8,
            maxScale: 4,
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                tooltip: '닫기',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
