import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';

const String _baseUrl = 'http://localhost:8000';

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
  {'code': 'BC236',  'name': '硫酸バリウム',          'maker': '東北化工(株)'},
  {'code': 'BC210',  'name': '二硫化モリブデン',      'maker': '東北化工(株)'},
  {'code': 'BC388',  'name': 'フェノール樹脂',        'maker': '東北化工(株)'},
  {'code': 'BC465',  'name': 'アラミド繊維',          'maker': '奥多摩工業(株)'},
  {'code': 'BC746',  'name': 'スチール繊維',          'maker': '山石金属(株)'},
  {'code': 'BC765',  'name': 'チタン酸カリウム',      'maker': '東北化工(株)'},
];

List<Map<String, String>> _search(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return _allMaterials;
  return _allMaterials.where((m) =>
    m['code']!.toLowerCase().contains(q) ||
    m['name']!.toLowerCase().contains(q) ||
    m['maker']!.toLowerCase().contains(q)
  ).toList();
}

String _extractCode(String qrData) {
  return qrData.trim().split(RegExp(r'\s+')).first.trim();
}

Map<String, String>? _findByQr(String qrData) {
  final code = _extractCode(qrData).toLowerCase();
  if (!code.startsWith('bc')) return null;
  for (final m in _allMaterials) {
    if (m['code']!.toLowerCase() == code) return m;
  }
  return null;
}

// ── Main screen ────────────────────────────────────────────────────────────

class MaterialSearchScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const MaterialSearchScreen({super.key, required this.onNavigate});

  @override
  State<MaterialSearchScreen> createState() => _MaterialSearchScreenState();
}

class _MaterialSearchScreenState extends State<MaterialSearchScreen> {
  final _controller = TextEditingController();
  Map<String, String>? _selected;

