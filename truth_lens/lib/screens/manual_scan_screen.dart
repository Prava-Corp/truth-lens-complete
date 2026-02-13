import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import 'product_result_screen.dart';

class ManualScanScreen extends StatefulWidget {
  const ManualScanScreen({super.key});

  @override
  State<ManualScanScreen> createState() => _ManualScanScreenState();
}

class _ManualScanScreenState extends State<ManualScanScreen> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _isValid = _controller.text.length >= 5;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_isValid) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductResultScreen(barcode: _controller.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Enter Barcode'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Illustration
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🔢', style: TextStyle(fontSize: 70)),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            Text('Type the barcode number', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Enter the numbers below the barcode on your product',
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            
            const SizedBox(height: 32),
            
            // Input field
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
                ],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '8901234567890',
                  hintStyle: TextStyle(
                    fontSize: 24,
                    color: AppColors.textTertiary,
                    letterSpacing: 4,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            
            const SizedBox(height: 12),
            Center(
              child: Text(
                '${_controller.text.length} / 13 digits',
                style: AppTextStyles.bodySmall,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isValid ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.divider,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: Text(
                  'Check Product',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _isValid ? Colors.white : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Example barcodes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Try these examples',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildExample('8901063010116', 'Parle-G Biscuits'),
                  _buildExample('8901058858242', 'Maggi Noodles'),
                  _buildExample('8906002870059', 'Paper Boat'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExample(String barcode, String name) {
    return GestureDetector(
      onTap: () {
        _controller.text = barcode;
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                barcode,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: AppTextStyles.bodySmall)),
            const Icon(Icons.content_copy, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
