import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Evict decoded photo data when a session image is replaced or leaves a view.
class PhotoImage extends StatefulWidget {
  const PhotoImage({super.key, required this.bytes, this.label});
  final Uint8List bytes;
  final String? label;
  @override
  State<PhotoImage> createState() => _PhotoImageState();
}

class _PhotoImageState extends State<PhotoImage> {
  @override
  void didUpdateWidget(PhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.bytes, widget.bytes)) {
      unawaited(MemoryImage(oldWidget.bytes).evict());
    }
  }

  @override
  void dispose() {
    unawaited(MemoryImage(widget.bytes).evict());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Image.memory(
    widget.bytes,
    fit: BoxFit.cover,
    semanticLabel: widget.label,
  );
}
