// lib/views/settings/settings_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_theme.dart';
import '../../controllers/settings_controller.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _farmNameCtrl;
  late TextEditingController _rateCtrl;
  late TextEditingController _ownerCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    final ctrl = Get.find<SettingsController>();
    _farmNameCtrl = TextEditingController(text: ctrl.farmName.value);
    _rateCtrl     = TextEditingController(text: ctrl.ratePerLiter.value.toString());
    _ownerCtrl    = TextEditingController(text: ctrl.ownerName.value);
    _phoneCtrl    = TextEditingController(text: ctrl.phone.value);
    _addressCtrl  = TextEditingController(text: ctrl.address.value);
  }

  @override
  void dispose() {
    _farmNameCtrl.dispose();
    _rateCtrl.dispose();
    _ownerCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Configure your dairy farm details and milk pricing',
                      style: TextStyle(color: Colors.black45, fontSize: 14)),
                ],
              ),
            ]),
            const SizedBox(height: 24),

            // ── Two-column layout ─────────────────────────────────────────
            LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth > 700;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildFarmForm(ctrl)),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildInfoCards()),
                  ],
                );
              } else {
                return Column(children: [
                  _buildFarmForm(ctrl),
                  const SizedBox(height: 20),
                  _buildInfoCards(),
                ]);
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmForm(SettingsController ctrl) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Farm Information ───────────────────────────────────────────
          _SectionCard(
            title: 'Farm Information',
            icon: Icons.agriculture_outlined,
            iconColor: AppTheme.primary,
            child: Column(children: [
              _Field(
                controller: _farmNameCtrl,
                label: 'Farm Name',
                hint: 'e.g. Al-Madina Dairy Farm',
                icon: Icons.home_work_outlined,
                validator: (v) => v?.isEmpty == true ? 'Farm name is required' : null,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _rateCtrl,
                label: 'Rate per Liter (Rs.)',
                hint: 'e.g. 120',
                icon: Icons.attach_money_outlined,
                suffix: 'Rs./L',
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Rate is required';
                  if (double.tryParse(v!) == null) return 'Enter a valid number';
                  return null;
                },
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Owner Details ──────────────────────────────────────────────
          _SectionCard(
            title: 'Owner Details',
            icon: Icons.person_outline,
            iconColor: AppTheme.primary,
            child: Column(children: [
              _Field(
                controller: _ownerCtrl,
                label: 'Owner Name',
                hint: 'e.g. Muhammad Ali',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _phoneCtrl,
                label: 'Phone Number',
                hint: 'e.g. 0300-1234567',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _Field(
                controller: _addressCtrl,
                label: 'Farm Address',
                hint: 'e.g. Village Chak 50, District Faisalabad',
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Save button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_formKey.currentState?.validate() == true) {
                  ctrl.saveSettings(
                    name:  _farmNameCtrl.text.trim(),
                    rate:  double.tryParse(_rateCtrl.text) ?? 100,
                    owner: _ownerCtrl.text.trim().isEmpty ? null : _ownerCtrl.text.trim(),
                    ph:    _phoneCtrl.text.trim().isEmpty  ? null : _phoneCtrl.text.trim(),
                    addr:  _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
                  );
                }
              },
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save Settings',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Data Storage ───────────────────────────────────────────────
        _SectionCard(
          title: 'Data Storage',
          icon: Icons.folder_outlined,
          iconColor: AppTheme.info,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your data is stored locally at:',
                  style: TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'C:\\dairy_farm\\dairy_farm.db',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Quick Stats ────────────────────────────────────────────────
        _SectionCard(
          title: 'App Info',
          icon: Icons.info_outline,
          iconColor: Colors.purple,
          child: Column(children: [
            _InfoRow(
              icon: Icons.eco_outlined,
              color: AppTheme.primary,
              text: 'Dairy Farm Management System',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.storage_outlined,
              color: Colors.orange,
              text: 'Offline Software-All data stays on your device',
            ),
            const SizedBox(height: 6),
            _InfoRow(
              icon: Icons.lock_outline,
              color: Colors.blue,
              text: 'Developed By Haider Naeem',
            ),
          ]),
        ),
      ],
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              Icon(icon, size: 17, color: iconColor),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: iconColor)),
            ]),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ── Text field ────────────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? suffix;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.suffix,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        suffixText: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4)),
        ),
      ],
    );
  }
}