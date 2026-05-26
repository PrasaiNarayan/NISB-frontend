import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';
import '../services/api_service.dart';

class InspectedListScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const InspectedListScreen({super.key, required this.onNavigate});

  @override
  State<InspectedListScreen> createState() => _InspectedListScreenState();
}

class _InspectedListScreenState extends State<InspectedListScreen> {
  List<RawMaterial> _materials = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.fetchMaterialList(status: '検品済');
    final inspected = list.where((m) => m.inspectedAt != null).toList();
    setState(() { _materials = inspected; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy/MM/dd HH:mm');

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(activeRoute: '/inspected', onNavigate: widget.onNavigate),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(title: '検品済み原料'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('検品済み原料',
                              style: GoogleFonts.notoSansJp(fontSize: 24, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 12),
                            Text('優先度',
                              style: GoogleFonts.notoSansJp(fontSize: 24, fontWeight: FontWeight.w300, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_loading)
                          const Center(child: CircularProgressIndicator())
                        else
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: AppTheme.border),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                children: [
                                  // Table header
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(4),
                                        topRight: Radius.circular(4),
                                      ),
                                      border: Border(bottom: BorderSide(color: AppTheme.border)),
                                    ),
                                    child: Row(
                                      children: [
                                        _PHeader('原料コード', flex: 2),
                                        _PHeader('メーカー識別コード', flex: 2),
                                        _PHeader('検品日時', flex: 3),
                                        _PHeader('ラベル発行優先度', flex: 2),
                                      ],
                                    ),
                                  ),
                                  // Rows
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: _materials.length,
                                      itemBuilder: (ctx, i) {
                                        final m = _materials[i];
                                        final isHighlighted = m.labelPriority;
                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: isHighlighted ? const Color(0xFFFFF0F0) : AppTheme.surface,
                                            border: const Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                                          ),
                                          child: Row(
                                            children: [
                                              _PCell(
                                                Text(m.code,
                                                  style: GoogleFonts.notoSansJp(
                                                    fontSize: 14,
                                                    fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400,
                                                  ),
                                                ),
                                                flex: 2,
                                              ),
                                              _PCell(
                                                Text(m.makerCode, style: GoogleFonts.notoSansJp(fontSize: 14)),
                                                flex: 2,
                                              ),
                                              _PCell(
                                                Text(
                                                  m.inspectedAt != null ? fmt.format(m.inspectedAt!) : '',
                                                  style: GoogleFonts.notoSansJp(fontSize: 14),
                                                ),
                                                flex: 3,
                                              ),
                                              _PCell(
                                                Checkbox(
                                                  value: m.labelPriority,
                                                  onChanged: (v) {
                                                    setState(() => m.labelPriority = v ?? false);
                                                  },
                                                  activeColor: AppTheme.primary,
                                                ),
                                                flex: 2,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    );
  }
}

class _PHeader extends StatelessWidget {
  final String text;
  final int flex;
  const _PHeader(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, style: GoogleFonts.notoSansJp(
        fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary,
      )),
    );
  }
}

class _PCell extends StatelessWidget {
  final Widget child;
  final int flex;
  const _PCell(this.child, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: child);
  }
}
