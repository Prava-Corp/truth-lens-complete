import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Service for communicating with Truth Lens backend
class ApiService {
  /// Backend URL — deployed on Render
  static const String baseUrl = 'https://truth-lens-complete.onrender.com';
  
  /// Fetch product by barcode
  static Future<ProductResponse?> getProduct(String barcode) async {
    final url = '$baseUrl/product?barcode=$barcode';
    
    try {
      print('🔍 Fetching: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      
      print('📥 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for error response
        if (data['error'] != null) {
          print('❌ API Error: ${data['error']}');
          return null;
        }
        
        print('✅ Product found: ${data['product_name']}');
        return ProductResponse.fromJson(data);
      }
      
      print('❌ HTTP Error: ${response.statusCode}');
      return null;
      
    } catch (e) {
      print('❌ Network Error: $e');
      return null;
    }
  }
}

/// Product response model
class ProductResponse {
  final String? barcode;
  final String productName;
  final String? brand;
  final String? category;
  final String ingredients;
  final List<String> additives;
  final List<ProductFlag> flags;
  final List<FssaiFinding> fssaiFindings;
  final FssaiSummary? fssaiSummary;

  ProductResponse({
    this.barcode,
    required this.productName,
    this.brand,
    this.category,
    required this.ingredients,
    required this.additives,
    required this.flags,
    this.fssaiFindings = const [],
    this.fssaiSummary,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    // Parse FSSAI data
    final fssaiData = json['fssai'] as Map<String, dynamic>?;
    List<FssaiFinding> fssaiFindings = [];
    FssaiSummary? fssaiSummary;

    if (fssaiData != null) {
      fssaiFindings = (fssaiData['findings'] as List?)
          ?.map((f) => FssaiFinding.fromJson(f))
          .toList() ?? [];
      if (fssaiData['summary'] != null) {
        fssaiSummary = FssaiSummary.fromJson(fssaiData['summary']);
      }
    }

    return ProductResponse(
      barcode: json['barcode'],
      productName: json['product_name'] ?? 'Unknown Product',
      brand: json['brand'],
      category: json['category'],
      ingredients: json['ingredients'] ?? 'Ingredients not available',
      additives: List<String>.from(json['additives'] ?? []),
      flags: (json['flags'] as List?)
          ?.map((f) => ProductFlag.fromJson(f))
          .toList() ?? [],
      fssaiFindings: fssaiFindings,
      fssaiSummary: fssaiSummary,
    );
  }

  /// Calculate health score (0-100)
  int get healthScore {
    int score = 85;
    
    // Deduct for flags
    for (var flag in flags) {
      switch (flag.flagType.toLowerCase()) {
        case 'banned':
          score -= 30;
          break;
        case 'restricted':
          score -= 15;
          break;
        case 'warning':
          score -= 10;
          break;
      }
    }
    
    // Deduct for additives
    for (var additive in additives) {
      final code = additive.toUpperCase();
      
      // High concern additives
      if (['E621', 'E631', 'E627', 'E951', 'E950'].contains(code)) {
        score -= 8;
      }
      // Artificial colors
      else if (['E102', 'E110', 'E129', 'E133', 'E150D'].contains(code)) {
        score -= 10;
      }
      // Preservatives
      else if (['E211', 'E220', 'E250', 'E320', 'E321'].contains(code)) {
        score -= 7;
      }
      // Other additives
      else {
        score -= 2;
      }
    }
    
    return score.clamp(0, 100);
  }

  /// Get verdict based on score
  String get verdict {
    if (healthScore >= 75) return 'Good';
    if (healthScore >= 50) return 'Moderate';
    return 'Poor';
  }
}

/// Product flag model
class ProductFlag {
  final String flagType;
  final String explanation;
  final String? region;

  ProductFlag({
    required this.flagType,
    required this.explanation,
    this.region,
  });

  factory ProductFlag.fromJson(Map<String, dynamic> json) {
    return ProductFlag(
      flagType: json['flag_type'] ?? 'warning',
      explanation: json['explanation'] ?? '',
      region: json['region'],
    );
  }
}

/// Additive information database
class AdditiveInfo {
  final String code;
  final String name;
  final String description;
  final String riskLevel;
  final Map<String, String> regulatoryStatus;

  AdditiveInfo({
    required this.code,
    required this.name,
    required this.description,
    required this.riskLevel,
    required this.regulatoryStatus,
  });

  /// Get additive info by code
  static AdditiveInfo? getInfo(String code) {
    return _database[code.toUpperCase()];
  }

