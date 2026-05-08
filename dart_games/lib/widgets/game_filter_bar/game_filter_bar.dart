import 'package:flutter/material.dart';

import '../../constants/test_keys.dart';
import '../../models/game_metadata.dart';
import 'multi_select_filter_dropdown.dart';

/// Sticky bar of multi-select filter dropdowns, rendered between the
/// home-screen AppBar and the scrollable game-card grid.
///
/// Each dropdown represents one [FilterCriterion]. Within a single
/// criterion, multiple selections OR together (a game matches if any of
/// its values is selected). Across criteria, selections AND together (a
/// game must satisfy every active criterion to be shown).
///
/// Empty selection for a criterion is treated as "no filter applied" and
/// matches all games — that's the default state, so the home screen
/// renders all games until the user makes a selection.
///
/// The bar is stateless w.r.t. the selections: state lives in the parent
/// (the home screen). [onFiltersChanged] fires every time a checkbox
/// toggles so the parent can re-filter the games list immediately.
class GameFilterBar extends StatelessWidget {
  /// Currently-active filter selections, keyed by criterion. Missing or
  /// empty entries mean "no filter active for that criterion".
  final Map<FilterCriterion, Set<Object>> filters;

  /// Called whenever the selection for any criterion changes. The parent
  /// is expected to update its state and re-render the filtered games.
  final ValueChanged<Map<FilterCriterion, Set<Object>>> onFiltersChanged;

  const GameFilterBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  void _setSelection<T>(FilterCriterion criterion, Set<T> next) {
    final newFilters = Map<FilterCriterion, Set<Object>>.from(filters);
    if (next.isEmpty) {
      newFilters.remove(criterion);
    } else {
      newFilters[criterion] = next.cast<Object>();
    }
    onFiltersChanged(newFilters);
  }

  @override
  Widget build(BuildContext context) {
    final maxPlayersSel =
        (filters[FilterCriterion.maxPlayers] ?? <Object>{})
            .cast<MaxPlayersBucket>();
    final styleSel =
        (filters[FilterCriterion.gameplayStyle] ?? <Object>{})
            .cast<GameplayStyle>();
    final interactionSel =
        (filters[FilterCriterion.playerInteraction] ?? <Object>{})
            .cast<PlayerInteraction>();
    final lengthSel =
        (filters[FilterCriterion.gameLength] ?? <Object>{}).cast<GameLength>();
    final soloTeamSel =
        (filters[FilterCriterion.soloTeam] ?? <Object>{})
            .cast<SoloTeamSupport>();

    return Material(
      key: HomeKeys.filterBar,
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SingleChildScrollView(
          // Horizontal scroll so a narrow viewport doesn't clip the
          // last dropdown. The bar itself stays vertically sticky thanks
          // to the parent Column[FilterBar, Expanded(grid)] layout.
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MultiSelectFilterDropdown<MaxPlayersBucket>(
                buttonKey: HomeKeys.filterMaxPlayersButton,
                menuItemKey: HomeKeys.filterMaxPlayersOption,
                label: FilterCriterion.maxPlayers.label,
                options: {
                  for (final v in MaxPlayersBucket.values) v: v.label,
                },
                selected: maxPlayersSel,
                onChanged: (s) => _setSelection(FilterCriterion.maxPlayers, s),
              ),
              const SizedBox(width: 8),
              MultiSelectFilterDropdown<GameplayStyle>(
                buttonKey: HomeKeys.filterGameplayStyleButton,
                menuItemKey: HomeKeys.filterGameplayStyleOption,
                label: FilterCriterion.gameplayStyle.label,
                options: {
                  for (final v in GameplayStyle.values) v: v.label,
                },
                selected: styleSel,
                onChanged: (s) =>
                    _setSelection(FilterCriterion.gameplayStyle, s),
              ),
              const SizedBox(width: 8),
              MultiSelectFilterDropdown<PlayerInteraction>(
                buttonKey: HomeKeys.filterPlayerInteractionButton,
                menuItemKey: HomeKeys.filterPlayerInteractionOption,
                label: FilterCriterion.playerInteraction.label,
                options: {
                  for (final v in PlayerInteraction.values) v: v.label,
                },
                selected: interactionSel,
                onChanged: (s) =>
                    _setSelection(FilterCriterion.playerInteraction, s),
              ),
              const SizedBox(width: 8),
              MultiSelectFilterDropdown<GameLength>(
                buttonKey: HomeKeys.filterGameLengthButton,
                menuItemKey: HomeKeys.filterGameLengthOption,
                label: FilterCriterion.gameLength.label,
                options: {
                  for (final v in GameLength.values) v: v.label,
                },
                selected: lengthSel,
                onChanged: (s) =>
                    _setSelection(FilterCriterion.gameLength, s),
              ),
              const SizedBox(width: 8),
              MultiSelectFilterDropdown<SoloTeamSupport>(
                buttonKey: HomeKeys.filterSoloTeamButton,
                menuItemKey: HomeKeys.filterSoloTeamOption,
                label: FilterCriterion.soloTeam.label,
                options: {
                  for (final v in SoloTeamSupport.values) v: v.label,
                },
                selected: soloTeamSel,
                onChanged: (s) =>
                    _setSelection(FilterCriterion.soloTeam, s),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
