import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'api_service.dart';

/// Service for managing per-user scan history in Supabase
class ScanHistoryService {
  static SupabaseClient get _db => AuthService.client;
  static const String _table = 'user_scans';

  /// Save or update a scan (upsert on user_id + barcode)
  static Future<void> saveScan({
    required ProductResponse product,
    String intent = 'checked',
    DateTime? purchaseDate,
  }) async {
    final userId = AuthService.userId;
    if (userId == null) return;

    final barcode = product.barcode ?? '';

    try {
      // Check if scan already exists for this user + barcode
      final existing = await _db
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .eq('barcode', barcode)
          .maybeSingle();

      if (existing != null) {
        // Update existing record
        final updates = <String, dynamic>{
          'intent': intent,
          'scanned_at': DateTime.now().toIso8601String(),
          'product_name': product.productName,
          'health_score': product.healthScore,
          'verdict': product.verdict,
          'additives_count': product.additives.length,
        };
        if (purchaseDate != null) {
          updates['purchase_date'] = purchaseDate.toIso8601String().split('T')[0];
        }
        await _db.from(_table).update(updates).eq('id', existing['id']);
      } else {
        // Insert new record
        await _db.from(_table).insert({
          'user_id': userId,
          'barcode': barcode,
          'product_name': product.productName,
          'brand': product.brand,
          'category': product.category,
          'health_score': product.healthScore,
          'verdict': product.verdict,
          'additives_count': product.additives.length,
          'intent': intent,
          'purchase_date': purchaseDate?.toIso8601String().split('T')[0],
        });
      }
    } catch (e) {
      print('⚠️ saveScan error: $e');
      rethrow;
    }
  }

  /// Update just the intent of a scan
  static Future<void> updateIntent(String scanId, String intent) async {
    await _db.from(_table).update({'intent': intent}).eq('id', scanId);
  }

  /// Update purchase date for a scan by barcode
  static Future<void> savePurchase({
    required ProductResponse product,
    required DateTime purchaseDate,
  }) async {
    final userId = AuthService.userId;
    if (userId == null) return;

    final barcode = product.barcode ?? '';

    try {
      final existing = await _db
          .from(_table)
          .select('id')
          .eq('user_id', userId)
          .eq('barcode', barcode)
          .maybeSingle();

      if (existing != null) {
        await _db.from(_table).update({
          'intent': 'purchased',
          'purchase_date': purchaseDate.toIso8601String().split('T')[0],
        }).eq('id', existing['id']);
      } else {
        await _db.from(_table).insert({
          'user_id': userId,
          'barcode': barcode,
          'product_name': product.productName,
          'brand': product.brand,
          'category': product.category,
          'health_score': product.healthScore,
          'verdict': product.verdict,
          'additives_count': product.additives.length,
          'intent': 'purchased',
          'purchase_date': purchaseDate.toIso8601String().split('T')[0],
        });
      }
    } catch (e) {
      print('⚠️ savePurchase error: $e');
      rethrow;
    }
  }

  /// Get recent scans for current user
  static Future<List<UserScan>> getRecentScans({int limit = 5}) async {
    final userId = AuthService.userId;
    if (userId == null) return [];

    final data = await _db
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('scanned_at', ascending: false)
        .limit(limit);

    return (data as List).map((row) => UserScan.fromJson(row)).toList();
  }

  /// Get last 30 days stats for current user
  static Future<ScanStats> getLast30DaysStats() async {
    final userId = AuthService.userId;
    if (userId == null) return ScanStats.empty();

    final since = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

    final data = await _db
        .from(_table)
        .select('intent')
        .eq('user_id', userId)
        .gte('scanned_at', since);

    final rows = data as List;
    int scanned = rows.length;
    int consumed = rows.where((r) => r['intent'] == 'consumed').length;
    int avoided = rows.where((r) => r['intent'] == 'avoided').length;
    int purchased = rows.where((r) => r['intent'] == 'purchased').length;

    return ScanStats(
      scanned: scanned,
      consumed: consumed,
      avoided: avoided,
      purchased: purchased,
    );
  }

