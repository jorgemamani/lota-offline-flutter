import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../dependency_injection.dart';
import '../../../../routing/route_names.dart';
import '../../../../shared/constants/app_colors.dart';
import '../../../../shared/managers/alert_manager.dart';
import '../../../../shared/constants/lota_card_colors.dart';
import '../../data/carton_manager.dart';
import '../../domain/models/favorite_carton.dart';
import '../../domain/models/game_mode.dart';
import '../../domain/models/lota_card_model.dart';
import '../bloc/game_bloc.dart';
import '../cubit/favorites_cubit.dart';
import '../widgets/lota_card_widget.dart';
import 'game_play_page.dart';

// ── Args ──────────────────────────────────────────────────────────────────

class CartonSelectArgs {
  const CartonSelectArgs({required this.mode});
  final GameMode mode;
}

// ── Page ──────────────────────────────────────────────────────────────────

class CartonSelectPage extends StatefulWidget {
  const CartonSelectPage({super.key, required this.args});

  final CartonSelectArgs args;

  @override
  State<CartonSelectPage> createState() => _CartonSelectPageState();
}

class _CartonSelectPageState extends State<CartonSelectPage>
    with SingleTickerProviderStateMixin {
  // ── Lista de cartones (tab "Todos") ───────────────────────────────
  final List<LotaCardModel> _available = [];
  final Map<String, LotaCardColor> _cardColors = {};
  late final ScrollController _scrollController;
  bool _isLoadingMore = false;
  final _random = Random();

  // ── Selección para iniciar partida (compartida entre tabs) ────────
  /// Mapa de id → modelo: usa el content-hash para favoritos y el id
  /// de sesión para los cartones del tab "Todos".
  final Map<String, LotaCardModel> _selectedCards = {};
  final Map<String, LotaCardColor> _selectedColors = {};

  // ── Tabs ──────────────────────────────────────────────────────────
  late final TabController _tabController;

  static const _pageSize = 10;
  static const _maxCartones = 50;
  static const _maxSelection = 3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController = ScrollController()..addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Paginación ────────────────────────────────────────────────────

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
    setState(() => _isLoadingMore = true);
    final newCards = sl<CartonManager>().generateCards(toLoad);
    const palette = LotaCardColors.all;
    setState(() {
      for (final card in newCards) {
        _cardColors[card.id] = palette[_random.nextInt(palette.length)];
      }
      _available.addAll(newCards);
      _isLoadingMore = false;
    });
  }

  // ── Selección ─────────────────────────────────────────────────────

  void _toggleSelection(String id, LotaCardModel card, LotaCardColor color) {
    setState(() {
      if (_selectedCards.containsKey(id)) {
        _selectedCards.remove(id);
        _selectedColors.remove(id);
      } else if (_selectedCards.length < _maxSelection) {
        _selectedCards[id] = card;
        _selectedColors[id] = color;
      } else {
        AlertManager.showSnackBarWarning(
          message: 'Máximo $_maxSelection cartones permitidos.',
        );
      }
    });
  }

  // ── Inicio de partida ─────────────────────────────────────────────

  void _startGame() {
    if (_selectedCards.isEmpty) return;
    final selected = _selectedCards.values.toList();
    context.read<GameBloc>().add(GameStarted(
          mode: widget.args.mode,
          cartones: selected,
        ));
    context.pushReplacement(
      RouteNames.gamePlay,
      extra: GamePlayArgs(
        mode: widget.args.mode,
        cartones: selected,
        cardColors: Map.from(_selectedColors),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedCards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Elegir cartones — ${widget.args.mode.label}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.grid_view_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('Todos'),
                ],
              ),
            ),
            Tab(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 16),
                  SizedBox(width: 6),
                  Text('Favoritos'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _InfoBar(selectedCount: selectedCount, maxSelection: _maxSelection),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TodosTab(
                  available: _available,
                  cardColors: _cardColors,
                  selectedIds: _selectedCards.keys.toSet(),
                  isLoadingMore: _isLoadingMore,
                  scrollController: _scrollController,
                  maxSelection: _maxSelection,
                  onToggleSelect: _toggleSelection,
                ),
                _FavoritosTab(
                  selectedIds: _selectedCards.keys.toSet(),
                  maxSelection: _maxSelection,
                  onToggleSelect: _toggleSelection,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: selectedCount > 0 ? _startGame : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              selectedCount == 0
                  ? 'Seleccioná al menos un cartón'
                  : 'Comenzar con $selectedCount cartón(es)',
            ),
          ),
        ),
      ),
    );
  }
}

// ── Info bar ──────────────────────────────────────────────────────────────

