import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'design_components.dart';

/// Values captured by [ObservationForm].
class ObservationDraft {
  const ObservationDraft({
    required this.target,
    required this.notes,
    required this.skyQuality,
    required this.equipment,
  });

  final String target;
  final String notes;
  final int skyQuality;
  final String equipment;
}

/// Quick-entry observation form (aim: save in under 30 s). Time and location
/// are filled in by the caller, not typed by the user.
class ObservationForm extends StatefulWidget {
  const ObservationForm({
    super.key,
    this.initialTarget,
    required this.onSubmit,
  });

  final String? initialTarget;
  final ValueChanged<ObservationDraft> onSubmit;

  @override
  State<ObservationForm> createState() => _ObservationFormState();
}

class _ObservationFormState extends State<ObservationForm> {
  final _formKey = GlobalKey<FormState>();
  late final _target = TextEditingController(text: widget.initialTarget);
  final _notes = TextEditingController();
  int _sky = 3;
  String _equipment = 'Naked eye';

  static const _skyLabels = ['Poor', 'Fair', 'OK', 'Good', 'Excellent'];

  static const _equipmentOptions = [
    'Naked eye',
    'Binoculars',
    'Telescope',
    'Phone camera',
  ];

  @override
  void dispose() {
    _target.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      ObservationDraft(
        target: _target.text.trim(),
        notes: _notes.text.trim(),
        skyQuality: _sky,
        equipment: _equipment,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _target,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'What did you see?'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notes,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Notes (optional)'),
          ),
          const SizedBox(height: 24),
          SectionLabel(
            'Sky conditions',
            padding: const EdgeInsets.only(left: 4),
            trailing: Text(
              _skyLabels[_sky - 1],
              style: Theme.of(context).textTheme.labelLarge!
                  .copyWith(color: SkyTokens.of(context).primary),
            ),
          ),
          Slider(
            value: _sky.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _skyLabels[_sky - 1],
            onChanged: (v) => setState(() => _sky = v.round()),
          ),
          const SectionLabel(
            'Equipment',
            padding: EdgeInsets.only(left: 4, top: Space.sm, bottom: Space.md),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _equipmentOptions)
                ChoiceChip(
                  label: Text(e),
                  selected: _equipment == e,
                  onSelected: (_) => setState(() => _equipment = e),
                ),
            ],
          ),
          const SizedBox(height: Space.xl),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Save observation'),
          ),
        ],
      ),
    );
  }
}
