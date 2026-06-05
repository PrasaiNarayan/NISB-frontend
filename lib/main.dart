import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/receiving_list_screen.dart';
import 'screens/inspection_screen.dart';
import 'screens/inspected_list_screen.dart';
import 'screens/material_search_screen.dart';
import 'services/api_service.dart';

void main() => runApp(const NisbApp());

class NisbApp extends StatelessWidget {
  const NisbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '原料受入システム',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _loggedIn = false;
  String _currentRoute = '/receiving';
  RawMaterial? _selectedMaterial;

  void _handleLogin(String code) =>
    setState(() { _loggedIn = true; _currentRoute = '/receiving'; });

  void _handleNavigate(String route) =>
    setState(() => _currentRoute = route);

  void _handleInspect(RawMaterial material) =>
    setState(() { _selectedMaterial = material; _currentRoute = '/inspection'; });

  @override
  Widget build(BuildContext context) {
    if (!_loggedIn) return LoginScreen(onLogin: _handleLogin);
    switch (_currentRoute) {
      case '/receiving':
        return ReceivingListScreen(
          onNavigate: _handleNavigate, onInspect: _handleInspect);
      case '/inspection':
        return InspectionScreen(
          onNavigate: _handleNavigate, material: _selectedMaterial);
      case '/inspected':
        return InspectedListScreen(onNavigate: _handleNavigate);
      case '/search':
        return MaterialSearchScreen(onNavigate: _handleNavigate);
      default:
        return ReceivingListScreen(
          onNavigate: _handleNavigate, onInspect: _handleInspect);
    }
  }
}