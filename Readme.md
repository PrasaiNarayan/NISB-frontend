# NISB Frontend — 原料受入システム

Flutter Web frontend for the Nisshinbo Brake raw material receiving system (原料受入システム).

## Overview

This system provides tablet-based image inspection and QR verification for incoming raw materials at the Nisshinbo Brake production facility.

## Features

- **Login** — Employee code authentication
- **受入一覧** — Raw material receiving list with date/status filters
- **画像照合** — Image inspection using PC camera or file upload, matched against YOLO + PaddleOCR backend
- **検品済み原料** — Inspected materials priority list with label print priority
- **QRスキャン** — Dual QR code scan and comparison (仮ラベル vs 現品票)

## Tech Stack

- Flutter Web
- Dart
- Google Fonts (Noto Sans JP)
- `dart:html` for camera and file access
- `jsQR` (CDN) for QR code decoding

## Requirements

- Flutter SDK >= 3.0.0
- Chrome browser

## Setup

```bash
flutter pub get
flutter run -d chrome
```

## Backend

This frontend connects to the FastAPI backend at `http://localhost:8000`.
See the component-inspector backend repo for setup instructions.

API endpoint used:
```
POST /api/v1/inspect   — YOLO + OCR image inspection
GET  /api/v1/info      — Model metadata
GET  /health           — Server health check
```

## Project Structure

```
lib/
├── main.dart                      # App entry + navigation state
├── theme/
│   └── app_theme.dart             # Brand colors, fonts, button styles
├── services/
│   └── api_service.dart           # FastAPI connector + data models
├── widgets/
│   └── app_sidebar.dart           # Shared sidebar + top bar
└── screens/
    ├── login_screen.dart           # Employee code login
    ├── receiving_list_screen.dart  # 原料入荷 list
    ├── inspection_screen.dart      # Camera + YOLO/OCR inspection
    ├── inspected_list_screen.dart  # 検品済み原料 priority
    ├── qr_scan_screen.dart         # Dual QR scan and compare
    └── label_position_screen.dart  # ラベル貼り付け位置 popup
```

## Configuration

Backend URL is set in `lib/services/api_service.dart`:

```dart
static String baseUrl = 'http://localhost:8000';
```

Change this to your server IP/domain for production deployment.

## Client

日清紡ブレーキ株式会社 (Nisshinbo Brake Co., Ltd.)
館林事業所, 群馬県邑楽郡邑楽町赤堀1503番地

## Developer

Toray Engineering D Solutions Co., Ltd.