  // QR state
  bool _jsQrLoaded = false;
  bool _qrScanning = false;
  String? _qrError;
  Uint8List? _previewFrame;
  html.VideoElement? _video;
  html.CanvasElement? _canvas;
  Timer? _previewTimer;
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _loadJsQr();
  }

  @override
  void dispose() {
    _controller.dispose();
    _stopCamera();
    super.dispose();
  }

  void _loadJsQr() {
    if (js.context.hasProperty('jsQR')) {
      setState(() => _jsQrLoaded = true);
      return;
    }
    final script = html.ScriptElement()
      ..src = 'https://cdn.jsdelivr.net/npm/jsqr@1.4.0/dist/jsQR.js'
      ..type = 'text/javascript';
    script.onLoad.listen((_) {
      if (mounted) setState(() => _jsQrLoaded = true);
    });
    html.document.head!.append(script);
  }

  void _onSelected(Map<String, String> item) {
    _controller.text = item['code']!;
    setState(() => _selected = item);
  }

  void _clear() {
    _controller.clear();
    setState(() => _selected = null);
  }

  Future<void> _startQrScan() async {
    setState(() => _qrError = null);
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'width': {'ideal': 1280}, 'height': {'ideal': 720}},
        'audio': false,
      });
      _video = html.VideoElement()
        ..srcObject = stream
        ..autoplay = true
        ..muted = true;
      html.document.body!.append(_video!);
      _video!.style.position = 'fixed';
      _video!.style.opacity = '0';
      _video!.style.width = '1px';
      _video!.style.height = '1px';

      for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_video!.readyState >= 2 && _video!.videoWidth > 0) break;
      }

      final w = _video!.videoWidth > 0 ? _video!.videoWidth : 1280;
      final h = _video!.videoHeight > 0 ? _video!.videoHeight : 720;
      _canvas = html.CanvasElement(width: w, height: h);

      if (mounted) setState(() => _qrScanning = true);

      _previewTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        if (!_qrScanning) return;
        _updatePreview();
      });
      _scanTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
        if (!_qrScanning) return;
        _tryScanQr();
      });
    } catch (e) {
      setState(() => _qrError = 'カメラエラー: $e');
    }
  }

  void _updatePreview() {
    if (_video == null || _canvas == null) return;
    if (_video!.readyState < 2 || _video!.videoWidth == 0) return;
    try {
      _canvas!.context2D.drawImage(_video!, 0, 0);
      final url = _canvas!.toDataUrl('image/jpeg', 0.5);
      if (url.contains(',')) {
        final bytes = base64Decode(url.split(',').last);
        if (mounted) setState(() => _previewFrame = bytes);
      }
    } catch (_) {}
  }

  void _tryScanQr() {
    if (_video == null || _canvas == null) return;
    if (_video!.readyState < 2 || _video!.videoWidth == 0) return;
    try {
      _canvas!.context2D.drawImage(_video!, 0, 0);
      final imageData = _canvas!.context2D.getImageData(
        0, 0, _canvas!.width!, _canvas!.height!);
      if (!js.context.hasProperty('jsQR')) return;
      final result = js.context.callMethod('jsQR', [
        imageData.data, _canvas!.width, _canvas!.height,
        js.JsObject.jsify({'inversionAttempts': 'attemptBoth'}),
      ]);
      if (result != null) {
        final data = result['data']?.toString();
        if (data != null && data.isNotEmpty) {
          _stopCamera();
          final found = _findByQr(data);
          final extracted = _extractCode(data);
          if (found != null) {
            _controller.text = found['code']!;
            setState(() { _selected = found; _qrError = null; });
          } else {
            _controller.text = extracted;
            setState(() => _qrError = 'QR読み取り: "$extracted" — 原料リストに一致なし');
          }
        }
      }
    } catch (_) {}
  }

  void _stopCamera() {
    _previewTimer?.cancel();
    _scanTimer?.cancel();
    if (_video?.srcObject != null) {
      final stream = _video!.srcObject as html.MediaStream;
      for (final track in stream.getTracks()) track.stop();
    }
    try { _video?.remove(); } catch (_) {}
    if (mounted) setState(() {
      _qrScanning = false;
      _video = null;
      _canvas = null;
      _previewFrame = null;
    });
  }

  Future<void> _scanFromFile() async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files!.isEmpty) return;
    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    final dataUrl = reader.result as String;
    final img = html.ImageElement()..src = dataUrl;
    await img.onLoad.first;
    final canvas = html.CanvasElement(width: img.naturalWidth, height: img.naturalHeight);
    canvas.context2D.drawImage(img, 0, 0);
    final imageData = canvas.context2D.getImageData(0, 0, canvas.width!, canvas.height!);
    if (!js.context.hasProperty('jsQR')) return;
    final result = js.context.callMethod('jsQR', [
      imageData.data, canvas.width, canvas.height,
      js.JsObject.jsify({'inversionAttempts': 'attemptBoth'}),
    ]);
    if (result != null) {
      final data = result['data']?.toString();
      if (data != null && data.isNotEmpty) {
        final found = _findByQr(data);
        final extracted = _extractCode(data);
        if (found != null) {
          _controller.text = found['code']!;
          setState(() { _selected = found; _qrError = null; });
        } else {
          _controller.text = extracted;
          setState(() => _qrError = 'QR読み取り: "$extracted" — 原料リストに一致なし');
        }
        return;
      }
    }
    setState(() => _qrError = 'QRコードが検出できませんでした');
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
                            fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 20),

                        // Search + QR row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Typeahead
                            SizedBox(
                              width: 420,
                              child: TypeAheadField<Map<String, String>>(
                                controller: _controller,
                                suggestionsCallback: (query) => _search(query),
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
                                        fontSize: 13, color: AppTheme.textLight),
                                      prefixIcon: const Icon(Icons.search,
                                        size: 20, color: AppTheme.textLight),
                                      suffixIcon: _controller.text.isNotEmpty
                                        ? IconButton(
                                            onPressed: _clear,
                                            icon: const Icon(Icons.close, size: 16))
                                        : null,
                                      filled: true,
                                      fillColor: AppTheme.surface,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(color: AppTheme.border)),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(color: AppTheme.border)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(
                                          color: AppTheme.primary, width: 1.5)),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 14),
                                    ),
                                  );
                                },
                                itemBuilder: (context, item) {
                                  final query = _controller.text.trim().toLowerCase();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(
                                        color: AppTheme.border, width: 0.5))),
                                    child: Row(
                                      children: [
                                        _HighlightText(
                                          text: item['code']!, query: query,
                                          baseStyle: GoogleFonts.notoSansJp(
                                            fontSize: 14, fontWeight: FontWeight.w600)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _HighlightText(
                                            text: item['name']!, query: query,
                                            baseStyle: GoogleFonts.notoSansJp(
                                              fontSize: 13, color: AppTheme.textSecondary)),
                                        ),
                                        Text(item['maker']!,
                                          style: GoogleFonts.notoSansJp(
                                            fontSize: 11, color: AppTheme.textLight)),
                                      ],
                                    ),
                                  );
                                },
                                onSelected: _onSelected,
                                emptyBuilder: (context) => Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('該当する原料が見つかりません',
                                    style: GoogleFonts.notoSansJp(
                                      fontSize: 13, color: AppTheme.textSecondary)),
                                ),
                                decorationBuilder: (context, child) => Material(
                                  elevation: 4,
                                  borderRadius: BorderRadius.circular(4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: child),
                                ),
                                offset: const Offset(0, 4),
                                constraints: const BoxConstraints(maxHeight: 320),
                              ),
                            ),

                            const SizedBox(width: 12),

                            // QR scan button / inline camera
                            if (!_qrScanning)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _jsQrLoaded ? _startQrScan : null,
                                    icon: const Icon(Icons.qr_code_scanner,
                                      size: 18, color: Colors.white),
                                    label: Text('QRスキャン',
                                      style: GoogleFonts.notoSansJp(
                                        fontSize: 13, color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      minimumSize: const Size(0, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                                  ),
                                  const SizedBox(height: 6),
                                  OutlinedButton.icon(
                                    onPressed: _jsQrLoaded ? _scanFromFile : null,
                                    icon: const Icon(Icons.folder_open, size: 14),
                                    label: Text('画像から読取',
                                      style: GoogleFonts.notoSansJp(fontSize: 12)),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12)),
                                  ),
                                ],
                              )
                            else
                              Container(
                                width: 500,
                                height: 360,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: AppTheme.primary),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    if (_previewFrame != null && _previewFrame!.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: Image.memory(_previewFrame!,
                                          fit: BoxFit.cover, gaplessPlayback: true),
                                      )
                                    else
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2),
                                            const SizedBox(height: 8),
                                            Text('カメラ起動中...',
                                              style: GoogleFonts.notoSansJp(
                                                color: Colors.white, fontSize: 12)),
                                          ],
                                        ),
                                      ),
                                    if (_previewFrame != null)
                                      Positioned.fill(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Stack(children: [
                                            Positioned(top: 0, left: 0, child: _Corner()),
                                            Positioned(top: 0, right: 0, child: _Corner(flipH: true)),
                                            Positioned(bottom: 0, left: 0, child: _Corner(flipV: true)),
                                            Positioned(bottom: 0, right: 0, child: _Corner(flipH: true, flipV: true)),
                                          ]),
                                        ),
                                      ),
                                    Positioned(
                                      top: 6, left: 0, right: 0,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(12)),
                                          child: Text('QRをカメラに向けてください',
                                            style: GoogleFonts.notoSansJp(
                                              color: Colors.white, fontSize: 10)),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 8, right: 8,
                                      child: GestureDetector(
                                        onTap: _stopCamera,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius: BorderRadius.circular(4)),
                                          child: Text('停止',
                                            style: GoogleFonts.notoSansJp(
                                              color: Colors.white, fontSize: 11)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        if (_qrError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                  size: 14, color: AppTheme.danger),
                                const SizedBox(width: 6),
                                Text(_qrError!,
                                  style: GoogleFonts.notoSansJp(
                                    fontSize: 12, color: AppTheme.danger)),
                              ],
                            ),
                          ),

                        const SizedBox(height: 32),

                        if (_selected != null)
                          Expanded(
                            child: SingleChildScrollView(
                              child: _SelectedProductCard(
                                material: _selected!, onClear: _clear),
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

// ── Highlight text ─────────────────────────────────────────────────────────

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle baseStyle;

  const _HighlightText({required this.text, required this.query, required this.baseStyle});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) return Text(text, style: baseStyle);
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query.toLowerCase());
    if (idx < 0) return Text(text, style: baseStyle);
    return RichText(
      text: TextSpan(children: [
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
      ]),
    );
  }
}

