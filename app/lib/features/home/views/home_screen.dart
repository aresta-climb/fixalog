// SPDX-License-Identifier: MPL-2.0
// Copyright (c) 2026 Fixalog Contributors

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/resolvedor_idioma.dart';
import '../../../core/services/agendador_sincronizacao_background.dart';
import '../../settings/views/tela_configuracoes.dart';
import 'new_protocol_screen.dart';
import 'history_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  AgendadorSincronizacaoBackground? _agendadorBackground;

  static const _pages = <Widget>[
    NewProtocolScreen(),
    HistoryScreen(),
    TelaConfiguracoes(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _agendadorBackground = ref.read(agendadorSincronizacaoBackgroundProvider);
    unawaited(_agendadorBackground!.iniciarMonitoramento());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_agendadorBackground?.aoRetomarAplicativo());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _agendadorBackground?.cancelarTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ResolvedorIdioma.obterLocaleEfetivo(context, ref);
    final l10n = ResolvedorIdioma.obterTraducoes(locale);
    final ehPt = locale.languageCode == 'pt';

    return Scaffold(
      backgroundColor: const Color(0xFF060908),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: _FixalogBottomBar(
        currentIndex: _currentIndex,
        labelNovo: ehPt ? 'Novo Protocolo' : l10n.homeAbaNovo,
        labelHistorico: ehPt ? 'Histórico' : l10n.homeAbaHistorico,
        labelConfig: ehPt ? 'Configurações' : l10n.homeAbaConfig,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom Bar
// ---------------------------------------------------------------------------
class _FixalogBottomBar extends StatelessWidget {
  const _FixalogBottomBar({
    required this.currentIndex,
    required this.labelNovo,
    required this.labelHistorico,
    required this.labelConfig,
    required this.onTap,
  });

  final int currentIndex;
  final String labelNovo;
  final String labelHistorico;
  final String labelConfig;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F11),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.07),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              _BottomBarItem(
                icon: Icons.add_circle_outline,
                activeIcon: Icons.add_circle,
                label: labelNovo,
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _BottomBarItem(
                icon: Icons.history_outlined,
                activeIcon: Icons.history,
                label: labelHistorico,
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _BottomBarItem(
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: labelConfig,
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  const _BottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFFF6B00);
    final inactiveColor = Colors.white.withValues(alpha: 0.4);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isSelected ? activeIcon : icon,
                  key: ValueKey(isSelected),
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.3,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
