import 'package:flutter/material.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'edit_score_dialog_config.dart';

/// Shows a modal dialog for editing three dart scores.
///
/// [playerName] — shown in the dialog title.
/// [initialSegments] — current dart segments (e.g. ['S20', 'D15', 'Miss']).
///   The list may have 0–3 elements; missing darts start with no ring selected.
/// [onSubmit] — called with the new list of 3 segment strings on confirm.
/// [config] — visual styling; use [EditScoreDialogConfig.carnivalDerby()] or
///   [EditScoreDialogConfig.targetTag()] (or a custom instance).
/// [dartBorderColors] — optional per-dart score box border color overrides.
///   When provided, each non-null entry overrides the config's default border
///   color for that dart index. Used by Target Tag for result-based coloring.
Future<void> showEditScoreDialog({
  required BuildContext context,
  required String playerName,
  required List<String> initialSegments,
  required void Function(List<String>) onSubmit,
  required EditScoreDialogConfig config,
  List<Color?>? dartBorderColors,
}) async {
  final dart1 = _parseScore(initialSegments.isNotEmpty ? initialSegments[0] : '');
  final dart2 = _parseScore(initialSegments.length > 1 ? initialSegments[1] : '');
  final dart3 = _parseScore(initialSegments.length > 2 ? initialSegments[2] : '');

  final Map<int, String?> selectedRings = {
    0: dart1['ring'] as String?,
    1: dart2['ring'] as String?,
    2: dart3['ring'] as String?,
  };
  final Map<int, int?> selectedNumbers = {
    0: dart1['number'] as int?,
    1: dart2['number'] as int?,
    2: dart3['number'] as int?,
  };

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          bool isValidSelection = true;
          for (int i = 0; i < 3; i++) {
            final ring = selectedRings[i];
            final number = selectedNumbers[i];
            if (ring == null) {
              isValidSelection = false;
              break;
            }
            if (ring == 'Single (inner)' ||
                ring == 'Single (outer)' ||
                ring == 'Double' ||
                ring == 'Triple') {
              if (number == null) {
                isValidSelection = false;
                break;
              }
            }
          }

          return Dialog(
            key: EditScoreDialogKeys.dialogContainer,
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1000),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: config.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: config.borderColor,
                  width: config.borderWidth,
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Edit $playerName's score",
                      style: config.titleStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(3, (dartIndex) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: dartIndex == 0 ? 0 : 8,
                              right: dartIndex == 2 ? 0 : 8,
                            ),
                            child: _buildDartScoreSection(
                              dartIndex,
                              initialSegments,
                              selectedRings,
                              selectedNumbers,
                              setState,
                              config,
                              dartBorderColors,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          key: EditScoreDialogKeys.cancelButton,
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: config.cancelButtonColor,
                            foregroundColor: config.cancelButtonForeground,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Cancel', style: config.cancelButtonTextStyle),
                        ),
                        ElevatedButton(
                          key: EditScoreDialogKeys.saveButton,
                          onPressed: isValidSelection
                              ? () {
                                  final newSegments = <String>[];
                                  for (int i = 0; i < 3; i++) {
                                    newSegments.add(_buildSegment(
                                      selectedRings[i]!,
                                      selectedNumbers[i],
                                    ));
                                  }
                                  onSubmit(newSegments);
                                  Navigator.of(dialogContext).pop();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: config.submitButtonColor,
                            foregroundColor: config.submitButtonForeground,
                            disabledBackgroundColor:
                                Colors.grey.withOpacity(0.3),
                            disabledForegroundColor: Colors.white38,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('Update score',
                              style: config.submitButtonTextStyle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _parseScore(String segment) {
  if (segment.isEmpty || segment == '-') {
    return {'ring': null, 'number': null};
  } else if (segment == 'Miss') {
    return {'ring': 'Miss', 'number': null};
  } else if (segment == 'Bull') {
    return {'ring': 'Bullseye', 'number': null};
  } else if (segment == '25') {
    return {'ring': 'Outer Bull', 'number': null};
  } else {
    final match = RegExp(r'([SDTsdt])(\d+)').firstMatch(segment);
    if (match != null) {
      final prefix = match.group(1)!;
      final number = int.parse(match.group(2)!);
      String ring;
      if (prefix == 'D' || prefix == 'd') {
        ring = 'Double';
      } else if (prefix == 'T' || prefix == 't') {
        ring = 'Triple';
      } else if (prefix == 's') {
        ring = 'Single (inner)';
      } else {
        ring = 'Single (outer)';
      }
      return {'ring': ring, 'number': number};
    }
  }
  return {'ring': null, 'number': null};
}

String _buildSegment(String ring, int? number) {
  if (ring == 'Bullseye') return 'Bull';
  if (ring == 'Outer Bull') return '25';
  if (ring == 'Miss') return 'Miss';
  final prefix = ring == 'Double'
      ? 'D'
      : ring == 'Triple'
          ? 'T'
          : ring == 'Single (inner)'
              ? 's'
              : 'S';
  return '$prefix$number';
}

Widget _buildDartScoreSection(
  int dartIndex,
  List<String> dartSegments,
  Map<int, String?> selectedRings,
  Map<int, int?> selectedNumbers,
  StateSetter setState,
  EditScoreDialogConfig config,
  List<Color?>? dartBorderColors,
) {
  final segment = dartIndex < dartSegments.length ? dartSegments[dartIndex] : '';

  // Determine score box border color
  final borderColor = (dartBorderColors != null &&
          dartIndex < dartBorderColors.length &&
          dartBorderColors[dartIndex] != null)
      ? dartBorderColors[dartIndex]!
      : config.scoreBoxDefaultBorderColor;

  // Determine display text for score box
  final displayText = segment.isEmpty
      ? '-'
      : (config.scoreDisplayTransform != null
          ? config.scoreDisplayTransform!(segment)
          : segment);

  // Determine the key based on dart index
  final Key? dartKey = dartIndex == 0
      ? EditScoreDialogKeys.dart1Dropdown
      : dartIndex == 1
          ? EditScoreDialogKeys.dart2Dropdown
          : EditScoreDialogKeys.dart3Dropdown;

  return Column(
    key: dartKey,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Dart label (D1, D2, D3)
      Text(
        'D${dartIndex + 1}',
        style: config.dartLabelStyle,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 6),

      // Score display box
      Container(
        height: 50,
        decoration: BoxDecoration(
          color: config.scoreBoxBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 3),
        ),
        child: Center(
          child: Text(
            displayText,
            style: segment.isEmpty
                ? config.scoreTextStyle.copyWith(color: Colors.white38)
                : config.scoreTextStyle,
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Ring buttons — top group (singles, double, triple)
      _buildSmallRingButton('Single (inner)', selectedRings[dartIndex],
          (ring) => setState(() => selectedRings[dartIndex] = ring), config),
      const SizedBox(height: 6),
      _buildSmallRingButton('Single (outer)', selectedRings[dartIndex],
          (ring) => setState(() => selectedRings[dartIndex] = ring), config),
      const SizedBox(height: 6),
      _buildSmallRingButton('Double', selectedRings[dartIndex],
          (ring) => setState(() => selectedRings[dartIndex] = ring), config),
      const SizedBox(height: 6),
      _buildSmallRingButton('Triple', selectedRings[dartIndex],
          (ring) => setState(() => selectedRings[dartIndex] = ring), config),
      const SizedBox(height: 12),

      // Number grid — 4 rows × 5 columns (1–20)
      ...List.generate(4, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (colIndex) {
              final num = rowIndex * 5 + colIndex + 1;
              final isSelected = selectedNumbers[dartIndex] == num;
              final isDisabled = selectedRings[dartIndex] == 'Outer Bull' ||
                  selectedRings[dartIndex] == 'Bullseye' ||
                  selectedRings[dartIndex] == 'Miss';

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: colIndex == 0 ? 0 : 3,
                    right: colIndex == 4 ? 0 : 3,
                  ),
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton(
                      onPressed: isDisabled
                          ? null
                          : () => setState(
                              () => selectedNumbers[dartIndex] = num),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? config.buttonSelectedColor
                            : config.buttonUnselectedColor,
                        foregroundColor: isSelected
                            ? config.buttonSelectedForeground
                            : config.buttonUnselectedForeground,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        '$num',
                        style: config.buttonTextStyle,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),

      const SizedBox(height: 12),

      // Ring buttons — bottom group (bulls + miss)
      _buildSmallRingButton(
          'Outer Bull',
          selectedRings[dartIndex],
          (ring) => setState(() {
                selectedRings[dartIndex] = ring;
                selectedNumbers[dartIndex] = null;
              }),
          config),
      const SizedBox(height: 6),
      _buildSmallRingButton(
          'Bullseye',
          selectedRings[dartIndex],
          (ring) => setState(() {
                selectedRings[dartIndex] = ring;
                selectedNumbers[dartIndex] = null;
              }),
          config),
      const SizedBox(height: 6),
      _buildSmallRingButton(
          'Miss',
          selectedRings[dartIndex],
          (ring) => setState(() {
                selectedRings[dartIndex] = ring;
                selectedNumbers[dartIndex] = null;
              }),
          config),
    ],
  );
}

Widget _buildSmallRingButton(
  String ring,
  String? currentRing,
  void Function(String) onSelect,
  EditScoreDialogConfig config,
) {
  final isSelected = currentRing == ring;

  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () => onSelect(ring),
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? config.buttonSelectedColor : config.buttonUnselectedColor,
        foregroundColor: isSelected
            ? config.buttonSelectedForeground
            : config.buttonUnselectedForeground,
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      child: Text(ring, style: config.buttonTextStyle),
    ),
  );
}
