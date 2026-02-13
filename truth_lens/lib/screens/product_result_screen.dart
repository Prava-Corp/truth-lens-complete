import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class ProductResultScreen extends StatefulWidget {
  final String barcode;

  const ProductResultScreen({super.key, required this.barcode});

  @override
  State<ProductResultScreen> createState() => _ProductResultScreenState();
}

class _ProductResultScreenState extends State<ProductResultScreen> {
  ProductResponse? _product;
  bool _loading = true;
  String? _error;
  bool _ingredientsExpanded = false;
  int? _expandedAdditiveIndex;

  @override
  void initState() {
    super.initState();
    _fetchProduct();
  }

  Future<void> _fetchProduct() async {
    try {
      final product = await ApiService.getProduct(widget.barcode);
      setState(() {
        _product = product;
        _loading = false;
        if (product == null) {
          _error = 'Product not found';
        }
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Failed to load: $e';
      });
    }
  }

  // Merge FSSAI findings with additive codes for unified display
  List<_UnifiedAdditive> get _unifiedAdditives {
    final fssaiMap = <String, FssaiFinding>{};
    for (final f in _product!.fssaiFindings) {
      fssaiMap[f.code.toUpperCase()] = f;
    }

    final result = <_UnifiedAdditive>[];
    for (final code in _product!.additives) {
      final normalized = code.toUpperCase();
      final fssai = fssaiMap[normalized];
      final localInfo = AdditiveInfo.getInfo(code);
      result.add(_UnifiedAdditive(
        code: normalized,
        name: fssai?.name ?? localInfo?.name ?? 'Unknown',
        fssaiStatus: fssai?.fssaiStatus ?? 'not_listed',
        category: fssai?.category ?? 'unknown',
        maxLimit: fssai?.maxLimit ?? 'unknown',
        healthConcern: fssai?.healthConcern ?? localInfo?.description ?? '',
        fssaiNote: fssai?.fssaiNote ?? '',
        severity: fssai?.severity ?? 0,
      ));
    }

    // Sort: highest severity first
    result.sort((a, b) => b.severity.compareTo(a.severity));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingScreen();
    if (_error != null || _product == null) return _buildErrorScreen();

    final unified = _unifiedAdditives;
    final concerning = unified.where((a) => a.severity >= 2).toList();
    final safe = unified.where((a) => a.severity < 2).toList();
    final hasConcerns = concerning.isNotEmpty || _product!.flags.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppColors.background,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1) Product header
                  _buildProductHeader(),
                  const SizedBox(height: 16),

                  // 2) Quick verdict banner
                  _buildVerdictBanner(unified),
                  const SizedBox(height: 20),

                  // 3) Ingredients (collapsed by default)
                  _buildCollapsibleIngredients(),
                  const SizedBox(height: 20),

                  // 4) Concerning additives (full cards)
                  if (concerning.isNotEmpty) ...[
                    _buildSectionTitle(
                      'Needs Attention (${concerning.length})',
                      Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: 10),
                    ...concerning.asMap().entries.map((e) =>
                      _buildConcerningAdditiveCard(e.value, e.key)),
                    const SizedBox(height: 20),
                  ],

                  // 5) Flags / What You Should Know (compact)
                  if (_product!.flags.isNotEmpty) ...[
                    _buildSectionTitle('Alerts', Icons.notifications_outlined),
                    const SizedBox(height: 10),
                    ..._product!.flags.map((f) => _buildCompactFlag(f)),
                    const SizedBox(height: 20),
                  ],

                  // 6) Safe additives (compact chips)
                  if (safe.isNotEmpty) ...[
                    _buildSectionTitle(
                      'Safe Additives (${safe.length})',
                      Icons.check_circle_outline,
                    ),
                    const SizedBox(height: 10),
                    _buildSafeAdditiveChips(safe),
                    const SizedBox(height: 20),
                  ],

