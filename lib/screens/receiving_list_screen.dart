import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';
import '../services/api_service.dart';

class ReceivingListScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final Function(RawMaterial) onInspect;

  const ReceivingListScreen({
    super.key,
    required this.onNavigate,
    required this.onInspect,
  });

  @override
  State<ReceivingListScreen> createState() => _ReceivingListScreenState();
}

class _ReceivingListScreenState extends State<ReceivingListScreen> {
  List<RawMaterial> _materials = [];
  bool _loading = true;
  String _statusFilter = '入荷済';
  final _searchController = TextEditingController();
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  final _fmt = DateFormat('yyyy/MM/dd');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.fetchMaterialList(status: _statusFilter);
    setState(() { _materials = list; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(activeRoute: '/receiving', onNavigate: widget.onNavigate),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppTopBar(title: '原料入荷'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('原料入荷',
                          style: GoogleFonts.notoSansJp(
                            fontSize: 24, fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Filter row
                        Row(
                          children: [
                            Text('入荷予定日', style: GoogleFonts.notoSansJp(fontSize: 13)),
                            const SizedBox(width: 8),
                            Text('From', style: GoogleFonts.notoSansJp(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(width: 6),
                            _DatePickerButton(
                              date: _fromDate,
                              onChanged: (d) => setState(() => _fromDate = d),
                            ),
                            const SizedBox(width: 8),
                            Text('To', style: GoogleFonts.notoSansJp(fontSize: 12, color: AppTheme.textSecondary)),
                            const SizedBox(width: 6),
                            _DatePickerButton(
                              date: _toDate,
                              onChanged: (d) => setState(() => _toDate = d),
                            ),
                            const SizedBox(width: 16),
                            Text('区分', style: GoogleFonts.notoSansJp(fontSize: 13)),
                            const SizedBox(width: 8),
                            _DropdownFilter(
                              value: _statusFilter,
                              items: const ['入荷済', '未入荷', '全て'],
                              onChanged: (v) => setState(() => _statusFilter = v),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.notoSansJp(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: '原料名、サプライヤーで検索',
                                  hintStyle: GoogleFonts.notoSansJp(fontSize: 12, color: AppTheme.textLight),
                                  prefixIcon: const Icon(Icons.search, size: 18, color: AppTheme.textLight),
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
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _load,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                minimumSize: const Size(72, 38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: Text('検索', style: GoogleFonts.notoSansJp(fontSize: 13, color: Colors.white)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Table
                        Expanded(
                          child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _MaterialTable(
                                materials: _materials,
                                onInspect: widget.onInspect,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => widget.onNavigate('/inspection'),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.fact_check, color: Colors.white),
        label: Text('検品', style: GoogleFonts.notoSansJp(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _MaterialTable extends StatelessWidget {
  final List<RawMaterial> materials;
  final Function(RawMaterial) onInspect;

  const _MaterialTable({required this.materials, required this.onInspect});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy/MM/dd');
    final headers = ['原料コード', 'メーカー識別コード', '重量(KG/個)', '入荷予定数', '入荷済数', '入荷予定日', '入荷日付', '検品日時', 'ラベル発行優先度', 'メーカー', '発注番号'];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.tableHeader,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
            child: Row(
              children: headers.map((h) => _HeaderCell(h)).toList(),
            ),
          ),
          // Rows
          Expanded(
            child: ListView.builder(
              itemCount: materials.length,
              itemBuilder: (ctx, i) {
                final m = materials[i];
                final isHighlighted = m.labelPriority;
                return InkWell(
                  onDoubleTap: () => onInspect(m),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isHighlighted ? AppTheme.tableRowAlt : (i.isEven ? AppTheme.surface : const Color(0xFFFAFAFA)),
                      border: const Border(bottom: BorderSide(color: AppTheme.border, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        _Cell(Text(m.code, style: GoogleFonts.notoSansJp(fontSize: 13, fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w400))),
                        _Cell(Text(m.makerCode, style: GoogleFonts.notoSansJp(fontSize: 13))),
                        _Cell(Text(m.weight.toStringAsFixed(0), style: GoogleFonts.notoSansJp(fontSize: 13))),
                        _Cell(Text(m.plannedQty.toString(), style: GoogleFonts.notoSansJp(fontSize: 13))),
                        _Cell(Text(m.receivedQty.toString(), style: GoogleFonts.notoSansJp(fontSize: 13))),
                        _Cell(Text(fmt.format(m.plannedDate), style: GoogleFonts.notoSansJp(fontSize: 13))),
                        _Cell(Text(m.receivedDate != null ? fmt.format(m.receivedDate!) : '', style: GoogleFonts.notoSansJp(fontSize: 13))),
                        _Cell(Text(m.inspectedAt != null ? DateFormat('yyyy/MM/dd HH:mm').format(m.inspectedAt!) : '', style: GoogleFonts.notoSansJp(fontSize: 12))),
                        _Cell(Checkbox(
                          value: m.labelPriority,
                          onChanged: null,
                          activeColor: AppTheme.primary,
                        )),
                        _Cell(Text(m.maker, style: GoogleFonts.notoSansJp(fontSize: 12))),
                        _Cell(Text(m.orderNo, style: GoogleFonts.notoSansJp(fontSize: 11, color: AppTheme.textSecondary))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Text(
          text,
          style: GoogleFonts.notoSansJp(
            fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Widget child;
  const _Cell(this.child);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: child,
      ),
    );
  }
}

class _DatePickerButton extends StatelessWidget {
  final DateTime date;
  final Function(DateTime) onChanged;

  const _DatePickerButton({required this.date, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(4),
          color: AppTheme.surface,
        ),
        child: Text(
          DateFormat('yyyy/MM/dd').format(date),
          style: GoogleFonts.notoSansJp(fontSize: 13),
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String value;
  final List<String> items;
  final Function(String) onChanged;

  const _DropdownFilter({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
        color: AppTheme.surface,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: GoogleFonts.notoSansJp(fontSize: 13)))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
          style: GoogleFonts.notoSansJp(fontSize: 13, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}
