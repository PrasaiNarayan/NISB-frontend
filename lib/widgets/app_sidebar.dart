import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppSidebar extends StatelessWidget {
  final String activeRoute;
  final Function(String) onNavigate;

  const AppSidebar({super.key, required this.activeRoute, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      color: AppTheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border))),
            child: Text('原料受入システム',
              style: GoogleFonts.notoSansJp(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: AppTheme.primary)),
          ),
          const SizedBox(height: 8),
          _NavItem(icon: Icons.list_alt,             label: '受入一覧',   route: '/receiving',  activeRoute: activeRoute, onTap: () => onNavigate('/receiving')),
          _NavItem(icon: Icons.image_search,         label: '画像照合',   route: '/inspection', activeRoute: activeRoute, onTap: () => onNavigate('/inspection')),
          _NavItem(icon: Icons.inventory_2_outlined, label: '検品済原料', route: '/inspected',  activeRoute: activeRoute, onTap: () => onNavigate('/inspected')),
          _NavItem(icon: Icons.search,               label: '原料検索',   route: '/search',     activeRoute: activeRoute, onTap: () => onNavigate('/search')),
          _NavItem(icon: Icons.settings,             label: 'システム設定', route: '/settings',  activeRoute: activeRoute, onTap: () => onNavigate('/settings')),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String activeRoute;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.route,
    required this.activeRoute, required this.onTap});

  bool get isActive => activeRoute == route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary.withOpacity(0.08) : null,
          border: isActive
            ? const Border(left: BorderSide(color: AppTheme.primary, width: 3))
            : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.notoSansJp(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AppTopBar({super.key, required this.title, this.actions});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border))),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text('原料受入システム', style: GoogleFonts.notoSansJp(
            fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          if (actions != null) ...[const Spacer(), ...actions!],
        ],
      ),
    );
  }
}