                  // 7) All clear
                  if (!hasConcerns && unified.isEmpty)
                    _buildNoConcernsCard(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 1) PRODUCT HEADER - compact
  // ============================================================
  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                _getProductEmoji(_product!.category),
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _product!.productName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_product!.brand != null)
                  Text(_product!.brand!, style: AppTextStyles.bodySmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (_product!.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _product!.category!.split(',').first.trim(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.barcode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 2) VERDICT BANNER - instant glance
  // ============================================================
  Widget _buildVerdictBanner(List<_UnifiedAdditive> unified) {
    final summary = _product!.fssaiSummary;
    final hasBanned = unified.any((a) => a.fssaiStatus == 'banned');
    final hasRestricted = unified.any((a) => a.severity >= 3);
    final concernCount = unified.where((a) => a.severity >= 2).length;

    Color color;
    IconData icon;
    String title;
    String subtitle;

    if (hasBanned) {
      color = const Color(0xFFEF4444);
      icon = Icons.dangerous_outlined;
      title = 'Contains Banned Additives';
      subtitle = 'This product has additives banned by FSSAI';
    } else if (hasRestricted) {
      color = const Color(0xFFF59E0B);
      icon = Icons.warning_amber_rounded;
      title = '$concernCount Additive${concernCount == 1 ? '' : 's'} Need Attention';
      subtitle = summary?.overallStatus ?? 'Some additives have health concerns';
    } else if (unified.isNotEmpty) {
      color = const Color(0xFF22C55E);
      icon = Icons.verified_outlined;
      title = 'All Additives Safe';
      subtitle = 'All ${unified.length} additives are FSSAI permitted';
    } else {
      color = const Color(0xFF22C55E);
      icon = Icons.eco_outlined;
      title = 'No Additives Found';
      subtitle = 'This product appears to be additive-free';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // Quick count badges
          if (summary != null) ...[
            Column(
              children: [
                if (summary.bannedCount > 0)
                  _miniCountBadge('${summary.bannedCount}', const Color(0xFFEF4444)),
                if (summary.restrictedCount > 0)
                  _miniCountBadge('${summary.restrictedCount}', const Color(0xFFF59E0B)),
                if (summary.permittedCount > 0)
                  _miniCountBadge('${summary.permittedCount}', const Color(0xFF22C55E)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniCountBadge(String count, Color color) {
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          count,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color),
        ),
      ),
    );
  }

  // ============================================================
  // 3) COLLAPSIBLE INGREDIENTS
  // ============================================================
  Widget _buildCollapsibleIngredients() {
    final rawText = _product!.ingredients;
    final isLong = rawText.length > 100;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          // Header - always visible, tappable
          InkWell(
            onTap: () => setState(() => _ingredientsExpanded = !_ingredientsExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Ingredients',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Preview count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.divider.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_product!.additives.length} additives',
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _ingredientsExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Collapsed: show preview line
          if (!_ingredientsExpanded && isLong)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                rawText.substring(0, rawText.length.clamp(0, 80)) + '...',
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, height: 1.4),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Expanded: full ingredients with color coding
          if (_ingredientsExpanded || !isLong) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: _buildColorCodedIngredients(rawText),
            ),
            // Legend
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendDot(const Color(0xFF374151), 'Base'),
                  const SizedBox(width: 16),
                  _buildLegendDot(const Color(0xFFE85D04), 'Additives'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildColorCodedIngredients(String rawText) {
    final eCodePattern = RegExp(r'E\d{3,4}[a-z]?(?:\s*\([ivIV]+\))?', caseSensitive: false);
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in eCodePattern.allMatches(rawText)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: rawText.substring(lastEnd, match.start),
          style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF374151)),
        ));
      }
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: const Color(0xFFE85D04).withOpacity(0.12),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            match.group(0)!,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFE85D04)),
          ),
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < rawText.length) {
      spans.add(TextSpan(
        text: rawText.substring(lastEnd),
        style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF374151)),
      ));
    }

    if (spans.isEmpty) {
      return Text(rawText, style: const TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF374151)));
    }
    return RichText(text: TextSpan(children: spans));
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textPrimary),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 4) CONCERNING ADDITIVE CARDS - expandable
  // ============================================================
  Widget _buildConcerningAdditiveCard(_UnifiedAdditive additive, int index) {
    final isExpanded = _expandedAdditiveIndex == index;
    final color = _severityColor(additive);
    final statusLabel = _statusLabel(additive.fssaiStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          // Header row - always visible, tappable
          InkWell(
            onTap: () => setState(() {
              _expandedAdditiveIndex = isExpanded ? null : index;
            }),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Severity indicator dot
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        additive.code,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Name + one-line concern
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          additive.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          additive.healthConcern,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                          maxLines: isExpanded ? 10 : 1,
                          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Status pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textTertiary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Expanded detail
          if (isExpanded) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 10),
                  // Tags row
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildTag(Icons.category_outlined, additive.category),
                      if (additive.maxLimit != 'unknown')
                        _buildTag(Icons.speed, additive.maxLimit == 'GMP' ? 'GMP' : 'Limit: ${additive.maxLimit}'),
                    ],
                  ),
                  // FSSAI note
                  if (additive.fssaiNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🇮🇳', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              additive.fssaiNote,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF92400E),
                                height: 1.3,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.divider.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.textTertiary),
          const SizedBox(width: 3),
          Text(text, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ============================================================
  // 5) COMPACT FLAGS
  // ============================================================
  Widget _buildCompactFlag(ProductFlag flag) {
    Color color;
    IconData icon;
    switch (flag.flagType) {
      case 'banned':
        color = const Color(0xFFEF4444);
        icon = Icons.block;
        break;
      case 'restricted':
        color = const Color(0xFFF59E0B);
        icon = Icons.warning_amber_rounded;
        break;
      default:
        color = const Color(0xFF3B82F6);
        icon = Icons.info_outline;
    }

    String regionFlag = '';
    if (flag.region != null) {
      switch (flag.region!.toUpperCase()) {
        case 'INDIA': regionFlag = '🇮🇳'; break;
        case 'EU': regionFlag = '🇪🇺'; break;
        case 'FDA': regionFlag = '🇺🇸'; break;
        default: regionFlag = '🌍';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              flag.explanation,
              style: TextStyle(fontSize: 12, height: 1.4, color: color.withOpacity(0.9)),
            ),
          ),
          if (regionFlag.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(regionFlag, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 6) SAFE ADDITIVE CHIPS - compact, one row
  // ============================================================
  Widget _buildSafeAdditiveChips(List<_UnifiedAdditive> safeAdditives) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8),
        ],
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: safeAdditives.map((a) {
          return Tooltip(
            message: '${a.name}: ${a.healthConcern}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check, size: 12, color: Color(0xFF22C55E)),
                  const SizedBox(width: 4),
                  Text(
                    '${a.code}  ${a.name}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // 7) NO CONCERNS
  // ============================================================
  Widget _buildNoConcernsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          const Text('🌿', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 10),
          const Text(
            'Looking Clean!',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF166534)),
          ),
          const SizedBox(height: 4),
          Text(
            'No additives or concerns detected.',
            style: TextStyle(fontSize: 13, color: const Color(0xFF166534).withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  Color _severityColor(_UnifiedAdditive a) {
    if (a.fssaiStatus == 'banned') return const Color(0xFFEF4444);
    if (a.severity >= 4) return const Color(0xFFEF4444);
    if (a.severity >= 3) return const Color(0xFFF59E0B);
    if (a.severity >= 2) return const Color(0xFFF59E0B);
    return const Color(0xFF22C55E);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'banned': return 'BANNED';
      case 'restricted': return 'RESTRICTED';
      case 'permitted': return 'PERMITTED';
      default: return 'UNKNOWN';
    }
  }

  String _getProductEmoji(String? category) {
    if (category == null) return '📦';
    final cat = category.toLowerCase();
    if (cat.contains('biscuit') || cat.contains('cookie')) return '🍪';
    if (cat.contains('noodle') || cat.contains('pasta')) return '🍜';
    if (cat.contains('snack') || cat.contains('chip')) return '🥨';
    if (cat.contains('drink') || cat.contains('beverage')) return '🥤';
    if (cat.contains('milk') || cat.contains('dairy')) return '🥛';
    if (cat.contains('bread')) return '🍞';
    if (cat.contains('chocolate') || cat.contains('candy')) return '🍫';
    if (cat.contains('juice')) return '🧃';
    if (cat.contains('tea') || cat.contains('coffee')) return '☕';
    return '📦';
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)),
            ),
            const SizedBox(height: 20),
            Text('Analyzing product...', style: AppTextStyles.heading3),
            const SizedBox(height: 6),
            Text('Checking ingredients & FSSAI regulations', style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 20),
              Text('Product Not Found', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Text(
                'We couldn\'t find this product.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(8)),
                child: Text(widget.barcode, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Scan Another'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Unified additive model (merged from FSSAI + local info)
// ============================================================
class _UnifiedAdditive {
  final String code;
  final String name;
  final String fssaiStatus;
  final String category;
  final String maxLimit;
  final String healthConcern;
  final String fssaiNote;
  final int severity;

  _UnifiedAdditive({
    required this.code,
    required this.name,
    required this.fssaiStatus,
    required this.category,
    required this.maxLimit,
    required this.healthConcern,
    required this.fssaiNote,
    required this.severity,
  });
}
