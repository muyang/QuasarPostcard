import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Simple in-memory cache for fetched image bytes, keyed by URL.
/// Prevents redundant network requests when the same image is loaded
/// by multiple AppImage widgets (e.g., in list views).
class _ImageCache {
  static final _cache = <String, Uint8List?>{};
  static final _pending = <String, Future<Uint8List?>>{};

  static const _maxEntries = 200;

  static Future<Uint8List?> load(String src) {
    if (_cache.containsKey(src)) return Future.value(_cache[src]);

    // Deduplicate concurrent requests for the same URL
    final pending = _pending[src];
    if (pending != null) return pending;

    final f = ApiService.fetchImageBytes(src).then((bytes) {
      _cache[src] = bytes;
      _pending.remove(src);
      _evictIfNeeded();
      return bytes;
    }).catchError((e) {
      _pending.remove(src);
      return null;
    });
    _pending[src] = f;
    return f;
  }

  static void _evictIfNeeded() {
    if (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }
}

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
    _future = _ImageCache.load(widget.src);
  }

  @override
  void didUpdateWidget(covariant _MemoryImage old) {
    super.didUpdateWidget(old);
    if (old.src != widget.src) {
      _future = _ImageCache.load(widget.src);
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
