import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/auth_service.dart';
import '../services/scan_history_service.dart';
import 'camera_scan_screen.dart';
import 'manual_scan_screen.dart';
import 'product_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _greeting = '';
  ScanStats _stats = ScanStats.empty();
  List<UserScan> _recentScans = [];
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    _loadData();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _loadData() async {
    try {
      final stats = await ScanHistoryService.getLast30DaysStats();
      final recent = await ScanHistoryService.getRecentScans(limit: 5);
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentScans = recent;
          _loadingStats = false;
        });
      }
    } catch (e) {
      print('⚠️ Could not load stats: $e');
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background decorations
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStatsCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildScanButton(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildQuickActions(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildRecentScans(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final email = AuthService.userEmail ?? '';
    final name = email.split('@').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📍 Hyderabad, India',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Hi $name,',
          style: AppTextStyles.heading1,
        ),
        Text(
          '$_greeting ☀️',
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('📊', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                'Last 30 Days',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _loadingStats
              ? const SizedBox(
                  height: 40,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                )
              : Row(
                  children: [
                    _buildStatItem('${_stats.scanned}', 'Scanned'),
                    _buildStatDivider(),
                    _buildStatItem('${_stats.consumed}', 'Consumed',
                        color: AppColors.primary),
                    _buildStatDivider(),
                    _buildStatItem('${_stats.avoided}', 'Avoided',
                        color: AppColors.scorePoor),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, {Color? color}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.divider,
    );
  }

  Widget _buildScanButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CameraScanScreen()),
        );
        // Refresh data when coming back from scan
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Text('📷', style: TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan a Product',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Know what you're consuming",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ManualScanScreen()),
        );
        _loadData();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('⌨️', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manual Entry',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                ),
                Text('Type barcode manually', style: AppTextStyles.bodySmall),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentScans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recent Scans', style: AppTextStyles.heading3),
            if (_recentScans.isNotEmpty)
              Text(
                'See History tab',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_loadingStats)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            ),
          )
        else if (_recentScans.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                const Text('🔍', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text('No scans yet', style: AppTextStyles.heading3),
                const SizedBox(height: 8),
                Text(
                  'Scan your first product to see it here',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ..._recentScans.map((scan) => _buildScanCard(scan)),
      ],
    );
  }

  Widget _buildScanCard(UserScan scan) {
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

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductResultScreen(barcode: scan.barcode),
          ),
        );
        _loadData();
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: verdictColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '${scan.healthScore}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: verdictColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.productName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (scan.brand != null) ...[
                        Text(
                          scan.brand!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const Text(' · ',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textTertiary)),
                      ],
                      Text(
                        scan.timeAgo,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Intent icon
            Icon(intentIcon, size: 18, color: intentColor),
          ],
        ),
      ),
    );
  }
}