  /// Get full scan history with pagination
  static Future<List<UserScan>> getScanHistory({
    int offset = 0,
    int limit = 20,
    String? intentFilter,
  }) async {
    final userId = AuthService.userId;
    if (userId == null) return [];

    var query = _db
        .from(_table)
        .select()
        .eq('user_id', userId);

    if (intentFilter != null && intentFilter != 'all') {
      query = query.eq('intent', intentFilter);
    }

    final data = await query
        .order('scanned_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (data as List).map((row) => UserScan.fromJson(row)).toList();
  }

  // ============================================================
  // ANALYTICS METHODS
  // ============================================================

  /// Get purchase history for last N days
  static Future<List<UserScan>> getPurchaseHistory({int days = 30}) async {
    final userId = AuthService.userId;
    if (userId == null) return [];

    final data = await _db
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('intent', 'purchased')
        .order('purchase_date', ascending: false)
        .limit(20);

    return (data as List).map((row) => UserScan.fromJson(row)).toList();
  }

  /// Get health score distribution for last N days
  static Future<HealthDistribution> getHealthScoreDistribution({int days = 30}) async {
    final userId = AuthService.userId;
    if (userId == null) return HealthDistribution(good: 0, moderate: 0, poor: 0);

    final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();

    final data = await _db
        .from(_table)
        .select('health_score')
        .eq('user_id', userId)
        .gte('scanned_at', since);

    final rows = data as List;
    int good = rows.where((r) => (r['health_score'] ?? 0) >= 75).length;
    int moderate = rows.where((r) {
      final s = r['health_score'] ?? 0;
      return s >= 50 && s < 75;
    }).length;
    int poor = rows.where((r) => (r['health_score'] ?? 0) < 50).length;

    return HealthDistribution(good: good, moderate: moderate, poor: poor);
  }

  /// Get top scanned products (by most recent, since we use upsert now)
  static Future<List<UserScan>> getTopProducts({int limit = 5}) async {
    final userId = AuthService.userId;
    if (userId == null) return [];

    final data = await _db
        .from(_table)
        .select()
        .eq('user_id', userId)
        .order('scanned_at', ascending: false)
        .limit(limit);

    return (data as List).map((row) => UserScan.fromJson(row)).toList();
  }

  /// Get weekly activity (scan counts per day for last 7 days)
  static Future<List<int>> getWeeklyActivity() async {
    final userId = AuthService.userId;
    if (userId == null) return List.filled(7, 0);

    final since = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    final data = await _db
        .from(_table)
        .select('scanned_at')
        .eq('user_id', userId)
        .gte('scanned_at', since);

    final result = List.filled(7, 0);
    final now = DateTime.now();

    for (final row in data as List) {
      final scannedAt = DateTime.tryParse(row['scanned_at'] ?? '');
      if (scannedAt != null) {
        final daysAgo = now.difference(scannedAt).inDays;
        if (daysAgo >= 0 && daysAgo < 7) {
          result[6 - daysAgo]++;
        }
      }
    }

    return result;
  }

  /// Get lifetime total scan count
  static Future<int> getLifetimeStats() async {
    final userId = AuthService.userId;
    if (userId == null) return 0;

    final data = await _db
        .from(_table)
        .select('id')
        .eq('user_id', userId);

    return (data as List).length;
  }

  /// Get average health score
  static Future<int> getAverageHealthScore() async {
    final userId = AuthService.userId;
    if (userId == null) return 0;

    final since = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();

    final data = await _db
        .from(_table)
        .select('health_score')
        .eq('user_id', userId)
        .gte('scanned_at', since);

    final rows = data as List;
    if (rows.isEmpty) return 0;

    final total = rows.fold<int>(0, (sum, r) => sum + ((r['health_score'] ?? 0) as int));
    return (total / rows.length).round();
  }
}

/// Model for a user scan record
class UserScan {
  final String id;
  final String barcode;
  final String productName;
  final String? brand;
  final String? category;
  final int healthScore;
  final String verdict;
  final int additivesCount;
  final String intent;
  final DateTime scannedAt;
  final DateTime? purchaseDate;

  UserScan({
    required this.id,
    required this.barcode,
    required this.productName,
    this.brand,
    this.category,
    required this.healthScore,
    required this.verdict,
    required this.additivesCount,
    required this.intent,
    required this.scannedAt,
    this.purchaseDate,
  });

  factory UserScan.fromJson(Map<String, dynamic> json) {
    return UserScan(
      id: json['id'] ?? '',
      barcode: json['barcode'] ?? '',
      productName: json['product_name'] ?? 'Unknown',
      brand: json['brand'],
      category: json['category'],
      healthScore: json['health_score'] ?? 0,
      verdict: json['verdict'] ?? 'Unknown',
      additivesCount: json['additives_count'] ?? 0,
      intent: json['intent'] ?? 'checked',
      scannedAt: DateTime.tryParse(json['scanned_at'] ?? '') ?? DateTime.now(),
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'])
          : null,
    );
  }

  /// Time ago string (e.g., "2h ago", "3d ago")
  String get timeAgo {
    final diff = DateTime.now().difference(scannedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }
}

/// Stats model for dashboard
class ScanStats {
  final int scanned;
  final int consumed;
  final int avoided;
  final int purchased;

  ScanStats({
    required this.scanned,
    required this.consumed,
    required this.avoided,
    this.purchased = 0,
  });

  factory ScanStats.empty() => ScanStats(scanned: 0, consumed: 0, avoided: 0, purchased: 0);
}

/// Health score distribution model
class HealthDistribution {
  final int good;
  final int moderate;
  final int poor;

  HealthDistribution({required this.good, required this.moderate, required this.poor});
}
