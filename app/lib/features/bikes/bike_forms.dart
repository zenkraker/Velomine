import 'package:flutter/material.dart';
import 'package:velomine_api/api.dart';

import '../../core/l10n.dart';
import '../../core/widgets/app_text_field.dart';
import '../../l10n/generated/app_localizations.dart';
import 'component_names.dart';
import 'part_identity.dart';
import '../../core/tokens.dart';
import '../../core/motion.dart';

const bikeKindIds = [
  'road',
  'gravel',
  'mountain',
  'ebike',
  'timetrial',
  'track',
  'city',
  'other',
];

/// The name of a kind of bike in the language on screen; an unknown kind is shown as the server sent it.
String bikeKindName(AppLocalizations l10n, String kind) => switch (kind) {
  'road' => l10n.bikeKindRoad,
  'gravel' => l10n.bikeKindGravel,
  'mountain' => l10n.bikeKindMountain,
  'ebike' => l10n.bikeKindEbike,
  'timetrial' => l10n.bikeKindTimeTrial,
  'track' => l10n.bikeKindTrack,
  'city' => l10n.bikeKindCity,
  'other' => l10n.bikeKindOther,
  _ => kind,
};

/// Rough rolling lengths for common wheel and tyre sizes. They vary with the tyre and the pressure:
/// the dialog says so, and the member can type their own measured value.
const wheelPresets = {
  '700×25c road': 2105,
  '700×32c': 2155,
  '700×40c gravel': 2200,
  '27.5×2.3 mountain': 2150,
  '29×2.2 mountain': 2290,
};

String? _text(String value) => value.trim().isEmpty ? null : value.trim();

double? _number(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.'));

enum _BikeProblem { name, year, wheelRange, initialDistance }

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class BikeFormData {
  const BikeFormData({
    required this.name,
    this.brand,
    this.model,
    this.modelYear,
    this.buildSpec,
    this.frameSize,
    required this.kind,
    required this.wheelMm,
    required this.initialKm,
    this.purchasedOn,
  });

  final String name;
  final String? brand;
  final String? model;
  final int? modelYear;
  final String? buildSpec;
  final String? frameSize;
  final String kind;
  final int wheelMm;
  final double initialKm;
  final DateTime? purchasedOn;

  CreateBikeRequest toCreate() => CreateBikeRequest(
    name: name,
    brand: Optional.present(brand),
    model: Optional.present(model),
    modelYear: Optional.present(modelYear),
    buildSpec: Optional.present(buildSpec),
    frameSize: Optional.present(frameSize),
    kind: kind,
    wheelCircumferenceMm: wheelMm,
    initialDistanceM: initialKm * 1000,
    purchasedOn: Optional.present(purchasedOn),
  );

  UpdateBikeRequest toUpdate({required bool isActive}) => UpdateBikeRequest(
    name: name,
    brand: Optional.present(brand),
    model: Optional.present(model),
    modelYear: Optional.present(modelYear),
    buildSpec: Optional.present(buildSpec),
    frameSize: Optional.present(frameSize),
    kind: kind,
    wheelCircumferenceMm: wheelMm,
    initialDistanceM: initialKm * 1000,
    purchasedOn: Optional.present(purchasedOn),
    isActive: Optional.present(isActive),
  );
}

Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) =>
    showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );

/// Add a bike, or change one when [bike] is given.
Future<BikeFormData?> showBikeForm(
  BuildContext context, {
  BikeResponse? bike,
}) => showModalBottomSheet<BikeFormData>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  // The sheet keeps the app's motion, or none when the system asks for none.
  sheetAnimationStyle: AnimationStyle(
    duration: motionDuration(context, AppMotion.standard),
  ),
  constraints: const BoxConstraints(maxWidth: 640),
  builder: (_) => _BikeForm(bike: bike),
);

class _BikeForm extends StatefulWidget {
  const _BikeForm({this.bike});

  final BikeResponse? bike;

  @override
  State<_BikeForm> createState() => _BikeFormState();
}

