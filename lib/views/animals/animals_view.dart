// lib/views/animals/animals_view.dart
import 'package:dairy_farm_app/data/models/animal_event_model.dart';
import 'package:dairy_farm_app/data/models/animal_model.dart';
import 'package:dairy_farm_app/data/models/vaccination_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../controllers/animal_controller.dart';
import '../../controllers/production_controller.dart';

class AnimalsView extends StatelessWidget {
  const AnimalsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AnimalController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Animals',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAnimalDialog(context, ctrl),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Animal'),
              ),
            ]),
            const SizedBox(height: 4),
            const Text('Click an animal to view details, events, vaccinations and calves',
                style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 16),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LEFT: animal list ──────────────────────────────────
                  SizedBox(
                    width: 290,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12)),
                          ),
                          child: Obx(() => Row(children: [
                                const Icon(Icons.pets,
                                    size: 16, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                    '${ctrl.animals.where((a) => a.isActive).length} Active Animals',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13)),
                              ])),
                        ),
                        Expanded(
                          child: Obx(() {
                            if (ctrl.isLoading.value) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (ctrl.animals.isEmpty) {
                              return const Center(
                                  child: Text('No animals yet',
                                      style: TextStyle(
                                          color: Colors.black45)));
                            }
                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: ctrl.animals.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: Color(0xFFEEEEEE)),
                              itemBuilder: (_, i) => _AnimalListTile(
                                  animal: ctrl.animals[i],
                                  index: i,
                                  ctrl: ctrl),
                            );
                          }),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ── RIGHT: detail panel ────────────────────────────────
                  Expanded(
                    child: Obx(() {
                      final a = ctrl.selectedAnimal.value;
                      if (a == null) {
                        return Card(
                          margin: EdgeInsets.zero,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.pets_outlined,
                                    size: 56, color: Colors.black12),
                                const SizedBox(height: 12),
                                const Text('Select an animal from the list',
                                    style: TextStyle(
                                        color: Colors.black38, fontSize: 15)),
                              ],
                            ),
                          ),
                        );
                      }
                      return _AnimalDetailPanel(animal: a, ctrl: ctrl);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add / Edit animal dialog ───────────────────────────────────────────────
  static void _showAnimalDialog(BuildContext context, AnimalController ctrl,
      {AnimalModel? animal, int? fixedMotherId}) {
    final tagCtrl           = TextEditingController(text: animal?.tagNumber ?? '');
    final nameCtrl          = TextEditingController(text: animal?.name ?? '');
    final breedCtrl         = TextEditingController(text: animal?.breed ?? '');
    final dobCtrl           = TextEditingController(text: animal?.dateOfBirth ?? '');
    final purchaseDateCtrl  = TextEditingController(text: animal?.purchaseDate ?? '');
    final purchasePriceCtrl = TextEditingController(
        text: animal?.purchasePrice != null
            ? animal!.purchasePrice!.toStringAsFixed(0)
            : '');
    final fatherTagCtrl = TextEditingController(text: animal?.fatherTag ?? '');
    final notesCtrl     = TextEditingController(text: animal?.notes ?? '');
    final gender        = (animal?.gender ?? 'Female').obs;
    final isActive      = (animal?.isActive ?? true).obs;
    final isCalf        = fixedMotherId != null;

    Get.dialog(AlertDialog(
      title: Text(animal == null
          ? (isCalf ? 'Record Calf Birth' : 'Add Animal')
          : 'Edit Animal'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (isCalf)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(children: [
                  const Icon(Icons.child_care, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Calf will be linked to mother ID $fixedMotherId',
                      style: TextStyle(
                          color: Colors.green.shade700, fontSize: 12)),
                ]),
              ),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: tagCtrl,
                      decoration: const InputDecoration(labelText: 'Tag Number *'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: breedCtrl,
                      decoration: const InputDecoration(labelText: 'Breed'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: dobCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Date of Birth', hintText: 'yyyy-mm-dd'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: Obx(() => DropdownButtonFormField<String>(
                      value: gender.value,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: ['Female', 'Male']
                          .map((g) =>
                              DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => gender.value = v ?? 'Female',
                    )),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: fatherTagCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Father Tag (optional)'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: purchaseDateCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Purchase Date', hintText: 'yyyy-mm-dd'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: purchasePriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Purchase Price (Rs.)',
                          prefixText: 'Rs. '))),
            ]),
            const SizedBox(height: 12),
            TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 8),
            Obx(() => SwitchListTile(
                  title: const Text('Active Animal'),
                  value: isActive.value,
                  onChanged: (v) => isActive.value = v,
                  contentPadding: EdgeInsets.zero,
                )),
          ]),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (tagCtrl.text.trim().isEmpty) return;
            final model = AnimalModel(
              id: animal?.id,
              tagNumber: tagCtrl.text.trim(),
              name: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
              breed: breedCtrl.text.trim().isEmpty ? null : breedCtrl.text.trim(),
              dateOfBirth: dobCtrl.text.trim().isEmpty ? null : dobCtrl.text.trim(),
              gender: gender.value,
              motherId: fixedMotherId ?? animal?.motherId,
              fatherTag: fatherTagCtrl.text.trim().isEmpty
                  ? null
                  : fatherTagCtrl.text.trim(),
              purchaseDate: purchaseDateCtrl.text.trim().isEmpty
                  ? null
                  : purchaseDateCtrl.text.trim(),
              purchasePrice: double.tryParse(purchasePriceCtrl.text),
              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
              isActive: isActive.value,
              inProduction: animal?.inProduction,
              createdAt: animal?.createdAt ?? DateTime.now().toIso8601String(),
            );
            if (animal == null) {
              isCalf ? ctrl.addCalf(model) : ctrl.addAnimal(model);
            } else {
              isCalf ? ctrl.updateCalf(model) : ctrl.updateAnimal(model);
            }
            Get.back();
          },
          child: Text(animal == null
              ? (isCalf ? 'Record Birth' : 'Add')
              : 'Update'),
        ),
      ],
    ));
  }
}

