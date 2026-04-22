import 'dart:io';

import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/network/api_client.dart';
import '../models/common/api_response.dart';
import '../models/material/cached_material.dart';
import '../models/material/material_dto.dart';
import '../providers/core_providers.dart';

part 'material_repository.g.dart';

class MaterialRepository {
  MaterialRepository(this._api, this._isar);

  final ApiClient _api;
  final Isar _isar;
  static final _logger = Logger(printer: PrettyPrinter(methodCount: 0));

  Future<List<MaterialDto>> getMaterials() async {
    final cached = await _isar.cachedMaterials.where().findAll();

    if (cached.isNotEmpty) {
      _refreshInBackground();
      return cached.map(MaterialDto.fromCached).toList();
    }

    return _fetchAndCache();
  }

  Future<List<MaterialDto>> refresh() => _fetchAndCache();

  Future<void> downloadMaterial({
    required MaterialDto material,
    void Function(double)? onProgress,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/materials/${material.fileName}';
    final saveDir = Directory('${dir.path}/materials');
    if (!await saveDir.exists()) {
      await saveDir.create(recursive: true);
    }

    await _api.downloadMaterial(
      material.downloadUrl ?? '',
      savePath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    await _isar.writeTxn(() async {
      final existing = await _isar.cachedMaterials
          .filter()
          .serverIdEqualTo(material.id)
          .findFirst();
      if (existing != null) {
        existing.isDownloaded = true;
        existing.localFilePath = savePath;
        await _isar.cachedMaterials.put(existing);
      }
    });
  }

  Future<void> deleteDownloadedFile(String materialId) async {
    final cached = await _isar.cachedMaterials
        .filter()
        .serverIdEqualTo(materialId)
        .findFirst();

    if (cached?.localFilePath != null) {
      final file = File(cached!.localFilePath!);
      if (await file.exists()) await file.delete();
    }

    await _isar.writeTxn(() async {
      if (cached != null) {
        cached.isDownloaded = false;
        cached.localFilePath = null;
        await _isar.cachedMaterials.put(cached);
      }
    });
  }

  Future<List<MaterialDto>> _fetchAndCache() async {
    try {
      final response = await _api.getMaterials();
      final apiResponse = ApiResponse.fromResponse(response);
      final materials = apiResponse.parseList(MaterialDto.fromJson);

      await _isar.writeTxn(() async {
        for (final material in materials) {
          final existing = await _isar.cachedMaterials
              .filter()
              .serverIdEqualTo(material.id)
              .findFirst();

          final cached = material.toCached();
          if (existing != null) {
            cached.id = existing.id;
            cached.isDownloaded = existing.isDownloaded;
            cached.localFilePath = existing.localFilePath;
          }
          await _isar.cachedMaterials.put(cached);
        }
      });

      final updatedCache = await _isar.cachedMaterials.where().findAll();
      return updatedCache.map(MaterialDto.fromCached).toList();
    } catch (e) {
      _logger.e('Failed to fetch materials: $e');
      final cached = await _isar.cachedMaterials.where().findAll();
      if (cached.isNotEmpty) return cached.map(MaterialDto.fromCached).toList();
      rethrow;
    }
  }

  void _refreshInBackground() {
    Future.delayed(const Duration(milliseconds: 100), () async {
      try {
        await _fetchAndCache();
      } catch (e) {
        _logger.w('Background material refresh failed: $e');
      }
    });
  }
}

@riverpod
MaterialRepository materialRepository(Ref ref) {
  final api = ref.watch(apiClientProvider);
  final isar = ref.watch(isarProvider).requireValue;
  return MaterialRepository(api, isar);
}

@riverpod
Future<List<MaterialDto>> materials(Ref ref) {
  return ref.watch(materialRepositoryProvider).getMaterials();
}

@riverpod
class DownloadProgress extends _$DownloadProgress {
  @override
  Map<String, double> build() => {};

  Future<void> startDownload(MaterialDto material) async {
    state = {...state, material.id: 0.0};
    try {
      await ref.read(materialRepositoryProvider).downloadMaterial(
            material: material,
            onProgress: (progress) {
              state = {...state, material.id: progress};
            },
          );
      state = Map.from(state)..remove(material.id);
      ref.invalidate(materialsProvider);
    } catch (e) {
      state = Map.from(state)..remove(material.id);
      rethrow;
    }
  }
}
