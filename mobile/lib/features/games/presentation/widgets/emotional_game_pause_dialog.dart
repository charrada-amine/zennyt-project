import 'package:flutter/material.dart';

import 'game_system_components.dart';

enum EmotionalGamePauseAction { resume, rules, exit }

/// Menu pause commun aux jeux de régulation émotionnelle.
///
/// Il conserve les options d'accessibilité déjà utilisées par Emotional Radar
/// et évite que Reflective Pause introduise un second menu divergent.
class EmotionalGamePauseDialog extends StatefulWidget {
  const EmotionalGamePauseDialog({
    super.key,
    required this.soundEffects,
    required this.music,
    required this.buttonsInput,
    required this.onSoundEffects,
    required this.onMusic,
    required this.onInputMode,
  });

  final bool soundEffects;
  final bool music;
  final bool buttonsInput;
  final ValueChanged<bool> onSoundEffects;
  final ValueChanged<bool> onMusic;
  final ValueChanged<bool> onInputMode;

  @override
  State<EmotionalGamePauseDialog> createState() =>
      _EmotionalGamePauseDialogState();
}

class _EmotionalGamePauseDialogState extends State<EmotionalGamePauseDialog> {
  late bool _sound = widget.soundEffects;
  late bool _music = widget.music;
  late bool _buttons = widget.buttonsInput;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 60),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pause',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: ZennytGamePalette.blue,
              ),
            ),
            const SizedBox(height: 26),
            const _SectionTitle('Input mode'),
            const SizedBox(height: 12),
            _InputModeToggle(
              buttonsSelected: _buttons,
              onChanged: (value) {
                setState(() => _buttons = value);
                widget.onInputMode(value);
              },
            ),
            const SizedBox(height: 22),
            const _SectionTitle('Audio options'),
            const SizedBox(height: 12),
            _AudioRow(
              label: 'Sound effects',
              value: _sound,
              onChanged: (value) {
                setState(() => _sound = value);
                widget.onSoundEffects(value);
              },
            ),
            const SizedBox(height: 10),
            _AudioRow(
              label: 'Music',
              value: _music,
              onChanged: (value) {
                setState(() => _music = value);
                widget.onMusic(value);
              },
            ),
            const SizedBox(height: 18),
            GamePrimaryButton(
              label: 'Resume',
              onPressed: () =>
                  Navigator.of(context).pop(EmotionalGamePauseAction.resume),
            ),
            const SizedBox(height: 12),
            GameOutlineButton(
              label: 'View rules / Help',
              onPressed: () =>
                  Navigator.of(context).pop(EmotionalGamePauseAction.rules),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () =>
                    Navigator.of(context).pop(EmotionalGamePauseAction.exit),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB33B3B),
                  backgroundColor: const Color(0xFFFDF6F6),
                  side: const BorderSide(color: Color(0xFFF3C9C9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Exit mission',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: ZennytGamePalette.blue,
    ),
  );
}

class _InputModeToggle extends StatelessWidget {
  const _InputModeToggle({
    required this.buttonsSelected,
    required this.onChanged,
  });

  final bool buttonsSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleHalf(
              label: 'Buttons',
              selected: buttonsSelected,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleHalf(
              label: 'Tactile',
              selected: !buttonsSelected,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleHalf extends StatelessWidget {
  const _ToggleHalf({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label input mode',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? ZennytGamePalette.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : ZennytGamePalette.blue,
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioRow extends StatelessWidget {
  const _AudioRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ZennytGamePalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: ZennytGamePalette.blue,
              ),
            ),
          ),
          Text(
            value ? 'On' : 'Off',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: value ? const Color(0xFF197340) : ZennytGamePalette.muted,
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