// ── Animal list tile ──────────────────────────────────────────────────────────
class _AnimalListTile extends StatelessWidget {
  final AnimalModel animal;
  final int index;
  final AnimalController ctrl;
  const _AnimalListTile(
      {required this.animal, required this.index, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    // ── FIX: wrap in Obx and explicitly read alertAnimalIds.value so
    // GetX registers this widget as a subscriber. Previously, calling
    // ctrl.hasAlert() through a method did not guarantee the Obx tracked
    // alertAnimalIds as a dependency, leaving the badge stale after done.
    return Obx(() {
      final isSelected = ctrl.selectedAnimal.value?.id == animal.id;
      // Explicit .value read — this is what registers the Obx dependency.
      final alertIds = ctrl.alertAnimalIds.value;
      final hasAlert = alertIds.contains(animal.id ?? -1);

      return InkWell(
        onTap: () => ctrl.selectAnimal(animal),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: isSelected
              ? AppTheme.primary.withOpacity(0.08)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: animal.isActive
                    ? AppTheme.primary.withOpacity(0.12)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: animal.isActive
                          ? AppTheme.primary
                          : Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(animal.tagNumber,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.black87)),
                    if (!animal.isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text('Inactive',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade600)),
                      ),
                    ],
                    if (animal.isCalf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                                color: Colors.green.shade200)),
                        child: Text('Calf',
                            style: TextStyle(
                                fontSize: 9,
                                color: Colors.green.shade700)),
                      ),
                    ],
                  ]),
                  Text(
                      '${animal.name ?? "—"}'
                      '${animal.breed != null ? " · ${animal.breed}" : ""}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45)),
                ],
              ),
            ),
            if (hasAlert)
              Tooltip(
                message: 'Vaccination due soon',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.vaccines,
                        size: 11, color: Colors.red.shade600),
                    const SizedBox(width: 3),
                    Text('Due',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.chevron_right,
                    size: 16, color: AppTheme.primary),
              ),
          ]),
        ),
      );
    });
  }
}

