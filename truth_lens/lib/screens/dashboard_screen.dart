import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/scan_history_service.dart';
import 'product_result_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  ScanStats _stats = ScanStats.empty();
  HealthDistribution _healthDist = HealthDistribution(good: 0, moderate: 0, poor: 0);
  List<int> _weeklyActivity = List.filled(7, 0);
  List<UserScan> _topProducts = [];
  List<UserScan> _purchases = [];
  int _avgHealthScore = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        ScanHistoryService.getLast30DaysStats(),
        ScanHistoryService.getHealthScoreDistribution(),
        ScanHistoryService.getWeeklyActivity(),
        ScanHistoryService.getTopProducts(limit: 5),
        ScanHistoryService.getPurchaseHistory(),
        ScanHistoryService.getAverageHealthScore(),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as ScanStats;
          _healthDist = results[1] as HealthDistribution;
          _weeklyActivity = results[2] as List<int>;
          _topProducts = results[3] as List<UserScan>;
          _purchases = results[4] as List<UserScan>;
          _avgHealthScore = results[5] as int;
          _loading = false;
        });
      }
    } catch (e) {
      print('⚠️ Dashboard load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      const Text('Analytics', style: AppTextStyles.heading1),
                      const SizedBox(height: 4),
                      Text(
                        'Last 30 days overview',
                        style: AppTextStyles.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      // Summary cards
                      _buildSummaryCards(),
                      const SizedBox(height: AppSpacing.lg),

                      // Health score distribution
                      _buildHealthDistribution(),
                      const SizedBox(height: AppSpacing.lg),

                      // Weekly activity
                      _buildWeeklyChart(),
                      const SizedBox(height: AppSpacing.lg),

                      // Recent products
                      _buildTopProducts(),
                      const SizedBox(height: AppSpacing.lg),

                      // Purchase history
                      _buildPurchaseHistory(),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Total Scans',
                value: '${_stats.scanned}',
                icon: Icons.qr_code_scanner,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Avg Score',
                value: '$_avgHealthScore',
                icon: Icons.speed,
                color: AppColors.getScoreColor(_avgHealthScore),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Purchased',
                value: '${_stats.purchased}',
                icon: Icons.shopping_bag,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                title: 'Avoided',
                value: '${_stats.avoided}',
                icon: Icons.not_interested,
                color: AppColors.scorePoor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(title, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildHealthDistribution() {
    final total = _healthDist.good + _healthDist.moderate + _healthDist.poor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Score Distribution',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          // Stacked bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 20,
              child: total > 0
                  ? Row(
                      children: [
                        if (_healthDist.good > 0)
                          Expanded(
                            flex: _healthDist.good,
                            child: Container(color: AppColors.scoreGood),
                          ),
                        if (_healthDist.moderate > 0)
                          Expanded(
                            flex: _healthDist.moderate,
                            child: Container(color: AppColors.scoreModerate),
                          ),
                        if (_healthDist.poor > 0)
                          Expanded(
                            flex: _healthDist.poor,
                            child: Container(color: AppColors.scorePoor),
                          ),
                      ],
                    )
                  : Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDistLabel('Good (75+)', '${_healthDist.good}', AppColors.scoreGood),
              _buildDistLabel('Moderate', '${_healthDist.moderate}', AppColors.scoreModerate),
              _buildDistLabel('Poor (<50)', '${_healthDist.poor}', AppColors.scorePoor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistLabel(String label, String count, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(height: 6),
        Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
      ],
    );
  }

  Widget _buildWeeklyChart() {
    final maxCount = _weeklyActivity.reduce((a, b) => a > b ? a : b);
    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Activity',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final count = _weeklyActivity[i];
                final barHeight = maxCount > 0 ? (count / maxCount) * 100 : 0.0;
                final isToday = i == 6;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isToday ? AppColors.primary : AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: barHeight < 8 && count > 0 ? 8 : barHeight,
                          decoration: BoxDecoration(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dayLabels[i],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                            color: isToday ? AppColors.primary : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Products',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_topProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text('No products scanned yet', style: AppTextStyles.bodySmall),
              ),
            )
          else
            ...List.generate(_topProducts.length, (i) {
              final product = _topProducts[i];
              final scoreColor = AppColors.getScoreColor(product.healthScore);
              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductResultScreen(barcode: product.barcode),
                    ),
                  );
                  _loadData();
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${product.healthScore}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: scoreColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.productName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (product.brand != null)
                              Text(product.brand!, style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.textTertiary),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPurchaseHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Purchase History',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_purchases.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 32, color: AppColors.textTertiary),
                    const SizedBox(height: 8),
                    Text('No purchases recorded yet', style: AppTextStyles.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      'Mark products as purchased from the scan page',
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_purchases.length, (i) {
              final purchase = _purchases[i];
              final dateStr = purchase.purchaseDate != null
                  ? '${purchase.purchaseDate!.day}/${purchase.purchaseDate!.month}/${purchase.purchaseDate!.year}'
                  : purchase.timeAgo;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 18,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            purchase.productName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(dateStr, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
