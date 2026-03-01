// lib/views/clients/clients_view.dart
import 'package:dairy_farm_app/data/models/client_model.dart';
import 'package:dairy_farm_app/data/models/monthly_bill_model.dart';
import 'package:dairy_farm_app/data/models/sale_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_theme.dart';
import '../../app/utils/excel_exporter.dart';
import '../../app/utils/format_utils.dart';
import '../../controllers/client_controller.dart';

class ClientsView extends StatefulWidget {
  const ClientsView({super.key});

  @override
  State<ClientsView> createState() => _ClientsViewState();
}

class _ClientsViewState extends State<ClientsView> {
  final _searchCtrl = TextEditingController();
  final _searchQuery = ''.obs;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ClientController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Clients',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
                Obx(() {
                  final active =
                      ctrl.clients.where((c) => c.isActive).length;
                  final inactive =
                      ctrl.clients.where((c) => !c.isActive).length;
                  final free = ctrl.clients
                      .where((c) => c.isActive && !c.isPayer)
                      .length;
                  return Text(
                    '$active active  ·  $inactive inactive'
                    '${free > 0 ? "  ·  $free free" : ""}  ·  ${ctrl.clients.length} total',
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 14),
                  );
                }),
              ]),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showClientDialog(context, ctrl),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Client',
                    style: TextStyle(fontSize: 15)),
              ),
            ]),
            const SizedBox(height: 16),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── LEFT: client list ───────────────────────────────────
                  SizedBox(
                    width: 320,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        // Stats bar
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12)),
                          ),
                          child: Obx(() {
                            final active = ctrl.clients
                                .where((c) => c.isActive)
                                .toList();
                            final totalL = active.fold(
                                0.0, (s, c) => s + c.allocatedLiters);
                            return Row(children: [
                              const Icon(Icons.people_outline,
                                  size: 16, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                  '${active.length} active · '
                                  '${formatL(totalL)} L/day',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary)),
                            ]);
                          }),
                        ),

                        // ── Search bar ─────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                          child: TextField(
                            controller: _searchCtrl,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search clients…',
                              hintStyle: const TextStyle(
                                  fontSize: 14, color: Colors.black38),
                              prefixIcon: const Icon(Icons.search,
                                  size: 18, color: Colors.black38),
                              suffixIcon: Obx(() => _searchQuery.value.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close,
                                          size: 16, color: Colors.black38),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        _searchQuery.value = '';
                                      },
                                    )
                                  : const SizedBox.shrink()),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Colors.black12)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: Colors.black12)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                      color: AppTheme.primary
                                          .withOpacity(0.5))),
                            ),
                            onChanged: (v) => _searchQuery.value = v.trim(),
                          ),
                        ),
                        const Divider(height: 1),

                        // Client list
                        Expanded(
                          child: Obx(() {
                            if (ctrl.isLoading.value) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final query = _searchQuery.value.toLowerCase();
                            final filtered = query.isEmpty
                                ? ctrl.clients
                                : ctrl.clients
                                    .where((c) => c.name
                                        .toLowerCase()
                                        .contains(query))
                                    .toList();

                            if (filtered.isEmpty) {
                              return Center(
                                child: Text(
                                  query.isEmpty
                                      ? 'No clients yet'
                                      : 'No clients match "$query"',
                                  style: const TextStyle(
                                      color: Colors.black45, fontSize: 14),
                                ),
                              );
                            }
                            return ListView.separated(
                              padding: EdgeInsets.zero,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (ctx, i) {
                                final client = filtered[i];
                                final pos = ctrl.clients
                                        .indexWhere(
                                            (c) => c.id == client.id) +
                                    1;
                                final isFirst = ctrl.clients.first.id ==
                                    client.id;
                                final isLast  = ctrl.clients.last.id ==
                                    client.id;
                                return _ClientListTile(
                                  client: client,
                                  position: pos,
                                  isFirst: isFirst,
                                  isLast: isLast,
                                  ctrl: ctrl,
                                  onEdit: () => _showClientDialog(
                                      context, ctrl,
                                      client: client),
                                  onMoveTo: () => _showMoveToDialog(
                                      context, ctrl, client),
                                  onDelete: () => _confirmDelete(
                                      context, ctrl, client),
                                );
                              },
                            );
                          }),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // ── RIGHT: profile panel ────────────────────────────────
                  Expanded(
                    child: Obx(() {
                      final client = ctrl.selectedClient.value;
                      if (client == null) {
                        return Card(
                          margin: EdgeInsets.zero,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_search_outlined,
                                    size: 60, color: Colors.black12),
                                const SizedBox(height: 12),
                                const Text(
                                    'Select a client to view profile',
                                    style: TextStyle(
                                        color: Colors.black38,
                                        fontSize: 16)),
                              ],
                            ),
                          ),
                        );
                      }
                      return _ClientProfilePanel(
                        client: client,
                        ctrl: ctrl,
                        onEdit: () => _showClientDialog(context, ctrl,
                            client: client),
                        onDeactivate: () =>
                            _confirmDeactivate(context, ctrl, client),
                      );
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

  // ── Add / Edit dialog ───────────────────────────────────────────────────
  static void _showClientDialog(BuildContext context, ClientController ctrl,
      {ClientModel? client}) {
    final nameCtrl   = TextEditingController(text: client?.name ?? '');
    final phoneCtrl  = TextEditingController(text: client?.phone ?? '');
    // Use formatL so existing values like 1.25 don't show as 1.2 in the field
    final litersCtrl = TextEditingController(
        text: client != null ? formatL(client.allocatedLiters) : '');
    final isActive = (client?.isActive ?? true).obs;
    final isPayer  = (client?.isPayer  ?? true).obs;

    Get.dialog(AlertDialog(
      title: Row(children: [
        Icon(client == null ? Icons.person_add : Icons.edit,
            color: AppTheme.primary, size: 24),
        const SizedBox(width: 10),
        Text(client == null ? 'Add Client' : 'Edit Client',
            style: const TextStyle(fontSize: 17)),
      ]),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: nameCtrl,
            autofocus: true,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Client Name *',
              labelStyle: TextStyle(fontSize: 15),
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneCtrl,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              labelStyle: TextStyle(fontSize: 15),
              prefixIcon: Icon(Icons.phone_outlined, size: 20),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: litersCtrl,
            style: const TextStyle(fontSize: 16),
            decoration: const InputDecoration(
              labelText: 'Daily Allocated Liters *',
              labelStyle: TextStyle(fontSize: 15),
              suffixText: 'L',
              prefixIcon: Icon(Icons.opacity, size: 20),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 14),
          Obx(() => SwitchListTile(
                title: const Text('Active Client',
                    style: TextStyle(fontSize: 15)),
                value: isActive.value,
                onChanged: (v) => isActive.value = v,
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primary,
              )),
          Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    title: const Text('Pays Bills',
                        style: TextStyle(fontSize: 15)),
                    subtitle: Text(
                      isPayer.value
                          ? 'Included in billing — amount due is calculated'
                          : 'FREE client — milk is deducted but no bill generated',
                      style: TextStyle(
                          fontSize: 12,
                          color: isPayer.value
                              ? Colors.black45
                              : Colors.orange.shade700),
                    ),
                    value: isPayer.value,
                    onChanged: (v) => isPayer.value = v,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primary,
                    inactiveThumbColor: Colors.orange,
                    inactiveTrackColor: Colors.orange.shade100,
                  ),
                  if (!isPayer.value)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(children: [
                        Icon(Icons.info_outline,
                            size: 15, color: Colors.orange.shade700),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Milk will be deducted from daily stock but this client '
                            'will NOT appear in billing reports.',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade800),
                          ),
                        ),
                      ]),
                    ),
                ],
              )),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontSize: 15))),
        ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty ||
                litersCtrl.text.trim().isEmpty) return;
            final model = ClientModel(
              id: client?.id,
              name: nameCtrl.text.trim(),
              phone: phoneCtrl.text.trim().isEmpty
                  ? null
                  : phoneCtrl.text.trim(),
              allocatedLiters: double.tryParse(litersCtrl.text) ?? 0,
              isActive: isActive.value,
              isPayer: isPayer.value,
              createdAt:
                  client?.createdAt ?? DateTime.now().toIso8601String(),
              sortOrder: client?.sortOrder ?? 0,
            );
            client == null
                ? ctrl.addClient(model)
                : ctrl.updateClient(model);
            Get.back();
          },
          child: Text(client == null ? 'Add Client' : 'Update',
              style: const TextStyle(fontSize: 15)),
        ),
      ],
    ));
  }

  // ── Move-to-position dialog ─────────────────────────────────────────────
  void _showMoveToDialog(
      BuildContext context, ClientController ctrl, ClientModel client) {
    final posCtrl = TextEditingController();
    Get.dialog(AlertDialog(
      title: Text('Move "${client.name}"',
          style: const TextStyle(fontSize: 17)),
      content: SizedBox(
        width: 300,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
              'Current position: ${ctrl.clients.indexWhere((c) => c.id == client.id) + 1}',
              style: const TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 14),
          TextField(
            controller: posCtrl,
            autofocus: true,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Move to position',
              labelStyle: const TextStyle(fontSize: 15),
              hintText: '1 – ${ctrl.clients.length}',
            ),
            keyboardType: TextInputType.number,
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontSize: 15))),
        ElevatedButton(
          onPressed: () {
            final pos = int.tryParse(posCtrl.text);
            if (pos != null) ctrl.moveTo(client, pos);
            Get.back();
          },
          child: const Text('Move', style: TextStyle(fontSize: 15)),
        ),
      ],
    ));
  }

  void _confirmDeactivate(
      BuildContext context, ClientController ctrl, ClientModel client) {
    Get.dialog(AlertDialog(
      title: const Text('Deactivate Client',
          style: TextStyle(fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(client.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
              'This client will be marked as INACTIVE.\n'
              'Their position number is PRESERVED in the list.\n'
              'All sales history is kept.',
              style: TextStyle(color: Colors.black54, fontSize: 14)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontSize: 15))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () {
            ctrl.deactivateClient(client.id!);
            Get.back();
          },
          child: const Text('Deactivate',
              style: TextStyle(fontSize: 15, color: Colors.white)),
        ),
      ],
    ));
  }

  // ── Hard delete dialog ──────────────────────────────────────────────────
  void _confirmDelete(
      BuildContext context, ClientController ctrl, ClientModel client) {
    Get.dialog(AlertDialog(
      title: Row(children: [
        const Icon(Icons.delete_forever, color: Colors.red, size: 22),
        const SizedBox(width: 8),
        const Text('Delete Client', style: TextStyle(fontSize: 17)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(client.name,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: const Text(
              '⚠️  This will PERMANENTLY delete the client and all their '
              'sales history. This cannot be undone.\n\n'
              'Only use this to remove accidentally added clients.',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(fontSize: 15))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            ctrl.deleteClient(client.id!);
            Get.back();
          },
          child: const Text('Delete Permanently',
              style: TextStyle(fontSize: 15, color: Colors.white)),
        ),
      ],
    ));
  }
}

