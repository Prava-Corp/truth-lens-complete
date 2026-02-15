import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'api_service.dart';

/// Service for managing per-user scan history in Supabase
class ScanHistoryService {
  static SupabaseClient get _db => AuthService.client;
  static const String _table = 'user_scans';

  /// Save a scan to the user's history
  static Future<void> saveScan({
    required ProductResponse product,
    String intent = 'checked',
  }) async {
    final userId = AuthService.userId;
    if (userId == null) return;

    await _db.from(_table).insert({
      'user_id': userId,
      'barcode': product.barcode ?? '',
      'product_name': product.productName,
      'brand': product.brand,
      'category': product.category,
      'health_score': product.healthScore,
      'verdict': product.verdict,
      'additives_count': product.additives.length,
      'intent': intent,
    });
  }

  /// Update the intent of a scan (checked → consumed/avoided)
  static Future<void> updateIntent(String scanId, String intent) async {
    await _db.from(_table).update({'intent': intent}).eq('id', scanId);
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

    return ScanStats(scanned: scanned, consumed: consumed, avoided: avoided);
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

  ScanStats({
    required this.scanned,
    required this.consumed,
    required this.avoided,
  });

  factory ScanStats.empty() => ScanStats(scanned: 0, consumed: 0, avoided: 0);
}
