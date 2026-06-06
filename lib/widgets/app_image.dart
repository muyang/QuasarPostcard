import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AppImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function()? placeholder;
  final Widget Function()? errorWidget;
  final String? thumbnailSize; // 'thumb' or 'small' for server-side thumbnail

  const AppImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.thumbnailSize,
  });

  @override
  Widget build(BuildContext context) {
    final src = ApiService.imageUrl(url, size: thumbnailSize);
    if (src.isEmpty) {
      return errorWidget?.call() ?? const SizedBox.shrink();
    }

    // Always use memory-based loading to avoid CanvasKit crossOrigin issues on mobile
    return _MemoryImage(src: src, width: width, height: height, fit: fit, placeholder: placeholder, errorWidget: errorWidget);
  }
}

class _MemoryImage extends StatefulWidget {
  final String src;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function()? placeholder;
  final Widget Function()? errorWidget;

  const _MemoryImage({required this.src, this.width, this.height, this.fit, this.placeholder, this.errorWidget});

  @override
  State<_MemoryImage> createState() => _MemoryImageState();
}

class _MemoryImageState extends State<_MemoryImage> {
  Future<Uint8List?>? _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchImageBytes(widget.src);
  }

  @override
  void didUpdateWidget(covariant _MemoryImage old) {
    super.didUpdateWidget(old);
    if (old.src != widget.src) {
      _future = ApiService.fetchImageBytes(widget.src);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.placeholder?.call() ?? const SizedBox.shrink();
        }
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            width: widget.width,
            height: widget.height,
            fit: widget.fit ?? BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                widget.errorWidget?.call() ?? const SizedBox.shrink(),
          );
        }
        return widget.errorWidget?.call() ?? const SizedBox.shrink();
      },
    );
  }
}
