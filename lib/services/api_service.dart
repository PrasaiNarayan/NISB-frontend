import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  static String baseUrl = 'http://localhost:8000';

  // ── Health check ──────────────────────────────────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/health'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── Inspect image against code ────────────────────────────────────────
  static Future<InspectionResult> inspect({
    required Uint8List imageBytes,
    required String filename,
    required String code,
    String mode = 'parallel',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/api/v1/inspect'),
    );
    // Detect content type from filename
    String contentType = 'image/jpeg';
    final ext = filename.toLowerCase().split('.').last;
    if (ext == 'png')
      contentType = 'image/png';
    else if (ext == 'webp')
      contentType = 'image/webp';
    else if (ext == 'bmp') contentType = 'image/bmp';

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: filename,
      contentType: MediaType.parse(contentType),
    ));
    request.fields['code'] = code;
    request.fields['mode'] = mode;

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();
    final json = jsonDecode(body) as Map<String, dynamic>;
    return InspectionResult.fromJson(json);
  }

  // ── Mock: Raw material list (replace with real PMS API) ───────────────
  static Future<List<RawMaterial>> fetchMaterialList({
    DateTime? from,
    DateTime? to,
    String? status,
    String? search,
  }) async {
    // Mock data matching the screenshots
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      RawMaterial(
        code: 'BC100',
        makerCode: 'Y',
        weight: 20,
        plannedQty: 50,
        receivedQty: 50,
        plannedDate: DateTime(2025, 4, 8),
        receivedDate: DateTime(2025, 4, 8),
        maker: '山石金属(株)',
        orderNo: '00000000026464',
        labelPriority: false,
        status: '入荷済',
      ),
      RawMaterial(
        code: 'BC16M',
        makerCode: '',
        weight: 100,
        plannedQty: 8,
        receivedQty: 8,
        plannedDate: DateTime(2025, 4, 8),
        receivedDate: DateTime(2025, 4, 8),
        inspectedAt: DateTime(2025, 4, 8, 9, 0),
        maker: '東北化工(株)',
        orderNo: '00000000026502',
        labelPriority: true,
        status: '入荷済',
      ),
      RawMaterial(
        code: 'BC192',
        makerCode: '',
        weight: 100,
        plannedQty: 4,
        receivedQty: 4,
        plannedDate: DateTime(2025, 4, 8),
        receivedDate: DateTime(2025, 4, 8),
        maker: '東北化工(株)',
        orderNo: '00000000026502',
        labelPriority: false,
        status: '入荷済',
      ),
      RawMaterial(
        code: 'BC2',
        makerCode: '',
        weight: 20,
        plannedQty: 100,
        receivedQty: 100,
        plannedDate: DateTime(2025, 4, 8),
        receivedDate: DateTime(2025, 4, 8),
        maker: '奥多摩工業(株)',
        orderNo: '00000000026452',
        labelPriority: false,
        status: '入荷済',
      ),
      RawMaterial(
        code: 'BC243',
        makerCode: '',
        weight: 100,
        plannedQty: 4,
        receivedQty: 4,
        plannedDate: DateTime(2025, 4, 8),
        receivedDate: DateTime(2025, 4, 8),
        maker: '東北化工(株)',
        orderNo: '00000000026502',
        labelPriority: false,
        status: '入荷済',
      ),
      RawMaterial(
        code: 'BC300',
        makerCode: '',
        weight: 25,
        plannedQty: 40,
        receivedQty: 40,
        plannedDate: DateTime(2025, 4, 8),
        receivedDate: DateTime(2025, 4, 8),
        maker: '小西安(株)',
        orderNo: '00000000026501',
        labelPriority: false,
        status: '入荷済',
      ),
    ];
  }
}

// ── Models ──────────────────────────────────────────────────────────────

class InspectionResult {
  final bool matched;
  final String? matchSource;
  final String code;
  final String mode;
  final YoloResult yolo;
  final OcrResult ocr;

  InspectionResult({
    required this.matched,
    this.matchSource,
    required this.code,
    required this.mode,
    required this.yolo,
    required this.ocr,
  });

  factory InspectionResult.fromJson(Map<String, dynamic> j) {
    return InspectionResult(
      matched: j['matched'] as bool? ?? false,
      matchSource: j['match_source'] as String?,
      code: j['code'] as String? ?? '',
      mode: j['mode'] as String? ?? 'parallel',
      yolo: YoloResult.fromJson(j['yolo'] as Map<String, dynamic>? ?? {}),
      ocr: OcrResult.fromJson(j['ocr'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class YoloResult {
  final String? predictedCode;
  final double? score;
  final bool matched;

  YoloResult({this.predictedCode, this.score, required this.matched});

  factory YoloResult.fromJson(Map<String, dynamic> j) {
    return YoloResult(
      predictedCode: j['predicted_code'] as String?,
      score: (j['score'] as num?)?.toDouble(),
      matched: j['matched'] as bool? ?? false,
    );
  }
}

class OcrResult {
  final String? detectedText;
  final double? confidence;
  final bool matched;
  final String? csvResolvedCode;

  OcrResult({
    this.detectedText,
    this.confidence,
    required this.matched,
    this.csvResolvedCode,
  });

  factory OcrResult.fromJson(Map<String, dynamic> j) {
    return OcrResult(
      detectedText: j['detected_text'] as String?,
      confidence: (j['confidence'] as num?)?.toDouble(),
      matched: j['matched'] as bool? ?? false,
      csvResolvedCode: j['csv_resolved_code'] as String?,
    );
  }
}

class RawMaterial {
  final String code;
  final String makerCode;
  final double weight;
  final int plannedQty;
  final int receivedQty;
  final DateTime plannedDate;
  final DateTime? receivedDate;
  final DateTime? inspectedAt;
  final String maker;
  final String orderNo;
  bool labelPriority;
  final String status;

  RawMaterial({
    required this.code,
    required this.makerCode,
    required this.weight,
    required this.plannedQty,
    required this.receivedQty,
    required this.plannedDate,
    this.receivedDate,
    this.inspectedAt,
    required this.maker,
    required this.orderNo,
    required this.labelPriority,
    required this.status,
  });
}