// ── Detail panel (right side) ─────────────────────────────────────────────────
class _AnimalDetailPanel extends StatelessWidget {
  final AnimalModel animal;
  final AnimalController ctrl;
  const _AnimalDetailPanel({required this.animal, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: DefaultTabController(
        length: 4,
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12)),
            ),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    animal.tagNumber.length >= 3
                        ? animal.tagNumber.substring(0, 3)
                        : animal.tagNumber,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(animal.tagNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.primary)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: animal.isActive
                              ? Colors.green.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: animal.isActive
                                  ? Colors.green.shade300
                                  : Colors.grey.shade300),
                        ),
                        child: Text(animal.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: animal.isActive
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600)),
                      ),
                      // ── FIX: explicitly read alertAnimalIds.value so this
                      // Obx is properly subscribed and rebuilds when the list
                      // changes (e.g. after marking a vaccination as done).
                      Obx(() {
                        final alertIds = ctrl.alertAnimalIds.value;
                        final hasAlert = alertIds.contains(animal.id ?? -1);
                        return hasAlert
                            ? Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: Colors.red.shade300),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.warning_amber,
                                          size: 13,
                                          color: Colors.red.shade600),
                                      const SizedBox(width: 4),
                                      Text('Vaccination Due',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade700)),
                                    ]),
                              )
                            : const SizedBox.shrink();
                      }),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                        '${animal.name ?? "Unnamed"}'
                        '${animal.breed != null ? " · ${animal.breed}" : ""}'
                        ' · ${animal.gender}',
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 13)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit animal',
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppTheme.info),
                onPressed: () =>
                    AnimalsView._showAnimalDialog(context, ctrl, animal: animal),
              ),
              IconButton(
                tooltip: 'Delete animal',
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppTheme.danger),
                onPressed: () => ctrl.deleteAnimal(animal.id!),
              ),
            ]),
          ),

          // Tabs
          const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info_outline, size: 16), text: 'Info'),
              Tab(icon: Icon(Icons.event_note_outlined, size: 16), text: 'Events'),
              Tab(icon: Icon(Icons.vaccines_outlined, size: 16), text: 'Vaccinations'),
              Tab(icon: Icon(Icons.child_care_outlined, size: 16), text: 'Calves'),
            ],
          ),

          Expanded(
            child: Obx(() {
              if (ctrl.isDetailLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return TabBarView(children: [
                _InfoTab(animal: animal),
                _EventsTab(animal: animal, ctrl: ctrl),
                _VaccinationsTab(animal: animal, ctrl: ctrl),
                _CalvesTab(animal: animal, ctrl: ctrl),
              ]);
            }),
          ),
        ]),
      ),
    );
  }
}

// ── Info tab ──────────────────────────────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  final AnimalModel animal;
  const _InfoTab({required this.animal});

  @override
  Widget build(BuildContext context) {
    final ageM   = animal.ageInMonths;
    final ageStr = ageM == null
        ? '—'
        : ageM >= 12
            ? '${(ageM / 12).floor()} yr ${ageM % 12} mo'
            : '$ageM mo';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Animal Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _infoChip('Tag Number', animal.tagNumber, Icons.tag),
            _infoChip('Name', animal.name ?? '—', Icons.pets),
            _infoChip('Breed', animal.breed ?? '—', Icons.category_outlined),
            _infoChip('Gender', animal.gender, Icons.transgender),
            _infoChip('Date of Birth', animal.dateOfBirth ?? '—',
                Icons.cake_outlined),
            _infoChip('Age', ageStr, Icons.timelapse_outlined),
            if (animal.fatherTag != null)
              _infoChip('Father Tag', animal.fatherTag!, Icons.male),
            if (animal.purchaseDate != null)
              _infoChip('Purchase Date', animal.purchaseDate!,
                  Icons.calendar_today_outlined),
            if (animal.purchasePrice != null)
              _infoChip('Purchase Price',
                  'Rs. ${animal.purchasePrice!.toStringAsFixed(0)}',
                  Icons.payments_outlined),
            _infoChip(
              'Production Status',
              animal.inProduction ? 'In Production' : 'Not in Production',
              Icons.opacity,
            ),
          ],
        ),
        if (animal.notes != null && animal.notes!.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Notes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(animal.notes!,
                style: const TextStyle(color: Colors.black54)),
          ),
        ],
      ]),
    );
  }

  Widget _infoChip(String label, String value, IconData icon) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Icon(icon, size: 15, color: AppTheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: Colors.black38)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Events tab ────────────────────────────────────────────────────────────────
class _EventsTab extends StatelessWidget {
  final AnimalModel animal;
  final AnimalController ctrl;
  const _EventsTab({required this.animal, required this.ctrl});

