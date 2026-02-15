import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/scan_history_service.dart';
import 'product_result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<UserScan> _scans = [];
  bool _loading = true;
  String _filter = 'all'; // all / consumed / avoided

  @override
  void initState() {
    super.initState();
    _loadScans();
  }

  Future<void> _loadScans() async {
    setState(() => _loading = true);
    try {
      final scans = await ScanHistoryService.getScanHistory(
        limit: 50,
        intentFilter: _filter,
      );
      if (mounted) {
        setState(() {
          _scans = scans;
          _loading = false;
        });
      }
    } catch (e) {
      print('⚠️ Could not load history: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Scan History'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Purchased', 'purchased'),
                const SizedBox(width: 8),
                _buildFilterChip('Consumed', 'consumed'),
                const SizedBox(width: 8),
                _buildFilterChip('Avoided', 'avoided'),
              ],
            ),
          ),

          // Scan list
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  )
                : _scans.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadScans,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _scans.length,
                          itemBuilder: (context, index) =>
                              _buildScanItem(_scans[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isActive = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        _loadScans();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildScanItem(UserScan scan) {
    final verdictColor = scan.verdict == 'Good'
        ? AppColors.scoreGood
        : scan.verdict == 'Moderate'
            ? AppColors.scoreModerate
            : AppColors.scorePoor;

    final intentIcon = scan.intent == 'purchased'
        ? Icons.shopping_bag
        : scan.intent == 'consumed'
            ? Icons.restaurant
            : scan.intent == 'avoided'
                ? Icons.not_interested
                : Icons.visibility;

    final intentColor = scan.intent == 'purchased'
        ? const Color(0xFF3B82F6)
        : scan.intent == 'consumed'
            ? AppColors.primary
            : scan.intent == 'avoided'
                ? AppColors.scorePoor
                : AppColors.textTertiary;

    final intentLabel = scan.intent == 'purchased'
        ? 'Purchased'
        : scan.intent == 'consumed'
            ? 'Consumed'
            : scan.intent == 'avoided'
                ? 'Avoided'
                : 'Viewed';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductResultScreen(barcode: scan.barcode),
          ),
        );
        _loadScans();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            // Health score badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: verdictColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  '${scan.healthScore}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: verdictColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.productName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (scan.brand != null) ...[
                        Flexible(
                          child: Text(
                            scan.brand!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Text(' · ',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textTertiary)),
                      ],
                      Text(
                        scan.timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Intent & additives count
                  Row(
                    children: [
                      Icon(intentIcon, size: 12, color: intentColor),
                      const SizedBox(width: 4),
                      Text(
                        intentLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: intentColor,
                        ),
                      ),
                      if (scan.additivesCount > 0) ...[
                        const Text(' · ',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary)),
                        Text(
                          '${scan.additivesCount} additives',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📋', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          Text(
            _filter == 'all'
                ? 'No scans yet'
                : 'No ${_filter} products',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 8),
          Text(
            _filter == 'all'
                ? 'Scan a product to start tracking'
                : 'Products you mark as $_filter will appear here',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
