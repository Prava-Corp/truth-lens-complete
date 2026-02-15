import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../services/auth_service.dart';
import '../services/scan_history_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _lifetimeScans = 0;
  int _avgScore = 0;
  ScanStats _stats = ScanStats.empty();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ScanHistoryService.getLifetimeStats(),
        ScanHistoryService.getAverageHealthScore(),
        ScanHistoryService.getLast30DaysStats(),
      ]);
      if (mounted) {
        setState(() {
          _lifetimeScans = results[0] as int;
          _avgScore = results[1] as int;
          _stats = results[2] as ScanStats;
          _loading = false;
        });
      }
    } catch (e) {
      print('⚠️ Profile load error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.userEmail ?? 'Unknown';
    final name = email.split('@').first;

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
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Profile', style: AppTextStyles.heading1),
                    const SizedBox(height: AppSpacing.lg),

                    // Profile header card
                    _buildProfileHeader(name, email),
                    const SizedBox(height: AppSpacing.lg),

                    // Stats card
                    _buildStatsCard(),
                    const SizedBox(height: AppSpacing.lg),

                    // 30-day breakdown
                    _build30DayBreakdown(),
                    const SizedBox(height: AppSpacing.lg),

                    // Account info
                    _buildAccountInfo(email),
                    const SizedBox(height: AppSpacing.lg),

                    // App info
                    _buildAppInfo(),
                    const SizedBox(height: AppSpacing.lg),

                    // Logout button
                    _buildLogoutButton(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lifetime Stats',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatColumn(
                  '$_lifetimeScans',
                  'Products\nScanned',
                  Icons.qr_code_scanner,
                  AppColors.primary,
                ),
              ),
              Container(width: 1, height: 50, color: AppColors.divider),
              Expanded(
                child: _buildStatColumn(
                  '$_avgScore',
                  'Avg Health\nScore',
                  Icons.speed,
                  AppColors.getScoreColor(_avgScore),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _build30DayBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 30 Days',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildBreakdownRow(Icons.visibility, 'Scanned', '${_stats.scanned}', AppColors.textPrimary),
          const SizedBox(height: 10),
          _buildBreakdownRow(Icons.shopping_bag, 'Purchased', '${_stats.purchased}', const Color(0xFF3B82F6)),
          const SizedBox(height: 10),
          _buildBreakdownRow(Icons.restaurant, 'Consumed', '${_stats.consumed}', AppColors.primary),
          const SizedBox(height: 10),
          _buildBreakdownRow(Icons.not_interested, 'Avoided', '${_stats.avoided}', AppColors.scorePoor),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfo(String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.mail_outline, 'Email', email),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.cloud_done_outlined, 'Data', 'Synced to cloud'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.security_outlined, 'Auth', 'Supabase'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textTertiary),
        const SizedBox(width: 12),
        Text(label, style: AppTextStyles.bodySmall),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Info',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.info_outline, 'Version', '1.0.0'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.code, 'Backend', 'Render'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.storage, 'Database', 'Supabase'),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _showLogoutDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.scorePoor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.scorePoor.withOpacity(0.2)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20, color: AppColors.scorePoor),
            SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.scorePoor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: Text(
          'Signed in as ${AuthService.userEmail}\n\nAre you sure you want to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              AuthService.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.scorePoor),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