class _BikeFormState extends State<_BikeForm> {
  late final _name = TextEditingController(text: widget.bike?.name);
  late final _brand = TextEditingController(text: widget.bike?.brand);
  late final _model = TextEditingController(text: widget.bike?.model);
  late final _year = TextEditingController(
    text: widget.bike?.modelYear?.toString(),
  );
  late final _spec = TextEditingController(text: widget.bike?.buildSpec);
  late final _size = TextEditingController(text: widget.bike?.frameSize);
  late final _wheel = TextEditingController(
    text: '${widget.bike?.wheelCircumferenceMm ?? 2105}',
  );
  late final _initial = TextEditingController(
    text: widget.bike == null || widget.bike!.initialDistanceM == 0
        ? ''
        : (widget.bike!.initialDistanceM / 1000).toStringAsFixed(0),
  );
  late String _kind = widget.bike?.kind ?? 'road';
  late DateTime? _purchased = widget.bike?.purchasedOn;
  _BikeProblem? _problem;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _spec.dispose();
    _size.dispose();
    _wheel.dispose();
    _initial.dispose();
    super.dispose();
  }

  void _submit() {
    final wheel = int.tryParse(_wheel.text.trim());
    final initial = _initial.text.trim().isEmpty ? 0.0 : _number(_initial.text);
    final year = _year.text.trim().isEmpty
        ? null
        : int.tryParse(_year.text.trim());
    if (_name.text.trim().isEmpty) {
      setState(() => _problem = _BikeProblem.name);
    } else if (_year.text.trim().isNotEmpty &&
        (year == null || year < 1900 || year > 2100)) {
      setState(() => _problem = _BikeProblem.year);
    } else if (wheel == null || wheel < 1000 || wheel > 2600) {
      setState(() => _problem = _BikeProblem.wheelRange);
    } else if (initial == null || initial < 0) {
      setState(() => _problem = _BikeProblem.initialDistance);
    } else {
      Navigator.pop(
        context,
        BikeFormData(
          name: _name.text.trim(),
          brand: _text(_brand.text),
          model: _text(_model.text),
          modelYear: year,
          buildSpec: _text(_spec.text),
          frameSize: _text(_size.text),
          kind: _kind,
          wheelMm: wheel,
          initialKm: initial,
          purchasedOn: _purchased,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final problem = switch (_problem) {
      null => null,
      _BikeProblem.name => l10n.errorBikeName,
      _BikeProblem.year => l10n.errorModelYear,
      _BikeProblem.wheelRange => l10n.errorWheelRange,
      _BikeProblem.initialDistance => l10n.errorInitialDistance,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Text(
                  widget.bike == null ? l10n.addBikeTitle : l10n.editBikeTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextField(
                  key: const Key('bike-name'),
                  controller: _name,
                  decoration: InputDecoration(labelText: l10n.name),
                ),
                DropdownButtonFormField<String>(
                  key: const Key('bike-kind'),
                  initialValue: _kind,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.kind),
                  items: [
                    for (final id in bikeKindIds)
                      DropdownMenuItem(
                        value: id,
                        child: Text(bikeKindName(l10n, id)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _kind = v ?? _kind),
                ),
                Row(
                  spacing: AppSpacing.md,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('bike-brand'),
                        controller: _brand,
                        decoration: InputDecoration(labelText: l10n.brand),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('bike-model'),
                        controller: _model,
                        decoration: InputDecoration(labelText: l10n.model),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: AppSpacing.md,
                  children: [
                    Expanded(
                      child: AppTextField(
                        fieldKey: const Key('bike-year'),
                        controller: _year,
                        keyboardType: TextInputType.number,
                        label: l10n.modelYear,
                        helper: l10n.modelYearHelper,
                      ),
                    ),
                    Expanded(
                      child: AppTextField(
                        fieldKey: const Key('bike-size'),
                        controller: _size,
                        label: l10n.frameSize,
                        helper: l10n.frameSizeHelper,
                      ),
                    ),
                  ],
                ),
                AppTextField(
                  fieldKey: const Key('bike-spec'),
                  controller: _spec,
                  label: l10n.buildSpec,
                  helper: l10n.buildSpecHelper,
                ),
                AppTextField(
                  fieldKey: const Key('bike-wheel'),
                  controller: _wheel,
                  keyboardType: TextInputType.number,
                  label: l10n.wheelCircumference,
                  helper: l10n.wheelHelper,
                ),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final e in wheelPresets.entries)
                      ActionChip(
                        label: Text('${e.key} · ${e.value}'),
                        onPressed: () =>
                            setState(() => _wheel.text = '${e.value}'),
                      ),
                  ],
                ),
                AppTextField(
                  fieldKey: const Key('bike-initial'),
                  controller: _initial,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  label: l10n.initialDistance,
                  helper: l10n.initialHelper,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('bike-purchased'),
                    icon: const Icon(Icons.event),
                    label: Text(
                      _purchased == null
                          ? l10n.purchaseDate
                          : l10n.boughtOn(isoDate(_purchased!)),
                    ),
                    onPressed: () async {
                      final d = await _pickDate(context, _purchased);
                      if (d != null) setState(() => _purchased = dateOnly(d));
                    },
                  ),
                ),
                if (problem != null)
                  Text(
                    problem,
                    key: const Key('form-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          // Twice the text: the two actions stack instead of running off the sheet.
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              TextButton(
                key: const Key('bike-cancel'),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                key: const Key('bike-save'),
                onPressed: _submit,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PartFormData {
  const PartFormData({
    required this.type,
    this.brand,
    this.model,
    this.mpn,
    this.gtin,
    this.custom = false,
    required this.installedOn,
    this.removedOn,
    this.expectedKm,
    this.expectedHours,
    this.expectedMonths,
  });

  final String type;
  final String? brand;
  final String? model;
  final String? mpn;
  final String? gtin;
  final bool custom;
  final DateTime installedOn;
  final DateTime? removedOn;
  final double? expectedKm;
  final double? expectedHours;
  final int? expectedMonths;

  CreateComponentRequest toCreate() => CreateComponentRequest(
    type: type,
    brand: Optional.present(brand),
    model: Optional.present(model),
    mpn: Optional.present(mpn),
    gtin: Optional.present(gtin),
    custom: Optional.present(custom),
    installedOn: installedOn,
    removedOn: Optional.present(removedOn),
    expectedDistanceM: Optional.present(
      expectedKm == null ? null : expectedKm! * 1000,
    ),
    expectedHours: Optional.present(expectedHours),
    expectedMonths: Optional.present(expectedMonths),
  );

  UpdateComponentRequest toUpdate() => UpdateComponentRequest(
    type: type,
    brand: Optional.present(brand),
    model: Optional.present(model),
    mpn: Optional.present(mpn),
    gtin: Optional.present(gtin),
    custom: Optional.present(custom),
    installedOn: installedOn,
    removedOn: Optional.present(removedOn),
    expectedDistanceM: Optional.present(
      expectedKm == null ? null : expectedKm! * 1000,
    ),
    expectedHours: Optional.present(expectedHours),
    expectedMonths: Optional.present(expectedMonths),
  );
}

/// Add a part, change one ([part]), or fit a new one of the same kind ([replacing]: starts from the old limits, installed today).
/// [search] offers the parts the club has used before as the member types.
Future<PartFormData?> showPartForm(
  BuildContext context, {
  required List<ComponentTypeResponse> types,
  required DateTime today,
  required Future<List<PartResponse>> Function(String query, String? type)
  search,
  ComponentResponse? part,
  ComponentResponse? replacing,
}) => showModalBottomSheet<PartFormData>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 640),
  // The sheet keeps the app's motion, or none when the system asks for none.
  sheetAnimationStyle: AnimationStyle(
    duration: motionDuration(context, AppMotion.standard),
  ),
  builder: (_) => _PartForm(
    types: types,
    today: today,
    search: search,
    part: part,
    replacing: replacing,
  ),
);

class _PartForm extends StatefulWidget {
  const _PartForm({
    required this.types,
    required this.today,
    required this.search,
    this.part,
    this.replacing,
  });

  final List<ComponentTypeResponse> types;
  final DateTime today;
  final Future<List<PartResponse>> Function(String query, String? type) search;
  final ComponentResponse? part;
  final ComponentResponse? replacing;

  @override
  State<_PartForm> createState() => _PartFormState();
}

String _fmt(num? v) => v == null
    ? ''
    : (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1));

enum _PartProblem { type, limits, gtin, removedBeforeInstalled }

/// Asks for the name of a build template. Returns null when the member cancels.
Future<String?> showTemplateNameDialog(BuildContext context) =>
    showDialog<String>(
      context: context,
      builder: (_) => const _TemplateNameDialog(),
    );

class _TemplateNameDialog extends StatefulWidget {
  const _TemplateNameDialog();

  @override
  State<_TemplateNameDialog> createState() => _TemplateNameDialogState();
}

class _TemplateNameDialogState extends State<_TemplateNameDialog> {
  final _name = TextEditingController();
  bool _missing = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _missing = true);
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.saveTemplateTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          TextField(
            key: const Key('template-name'),
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.templateName,
              hintText: l10n.templateNameHint,
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_missing)
            Text(
              l10n.errorTemplateName,
              key: const Key('form-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('template-save'),
          onPressed: _submit,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// Picks one of the member's build templates. Returns null when there is none or the member closes it.
Future<BikeTemplateResponse?> showApplyTemplateDialog(
  BuildContext context, {
  required List<BikeTemplateResponse> templates,
}) => showDialog<BikeTemplateResponse>(
  context: context,
  builder: (context) {
    final l10n = context.l10n;
    return SimpleDialog(
      title: Text(l10n.applyTemplateTitle),
      children: templates.isEmpty
          ? [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(l10n.noTemplates, key: const Key('no-templates')),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close),
                ),
              ),
            ]
          : [
              for (final template in templates)
                SimpleDialogOption(
                  key: Key('template-${template.id}'),
                  onPressed: () => Navigator.pop(context, template),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name),
                      Text(
                        l10n.templateParts(template.parts.length),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
            ],
    );
  },
);

class _PartFormState extends State<_PartForm> {
  late final ComponentResponse? _from = widget.part ?? widget.replacing;
  late String? _type = _from?.type;
  late final _brand = TextEditingController(text: widget.part?.brand);
  late final _model = TextEditingController(text: widget.part?.model);
  late final _mpn = TextEditingController(text: widget.part?.mpn);
  late final _gtin = TextEditingController(text: widget.part?.gtin);
  late bool _custom =
      widget.part?.isCustom ?? widget.replacing?.isCustom ?? false;
  late final _km = TextEditingController(
    text: _fmt(
      _from?.expectedDistanceM == null
          ? null
          : _from!.expectedDistanceM! / 1000,
    ),
  );
  late final _hours = TextEditingController(text: _fmt(_from?.expectedHours));
  late final _months = TextEditingController(text: _fmt(_from?.expectedMonths));
  late DateTime _installed = widget.part?.installedOn ?? dateOnly(widget.today);
  late DateTime? _removed = widget.part?.removedOn;
  _PartProblem? _problem;

  @override
  void dispose() {
    _brand.dispose();
    _model.dispose();
    _mpn.dispose();
    _gtin.dispose();
    _km.dispose();
    _hours.dispose();
    _months.dispose();
    super.dispose();
  }

  /// A known part fills what the club already knows about it, so the member only confirms the dates and limits.
  void _applyKnownPart(PartResponse part) {
    setState(() {
      if (widget.replacing == null) {
        _type = part.type;
        if (widget.part == null) {
          final t = widget.types.where((t) => t.id == part.type).firstOrNull;
          if (t != null) {
            _km.text = _fmt(
              t.typicalDistanceM == null ? null : t.typicalDistanceM! / 1000,
            );
            _hours.text = _fmt(t.typicalHours);
            _months.text = _fmt(t.typicalMonths);
          }
        }
      }
      _brand.text = part.brand;
      _model.text = part.model;
      _mpn.text = part.mpn ?? '';
      _gtin.text = part.gtin ?? '';
    });
  }

  /// Picking a kind of part offers its typical limits, unless the member already typed some.
  void _pickType(String? id) {
    setState(() {
      _type = id;
      final t = widget.types.where((t) => t.id == id).firstOrNull;
      if (t == null || widget.part != null || widget.replacing != null) return;
      _km.text = _fmt(
        t.typicalDistanceM == null ? null : t.typicalDistanceM! / 1000,
      );
      _hours.text = _fmt(t.typicalHours);
      _months.text = _fmt(t.typicalMonths);
    });
  }

  void _submit() {
    double? limit(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? null : double.tryParse(t.replaceAll(',', '.'));
    }

    final km = limit(_km), hours = limit(_hours), months = limit(_months);
    final gtin = _text(_gtin.text);
    bool bad(double? v, TextEditingController c) =>
        c.text.trim().isNotEmpty && (v == null || v <= 0);
    if (_type == null) {
      setState(() => _problem = _PartProblem.type);
    } else if (bad(km, _km) || bad(hours, _hours) || bad(months, _months)) {
      setState(() => _problem = _PartProblem.limits);
    } else if (gtin != null && !isValidGtin(gtin)) {
      setState(() => _problem = _PartProblem.gtin);
    } else if (_removed != null && _removed!.isBefore(_installed)) {
      setState(() => _problem = _PartProblem.removedBeforeInstalled);
    } else {
      Navigator.pop(
        context,
        PartFormData(
          type: _type!,
          brand: _text(_brand.text),
          model: _text(_model.text),
          mpn: _text(_mpn.text),
          gtin: gtin,
          custom: _custom,
          installedOn: _installed,
          removedOn: _removed,
          expectedKm: km,
          expectedHours: hours,
          expectedMonths: months?.round(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final replacingName = widget.replacing == null
        ? ''
        : componentTypeName(
            l10n,
            widget.replacing!.type,
            widget.replacing!.typeName,
          );
    final title = widget.replacing != null
        ? l10n.replacePartTitle(replacingName.toLowerCase())
        : widget.part != null
        ? l10n.editPartTitle
        : l10n.addPartTitle;
    final problem = switch (_problem) {
      null => null,
      _PartProblem.type => l10n.errorChoosePart,
      _PartProblem.limits => l10n.errorLimits,
      _PartProblem.gtin => l10n.errorGtin,
      _PartProblem.removedBeforeInstalled => l10n.errorRemovedBeforeInstalled,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Container(
            width: 32,
            height: 4,
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.md,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Autocomplete<PartResponse>(
                  optionsBuilder: (value) async {
                    final text = value.text.trim();
                    if (text.length < 2) return const <PartResponse>[];
                    return widget.search(text, _type);
                  },
                  displayStringForOption: (p) =>
                      [p.brand, p.model].where((s) => s.isNotEmpty).join(' '),
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) =>
                          TextField(
                            key: const Key('part-search'),
                            controller: controller,
                            focusNode: focusNode,
                            decoration: InputDecoration(
                              labelText: l10n.findPart,
                              hintText: l10n.findPartHint,
                            ),
                          ),
                  onSelected: _applyKnownPart,
                ),
                DropdownButtonFormField<String>(
                  key: const Key('part-type'),
                  initialValue: _type,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.partLabel),
                  items: [
                    for (final t in widget.types)
                      DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          '${componentTypeName(l10n, t.id, t.name)} '
                          '(${componentGroupName(l10n, t.group)})',
                        ),
                      ),
                  ],
                  onChanged: widget.replacing != null ? null : _pickType,
                ),
                Row(
                  spacing: AppSpacing.md,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('part-brand'),
                        controller: _brand,
                        decoration: InputDecoration(labelText: l10n.brand),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('part-model'),
                        controller: _model,
                        decoration: InputDecoration(labelText: l10n.model),
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: AppSpacing.md,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('part-mpn'),
                        controller: _mpn,
                        decoration: InputDecoration(
                          labelText: l10n.mpn,
                          helperText: l10n.mpnHelper,
                          helperMaxLines: 3,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('part-gtin'),
                        controller: _gtin,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.gtin,
                          helperText: l10n.gtinHelper,
                          helperMaxLines: 3,
                        ),
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  key: const Key('part-custom'),
                  value: _custom,
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.custom),
                  subtitle: Text(l10n.customHelper),
                  onChanged: (v) => setState(() => _custom = v ?? false),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('part-installed'),
                    icon: const Icon(Icons.event),
                    label: Text(l10n.installedOn(isoDate(_installed))),
                    onPressed: () async {
                      final d = await _pickDate(context, _installed);
                      if (d != null) setState(() => _installed = dateOnly(d));
                    },
                  ),
                ),
                if (widget.part != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        TextButton.icon(
                          key: const Key('part-removed'),
                          icon: const Icon(Icons.event_busy),
                          label: Text(
                            _removed == null
                                ? l10n.stillOnBike
                                : l10n.removedOn(isoDate(_removed!)),
                          ),
                          onPressed: () async {
                            final d = await _pickDate(context, _removed);
                            if (d != null) {
                              setState(() => _removed = dateOnly(d));
                            }
                          },
                        ),
                        if (_removed != null)
                          IconButton(
                            tooltip: l10n.putBackOnBike,
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _removed = null),
                          ),
                      ],
                    ),
                  ),
                Text(
                  l10n.partLimitsHelp,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  spacing: AppSpacing.md,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('part-km'),
                        controller: _km,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'km'),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('part-hours'),
                        controller: _hours,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(labelText: l10n.hours),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('part-months'),
                        controller: _months,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: l10n.months),
                      ),
                    ),
                  ],
                ),
                if (problem != null)
                  Text(
                    problem,
                    key: const Key('form-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                key: const Key('part-save'),
                onPressed: _submit,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