  Color _typeColor(AnimalEventType t) {
    switch (t) {
      case AnimalEventType.heat:
      case AnimalEventType.heatDetection:     return Colors.deepOrange;
      case AnimalEventType.insemination:
      case AnimalEventType.breedingDate:      return Colors.purple;
      case AnimalEventType.pregnancyCheck:    return Colors.pink;
      case AnimalEventType.expectedDelivery:  return Colors.indigo;
      case AnimalEventType.delivery:
      case AnimalEventType.birth:             return Colors.green;
      case AnimalEventType.lactationStart:    return AppTheme.primary;
      case AnimalEventType.dryOff:
      case AnimalEventType.lactationEnd:      return Colors.blueGrey;
      case AnimalEventType.illness:
      case AnimalEventType.injury:            return Colors.red;
      case AnimalEventType.treatment:
      case AnimalEventType.surgery:           return Colors.teal;
      case AnimalEventType.deworming:         return Colors.cyan.shade700;
      case AnimalEventType.vaccination:       return Colors.blue;
      case AnimalEventType.weightCheck:       return Colors.indigo;
      case AnimalEventType.milkTest:          return AppTheme.primary;
      case AnimalEventType.bodyConditionScore:return Colors.brown;
      case AnimalEventType.other:             return Colors.blueGrey;
    }
  }

  IconData _typeIcon(AnimalEventType t) {
    switch (t) {
      case AnimalEventType.heat:
      case AnimalEventType.heatDetection:     return Icons.thermostat;
      case AnimalEventType.insemination:
      case AnimalEventType.breedingDate:      return Icons.science_outlined;
      case AnimalEventType.pregnancyCheck:    return Icons.pregnant_woman;
      case AnimalEventType.expectedDelivery:  return Icons.event_outlined;
      case AnimalEventType.delivery:
      case AnimalEventType.birth:             return Icons.child_care;
      case AnimalEventType.lactationStart:    return Icons.opacity;
      case AnimalEventType.dryOff:
      case AnimalEventType.lactationEnd:      return Icons.stop_circle_outlined;
      case AnimalEventType.illness:
      case AnimalEventType.injury:            return Icons.sick_outlined;
      case AnimalEventType.treatment:
      case AnimalEventType.surgery:           return Icons.medication_outlined;
      case AnimalEventType.deworming:         return Icons.biotech_outlined;
      case AnimalEventType.vaccination:       return Icons.vaccines_outlined;
      case AnimalEventType.weightCheck:       return Icons.monitor_weight_outlined;
      case AnimalEventType.milkTest:          return Icons.science;
      case AnimalEventType.bodyConditionScore:return Icons.assessment_outlined;
      case AnimalEventType.other:             return Icons.event_note_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          const Text('Animal Events',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
            onPressed: () => _showAddEventDialog(context, animal, ctrl),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add Event', style: TextStyle(fontSize: 13)),
          ),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: Obx(() {
          final events = ctrl.animalEvents;
          if (events.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.event_note_outlined,
                    size: 40, color: Colors.black12),
                const SizedBox(height: 8),
                const Text('No events recorded yet',
                    style: TextStyle(color: Colors.black38)),
                const SizedBox(height: 4),
                const Text(
                    'Tap "Add Event" to log insemination, delivery, etc.',
                    style: TextStyle(color: Colors.black26, fontSize: 12)),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: events.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, i) {
              final e     = events[i];
              final color = _typeColor(e.eventType);
              final icon  = _typeIcon(e.eventType);
              return ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                title: Row(children: [
                  Flexible(
                    child: Text(e.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(e.eventType.label,
                        style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600)),
                  ),
                ]),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.eventDate,
                        style: const TextStyle(fontSize: 11)),
                    if (e.result != null)
                      Text('Result: ${e.result}',
                          style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w500)),
                    if (e.description != null)
                      Text(e.description!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black45)),
                  ],
                ),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 15, color: Colors.black38),
                    onPressed: () =>
                        _showAddEventDialog(context, animal, ctrl, event: e),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: AppTheme.danger),
                    onPressed: () => ctrl.deleteEvent(e.id!),
                  ),
                ]),
                isThreeLine: e.result != null || e.description != null,
              );
            },
          );
        }),
      ),
    ]);
  }

  void _showAddEventDialog(
    BuildContext context,
    AnimalModel animal,
    AnimalController ctrl, {
    AnimalEventModel? event,
  }) {
    final titleCtrl  = TextEditingController(text: event?.title ?? '');
    final dateCtrl   = TextEditingController(
        text: event?.eventDate ??
            DateTime.now().toIso8601String().substring(0, 10));
    final descCtrl   = TextEditingController(text: event?.description ?? '');
    final resultCtrl = TextEditingController(text: event?.result ?? '');
    final notesCtrl  = TextEditingController(text: event?.notes ?? '');
    final eventType  =
        (event?.eventType ?? AnimalEventType.insemination).obs;

    Get.dialog(AlertDialog(
      title: Text(event == null
          ? 'Add Event — ${animal.tagNumber}'
          : 'Edit Event',
          style: const TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Obx(() => DropdownButtonFormField<AnimalEventType>(
                  value: eventType.value,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Event Type *'),
                  items: _buildGroupedItems(),
                  onChanged: (v) {
                    if (v != null) {
                      eventType.value = v;
                      if (titleCtrl.text.isEmpty) {
                        titleCtrl.text = v.label;
                      }
                    }
                  },
                )),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: titleCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Title *'))),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                      controller: dateCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Date', hintText: 'yyyy-mm-dd'))),
            ]),
            const SizedBox(height: 12),
            TextField(
                controller: resultCtrl,
                decoration: const InputDecoration(
                    labelText: 'Result / Value (optional)',
                    hintText: 'e.g. Positive, Pregnant, 450 kg, 12 L/day')),
            const SizedBox(height: 12),
            TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Description (optional)')),
            const SizedBox(height: 12),
            TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes')),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (titleCtrl.text.trim().isEmpty) return;
            final model = AnimalEventModel(
              id: event?.id,
              animalId: animal.id!,
              eventType: eventType.value,
              eventDate: dateCtrl.text.trim(),
              title: titleCtrl.text.trim(),
              description: descCtrl.text.trim().isEmpty
                  ? null
                  : descCtrl.text.trim(),
              result: resultCtrl.text.trim().isEmpty
                  ? null
                  : resultCtrl.text.trim(),
              notes: notesCtrl.text.trim().isEmpty
                  ? null
                  : notesCtrl.text.trim(),
              createdAt:
                  event?.createdAt ?? DateTime.now().toIso8601String(),
            );
            event == null
                ? ctrl.addEvent(model)
                : ctrl.updateEvent(model);
            Get.back();
          },
          child: Text(event == null ? 'Add' : 'Update'),
        ),
      ],
    ));
  }

  List<DropdownMenuItem<AnimalEventType>> _buildGroupedItems() {
    final items = <DropdownMenuItem<AnimalEventType>>[];
    AnimalEventType.groups.forEach((groupLabel, types) {
      items.add(DropdownMenuItem<AnimalEventType>(
        enabled: false,
        value: null,
        child: Text(
          groupLabel.toUpperCase(),
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black38,
              letterSpacing: 0.8),
        ),
      ));
      for (final t in types) {
        items.add(DropdownMenuItem<AnimalEventType>(
          value: t,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(t.label, style: const TextStyle(fontSize: 13)),
          ),
        ));
      }
    });
    return items;
  }
}

