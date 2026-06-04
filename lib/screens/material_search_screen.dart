import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';

const List<Map<String, String>> _allMaterials = [
  {'code': 'BC100',  'name': '酸化亜鉛',           'maker': '山石金属(株)'},
  {'code': 'BC127',  'name': 'ステアリン酸',         'maker': '東北化工(株)'},
  {'code': 'BC192',  'name': '硫黄',               'maker': '東北化工(株)'},
  {'code': 'BC2',    'name': 'カーボンブラック',      'maker': '奥多摩工業(株)'},
  {'code': 'BC243',  'name': '酸化鉄',              'maker': '東北化工(株)'},
  {'code': 'BC300',  'name': 'シリカ',              'maker': '小西安(株)'},
  {'code': 'BC16M',  'name': '酸化亜鉛 M グレード',  'maker': '三井金属鉱業(株)'},
  {'code': 'BC16S',  'name': '酸化亜鉛 S グレード',  'maker': '三井金属鉱業(株)'},
  {'code': 'BC435',  'name': 'ケイ酸カルシウム',     'maker': '東北化工(株)'},
  {'code': 'BC484',  'name': '炭酸カルシウム',       'maker': '奥多摩工業(株)'},
  {'code': 'BC499',  'name': 'タルク',              'maker': '小西安(株)'},
  {'code': 'BC527',  'name': 'クレー',              'maker': '山石金属(株)'},
  {'code': 'BC560',  'name': 'バライト',             'maker': '東北化工(株)'},
  {'code': 'BC561',  'name': '水酸化アルミニウム',    'maker': '奥多摩工業(株)'},
  {'code': 'BC567',  'name': 'マイカ',              'maker': '山石金属(株)'},
  {'code': 'BC210',  'name': '二硫化モリブデン',      'maker': '東北化工(株)'},
  {'code': 'BC388',  'name': 'フェノール樹脂',        'maker': '東北化工(株)'},
  {'code': 'BC465',  'name': 'アラミド繊維',          'maker': '奥多摩工業(株)'},
  {'code': 'BC746',  'name': 'スチール繊維',          'maker': '山石金属(株)'},
  {'code': 'BC765',  'name': 'チタン酸カリウム',      'maker': '東北化工(株)'},
];

List<Map<String, String>> _search(String query) {
  final q = query.trim().toLowerCase();
  // Empty query — show all
  if (q.isEmpty) return _allMaterials;
  return _allMaterials.where((m) =>
    m['code']!.toLowerCase().contains(q) ||
    m['name']!.toLowerCase().contains(q) ||
    m['maker']!.toLowerCase().contains(q)
  ).toList();
}

class MaterialSearchScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const MaterialSearchScreen({super.key, required this.onNavigate});

  @override
  State<MaterialSearchScreen> createState() => _MaterialSearchScreenState();
}

class _MaterialSearchScreenState extends State<MaterialSearchScreen> {
  final _controller = TextEditingController();
  Map<String, String>? _selected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelected(Map<String, String> item) {
    _controller.text = item['code']!;
    setState(() => _selected = item);
  }

  void _clear() {
    _controller.clear();
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(activeRoute: '/search', onNavigate: widget.onNavigate),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(title: '原料検索'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('原料検索',
                          style: GoogleFonts.notoSansJp(
                            fontSize: 24, fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: 480,
                          child: TypeAheadField<Map<String, String>>(
                            controller: _controller,
                            suggestionsCallback: (query) => _search(query),
                            // Show dropdown immediately on focus even if empty
                            hideOnEmpty: false,
                            hideOnLoading: true,
                            builder: (context, controller, focusNode) {
                              return TextField(
                                controller: controller,
                                focusNode: focusNode,
                                style: GoogleFonts.notoSansJp(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: '原料コードまたは名称を入力',
                                  hintStyle: GoogleFonts.notoSansJp(
                                    fontSize: 13, color: AppTheme.textLight,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search, size: 20, color: AppTheme.textLight,
                                  ),
                                  suffixIcon: _controller.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: _clear,
                                        icon: const Icon(Icons.close, size: 16),
                                      )
                                    : null,
                                  filled: true,
                                  fillColor: AppTheme.surface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(color: AppTheme.border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(color: AppTheme.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primary, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14,
                                  ),
                                ),
                              );
                            },
                            itemBuilder: (context, item) {
                              final query = _controller.text.trim().toLowerCase();
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12,
                                ),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppTheme.border, width: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _HighlightText(
                                      text: item['code']!,
                                      query: query,
                                      baseStyle: GoogleFonts.notoSansJp(
                                        fontSize: 14, fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _HighlightText(
                                        text: item['name']!,
                                        query: query,
                                        baseStyle: GoogleFonts.notoSansJp(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Text(item['maker']!,
                                      style: GoogleFonts.notoSansJp(
                                        fontSize: 11, color: AppTheme.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onSelected: _onSelected,
                            emptyBuilder: (context) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('該当する原料が見つかりません',
                                style: GoogleFonts.notoSansJp(
                                  fontSize: 13, color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            decorationBuilder: (context, child) => Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: child,
                              ),
                            ),
                            offset: const Offset(0, 4),
                            constraints: const BoxConstraints(maxHeight: 320),
                          ),
                        ),

                        const SizedBox(height: 32),

                        if (_selected != null)
                          _SelectedProductCard(
                            material: _selected!,
                            onClear: _clear,
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

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;

  const _HighlightText({
    required this.text,
    required this.query,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: baseStyle);
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());
    if (idx < 0) return Text(text, style: baseStyle);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: text.substring(0, idx), style: baseStyle),
          TextSpan(
            text: text.substring(idx, idx + query.length),
            style: baseStyle.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
              backgroundColor: AppTheme.primary.withOpacity(0.08),
            ),
          ),
          TextSpan(text: text.substring(idx + query.length), style: baseStyle),
        ],
      ),
    );
  }
}

class _SelectedProductCard extends StatelessWidget {
  final Map<String, String> material;
  final VoidCallback onClear;

  const _SelectedProductCard({required this.material, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('選択中の原料',
                style: GoogleFonts.notoSansJp(
                  fontSize: 11, color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close, size: 16, color: AppTheme.textLight),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(material['code']!,
            style: GoogleFonts.notoSansJp(
              fontSize: 28, fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(material['name']!,
            style: GoogleFonts.notoSansJp(
              fontSize: 15, color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(material['maker']!,
            style: GoogleFonts.notoSansJp(
              fontSize: 12, color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.picture_as_pdf, size: 18, color: AppTheme.textLight),
              const SizedBox(width: 8),
              Text('ラベル貼り付け位置 PDF',
                style: GoogleFonts.notoSansJp(
                  fontSize: 13, color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('準備中',
                  style: GoogleFonts.notoSansJp(
                    fontSize: 11, color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}