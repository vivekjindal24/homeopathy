import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../errors/app_exception.dart';
import '../errors/error_handler.dart';
import '../utils/constants.dart';
import 'supabase_service.dart';

/// Handles file uploads and signed-URL retrieval via Supabase Storage.
class StorageService {
  final SupabaseClient _client;
  const StorageService(this._client);

  /// Upload a [file] to [bucket]/[path].
  /// Returns the storage path of the uploaded file.
  Future<String> uploadFile({
    required String bucket,
    required File file,
    String? customPath,
    String? contentType,
  }) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final path = customPath ?? '${const Uuid().v4()}.$ext';
      await _client.storage.from(bucket).upload(
            path,
            file,
            fileOptions: FileOptions(
              contentType: contentType ?? _mimeType(ext),
              upsert: false,
            ),
          );
      return path;
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Upload bytes (for PDF generated in memory) to [bucket]/[path].
  Future<String> uploadBytes({
    required String bucket,
    required List<int> bytes,
    required String fileName,
    String contentType = 'application/pdf',
  }) async {
    try {
      await _client.storage.from(bucket).uploadBinary(
            fileName,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );
      return fileName;
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Create a signed URL valid for [expiresIn] seconds (default 60s).
  Future<String> createSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 60,
  }) async {
    try {
      final url = await _client.storage
          .from(bucket)
          .createSignedUrl(path, expiresIn);
      return url;
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Delete a file from [bucket] at [path].
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw ErrorHandler.map(e);
    }
  }

  /// Public URL for the avatars bucket (publicly readable).
  String publicAvatarUrl(String path) =>
      _client.storage.from(AppConstants.bucketAvatars).getPublicUrl(path);

  String _mimeType(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}

/// Riverpod provider for [StorageService].
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

