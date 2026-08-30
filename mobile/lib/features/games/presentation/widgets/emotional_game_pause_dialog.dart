import 'package:flutter/material.dart';

import 'game_system_components.dart';

enum EmotionalGamePauseAction { resume, rules, exit }

/// Menu pause commun aux jeux de régulation émotionnelle.
///
/// Rendu strictement identique à celui des autres jeux via [GamePauseScaffold]
/// (titre « Pause », sélecteur d'entrée, options audio, puis les actions). Les
/// options audio sont gérées directement par le [SoundService] partagé.
class EmotionalGamePauseDialog extends StatefulWidget {
  const EmotionalGamePauseDialog({
    super.key,
    required this.buttonsInput,
    required this.onInputMode,
    this.showRules = true,
  });

  final bool buttonsInput;
  final ValueChanged<bool> onInputMode;
  final bool showRules;

  @override
  State<EmotionalGamePauseDialog> createState() =>
      _EmotionalGamePauseDialogState();
}

class _EmotionalGamePauseDialogState extends State<EmotionalGamePauseDialog> {
  late bool _buttons = widget.buttonsInput;

  @override
  Widget build(BuildContext context) {
    return GamePauseScaffold(
      inputMode: GamePauseInputModeToggle(
        buttonsSelected: _buttons,
        onChanged: (value) {
          setState(() => _buttons = value);
          widget.onInputMode(value);
        },
      ),
      buttons: [
        GamePrimaryButton(
          label: 'Resume',
          onPressed: () =>
              Navigator.of(context).pop(EmotionalGamePauseAction.resume),
        ),
        if (widget.showRules)
          GameOutlineButton(
            label: 'View rules / Help',
            onPressed: () =>
                Navigator.of(context).pop(EmotionalGamePauseAction.rules),
          ),
        GamePauseExitButton(
          label: 'Exit mission',
          onPressed: () =>
              Navigator.of(context).pop(EmotionalGamePauseAction.exit),
        ),
      ],
    );
  }
}
