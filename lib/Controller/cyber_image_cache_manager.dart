import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Global Image Cache Manager với LRU eviction
/// Quản lý tập trung memory cho tất cả CyberImage
class CyberImageCacheManager {
  static final CyberImageCacheManager _instance =
      CyberImageCacheManager._internal();
  factory CyberImageCacheManager() => _instance;
  CyberImageCacheManager._internal();

  // ⭐ Cache entries với metadata
  final Map<String, _CacheEntry> _cache = {};

  // ⭐ LRU queue để track usage
  final List<String> _lruQueue = [];

  // ⭐ Configurable limits
  int maxCacheSize = 20; // Max 20 images trong memory
  int maxMemoryBytes = 50 * 1024 * 1024; // Max 50MB total

  int _currentMemoryBytes = 0;

  /// Get image bytes by key (hash)
  Uint8List? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // ⭐ Update LRU
    _lruQueue.remove(key);
    _lruQueue.add(key); // Move to end (most recent)

    entry.lastAccessTime = DateTime.now();
    //entry.accessCount++;

    return entry.bytes;
  }

  /// ⭐ Get or put - lazy load pattern
  /// Nếu có trong cache -> trả về ngay
  /// Nếu chưa có -> gọi valueFactory, cache rồi trả về
  Uint8List? getOrPut(String key, Uint8List? Function() valueFactory) {
    // Try get from cache first
    final cached = get(key);
    if (cached != null) {
      return cached;
    }

    // Cache miss - create and cache
    final bytes = valueFactory();
    if (bytes != null) {
      put(key, bytes);
      return bytes;
    }

    return null;
  }

  /// ⭐ SINGLE SOURCE OF TRUTH - Decode base64 và cache
  /// Đây là method DUY NHẤT để decode base64 trong app
  /// Widgets KHÔNG ĐƯỢC decode riêng!
  Uint8List? getOrDecodeBase64(String base64String) {
    // 1. Decode base64 (chỉ 1 chỗ decode trong toàn app!)
    final decoded = CyberImageUtils.decodeBase64(base64String);
    if (decoded == null) return null;

    // 2. Hash từ DECODED BYTES
    final key = CyberImageUtils.hashBytes(decoded);

    // 3. Check cache hoặc put
    return getOrPut(key, () => decoded);
  }

  /// Put image bytes into cache
  void put(String key, Uint8List bytes) {
    final size = bytes.length;

    // ⭐ Check if need eviction
    while (_cache.length >= maxCacheSize ||
        _currentMemoryBytes + size > maxMemoryBytes) {
      if (_lruQueue.isEmpty) break;
      _evictOldest();
    }

    // Add to cache
    _cache[key] = _CacheEntry(
      bytes: bytes,
      size: size,
      lastAccessTime: DateTime.now(),
    );
    _lruQueue.add(key);
    _currentMemoryBytes += size;
  }

  /// Remove specific entry
  void remove(String key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      _lruQueue.remove(key);
      _currentMemoryBytes -= entry.size;
    }
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _lruQueue.clear();
    _currentMemoryBytes = 0;
  }

  /// Evict oldest (least recently used)
  void _evictOldest() {
    if (_lruQueue.isEmpty) return;

    final oldestKey = _lruQueue.first;
    final entry = _cache.remove(oldestKey);

    if (entry != null) {
      _lruQueue.removeAt(0);
      _currentMemoryBytes -= entry.size;
    }
  }

  /// Get cache statistics
  CacheStats getStats() {
    return CacheStats(
      entryCount: _cache.length,
      totalBytes: _currentMemoryBytes,
      maxEntries: maxCacheSize,
      maxBytes: maxMemoryBytes,
      hitRate: _calculateHitRate(),
    );
  }

  double _calculateHitRate() {
    if (_cache.isEmpty) return 0.0;

    int totalAccess = 0;
    // for (final entry in _cache.values) {
    //   totalAccess += entry.accessCount;
    // }

    return totalAccess / _cache.length;
  }
}

class _CacheEntry {
  final Uint8List bytes;
  final int size;
  DateTime lastAccessTime;
  //int accessCount;

  _CacheEntry({
    required this.bytes,
    required this.size,
    required this.lastAccessTime,
    //this.accessCount = 1,
  });
}

class CacheStats {
  final int entryCount;
  final int totalBytes;
  final int maxEntries;
  final int maxBytes;
  final double hitRate;

  CacheStats({
    required this.entryCount,
    required this.totalBytes,
    required this.maxEntries,
    required this.maxBytes,
    required this.hitRate,
  });

  double get usagePercent => (entryCount / maxEntries * 100);
  double get memoryPercent => (totalBytes / maxBytes * 100);
}

/// Utilities for image hashing
class CyberImageUtils {
  /// ⭐ Generate hash from base64 string (không giữ full string)
  static String hashBase64(String base64String) {
    // Chỉ hash, không store full string
    final bytes = utf8.encode(base64String);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// ⭐ Generate hash from bytes
  static String hashBytes(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Decode base64 với error handling
  static Uint8List? decodeBase64(String base64String) {
    try {
      String cleanBase64 = base64String;

      // Remove data URI prefix if exists
      if (cleanBase64.startsWith('data:image')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      return base64Decode(cleanBase64);
    } catch (e) {
      return null;
    }
  }
}