// ── Client list tile ──────────────────────────────────────────────────────────
class _ClientListTile extends StatelessWidget {
  final ClientModel client;
  final int position;
  final bool isFirst;
  final bool isLast;
  final ClientController ctrl;
  final VoidCallback onEdit;
  final VoidCallback onMoveTo;
  final VoidCallback onDelete;

  const _ClientListTile({
    required this.client,
    required this.position,
    required this.isFirst,
    required this.isLast,
    required this.ctrl,
    required this.onEdit,
    required this.onMoveTo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = ctrl.selectedClient.value?.id == client.id;
      final inactive   = !client.isActive;
      final isFree     = client.isActive && !client.isPayer;

      return InkWell(
        onTap: () => ctrl.selectClient(client),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          color: inactive
              ? Colors.grey.shade50
              : isSelected
                  ? AppTheme.primary.withOpacity(0.08)
                  : Colors.transparent,
          padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
          child: Row(children: [
            // ── Position badge ─────────────────────────────────────────
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: inactive
                    ? Colors.grey.shade200
                    : isFree
                        ? Colors.orange.withOpacity(0.12)
                        : AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$position',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: inactive
                          ? Colors.grey
                          : isFree
                              ? Colors.orange.shade700
                              : AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // ── Name + allocation ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(
                        client.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: inactive
                                ? Colors.grey
                                : isSelected
                                    ? AppTheme.primary
                                    : Colors.black87,
                            decoration: inactive
                                ? TextDecoration.lineThrough
                                : null),
                      ),
                    ),
                    if (inactive) ...[
                      const SizedBox(width: 6),
                      _badge('INACTIVE', Colors.grey.shade200,
                          Colors.grey.shade600),
                    ],
                    if (isFree) ...[
                      const SizedBox(width: 6),
                      _badge('FREE', Colors.orange.shade100,
                          Colors.orange.shade800),
                    ],
                  ]),
                  Text(
                      '${formatL(client.allocatedLiters)} L/day'
                      '${client.phone != null ? "  ·  ${client.phone}" : ""}',
                      style: TextStyle(
                          fontSize: 12,
                          color: inactive
                              ? Colors.grey.shade400
                              : Colors.black45)),
                ],
              ),
            ),

            // ── Up / Down / Move / Edit / Delete buttons ───────────────
            Column(mainAxisSize: MainAxisSize.min, children: [
              _iconBtn(Icons.keyboard_arrow_up,
                  isFirst ? null : () => ctrl.moveUp(client)),
              _iconBtn(Icons.keyboard_arrow_down,
                  isLast ? null : () => ctrl.moveDown(client)),
            ]),
            IconButton(
              icon: const Icon(Icons.open_with,
                  size: 16, color: Colors.black38),
              tooltip: 'Move to position…',
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onMoveTo,
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 15, color: AppTheme.info),
              tooltip: 'Edit',
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 15, color: Colors.red),
              tooltip: 'Delete permanently',
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: onDelete,
            ),
          ]),
        ),
      );
    });
  }

  Widget _badge(String text, Color bg, Color fg) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(4)),
        child: Text(text,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: fg)),
      );

  Widget _iconBtn(IconData icon, VoidCallback? onTap) => SizedBox(
        width: 22,
        height: 22,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Icon(icon,
              size: 18,
              color: onTap == null ? Colors.black12 : Colors.black38),
        ),
      );
}