  static final Map<String, AdditiveInfo> _database = {
    'E100': AdditiveInfo(
      code: 'E100',
      name: 'Curcumin',
      description: 'Natural yellow color from turmeric. Generally safe.',
      riskLevel: 'low',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Permitted', 'US': 'GRAS'},
    ),
    'E102': AdditiveInfo(
      code: 'E102',
      name: 'Tartrazine',
      description: 'Synthetic yellow dye. May cause allergic reactions.',
      riskLevel: 'moderate',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Warning required', 'US': 'Permitted'},
    ),
    'E110': AdditiveInfo(
      code: 'E110',
      name: 'Sunset Yellow',
      description: 'Synthetic dye linked to hyperactivity in children.',
      riskLevel: 'moderate',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Warning required', 'US': 'Permitted'},
    ),
    'E150D': AdditiveInfo(
      code: 'E150D',
      name: 'Caramel Color',
      description: 'Coloring in colas. Contains 4-MEI compound.',
      riskLevel: 'moderate',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Permitted', 'US': 'Permitted'},
    ),
    'E211': AdditiveInfo(
      code: 'E211',
      name: 'Sodium Benzoate',
      description: 'Preservative that may form benzene with vitamin C.',
      riskLevel: 'moderate',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Permitted', 'US': 'GRAS'},
    ),
    'E250': AdditiveInfo(
      code: 'E250',
      name: 'Sodium Nitrite',
      description: 'Preservative in meats. May form carcinogens.',
      riskLevel: 'high',
      regulatoryStatus: {'IN': 'Limited', 'EU': 'Limited', 'US': 'Permitted'},
    ),
    'E320': AdditiveInfo(
      code: 'E320',
      name: 'BHA',
      description: 'Antioxidant preservative. Possible carcinogen.',
      riskLevel: 'high',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Limited', 'US': 'GRAS'},
    ),
    'E322': AdditiveInfo(
      code: 'E322',
      name: 'Lecithin',
      description: 'Natural emulsifier from soy or eggs. Safe.',
      riskLevel: 'low',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Permitted', 'US': 'GRAS'},
    ),
    'E330': AdditiveInfo(
      code: 'E330',
      name: 'Citric Acid',
      description: 'Natural acid from citrus. Used as preservative.',
      riskLevel: 'low',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Permitted', 'US': 'GRAS'},
    ),
    'E500': AdditiveInfo(
      code: 'E500',
      name: 'Sodium Carbonate',
      description: 'Baking soda. Raising agent. Safe.',
      riskLevel: 'low',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Permitted', 'US': 'GRAS'},
    ),
    'E503': AdditiveInfo(
      code: 'E503',
      name: 'Ammonium Carbonate',
      description: 'Raising agent in baking. Safe.',
      riskLevel: 'low',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Permitted', 'US': 'GRAS'},
    ),
    'E621': AdditiveInfo(
      code: 'E621',
      name: 'MSG (Monosodium Glutamate)',
      description: 'Flavor enhancer. May cause sensitivity in some.',
      riskLevel: 'moderate',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Limited', 'US': 'GRAS'},
    ),
    'E627': AdditiveInfo(
      code: 'E627',
      name: 'Disodium Guanylate',
      description: 'Flavor enhancer. Avoid if gout-prone.',
      riskLevel: 'moderate',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Permitted', 'US': 'GRAS'},
    ),
    'E631': AdditiveInfo(
      code: 'E631',
      name: 'Disodium Inosinate',
      description: 'Flavor enhancer. Avoid with gout.',
      riskLevel: 'moderate',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Permitted', 'US': 'GRAS'},
    ),
    'E951': AdditiveInfo(
      code: 'E951',
      name: 'Aspartame',
      description: 'Artificial sweetener. Possibly carcinogenic.',
      riskLevel: 'moderate',
      regulatoryStatus: {'IN': 'Permitted', 'EU': 'Permitted', 'US': 'Permitted'},
    ),
  };
}

/// FSSAI Finding model - one per additive checked
class FssaiFinding {
  final String code;
  final String name;
  final String fssaiStatus;  // "permitted", "restricted", "banned", "not_listed"
  final String category;
  final String maxLimit;
  final String healthConcern;
  final String fssaiNote;
  final int severity;  // 0-5

  FssaiFinding({
    required this.code,
    required this.name,
    required this.fssaiStatus,
    required this.category,
    required this.maxLimit,
    required this.healthConcern,
    required this.fssaiNote,
    required this.severity,
  });

  factory FssaiFinding.fromJson(Map<String, dynamic> json) {
    return FssaiFinding(
      code: json['code'] ?? '',
      name: json['name'] ?? 'Unknown',
      fssaiStatus: json['fssai_status'] ?? 'not_listed',
      category: json['category'] ?? 'unknown',
      maxLimit: json['max_limit'] ?? 'unknown',
      healthConcern: json['health_concern'] ?? '',
      fssaiNote: json['fssai_note'] ?? '',
      severity: json['severity'] ?? 0,
    );
  }
}

/// FSSAI Summary model - overall product assessment
class FssaiSummary {
  final String overallStatus;
  final String concernLevel;  // "safe", "low", "moderate", "high"
  final int bannedCount;
  final int restrictedCount;
  final int permittedCount;
  final int unknownCount;
  final int totalAdditives;

  FssaiSummary({
    required this.overallStatus,
    required this.concernLevel,
    required this.bannedCount,
    required this.restrictedCount,
    required this.permittedCount,
    required this.unknownCount,
    required this.totalAdditives,
  });

  factory FssaiSummary.fromJson(Map<String, dynamic> json) {
    return FssaiSummary(
      overallStatus: json['overall_status'] ?? '',
      concernLevel: json['concern_level'] ?? 'safe',
      bannedCount: json['banned_count'] ?? 0,
      restrictedCount: json['restricted_count'] ?? 0,
      permittedCount: json['permitted_count'] ?? 0,
      unknownCount: json['unknown_count'] ?? 0,
      totalAdditives: json['total_additives'] ?? 0,
    );
  }
}
