import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/services/storage_service.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/clinic_app_bar.dart';
import '../../../shared/widgets/clinic_button.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final _mediaProvider =
    FutureProvider.family<List<PatientMediaModel>, String>((ref, patientId) async {
  final data = await Supabase.instance.client
      .from(AppConstants.tablePatientMedia)
      .select()
      .eq('patient_id', patientId)
      .order('created_at', ascending: false);
  return (data as List).map((e) => PatientMediaModel.fromJson(e)).toList();
});

/// Patient media gallery screen.
class PatientMediaScreen extends ConsumerStatefulWidget {
  final String patientId;
  const PatientMediaScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientMediaScreen> createState() => _PatientMediaScreenState();
}

class _PatientMediaScreenState extends ConsumerState<PatientMediaScreen> {
  MediaType? _filter;

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(_mediaProvider(widget.patientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ClinicAppBar(
        title: 'Patient Media',
        actions: [
          IconButton(
            onPressed: () => _showUploadSheet(context),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: const Icon(Icons.add_photo_alternate_rounded,
                  color: AppColors.textInverse, size: 20),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: mediaAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.pagePadding),
                child: LoadingShimmer(height: 200),
              ),
              error: (e, _) => ErrorState(message: e.toString()),
              data: (all) {
                final items = _filter == null
                    ? all
                    : all.where((m) => m.mediaType == _filter).toList();

                if (items.isEmpty) {
                  return EmptyState(
                    icon: Icons.photo_library_outlined,
                    title: 'No media',
                    subtitle: 'Upload photos or X-rays using the + button',
                    actionLabel: 'Upload',
                    onAction: () => _showUploadSheet(context),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _MediaThumb(
                    item: items[i],
                    onTap: () => _openGallery(context, items, i),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _filter == null,
            onTap: () => setState(() => _filter = null),
          ),
          ...MediaType.values.map((t) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.sm),
                child: _FilterChip(
                  label: t.displayName,
                  selected: _filter == t,
                  onTap: () => setState(
                    () => _filter = _filter == t ? null : t,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  void _openGallery(
      BuildContext context, List<PatientMediaModel> items, int initialIndex) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MediaGalleryPage(items: items, initialIndex: initialIndex),
    ));
  }

  Future<void> _showUploadSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _UploadSheet(
        patientId: widget.patientId,
        onUploaded: () => ref.invalidate(_mediaProvider(widget.patientId)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: selected ? AppColors.textInverse : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _MediaThumb extends StatelessWidget {
  final PatientMediaModel item;
  final VoidCallback onTap;

  const _MediaThumb({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: item.fileUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.card),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.card,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.textSecondary),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  item.mediaType.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaGalleryPage extends StatelessWidget {
  final List<PatientMediaModel> items;
  final int initialIndex;

  const _MediaGalleryPage({required this.items, required this.initialIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('${initialIndex + 1} / ${items.length}'),
      ),
      body: PhotoViewGallery.builder(
        itemCount: items.length,
        pageController: PageController(initialPage: initialIndex),
        builder: (_, i) => PhotoViewGalleryPageOptions(
          imageProvider: CachedNetworkImageProvider(items[i].fileUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 3,
        ),
        loadingBuilder: (_, __) => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _UploadSheet extends ConsumerStatefulWidget {
  final String patientId;
  final VoidCallback onUploaded;

  const _UploadSheet({required this.patientId, required this.onUploaded});

  @override
  ConsumerState<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends ConsumerState<_UploadSheet> {
  MediaType _mediaType = MediaType.before;
  final _captionCtrl = TextEditingController();
  XFile? _picked;
  Uint8List? _pickedBytes;
  bool _uploading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppSpacing.pagePadding,
        right: AppSpacing.pagePadding,
        top: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload Media', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.lg),
          DropdownButtonFormField<MediaType>(
            value: _mediaType,
            items: MediaType.values
                .map((t) => DropdownMenuItem(
                    value: t, child: Text(t.displayName)))
                .toList(),
            onChanged: (v) => setState(() => _mediaType = v ?? _mediaType),
            decoration: const InputDecoration(labelText: 'Media Type'),
            dropdownColor: AppColors.card,
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _captionCtrl,
            decoration: const InputDecoration(labelText: 'Caption (optional)'),
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_picked != null && _pickedBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Image.memory(
                _pickedBytes!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pick Photo'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _picked == null || _pickedBytes == null || _uploading ? null : _upload,
                  icon: _uploading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textInverse,
                          ),
                        )
                      : const Icon(Icons.upload_rounded),
                  label: const Text('Upload'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final image =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _picked = image;
        _pickedBytes = bytes;
      });
    }
  }

  Future<void> _upload() async {
    setState(() => _uploading = true);
    try {
      final bytes = _pickedBytes!;
      final fileName = _picked!.name;
      final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';
      final path = '${widget.patientId}/${const Uuid().v4()}.$ext';

      final storageService = ref.read(storageServiceProvider);
      final storedPath = await storageService.uploadFile(
        bucket: AppConstants.bucketPatientMedia,
        fileBytes: bytes,
        fileName: fileName,
        customPath: path,
      );

      final userId = ref.read(currentUserProvider)?.id ?? '';
      await Supabase.instance.client
          .from(AppConstants.tablePatientMedia)
          .insert({
        'patient_id': widget.patientId,
        'media_type': _mediaType.value,
        'file_url': storedPath,
        'caption': _captionCtrl.text.trim().isEmpty
            ? null
            : _captionCtrl.text.trim(),
        'uploaded_by': userId,
      });

      widget.onUploaded();
      if (mounted) {
        context.showSnackBar('Media uploaded!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) context.showErrorSnackBar(e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
}