// ── Client profile panel ──────────────────────────────────────────────────────
class _ClientProfilePanel extends StatelessWidget {
  final ClientModel client;
  final ClientController ctrl;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;

  const _ClientProfilePanel({
    required this.client,
    required this.ctrl,
    required this.onEdit,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    final position =
        ctrl.clients.indexWhere((c) => c.id == client.id) + 1;
    final isFree = client.isActive && !client.isPayer;

    return Card(
      margin: EdgeInsets.zero,
      child: Column(children: [
        // ── Profile header ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
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
                color: client.isActive
                    ? (isFree
                        ? Colors.orange.withOpacity(0.15)
                        : AppTheme.primary.withOpacity(0.15))
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('#$position',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: client.isActive
                            ? (isFree
                                ? Colors.orange.shade700
                                : AppTheme.primary)
                            : Colors.grey)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(client.name,
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            decoration: client.isActive
                                ? null
                                : TextDecoration.lineThrough,
                            color: client.isActive
                                ? Colors.black87
                                : Colors.grey)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: client.isActive
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: client.isActive
                                ? Colors.green.shade300
                                : Colors.red.shade300),
                      ),
                      child: Text(
                          client.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: client.isActive
                                  ? Colors.green.shade700
                                  : Colors.red.shade700)),
                    ),
                    if (isFree) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.orange.shade300),
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.card_giftcard,
                                  size: 12,
                                  color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Text('FREE / Non-Payer',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700)),
                            ]),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Wrap(spacing: 16, children: [
                    if (client.phone != null)
                      _detail(Icons.phone_outlined, client.phone!),
                    _detail(Icons.opacity,
                        '${formatL(client.allocatedLiters)} L/day'),
                    _detail(Icons.calendar_month_outlined,
                        '~${(client.allocatedLiters * 30).toStringAsFixed(0)} L/month'),
                    if (isFree)
                      _detail(Icons.money_off_outlined,
                          'No billing — milk deducted only',
                          color: Colors.orange.shade700),
                  ]),
                ],
              ),
            ),
            if (client.isActive)
              IconButton(
                tooltip: 'Deactivate (keeps position)',
                icon: const Icon(Icons.person_off_outlined,
                    size: 20, color: Colors.orange),
                onPressed: onDeactivate,
              ),
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined,
                  size: 20, color: AppTheme.info),
              onPressed: onEdit,
            ),
          ]),
        ),

        // ── Body ───────────────────────────────────────────────────────
        Expanded(
          child: Row(children: [
            SizedBox(
              width: 300,
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                  child: Row(children: [
                    Icon(
                      isFree
                          ? Icons.opacity
                          : Icons.receipt_long_outlined,
                      size: 15,
                      color: isFree
                          ? Colors.orange.shade600
                          : AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(isFree ? 'Milk Tracking' : 'Monthly Bills',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    if (isFree) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('No bills generated',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade700)),
                      ),
                    ],
                  ]),
                ),
                Expanded(
                  child: Obx(() {
                    if (ctrl.isProfileLoading.value) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (ctrl.monthlyBills.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFree
                                  ? Icons.opacity
                                  : Icons.receipt_outlined,
                              size: 40,
                              color: Colors.black12,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isFree
                                  ? 'No milk records yet'
                                  : 'No bills yet',
                              style: const TextStyle(
                                  color: Colors.black38, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: ctrl.monthlyBills.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (ctx, i) => _MonthBillTile(
                        bill: ctrl.monthlyBills[i],
                        ctrl: ctrl,
                        isFree: isFree,
                      ),
                    );
                  }),
                ),
              ]),
            ),
            Container(width: 1, color: const Color(0xFFEEEEEE)),
            Expanded(
              child: Obx(() {
                final bill = ctrl.selectedBill.value;
                if (bill == null) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFree
                              ? Icons.opacity
                              : Icons.receipt_long_outlined,
                          size: 48,
                          color: Colors.black12,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isFree
                              ? 'Click a month to view daily milk records'
                              : 'Click a month to view daily records',
                          style: const TextStyle(
                              color: Colors.black38, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                return _DailyBreakdownPanel(
                    bill: bill, client: client, ctrl: ctrl);
              }),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _detail(IconData icon, String text, {Color? color}) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color ?? Colors.black45),
        const SizedBox(width: 4),
        Text(text,
            style: TextStyle(
                fontSize: 13, color: color ?? Colors.black54)),
      ]);
}

