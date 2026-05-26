import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/app_sidebar.dart';
import '../services/api_service.dart';

class InspectionScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final RawMaterial? material;

  const InspectionScreen({
    super.key,
    required this.onNavigate,
    this.material,
  });

  @override
  State<InspectionScreen> createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  Uint8List? _capturedImage;
  String _capturedFilename = 'capture.jpg';
  bool _cameraActive = false;
  bool _inspecting = false;
  InspectionResult? _result;
  String _mode = 'parallel';
  int _quantity = 1;
  final _manualCodeController = TextEditingController();
  bool _editingCode = false;
  final _codeEditController = TextEditingController();

  Future<void> _runInspection() async {
    // Priority: edited code > manual input > material code
    String code;
    if (_codeEditController.text.trim().isNotEmpty) {
      code = _codeEditController.text.trim();
    } else if (_manualCodeController.text.trim().isNotEmpty) {
      code = _manualCodeController.text.trim();
    } else {
      code = widget.material?.code ?? '';
    }
    print(
        '[DEBUG] code=$code, imageBytes=${_capturedImage?.length}, filename=$_capturedFilename');
    if (_capturedImage == null || _capturedImage!.isEmpty || code.isEmpty) {
      print('[DEBUG] Blocked: image=${_capturedImage?.length}, code=$code');
      return;
    }
    setState(() => _inspecting = true);

    try {
      final result = await ApiService.inspect(
        imageBytes: _capturedImage!,
        filename: _capturedFilename,
        code: code,
        mode: _mode,
      );
      setState(() {
        _result = result;
        _inspecting = false;
      });

      if (result.matched) {
        _showOkDialog(result);
      } else {
        _showNgDialog(result);
      }
    } catch (e) {
      setState(() => _inspecting = false);
      _showNgDialog(null);
    }
  }

  void _showOkDialog(InspectionResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OkDialog(
        quantity: _quantity,
        result: result,
        onContinue: () {
          Navigator.pop(context);
          setState(() {
            _capturedImage = null;
            _result = null;
          });
        },
        onComplete: () {
          Navigator.pop(context);
          widget.onNavigate('/receiving');
        },
      ),
    );
  }

  void _showNgDialog(InspectionResult? result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NgDialog(
        quantity: _quantity,
        onRetry: () {
          Navigator.pop(context);
          setState(() {
            _capturedImage = null;
            _result = null;
          });
        },
        onForceOk: (reason, password) {
          Navigator.pop(context);
          widget.onNavigate('/receiving');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final material = widget.material;

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(activeRoute: '/inspection', onNavigate: widget.onNavigate),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppTopBar(title: '画像照合'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current material with editable code
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '現在の商品',
                              style: GoogleFonts.notoSansJp(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (_editingCode)
                                  SizedBox(
                                    width: 180,
                                    child: TextField(
                                      controller: _codeEditController,
                                      autofocus: true,
                                      style: GoogleFonts.notoSansJp(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 6),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          borderSide: const BorderSide(
                                              color: AppTheme.primary,
                                              width: 2),
                                        ),
                                      ),
                                      onSubmitted: (v) {
                                        setState(() => _editingCode = false);
                                      },
                                    ),
                                  )
                                else
                                  Text(
                                    _codeEditController.text.isNotEmpty
                                        ? _codeEditController.text
                                        : (material?.code ?? '—'),
                                    style: GoogleFonts.notoSansJp(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                const SizedBox(width: 10),
                                if (_editingCode)
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _editingCode = false),
                                    icon: const Icon(Icons.check_circle,
                                        color: AppTheme.success, size: 22),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: '確定',
                                  )
                                else
                                  IconButton(
                                    onPressed: () {
                                      _codeEditController.text =
                                          _codeEditController.text.isNotEmpty
                                              ? _codeEditController.text
                                              : (material?.code ?? '');
                                      setState(() => _editingCode = true);
                                    },
                                    icon: const Icon(Icons.edit,
                                        size: 18,
                                        color: AppTheme.textSecondary),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'コードを変更',
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Main content: Master image | Camera
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Master image panel
                              Expanded(
                                child: _ImagePanel(
                                  title: '原料マスタ',
                                  titleColor: AppTheme.textPrimary,
                                  child: material != null
                                      ? _MasterImagePlaceholder(
                                          code: material.code)
                                      : const Center(
                                          child: Text('原料を選択してください')),
                                  footer: material != null
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _InfoRow(
                                                label: '外観',
                                                value: '微細な白色結晶粉末、凝集なし。'),
                                            _InfoRow(
                                                label: '許容範囲',
                                                value: '±2% の色調変化まで許容。'),
                                          ],
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Camera panel
                              Expanded(
                                child: _ImagePanel(
                                  title: 'カメラ',
                                  titleColor: AppTheme.danger,
                                  titleDot: true,
                                  child: _capturedImage != null &&
                                          _capturedImage!.isNotEmpty
                                      ? Image.memory(_capturedImage!,
                                          fit: BoxFit.contain)
                                      : _cameraStreaming
                                          ? Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                Container(color: Colors.black),
                                                if (_previewFrame != null &&
                                                    _previewFrame!.isNotEmpty)
                                                  Image.memory(_previewFrame!,
                                                      fit: BoxFit.cover,
                                                      gaplessPlayback: true)
                                                else
                                                  Center(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const CircularProgressIndicator(
                                                            color:
                                                                Colors.white),
                                                        const SizedBox(
                                                            height: 12),
                                                        Text('カメラ起動中...',
                                                            style: GoogleFonts
                                                                .notoSansJp(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        13)),
                                                      ],
                                                    ),
                                                  ),
                                                Positioned(
                                                  bottom: 12,
                                                  left: 0,
                                                  right: 0,
                                                  child: Center(
                                                    child: ElevatedButton.icon(
                                                      onPressed:
                                                          _captureFromCamera,
                                                      icon: const Icon(
                                                          Icons.camera_alt,
                                                          color: Colors.white,
                                                          size: 20),
                                                      label: Text('撮影',
                                                          style: GoogleFonts
                                                              .notoSansJp(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .white)),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            AppTheme.primary,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            4)),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 24,
                                                                vertical: 12),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : _CameraPlaceholder(
                                              isActive: _cameraActive,
                                              onActivate: () => setState(
                                                  () => _cameraActive = true),
                                            ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Manual code input if no material selected
                        if (widget.material == null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Text('原料コード：',
                                    style: GoogleFonts.notoSansJp(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary)),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 200,
                                  child: TextField(
                                    controller: _manualCodeController,
                                    style: GoogleFonts.notoSansJp(fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: 'BC127 など',
                                      hintStyle: GoogleFonts.notoSansJp(
                                          fontSize: 13,
                                          color: AppTheme.textLight),
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          borderSide: const BorderSide(
                                              color: AppTheme.border)),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Mode selector
                        Row(
                          children: [
                            Text('照合モード：',
                                style: GoogleFonts.notoSansJp(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary)),
                            _ModeChip(
                                label: '並列実行',
                                value: 'parallel',
                                current: _mode,
                                onSelect: (v) => setState(() => _mode = v)),
                            const SizedBox(width: 8),
                            _ModeChip(
                                label: 'YOLO優先',
                                value: 'yolo_first',
                                current: _mode,
                                onSelect: (v) => setState(() => _mode = v)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton(
                              onPressed: () => widget.onNavigate('/receiving'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(100, 44),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4)),
                                side: const BorderSide(color: AppTheme.border),
                              ),
                              child: Text('キャンセル',
                                  style: GoogleFonts.notoSansJp(fontSize: 14)),
                            ),
                            Row(
                              children: [
                                // Simulate capture for web
                                // Camera start / file pick / retake / run
                                if (_capturedImage != null &&
                                    _capturedImage!.isNotEmpty) ...[
                                  // Retake button
                                  OutlinedButton.icon(
                                    onPressed: () => setState(() {
                                      _capturedImage = null;
                                    }),
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: Text('撮り直し',
                                        style: GoogleFonts.notoSansJp(
                                            fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(100, 44),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Run inspection
                                  ElevatedButton.icon(
                                    onPressed:
                                        _inspecting ? null : _runInspection,
                                    icon: _inspecting
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2))
                                        : const Icon(Icons.search,
                                            size: 18, color: Colors.white),
                                    label: Text(
                                      _inspecting ? '照合中...' : '照合実行',
                                      style: GoogleFonts.notoSansJp(
                                          fontSize: 14, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      minimumSize: const Size(140, 44),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ),
                                ] else if (_cameraStreaming) ...[
                                  // Stop camera
                                  OutlinedButton.icon(
                                    onPressed: _stopCamera,
                                    icon: const Icon(Icons.videocam_off,
                                        size: 16),
                                    label: Text('カメラ停止',
                                        style: GoogleFonts.notoSansJp(
                                            fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(110, 44),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ),
                                ] else ...[
                                  // Start camera
                                  ElevatedButton.icon(
                                    onPressed: _startCamera,
                                    icon: const Icon(Icons.videocam,
                                        size: 18, color: Colors.white),
                                    label: Text('カメラ起動',
                                        style: GoogleFonts.notoSansJp(
                                            fontSize: 14, color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primary,
                                      minimumSize: const Size(120, 44),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // File pick
                                  OutlinedButton.icon(
                                    onPressed: _simulateCapture,
                                    icon:
                                        const Icon(Icons.folder_open, size: 16),
                                    label: Text('ファイル選択',
                                        style: GoogleFonts.notoSansJp(
                                            fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(110, 44),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
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

  // ── Camera methods ─────────────────────────────────────────────────
  html.VideoElement? _videoElement;
  html.CanvasElement? _previewCanvas;
  bool _cameraStreaming = false;
  Uint8List? _previewFrame;

  Future<void> _startCamera() async {
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'width': 1280, 'height': 720},
        'audio': false,
      });
      _videoElement = html.VideoElement()
        ..srcObject = stream
        ..autoplay = true
        ..muted = true;

      // Append to DOM so browser actually plays it
      html.document.body!.append(_videoElement!);
      _videoElement!.style.position = 'fixed';
      _videoElement!.style.opacity = '0';
      _videoElement!.style.pointerEvents = 'none';
      _videoElement!.style.width = '1px';
      _videoElement!.style.height = '1px';

      // Poll until video has frames (readyState >= 2) — up to 5 seconds
      for (int i = 0; i < 100; i++) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (_videoElement!.readyState >= 2 && _videoElement!.videoWidth > 0)
          break;
      }

      // Use actual dimensions or fallback
      final w = _videoElement!.videoWidth > 0 ? _videoElement!.videoWidth : 640;
      final h =
          _videoElement!.videoHeight > 0 ? _videoElement!.videoHeight : 480;

      _previewCanvas = html.CanvasElement(width: w, height: h);

      if (mounted) setState(() => _cameraStreaming = true);

      // Small extra delay before first frame
      await Future.delayed(const Duration(milliseconds: 200));
      _startFrameCapture();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('カメラアクセスエラー: $e')),
        );
      }
    }
  }

  void _startFrameCapture() {
    if (!_cameraStreaming) return;
    _capturePreviewFrame();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_cameraStreaming) _startFrameCapture();
    });
  }

  void _capturePreviewFrame() {
    if (_videoElement == null || _previewCanvas == null || !_cameraStreaming)
      return;
    // Skip if video not ready
    if (_videoElement!.readyState < 2) return;
    if (_videoElement!.videoWidth == 0 || _videoElement!.videoHeight == 0)
      return;
    try {
      _previewCanvas!.context2D.drawImage(_videoElement!, 0, 0);
      final dataUrl = _previewCanvas!.toDataUrl('image/jpeg', 0.7);
      if (!dataUrl.contains(',')) return;
      final base64 = dataUrl.split(',').last;
      if (base64.isEmpty) return;
      final bytes = base64Decode(base64);
      if (mounted) setState(() => _previewFrame = bytes);
    } catch (_) {}
  }

  void _stopCamera() {
    if (_videoElement?.srcObject != null) {
      final stream = _videoElement!.srcObject as html.MediaStream;
      for (final track in stream.getTracks()) {
        track.stop();
      }
    }
    // Remove from DOM
    try {
      _videoElement?.remove();
    } catch (_) {}
    if (mounted)
      setState(() {
        _cameraStreaming = false;
        _videoElement = null;
        _previewCanvas = null;
        _previewFrame = null;
      });
  }

  Future<void> _captureFromCamera() async {
    if (_videoElement == null || _previewCanvas == null) return;
    _previewCanvas!.context2D.drawImage(_videoElement!, 0, 0);
    final dataUrl = _previewCanvas!.toDataUrl('image/jpeg', 0.92);
    final base64 = dataUrl.split(',').last;
    final bytes = base64Decode(base64);
    _stopCamera();
    if (mounted)
      setState(() {
        _capturedImage = bytes;
        _capturedFilename = 'capture.jpg';
      });
  }

  Future<void> _simulateCapture() async {
    // Use HTML file input for Flutter Web
    // ignore: avoid_web_libraries_in_flutter
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    if (input.files!.isEmpty) return;
    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    await reader.onLoad.first;
    final bytes = reader.result as List<int>;
    setState(() {
      _capturedImage = Uint8List.fromList(bytes);
      _capturedFilename = file.name;
    });
  }
}

class _ImagePanel extends StatelessWidget {
  final String title;
  final Color titleColor;
  final bool titleDot;
  final Widget child;
  final Widget? footer;

  const _ImagePanel({
    required this.title,
    required this.titleColor,
    this.titleDot = false,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(4),
        color: AppTheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                if (titleDot) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: titleColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(title,
                    style: GoogleFonts.notoSansJp(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    )),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
          if (footer != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: footer,
            ),
          ],
        ],
      ),
    );
  }
}

class _MasterImagePlaceholder extends StatelessWidget {
  final String code;
  const _MasterImagePlaceholder({required this.code});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF0F0F0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48, color: AppTheme.textLight),
            const SizedBox(height: 8),
            Text(
              '$code マスタ画像',
              style: GoogleFonts.notoSansJp(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  final bool isActive;
  final VoidCallback onActivate;

  const _CameraPlaceholder({required this.isActive, required this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_outlined, size: 48, color: AppTheme.textLight),
          const SizedBox(height: 12),
          Text(
            'VIDEO FEED STANDBY',
            style: GoogleFonts.notoSansJp(
              fontSize: 12,
              color: AppTheme.textLight,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label：',
              style: GoogleFonts.notoSansJp(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
            ),
            TextSpan(
              text: value,
              style: GoogleFonts.notoSansJp(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Function(String) onSelect;

  const _ModeChip(
      {required this.label,
      required this.value,
      required this.current,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;
    return InkWell(
      onTap: () => onSelect(value),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          border: Border.all(
              color: isSelected ? AppTheme.primary : AppTheme.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: GoogleFonts.notoSansJp(
              fontSize: 12,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}

// ── OK Dialog ─────────────────────────────────────────────────────────────

class _OkDialog extends StatefulWidget {
  final int quantity;
  final InspectionResult result;
  final VoidCallback onContinue;
  final VoidCallback onComplete;

  const _OkDialog({
    required this.quantity,
    required this.result,
    required this.onContinue,
    required this.onComplete,
  });

  @override
  State<_OkDialog> createState() => _OkDialogState();
}

class _OkDialogState extends State<_OkDialog> {
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = widget.quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.success, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              '照合結果: OK',
              style: GoogleFonts.notoSansJp(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '原料マスタとの一致を確認しました。',
              style: GoogleFonts.notoSansJp(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            _QtyField(qty: _qty, onChanged: (v) => setState(() => _qty = v)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onContinue,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text('続ける',
                        style: GoogleFonts.notoSansJp(fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onComplete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text('完了',
                        style: GoogleFonts.notoSansJp(
                            fontSize: 14, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── NG Dialog ─────────────────────────────────────────────────────────────

class _NgDialog extends StatefulWidget {
  final int quantity;
  final VoidCallback onRetry;
  final Function(String reason, String password) onForceOk;

  const _NgDialog({
    required this.quantity,
    required this.onRetry,
    required this.onForceOk,
  });

  @override
  State<_NgDialog> createState() => _NgDialogState();
}

class _NgDialogState extends State<_NgDialog> {
  late int _qty;
  String? _selectedReason;
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _qty = widget.quantity;
  }

  final List<String> _reasons = [
    '誤認識',
    '画像品質不良',
    '照明不足',
    '類似品',
    'その他',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.danger.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error, color: AppTheme.danger, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              '照合結果: NG',
              style: GoogleFonts.notoSansJp(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.danger,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '登録されているマスタ画像と一致しませんでした。内容を確認して、手動操作を選択してください。',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansJp(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            _QtyField(qty: _qty, onChanged: (v) => setState(() => _qty = v)),
            const SizedBox(height: 12),
            // NG reason dropdown
            Align(
              alignment: Alignment.centerLeft,
              child: Text('NG理由',
                  style: GoogleFonts.notoSansJp(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.border),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  hint: Text('理由を選択してください',
                      style: GoogleFonts.notoSansJp(
                          fontSize: 13, color: AppTheme.textLight)),
                  isExpanded: true,
                  items: _reasons
                      .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(r,
                              style: GoogleFonts.notoSansJp(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedReason = v),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Password field
            Align(
              alignment: Alignment.centerLeft,
              child: Text('承認パスワード',
                  style: GoogleFonts.notoSansJp(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: '管理者の承認が必要です',
                prefixIcon: const Icon(Icons.lock_outline,
                    size: 18, color: AppTheme.textLight),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: AppTheme.border)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: GoogleFonts.notoSansJp(fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('やり直す',
                        style: GoogleFonts.notoSansJp(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedReason != null &&
                            _passwordController.text.isNotEmpty
                        ? () => widget.onForceOk(
                            _selectedReason!, _passwordController.text)
                        : null,
                    icon:
                        const Icon(Icons.check, size: 16, color: Colors.white),
                    label: Text('強制OK',
                        style: GoogleFonts.notoSansJp(
                            fontSize: 14, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(0, 44),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyField extends StatelessWidget {
  final int qty;
  final Function(int) onChanged;

  const _QtyField({required this.qty, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('入荷数量',
            style: GoogleFonts.notoSansJp(
                fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: qty.toString(),
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null) onChanged(n);
          },
          style: GoogleFonts.notoSansJp(fontSize: 15),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.border)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
}
