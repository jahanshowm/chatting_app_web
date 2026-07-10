import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// 원본 비율 유지 — [maxWidth]·[maxHeight]는 **상한**만, 실제 크기는 이미지 비율로 결정.
class AdminAspectFitImage extends StatefulWidget {
  const AdminAspectFitImage.network({
    super.key,
    required String url,
    required this.maxWidth,
    required this.maxHeight,
    this.borderRadius = 0,
    this.alignment = Alignment.center,
    this.errorFallback,
  })  : _url = url,
        _bytes = null;

  const AdminAspectFitImage.memory({
    super.key,
    required Uint8List bytes,
    required this.maxWidth,
    required this.maxHeight,
    this.borderRadius = 0,
    this.alignment = Alignment.center,
    this.errorFallback,
  })  : _url = null,
        _bytes = bytes;

  final String? _url;
  final Uint8List? _bytes;
  final double maxWidth;
  final double maxHeight;
  final double borderRadius;
  final Alignment alignment;
  final Widget? errorFallback;

  @override
  State<AdminAspectFitImage> createState() => _AdminAspectFitImageState();
}

class _AdminAspectFitImageState extends State<AdminAspectFitImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageProvider? _provider;
  Size? _intrinsicSize;
  Size? _displaySize;
  bool _failed = false;

  ImageProvider get _imageProvider {
    _provider ??= widget._bytes != null
        ? MemoryImage(widget._bytes!)
        : NetworkImage(widget._url!);
    return _provider!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant AdminAspectFitImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._url != widget._url || oldWidget._bytes != widget._bytes) {
      _provider = null;
      _intrinsicSize = null;
      _displaySize = null;
      _failed = false;
      _resolveImage();
    } else if (oldWidget.maxWidth != widget.maxWidth ||
        oldWidget.maxHeight != widget.maxHeight) {
      _applyDisplaySize();
    }
  }

  void _applyDisplaySize() {
    if (_intrinsicSize == null) return;
    final size = _fitToMax(_intrinsicSize!.width, _intrinsicSize!.height);
    if (mounted) setState(() => _displaySize = size);
  }

  void _resolveImage() {
    _stream?.removeListener(_listener!);
    final stream = _imageProvider.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener(
      (info, _) {
        _intrinsicSize = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        _applyDisplaySize();
      },
      onError: (_, __) {
        if (mounted) setState(() => _failed = true);
      },
    );
    _stream = stream;
    stream.addListener(_listener!);
  }

  /// 원본보다 키우지 않고, maxWidth·maxHeight 안에 맞춤.
  Size _fitToMax(double width, double height) {
    if (width <= 0 || height <= 0) {
      return Size.zero;
    }
    final scale = math.min(
      math.min(widget.maxWidth / width, widget.maxHeight / height),
      1.0,
    );
    return Size(width * scale, height * scale);
  }

  @override
  void dispose() {
    if (_listener != null) {
      _stream?.removeListener(_listener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return widget.errorFallback ?? const Text('이미지를 불러올 수 없습니다');
    }

    if (_displaySize == null || _displaySize == Size.zero) {
      return SizedBox(
        width: widget.maxWidth,
        height: math.min(widget.maxHeight, 24),
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final image = SizedBox(
      width: _displaySize!.width,
      height: _displaySize!.height,
      child: Image(
        image: _imageProvider,
        fit: BoxFit.fill,
        gaplessPlayback: true,
      ),
    );

    final clipped = widget.borderRadius > 0
        ? ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: image,
          )
        : image;

    return Align(alignment: widget.alignment, child: clipped);
  }
}
