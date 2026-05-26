import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';

class QrScanScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const QrScanScreen({super.key, required this.onNavigate});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  // Left: 仮ラベル
  String? _tempQrData;
  bool _tempScanning = false;

  // Right: 現品表
  String? _productQrData;
  bool _productScanning = false;

  // Load jsQR from CDN once
  bool _jsQrLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadJsQr();
  }

  void _loadJsQr() {
    // Check if already loaded
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

  bool get _bothScanned => _tempQrData != null && _productQrData != null;
  bool get _isMatch => _bothScanned && _tempQrData == _productQrData;

  void _reset() {
    setState(() {
      _tempQrData = null;
      _productQrData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(activeRoute: '/qr-scan', onNavigate: widget.onNavigate),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const AppTopBar(title: 'QRスキャン'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QRコード照合',
                          style: GoogleFonts.notoSansJp(fontSize: 24, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('仮ラベルと現品ラベルのQRコードをスキャンして一致を確認してください。',
                          style: GoogleFonts.notoSansJp(fontSize: 13, color: AppTheme.textSecondary)),
                        const SizedBox(height: 20),

                        // Result banner
                        if (_bothScanned)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            decoration: BoxDecoration(
                              color: _isMatch
                                ? AppTheme.success.withOpacity(0.1)
                                : AppTheme.danger.withOpacity(0.1),
                              border: Border.all(
                                color: _isMatch ? AppTheme.success : AppTheme.danger,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isMatch ? Icons.check_circle : Icons.error,
                                  color: _isMatch ? AppTheme.success : AppTheme.danger,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  _isMatch ? '照合結果: OK — QRコードが一致しました' : '照合結果: NG — QRコードが一致しません',
                                  style: GoogleFonts.notoSansJp(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _isMatch ? AppTheme.success : AppTheme.danger,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _reset,
                                  child: Text('リセット', style: GoogleFonts.notoSansJp(fontSize: 13)),
                                ),
                              ],
                            ),
                          ),

                        // Two QR panels
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _QrCameraPanel(
                                  title: '仮ラベルQRをスキャン',
                                  icon: Icons.qr_code,
                                  scannedData: _tempQrData,
                                  isScanning: _tempScanning,
                                  jsQrLoaded: _jsQrLoaded,
                                  onScanned: (data) => setState(() => _tempQrData = data),
                                  onScanningChanged: (v) => setState(() => _tempScanning = v),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _QrCameraPanel(
                                  title: '現品表QRをスキャン',
                                  icon: Icons.qr_code_2,
                                  scannedData: _productQrData,
                                  isScanning: _productScanning,
                                  jsQrLoaded: _jsQrLoaded,
                                  onScanned: (data) => setState(() => _productQrData = data),
                                  onScanningChanged: (v) => setState(() => _productScanning = v),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: (_bothScanned && _isMatch)
                              ? () => widget.onNavigate('/receiving')
                              : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              minimumSize: const Size(100, 44),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            child: Text('確認', style: GoogleFonts.notoSansJp(fontSize: 14, color: Colors.white)),
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

// ── Individual QR Camera Panel ─────────────────────────────────────────────

class _QrCameraPanel extends StatefulWidget {
  final String title;
  final IconData icon;
  final String? scannedData;
  final bool isScanning;
  final bool jsQrLoaded;
  final Function(String) onScanned;
  final Function(bool) onScanningChanged;

  const _QrCameraPanel({
    required this.title,
    required this.icon,
    required this.scannedData,
    required this.isScanning,
    required this.jsQrLoaded,
    required this.onScanned,
    required this.onScanningChanged,
  });

  @override
  State<_QrCameraPanel> createState() => _QrCameraPanelState();
}

class _QrCameraPanelState extends State<_QrCameraPanel> {
  html.VideoElement? _video;
  html.CanvasElement? _canvas;
  bool _running = false;
  String? _error;
  Timer? _scanTimer;
  Uint8List? _previewFrame;

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

    // Draw to canvas and run jsQR
    final img = html.ImageElement()..src = dataUrl;
    await img.onLoad.first;
    final canvas = html.CanvasElement(width: img.naturalWidth, height: img.naturalHeight);
    canvas.context2D.drawImage(img, 0, 0);
    final imageData = canvas.context2D.getImageData(0, 0, canvas.width!, canvas.height!);
    if (!js.context.hasProperty('jsQR')) {
      setState(() => _error = 'jsQR未ロード');
      return;
    }
    final result = js.context.callMethod('jsQR', [
      imageData.data, canvas.width, canvas.height,
      js.JsObject.jsify({'inversionAttempts': 'attemptBoth'}),
    ]);
    if (result != null) {
      final data = result['data']?.toString();
      if (data != null && data.isNotEmpty) {
        widget.onScanned(data);
        return;
      }
    }
    setState(() => _error = 'QRコードが検出できませんでした');
  }

  Future<void> _startScan() async {
    if (!widget.jsQrLoaded) {
      setState(() => _error = 'jsQR読み込み中...');
      return;
    }
    setState(() { _error = null; });
    widget.onScanningChanged(true);

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

      // Wait for video ready
      for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_video!.readyState >= 2 && _video!.videoWidth > 0) break;
      }

      final w = _video!.videoWidth > 0 ? _video!.videoWidth : 640;
      final h = _video!.videoHeight > 0 ? _video!.videoHeight : 480;
      _canvas = html.CanvasElement(width: w, height: h);

      setState(() => _running = true);
      _startQrLoop();
    } catch (e) {
      widget.onScanningChanged(false);
      setState(() => _error = 'カメラエラー: $e');
    }
  }

  void _startQrLoop() {
    // Preview update timer - less frequent
    Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (!_running) { t.cancel(); return; }
      _updatePreview();
    });
    // QR scan timer - more frequent but no setState
    _scanTimer = Timer.periodic(const Duration(milliseconds: 150), (_) {
      if (!_running) return;
      _tryScanQr();
    });
  }

  void _updatePreview() {
    if (_video == null || _canvas == null || !_running) return;
    if (_video!.readyState < 2 || _video!.videoWidth == 0) return;
    try {
      _canvas!.context2D.drawImage(_video!, 0, 0);
      final url = _canvas!.toDataUrl('image/jpeg', 0.4);
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
      final ctx = _canvas!.context2D;
      ctx.drawImage(_video!, 0, 0);

      // Try QR decode
      final imageData = ctx.getImageData(0, 0, _canvas!.width!, _canvas!.height!);
      if (!js.context.hasProperty('jsQR')) return;

      final result = js.context.callMethod('jsQR', [
        imageData.data,
        _canvas!.width,
        _canvas!.height,
        js.JsObject.jsify({'inversionAttempts': 'attemptBoth'}),
      ]);

      if (result != null) {
        final data = result['data']?.toString();
        if (data != null && data.isNotEmpty) {
          _stopScan();
          widget.onScanned(data);
        }
      }
    } catch (e) {}
  }

  void _stopScan() {
    _scanTimer?.cancel();
    _scanTimer = null;
    if (_video?.srcObject != null) {
      final stream = _video!.srcObject as html.MediaStream;
      for (final track in stream.getTracks()) track.stop();
    }
    try { _video?.remove(); } catch (_) {}
    widget.onScanningChanged(false);
    if (mounted) setState(() { _running = false; _previewFrame = null; });
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isScanned = widget.scannedData != null;
    final status = isScanned ? 'OK' : (_running ? 'SCANNING' : 'PENDING');
    final statusColor = isScanned
      ? AppTheme.success
      : (_running ? AppTheme.warning : AppTheme.textLight);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
        color: AppTheme.surface,
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Text(widget.title, style: GoogleFonts.notoSansJp(fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(status,
                    style: GoogleFonts.notoSansJp(
                      fontSize: 11, fontWeight: FontWeight.w600, color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Expanded(
            child: isScanned
              ? _ScannedView(data: widget.scannedData!)
              : _running
                ? _ScanningView(onStop: _stopScan, previewFrame: _previewFrame)
                : _IdleView(
                    error: _error,
                    onStart: _startScan,
                    onScanFile: _scanFromFile,
                    jsQrLoaded: widget.jsQrLoaded,
                  ),
          ),

          // Data display
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('読み取りデータ',
                  style: GoogleFonts.notoSansJp(fontSize: 11, color: AppTheme.textLight)),
                const SizedBox(height: 4),
                Text(
                  widget.scannedData ?? '',
                  style: GoogleFonts.notoSansJp(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-views ──────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  final String? error;
  final VoidCallback onStart;
  final VoidCallback onScanFile;
  final bool jsQrLoaded;

  const _IdleView({this.error, required this.onStart, required this.onScanFile, required this.jsQrLoaded});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (error != null) ...[
            Icon(Icons.error_outline, color: AppTheme.danger, size: 36),
            const SizedBox(height: 8),
            Text(error!, style: GoogleFonts.notoSansJp(fontSize: 12, color: AppTheme.danger),
              textAlign: TextAlign.center),
            const SizedBox(height: 16),
          ] else ...[
            // QR frame corners
            SizedBox(
              width: 100, height: 100,
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _Corner()),
                  Positioned(top: 0, right: 0, child: _Corner(flipH: true)),
                  Positioned(bottom: 0, left: 0, child: _Corner(flipV: true)),
                  Positioned(bottom: 0, right: 0, child: _Corner(flipH: true, flipV: true)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          ElevatedButton.icon(
            onPressed: jsQrLoaded ? onStart : null,
            icon: const Icon(Icons.qr_code_scanner, size: 18, color: Colors.white),
            label: Text(
              jsQrLoaded ? 'カメラでスキャン' : '読み込み中...',
              style: GoogleFonts.notoSansJp(fontSize: 13, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: jsQrLoaded ? onScanFile : null,
            icon: const Icon(Icons.folder_open, size: 16),
            label: Text('QR画像ファイルを選択',
              style: GoogleFonts.notoSansJp(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningView extends StatelessWidget {
  final VoidCallback onStop;
  final Uint8List? previewFrame;
  const _ScanningView({required this.onStop, this.previewFrame});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black),
        // Show camera feed
        if (previewFrame != null && previewFrame!.isNotEmpty)
          Image.memory(previewFrame!, fit: BoxFit.cover, gaplessPlayback: true)
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                const SizedBox(height: 12),
                Text('カメラ起動中...',
                  style: GoogleFonts.notoSansJp(color: Colors.white, fontSize: 13)),
              ],
            ),
          ),
        // QR frame overlay — full area corners
        if (previewFrame != null)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Stack(
                children: [
                  Positioned(top: 0, left: 0, child: _ScanCorner()),
                  Positioned(top: 0, right: 0, child: _ScanCorner(flipH: true)),
                  Positioned(bottom: 0, left: 0, child: _ScanCorner(flipV: true)),
                  Positioned(bottom: 0, right: 0, child: _ScanCorner(flipH: true, flipV: true)),
                ],
              ),
            ),
          ),
        // Scanning label
        Positioned(
          top: 12, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('QRコードをカメラ全体に大きく映してください',
                style: GoogleFonts.notoSansJp(color: Colors.white, fontSize: 12)),
            ),
          ),
        ),
        Positioned(
          bottom: 12, left: 0, right: 0,
          child: Center(
            child: OutlinedButton.icon(
              onPressed: onStop,
              icon: const Icon(Icons.stop, size: 16, color: Colors.white),
              label: Text('停止', style: GoogleFonts.notoSansJp(color: Colors.white, fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanCorner extends StatelessWidget {
  final bool flipH;
  final bool flipV;
  const _ScanCorner({this.flipH = false, this.flipV = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flipH ? -1 : 1,
      scaleY: flipV ? -1 : 1,
      child: Container(
        width: 24, height: 24,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.primary, width: 3),
            left: BorderSide(color: AppTheme.primary, width: 3),
          ),
        ),
      ),
    );
  }
}

class _ScannedView extends StatelessWidget {
  final String data;
  const _ScannedView({required this.data});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.success, size: 52),
          const SizedBox(height: 12),
          Text('スキャン済み',
            style: GoogleFonts.notoSansJp(
              fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.success)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(data,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansJp(fontSize: 12, color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

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
        width: 20, height: 20,
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