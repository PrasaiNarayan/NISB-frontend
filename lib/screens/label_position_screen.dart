import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LabelPositionDialog extends StatelessWidget {
  final String materialCode;
  final VoidCallback onClose;

  const LabelPositionDialog({
    super.key,
    required this.materialCode,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 560,
        height: 520,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Text('原料マスタ',
                    style: GoogleFonts.notoSansJp(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Text('ラベル貼り付け位置 ($materialCode)',
                    style: GoogleFonts.notoSansJp(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Zoom controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.zoom_out, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Text('100%', style: GoogleFonts.notoSansJp(fontSize: 12)),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.zoom_in, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Image area
            Expanded(
              child: Container(
                color: Colors.white,
                child: Center(
                  child: _MockLabelPositionImage(code: materialCode),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MockLabelPositionImage extends StatelessWidget {
  final String code;
  const _MockLabelPositionImage({required this.code});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Mock image
        Container(
          width: 400,
          height: 350,
          color: const Color(0xFFE8F5E9),
          child: Column(
            children: [
              // Code banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: const Color(0xFFFFEB3B),
                child: Text(
                  code,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSansJp(
                    fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primary,
                  ),
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // Drum illustration
                    Center(
                      child: Container(
                        width: 140, height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade800, width: 2),
                        ),
                        child: Center(
                          child: Icon(Icons.circle, size: 60, color: Colors.green.shade800),
                        ),
                      ),
                    ),
                    // Label indicator
                    Positioned(
                      top: 30, left: 100,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: Colors.pink.shade100,
                        child: Text('FF-1119',
                          style: GoogleFonts.notoSansJp(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primary),
                        ),
                      ),
                    ),
                    // Arrow pointing to label position
                    Positioned(
                      top: 60, left: 130,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ラベル貼付位置',
                            style: GoogleFonts.notoSansJp(fontSize: 11, color: Colors.blue, decoration: TextDecoration.underline),
                          ),
                        ],
                      ),
                    ),
                    // Enlarged label mockup
                    Positioned(
                      bottom: 10, right: 10,
                      child: Container(
                        width: 130, height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                          color: Colors.white,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('FF-1119',
                              style: GoogleFonts.notoSansJp(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary),
                            ),
                            Text('C1A-165  100kg',
                              style: GoogleFonts.notoSansJp(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