// ── Monthly bill tile ─────────────────────────────────────────────────────────
class _MonthBillTile extends StatelessWidget {
  final MonthlyBillModel bill;
  final ClientController ctrl;
  final bool isFree;
  const _MonthBillTile(
      {required this.bill, required this.ctrl, this.isFree = false});

  @override
  Widget build(BuildContext context) {
    final monthName =
        DateFormat('MMMM yyyy').format(DateTime(bill.year, bill.month));
    return Obx(() {
      final isSelected =
          ctrl.selectedBill.value?.monthKey == bill.monthKey;
      return InkWell(
        onTap: () => ctrl.selectMonth(bill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          color: isSelected
              ? (isFree
                  ? Colors.orange.withOpacity(0.07)
                  : AppTheme.primary.withOpacity(0.07))
              : Colors.transparent,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isFree
                        ? Colors.orange.withOpacity(0.15)
                        : AppTheme.primary.withOpacity(0.15))
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isFree ? Icons.opacity : Icons.calendar_month,
                size: 18,
                color: isSelected
                    ? (isFree ? Colors.orange.shade600 : AppTheme.primary)
                    : Colors.black45,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(monthName,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isSelected
                              ? (isFree
                                  ? Colors.orange.shade700
                                  : AppTheme.primary)
                              : Colors.black87)),
                  Text(
                      '${bill.dayCount} days  ·  '
                      '${formatL(bill.totalLiters)} L',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45)),
                ],
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              isFree
                  ? Text('${formatL(bill.totalLiters)} L',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected
                              ? Colors.orange.shade700
                              : Colors.black54))
                  : Text('Rs. ${bill.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isSelected
                              ? AppTheme.primary
                              : Colors.black87)),
              Icon(
                  isSelected
                      ? Icons.keyboard_arrow_down
                      : Icons.chevron_right,
                  size: 16,
                  color: Colors.black38),
            ]),
          ]),
        ),
      );
    });
  }
}

