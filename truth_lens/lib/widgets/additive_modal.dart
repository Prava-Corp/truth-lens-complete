import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class AdditiveModal extends StatelessWidget {
  final String code;
  final AdditiveInfo? info;

  const AdditiveModal({super.key, required this.code, this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSection('What is it?', info?.description ?? 'No information available.'),
                  const SizedBox(height: 24),
                  _buildHealthImpact(),
                  const SizedBox(height: 24),
                  _buildRegulatoryStatus(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: _getGradient(),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              code,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(info?.name ?? 'Unknown Additive', style: AppTextStyles.heading3),
              const SizedBox(height: 4),
              _buildRiskBadge(),
            ],
          ),
        ),
      ],
    );
  }

  LinearGradient _getGradient() {
    switch (info?.riskLevel) {
      case 'low': return AppColors.getScoreGradient(80);
      case 'moderate': return AppColors.getScoreGradient(60);
      case 'high': return AppColors.getScoreGradient(30);
      default: return LinearGradient(colors: [AppColors.textSecondary, AppColors.textTertiary]);
    }
  }

  Widget _buildRiskBadge() {
    Color color;
    String text;
    
    switch (info?.riskLevel) {
      case 'low':
        color = AppColors.scoreGood;
        text = 'Low Risk';
        break;
      case 'moderate':
        color = AppColors.scoreModerate;
        text = 'Moderate Concern';
        break;
      case 'high':
        color = AppColors.scorePoor;
        text = 'High Risk';
        break;
      default:
        color = AppColors.textTertiary;
        text = 'Unknown Risk';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: AppTextStyles.label.copyWith(letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(content, style: AppTextStyles.body.copyWith(height: 1.6, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildHealthImpact() {
    final riskLevel = info?.riskLevel ?? 'unknown';
    Color color;
    String advice;
    IconData icon;
    
    switch (riskLevel) {
      case 'low':
        color = AppColors.scoreGood;
        advice = 'Generally safe for consumption.';
        icon = Icons.check_circle_outline;
        break;
      case 'moderate':
        color = AppColors.scoreModerate;
        advice = 'May cause issues for some. Limit intake if sensitive.';
        icon = Icons.info_outline;
        break;
      case 'high':
        color = AppColors.scorePoor;
        advice = 'Exercise caution. Consider alternatives.';
        icon = Icons.warning_amber_outlined;
        break;
      default:
        color = AppColors.textSecondary;
        advice = 'Insufficient data available.';
        icon = Icons.help_outline;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HEALTH IMPACT', style: AppTextStyles.label.copyWith(letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(child: Text(advice, style: AppTextStyles.body.copyWith(color: AppColors.textPrimary))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegulatoryStatus() {
    final status = info?.regulatoryStatus ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REGULATORY STATUS', style: AppTextStyles.label.copyWith(letterSpacing: 1)),
        const SizedBox(height: 12),
        if (status.isEmpty)
          Text('No regulatory info available', style: AppTextStyles.bodySmall)
        else
          ...status.entries.map((e) => _buildStatusRow(e.key, e.value)),
      ],
    );
  }

  Widget _buildStatusRow(String region, String status) {
    String flag;
    String name;
    
    switch (region) {
      case 'IN':
        flag = '🇮🇳';
        name = 'India (FSSAI)';
        break;
      case 'EU':
        flag = '🇪🇺';
        name = 'European Union';
        break;
      case 'US':
        flag = '🇺🇸';
        name = 'USA (FDA)';
        break;
      default:
        flag = '🌍';
        name = region;
    }

    Color statusColor = status.toLowerCase().contains('limit') || status.toLowerCase().contains('warning')
        ? AppColors.scoreModerate
        : AppColors.scoreGood;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.divider.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: AppTextStyles.body)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ],
      ),
    );
  }
}