// ── Vaccinations tab ──────────────────────────────────────────────────────────
class _VaccinationsTab extends StatelessWidget {
  final AnimalModel animal;
  final AnimalController ctrl;
  const _VaccinationsTab({required this.animal, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          const Text('Vaccination History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8)),
            onPressed: () =>
                _showAddVaccinationDialog(context, animal, ctrl),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add', style: TextStyle(fontSize: 13)),
          ),
        ]),
      ),
      const Divider(height: 1),
      Expanded(
        child: Obx(() {
          final list = ctrl.animalVaccinations;
          if (list.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.vaccines_outlined,
                    size: 40, color: Colors.black12),
                const SizedBox(height: 8),
                const Text('No vaccination records yet',
                    style: TextStyle(color: Colors.black38)),
              ]),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (context, i) {
              final v = list[i];
              final isDue = v.nextDueDate != null &&
                  !v.isDone &&
                  DateTime.tryParse(v.nextDueDate!)
                          ?.isBefore(DateTime.now()) ==
                      true;
              final isDueSoon = v.nextDueDate != null &&
                  !v.isDone &&
                  !isDue &&
                  DateTime.tryParse(v.nextDueDate!)?.isBefore(
                          DateTime.now().add(const Duration(days: 7))) ==
                      true;

              return ListTile(
                dense: true,
                leading: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: v.isDone
                        ? Colors.grey.shade100
                        : isDue
                            ? Colors.red.shade50
                            : isDueSoon
                                ? Colors.orange.shade50
                                : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                      v.isDone
                          ? Icons.check_circle_outline
                          : Icons.vaccines,
                      size: 18,
                      color: v.isDone
                          ? Colors.grey
                          : isDue
                              ? Colors.red.shade600
                              : isDueSoon
                                  ? Colors.orange.shade600
                                  : Colors.teal),
                ),
                title: Row(children: [
                  Flexible(
                    child: Text(v.vaccineName,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration:
                                v.isDone ? TextDecoration.lineThrough : null,
                            color: v.isDone
                                ? Colors.black38
                                : Colors.black87)),
                  ),
                  if (v.isDone) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Text('Done',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ]),
                subtitle: Text(
                    'Given: ${v.vaccinationDate}'
                    '${v.givenBy != null ? " by ${v.givenBy}" : ""}',
                    style: const TextStyle(fontSize: 11)),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  if (v.nextDueDate != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: v.isDone
                            ? Colors.grey.shade100
                            : isDue
                                ? Colors.red.shade50
                                : isDueSoon
                                    ? Colors.orange.shade50
                                    : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: v.isDone
                                ? Colors.grey.shade300
                                : isDue
                                    ? Colors.red.shade300
                                    : isDueSoon
                                        ? Colors.orange.shade300
                                        : Colors.grey.shade300),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if ((isDue || isDueSoon) && !v.isDone)
                          Icon(
                              isDue
                                  ? Icons.error_outline
                                  : Icons.warning_amber,
                              size: 12,
                              color: isDue
                                  ? Colors.red.shade600
                                  : Colors.orange.shade600),
                        if ((isDue || isDueSoon) && !v.isDone)
                          const SizedBox(width: 4),
                        Text('Due: ${v.nextDueDate}',
                            style: TextStyle(
                                fontSize: 11,
                                color: v.isDone
                                    ? Colors.black38
                                    : isDue
                                        ? Colors.red.shade700
                                        : isDueSoon
                                            ? Colors.orange.shade700
                                            : Colors.black54,
                                fontWeight:
                                    (isDue || isDueSoon) && !v.isDone
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                      ]),
                    ),
                  if (!v.isDone && v.nextDueDate != null) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Mark as done',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => ctrl.markVaccinationDone(v),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check,
                                    size: 13,
                                    color: Colors.green.shade700),
                                const SizedBox(width: 3),
                                Text('Done',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.bold)),
                              ]),
                        ),
                      ),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 16, color: AppTheme.danger),
                    onPressed: () => ctrl.deleteVaccination(v.id!),
                  ),
                ]),
              );
            },
          );
        }),
      ),
    ]);
  }

  void _showAddVaccinationDialog(BuildContext context,
      AnimalModel animal, AnimalController ctrl) {
    final vaccineCtrl = TextEditingController();
    final dateCtrl    = TextEditingController(
        text: DateTime.now().toIso8601String().substring(0, 10));
    final nextDueCtrl = TextEditingController();
    final givenByCtrl = TextEditingController();
    final notesCtrl   = TextEditingController();

    Get.dialog(AlertDialog(
      title: Text('Add Vaccination — ${animal.tagNumber}'),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: vaccineCtrl,
              decoration:
                  const InputDecoration(labelText: 'Vaccine Name *')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: dateCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Date Given',
                        hintText: 'yyyy-mm-dd'))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: nextDueCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Next Due Date',
                        hintText: 'yyyy-mm-dd'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: givenByCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Given By (Vet)'))),
            const SizedBox(width: 12),
            Expanded(
                child: TextField(
                    controller: notesCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Notes'))),
          ]),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (vaccineCtrl.text.trim().isEmpty) return;
            ctrl.addVaccination(VaccinationModel(
              animalId: animal.id!,
              vaccineName: vaccineCtrl.text.trim(),
              vaccinationDate: dateCtrl.text.trim(),
              nextDueDate: nextDueCtrl.text.trim().isEmpty
                  ? null
                  : nextDueCtrl.text.trim(),
              givenBy: givenByCtrl.text.trim().isEmpty
                  ? null
                  : givenByCtrl.text.trim(),
              notes: notesCtrl.text.trim().isEmpty
                  ? null
                  : notesCtrl.text.trim(),
              createdAt: DateTime.now().toIso8601String(),
            ));
            Get.back();
          },
          child: const Text('Add'),
        ),
      ],
    ));
  }
}