class _InfoBar extends StatelessWidget {
  const _InfoBar({required this.selectedCount, required this.maxSelection});

  final int selectedCount;
  final int maxSelection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Seleccioná hasta $maxSelection cartones para jugar.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (selectedCount > 0)
            Chip(
              label: Text('$selectedCount/$maxSelection seleccionado(s)'),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

// ── Tab Todos ─────────────────────────────────────────────────────────────

class _TodosTab extends StatelessWidget {
  const _TodosTab({
    required this.available,
    required this.cardColors,
    required this.selectedIds,
    required this.isLoadingMore,
    required this.scrollController,
    required this.maxSelection,
    required this.onToggleSelect,
  });

  final List<LotaCardModel> available;
  final Map<String, LotaCardColor> cardColors;
  final Set<String> selectedIds;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final int maxSelection;
  final void Function(String id, LotaCardModel card, LotaCardColor color)
      onToggleSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: available.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        if (index == available.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final carton = available[index];
        final color = cardColors[carton.id]!;
        return _CartonListItem(
          carton: carton,
          cardColor: color,
          label: 'Cartón ${index + 1}',
          selectionId: carton.id,
          isSelected: selectedIds.contains(carton.id),
          canSelect: selectedIds.length < maxSelection ||
              selectedIds.contains(carton.id),
          onTap: () => onToggleSelect(carton.id, carton, color),
        );
      },
    );
  }
}

// ── Tab Favoritos ─────────────────────────────────────────────────────────

class _FavoritosTab extends StatelessWidget {
  const _FavoritosTab({
    required this.selectedIds,
    required this.maxSelection,
    required this.onToggleSelect,
  });

  final Set<String> selectedIds;
  final int maxSelection;
  final void Function(String id, LotaCardModel card, LotaCardColor color)
      onToggleSelect;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.items.isEmpty) {
          return const _EmptyFavorites();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final fav = state.items[index];
            final carton = fav.toLotaCardModel();
            final color = LotaCardColors.all[fav.colorIndex];
            return _CartonListItem(
              carton: carton,
              cardColor: color,
              label: 'Favorito ${index + 1}',
              selectionId: fav.id,
              isSelected: selectedIds.contains(fav.id),
              canSelect: selectedIds.length < maxSelection ||
                  selectedIds.contains(fav.id),
              onTap: () => onToggleSelect(fav.id, carton, color),
            );
          },
        );
      },
    );
  }
}

// ── Empty state favoritos ─────────────────────────────────────────────────

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 72,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin favoritos todavía',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tocá ★ en cualquier cartón\npara guardarlo aquí.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Carton List Item ──────────────────────────────────────────────────────

/// Tarjeta de cartón reutilizable para ambos tabs.
///
/// Muestra el cartón con:
///   • Checkmark (arriba-izq) cuando está seleccionado para jugar.
///   • Botón de estrella (arriba-der) para agregar/quitar de favoritos.
///   • Borde animado de color cuando está seleccionado.
class _CartonListItem extends StatelessWidget {
  const _CartonListItem({
    required this.carton,
    required this.cardColor,
    required this.label,
    required this.selectionId,
    required this.isSelected,
    required this.canSelect,
    required this.onTap,
  });

  final LotaCardModel carton;
  final LotaCardColor cardColor;
  final String label;

  /// ID usado para la selección de partida (puede ser id de sesión o content-hash).
  final String selectionId;
  final bool isSelected;

  /// false cuando ya se alcanzó el máximo de selección y este no está seleccionado.
  final bool canSelect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = cardColor.primary;
    final contentId = FavoriteCarton.idFromGrid(carton.card);
    final colorIndex =
        LotaCardColors.all.indexWhere((c) => c.primary == cardColor.primary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? accentColor : theme.colorScheme.outlineVariant,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.22),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila del título: checkmark · label · descripción · estrella
              Row(
                children: [
                  if (isSelected) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: cardColor.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '· 3 sub-cartones · 45 números',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Estrella alineada con el texto del título
                  BlocBuilder<FavoritesCubit, FavoritesState>(
                    builder: (context, favState) {
                      final isFav = favState.isFavorite(contentId);
                      return GestureDetector(
                        onTap: () => context.read<FavoritesCubit>().toggle(
                              grid: carton.card,
                              colorIndex: colorIndex < 0 ? 0 : colorIndex,
                            ),
                        child: Tooltip(
                          message:
                              isFav ? 'Quitar de favoritos' : 'Guardar favorito',
                          child: Icon(
                            isFav
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 22,
                            color: isFav
                                ? AppColors.favorite
                                : theme.colorScheme.outlineVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LotaCardWidget(
                model: carton,
                compact: true,
                accentColor: cardColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