// ── Selected product card ─────────────────────────────────────────────────

class _SelectedProductCard extends StatefulWidget {
  final Map<String, String> material;
  final VoidCallback onClear;

  const _SelectedProductCard({required this.material, required this.onClear});

  @override
  State<_SelectedProductCard> createState() => _SelectedProductCardState();
}

class _SelectedProductCardState extends State<_SelectedProductCard> {
  bool _pdfAvailable = false;
  bool _pdfLoading = true;
  bool _pdfVisible = false;

  @override
  void initState() {
    super.initState();
    _checkPdf();
  }

  @override
  void didUpdateWidget(_SelectedProductCard old) {
    super.didUpdateWidget(old);
    if (old.material['code'] != widget.material['code']) {
      setState(() { _pdfAvailable = false; _pdfLoading = true; _pdfVisible = false; });
      _checkPdf();
    }
  }

  Future<void> _checkPdf() async {
    final code = widget.material['code']!;
    try {
      final response = await http.head(
        Uri.parse('$_baseUrl/api/v1/label-pdf/$code'));
      if (mounted) setState(() {
        _pdfAvailable = response.statusCode == 200;
        _pdfLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() { _pdfAvailable = false; _pdfLoading = false; });
    }
  }

  void _togglePdf() {
    if (!_pdfVisible) {
      final code = widget.material['code']!;
      final url = '$_baseUrl/api/v1/label-pdf/$code';
      final viewType = 'pdf-iframe-$code';
      try {
        ui_web.platformViewRegistry.registerViewFactory(
          viewType,
          (int id) => html.IFrameElement()
            ..src = url
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%',
        );
      } catch (_) {
        // Already registered — ignore
      }
    }
    setState(() => _pdfVisible = !_pdfVisible);
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.material['code']!;
    final pdfUrl = '$_baseUrl/api/v1/label-pdf/$code';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product info
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('選択中の原料',
                      style: GoogleFonts.notoSansJp(
                        fontSize: 11, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Text(code,
                      style: GoogleFonts.notoSansJp(
                        fontSize: 28, fontWeight: FontWeight.w700)),
                    Text(widget.material['name']!,
                      style: GoogleFonts.notoSansJp(
                        fontSize: 15, color: AppTheme.textSecondary)),
                    Text(widget.material['maker']!,
                      style: GoogleFonts.notoSansJp(
                        fontSize: 12, color: AppTheme.textLight)),
                  ],
                ),
                const Spacer(),
                if (_pdfLoading)
                  const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                else if (_pdfAvailable)
                  ElevatedButton.icon(
                    onPressed: _togglePdf,
                    icon: Icon(
                      _pdfVisible ? Icons.close : Icons.picture_as_pdf,
                      size: 16, color: Colors.white),
                    label: Text(
                      _pdfVisible ? '閉じる' : 'ラベル位置を表示',
                      style: GoogleFonts.notoSansJp(
                        fontSize: 13, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pdfVisible
                        ? AppTheme.textSecondary
                        : AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      children: [
                        const Icon(Icons.picture_as_pdf,
                          size: 14, color: AppTheme.textLight),
                        const SizedBox(width: 6),
                        Text('PDF未登録',
                          style: GoogleFonts.notoSansJp(
                            fontSize: 12, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: widget.onClear,
                  icon: const Icon(Icons.close,
                    size: 16, color: AppTheme.textLight),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Inline PDF viewer
          if (_pdfVisible && _pdfAvailable) ...[
            const Divider(height: 1),
            SizedBox(
              height: 700,
              child: HtmlElementView(viewType: 'pdf-iframe-$code'),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Corner widget ──────────────────────────────────────────────────────────

class _Corner extends StatelessWidget {
  final bool flipH;
  final bool flipV;
  const _Corner({this.flipH = false, this.flipV = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipH ? -1 : 1,
      scaleY: flipV ? -1 : 1,
      child: Container(
        width: 16, height: 16,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.primary, width: 2),
            left: BorderSide(color: AppTheme.primary, width: 2),
          ),
        ),
      ),
    );
  }
}