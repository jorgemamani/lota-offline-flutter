import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../dependency_injection.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/constants/lota_card_colors.dart';
import '../../data/carton_manager.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/lota_card_model.dart';
import '../bloc/game_bloc.dart';
import '../widgets/lota_card_widget.dart';
import 'game_play_page.dart';

class CartonSelectArgs {
  const CartonSelectArgs({required this.mode});
  final GameMode mode;
}

class CartonSelectPage extends StatefulWidget {
  const CartonSelectPage({super.key, required this.args});

  final CartonSelectArgs args;

  @override
  State<CartonSelectPage> createState() => _CartonSelectPageState();
}

class _CartonSelectPageState extends State<CartonSelectPage> {
  final List<LotaCardModel> _available = [];
  final Map<String, LotaCardColor> _cardColors = {};
  final Set<String> _selectedIds = {};
  late final ScrollController _scrollController;
  final _random = Random();
  bool _isLoadingMore = false;

  static const _pageSize = 10;
  static const _maxCartones = 50;
  static const _maxSelection = 3;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore || _available.length >= _maxCartones) return;
    final remaining = _maxCartones - _available.length;
    final toLoad = remaining < _pageSize ? remaining : _pageSize;
    setState(() {
      _isLoadingMore = true;
    });
    final newCards = sl<CartonManager>().generateCards(toLoad);
    final palette = LotaCardColors.all;
    setState(() {
      for (final card in newCards) {
        _cardColors[card.id] =
            palette[_random.nextInt(palette.length)];
      }
      _available.addAll(newCards);
      _isLoadingMore = false;
    });
  }

  void _toggleCarton(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else if (_selectedIds.length < _maxSelection) {
        _selectedIds.add(id);
      }
    });
  }

  void _startGame() {
    if (_selectedIds.isEmpty) return;

    final selected = _available
        .where((c) => _selectedIds.contains(c.id))
        .toList();

    context.read<GameBloc>().add(GameStarted(
          mode: widget.args.mode,
          cartones: selected,
        ));

    context.pushReplacement(
      RouteNames.gamePlay,
      extra: GamePlayArgs(
        mode: widget.args.mode,
        cartones: selected,
        cardColors: Map.fromEntries(
          selected.map((c) => MapEntry(c.id, _cardColors[c.id]!)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = widget.args.mode;

    return Scaffold(
      appBar: AppBar(
        title: Text('Elegir cartones — ${mode.label}'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seleccioná hasta $_maxSelection cartones para jugar.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_selectedIds.isNotEmpty)
                  Chip(
                    label: Text(
                        '${_selectedIds.length}/$_maxSelection seleccionado(s)'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: _available.length + (_isLoadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == _available.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final carton = _available[index];
                final isSelected = _selectedIds.contains(carton.id);

                final cardColor = _cardColors[carton.id];
                final accentColor =
                    cardColor?.primary ?? theme.colorScheme.primary;

                return GestureDetector(
                  onTap: () {
                    if (!_selectedIds.contains(carton.id) &&
                        _selectedIds.length >= _maxSelection) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Máximo $_maxSelection cartones permitidos.'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    _toggleCarton(carton.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? accentColor
                            : theme.colorScheme.outlineVariant,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withOpacity(0.22),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Cartón ${index + 1}',
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '· 3 sub-cartones · 45 números',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LotaCardWidget(
                                model: carton,
                                compact: true,
                                accentColor: _cardColors[carton.id],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: cardColor?.onPrimary ?? Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _selectedIds.isNotEmpty ? _startGame : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              _selectedIds.isEmpty
                  ? 'Seleccioná al menos un cartón'
                  : 'Comenzar con ${_selectedIds.length} cartón(es)',
            ),
          ),
        ),
      ),
    );
  }
}