// ── Daily breakdown panel ─────────────────────────────────────────────────────
class _DailyBreakdownPanel extends StatelessWidget {
  final MonthlyBillModel bill;
  final ClientModel client;
  final ClientController ctrl;
  const _DailyBreakdownPanel(
      {required this.bill, required this.client, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final isFree = !client.isPayer;
    final monthName =
        DateFormat('MMMM yyyy').format(DateTime(bill.year, bill.month));

    return Column(children: [
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(monthName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                Obx(() => Text(
                      isFree
                          ? '${ctrl.dailyBreakdown.length} records  ·  '
                              '${formatL(bill.totalLiters)} L total'
                          : '${ctrl.dailyBreakdown.length} records  ·  '
                              'Rs. ${bill.totalAmount.toStringAsFixed(0)} total',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black45),
                    )),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _export(client, bill, ctrl),
            icon: const Icon(Icons.download, size: 15),
            label: const Text('Export Excel',
                style: TextStyle(fontSize: 13)),
          ),
        ]),
      ),
      Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        color: const Color(0xFFF5F5F5),
        child: Row(children: [
          const SizedBox(width: 36, child: Text('#', style: _h)),
          const Expanded(flex: 2, child: Text('Date', style: _h)),
          const Expanded(flex: 2, child: Text('Day', style: _h)),
          const Expanded(flex: 2, child: Text('Allocated', style: _h)),
          const Expanded(flex: 2, child: Text('Taken', style: _h)),
          const Expanded(flex: 2, child: Text('Extra L', style: _h)),
          if (!isFree)
            const Expanded(flex: 2, child: Text('Extra Rs.', style: _h)),
          const Expanded(flex: 2, child: Text('Total L', style: _h)),
          if (!isFree)
            const Expanded(flex: 2, child: Text('Amount', style: _h)),
        ]),
      ),
      Expanded(
        child: Obx(() {
          if (ctrl.isDailyLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = ctrl.dailyBreakdown;
          if (list.isEmpty) {
            return const Center(
                child: Text('No records for this month',
                    style: TextStyle(
                        color: Colors.black38, fontSize: 14)));
          }
          return ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
            itemBuilder: (ctx, i) => _DailyRow(
              sale: list[i],
              index: i,
              isFree: isFree,
            ),
          );
        }),
      ),
      Obx(() {
        if (ctrl.dailyBreakdown.isEmpty) return const SizedBox.shrink();
        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isFree
                ? Colors.orange.withOpacity(0.07)
                : AppTheme.primary.withOpacity(0.07),
            borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(12)),
          ),
          child: Row(children: [
            const Expanded(
                flex: 10,
                child: Text('MONTHLY TOTAL',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13))),
            Expanded(
                flex: 2,
                child: Text(
                    '${formatL(bill.totalLiters)} L',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFree
                            ? Colors.orange.shade700
                            : AppTheme.primary,
                        fontSize: 14))),
            if (!isFree)
              Expanded(
                  flex: 2,
                  child: Text(
                      'Rs. ${bill.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                          fontSize: 14))),
          ]),
        );
      }),
    ]);
  }

  Future<void> _export(ClientModel client, MonthlyBillModel bill,
      ClientController ctrl) async {
    final sales =
        await ctrl.getSalesForExport(client.id!, bill.year, bill.month);
    if (sales.isEmpty) {
      Get.snackbar('No Data', 'No sales to export',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final from =
        '${bill.year}-${bill.month.toString().padLeft(2, '0')}-01';
    final to =
        '${bill.year}-${bill.month.toString().padLeft(2, '0')}-31';
    await ExcelExporter.exportClientBills(sales, client.name, from, to);
  }

  static const _h =
      TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
}

// ── Daily row ─────────────────────────────────────────────────────────────────
class _DailyRow extends StatelessWidget {
  final SaleModel sale;
  final int index;
  final bool isFree;

  const _DailyRow({
    required this.sale,
    required this.index,
    this.isFree = false,
  });

  @override
  Widget build(BuildContext context) {
    final date      = DateTime.tryParse(sale.saleDate);
    final dayName   = date != null ? DateFormat('EEE').format(date) : '';
    final formatted =
        date != null ? DateFormat('dd MMM').format(date) : sale.saleDate;
    final isEven    = index % 2 == 0;

    return Container(
      color: isEven ? Colors.white : const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(children: [
        SizedBox(
            width: 36,
            child: Text('${index + 1}',
                style: const TextStyle(
                    color: Colors.black38, fontSize: 13))),
        Expanded(
            flex: 2,
            child: Text(formatted,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13))),
        Expanded(
            flex: 2,
            child: Text(dayName,
                style: const TextStyle(
                    color: Colors.black54, fontSize: 13))),
        Expanded(
            flex: 2,
            child: Text(
                '${formatL(sale.allocatedLiters)} L',
                style: const TextStyle(fontSize: 13))),
        Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: sale.takenAllocated
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(sale.takenAllocated ? 'Yes' : 'No',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sale.takenAllocated
                          ? Colors.green.shade700
                          : Colors.red.shade700)),
            )),
        Expanded(
            flex: 2,
            child: Text(
                sale.extraLiters > 0
                    ? '+${formatL(sale.extraLiters)} L'
                    : '—',
                style: const TextStyle(
                    color: Colors.black54, fontSize: 13))),
        if (!isFree)
          Expanded(
              flex: 2,
              child: Text(
                  sale.extraAmount > 0
                      ? 'Rs. ${sale.extraAmount.toStringAsFixed(0)}'
                      : '—',
                  style: const TextStyle(
                      color: Colors.black54, fontSize: 13))),
        Expanded(
            flex: 2,
            child: Text('${formatL(sale.totalLiters)} L',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isFree ? Colors.orange.shade700 : AppTheme.primary,
                    fontSize: 13))),
        if (!isFree)
          Expanded(
              flex: 2,
              child: Text(
                  'Rs. ${sale.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 13))),
      ]),
    );
  }
}