// ── Calves tab ────────────────────────────────────────────────────────────────
class _CalvesTab extends StatelessWidget {
  final AnimalModel animal;
  final AnimalController ctrl;
  const _CalvesTab({required this.animal, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isFemale = animal.gender == 'Female';

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Row(children: [
          const Text('Calves / Offspring',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          if (isFemale)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8)),
              onPressed: () => AnimalsView._showAnimalDialog(
                  context, ctrl,
                  fixedMotherId: animal.id),
              icon: const Icon(Icons.child_care, size: 14),
              label: const Text('Record Birth',
                  style: TextStyle(fontSize: 13)),
            ),
        ]),
      ),
      const Divider(height: 1),
      if (!isFemale)
        const Expanded(
          child: Center(
              child: Text('Only female animals can have calves.',
                  style: TextStyle(color: Colors.black38))),
        )
      else
        Expanded(
          child: Obx(() {
            final calves = ctrl.animalChildren;
            if (calves.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.child_care_outlined,
                      size: 40, color: Colors.black12),
                  const SizedBox(height: 8),
                  const Text('No calves recorded yet',
                      style: TextStyle(color: Colors.black38)),
                  const SizedBox(height: 4),
                  Text(
                      'Tap "Record Birth" to add a calf for ${animal.tagNumber}',
                      style: const TextStyle(
                          color: Colors.black26, fontSize: 12)),
                ]),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: calves.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
              itemBuilder: (context, i) {
                final calf   = calves[i];
                final ageM   = calf.ageInMonths;
                final ageStr = ageM == null
                    ? '—'
                    : ageM >= 12
                        ? '${(ageM / 12).floor()}yr ${ageM % 12}mo'
                        : '${ageM}mo';

                return ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.child_care,
                        size: 18, color: Colors.green.shade600),
                  ),
                  title: Text(
                      '${calf.tagNumber}${calf.name != null ? " · ${calf.name}" : ""}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${calf.gender} · ${calf.breed ?? "Unknown breed"}'
                          '${calf.dateOfBirth != null ? " · Born ${calf.dateOfBirth}" : ""}',
                          style: const TextStyle(fontSize: 11)),
                      if (calf.inProduction)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.opacity,
                                    size: 11,
                                    color: AppTheme.primary
                                        .withOpacity(0.7)),
                                const SizedBox(width: 3),
                                Text('In production',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppTheme.primary
                                            .withOpacity(0.8),
                                        fontWeight: FontWeight.w500)),
                              ]),
                        ),
                    ],
                  ),
                  isThreeLine: calf.inProduction,
                  trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6)),
                          child: Text('Age: $ageStr',
                              style: const TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 4),
                        if (calf.gender == 'Female' && !calf.inProduction)
                          Tooltip(
                            message: 'Calf is ready to milk — add to production',
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () async {
                                await ctrl.addCalfToProduction(calf);
                                final productionCtrl =
                                    Get.find<ProductionController>();
                                await productionCtrl.loadProductionForDate(
                                    productionCtrl.selectedDate.value);
                              },
                              icon: const Icon(Icons.opacity,
                                  size: 13, color: Colors.white),
                              label: const Text('Add to Production',
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.white)),
                            ),
                          ),
                        if (calf.inProduction)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle,
                                      size: 13,
                                      color: AppTheme.primary),
                                  const SizedBox(width: 4),
                                  Text('In Production',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w600)),
                                ]),
                          ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: 'View calf',
                          icon: const Icon(Icons.open_in_new,
                              size: 15, color: AppTheme.info),
                          onPressed: () => ctrl.selectAnimal(calf),
                        ),
                        IconButton(
                          tooltip: 'Edit calf',
                          icon: const Icon(Icons.edit_outlined,
                              size: 15, color: Colors.black45),
                          onPressed: () =>
                              AnimalsView._showAnimalDialog(
                                  context, ctrl,
                                  animal: calf,
                                  fixedMotherId: animal.id),
                        ),
                      ]),
                );
              },
            );
          }),
        ),
    ]);
  }
}