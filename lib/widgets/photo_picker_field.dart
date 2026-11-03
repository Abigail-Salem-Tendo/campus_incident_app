import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/photo_service.dart';

/// Optional photo field for the Submit Report form.
/// The parent owns the chosen file; this widget reports changes.
class PhotoPickerField extends StatefulWidget {
  const PhotoPickerField({
    super.key,
    required this.photo,
    required this.onChanged,
    this.enabled = true,
  });

  final File? photo;
  final ValueChanged<File?> onChanged;
  final bool enabled;

  @override
  State<PhotoPickerField> createState() => _PhotoPickerFieldState();
}

class _PhotoPickerFieldState extends State<PhotoPickerField> {
  final PhotoService _service = PhotoService();
  bool _picking = false;
  String? _error;

  Future<void> _chooseSource() async {
    if (!widget.enabled || _picking) return;

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null) {
      await _pick(source);
    }
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _picking = true;
      _error = null;
    });

    try {
      final File? file = await _service.pickPhoto(source);
      if (file != null) {
        widget.onChanged(file);
      }
    } on PhotoTooLargeException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not open the camera or gallery. Please try again.';
    } finally {
      if (mounted) {
        setState(() => _picking = false);
      }
    }
  }

  void _remove() {
    setState(() => _error = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Photo (optional)', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        if (widget.photo == null) _buildEmptyBox(scheme, textTheme) else _buildPreview(),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyBox(ColorScheme scheme, TextTheme textTheme) {
    return InkWell(
      onTap: widget.enabled ? _chooseSource : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline),
        ),
        child: _picking
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: scheme.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Add a photo',
                    style: textTheme.bodyMedium?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPreview() {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.enabled ? _chooseSource : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(
              widget.photo!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              cacheWidth: 800,
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton.filled(
            onPressed: widget.enabled ? _remove : null,
            style: IconButton.styleFrom(backgroundColor: Colors.black54),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Remove photo',
          ),
        ),
      ],
    );
  }
}