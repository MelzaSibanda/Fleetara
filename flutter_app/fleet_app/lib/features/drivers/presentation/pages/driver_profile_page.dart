import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../../core/services/firestore_service.dart';

// ── Public avatar widget — shared by DriversPage, AppShell, etc. ─────────────
class DriverAvatar extends StatelessWidget {
  final String? photoBase64;
  final String  name;
  final double  size;
  final double  fontSize;

  const DriverAvatar({
    super.key,
    required this.photoBase64,
    required this.name,
    this.size     = 40,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        final bytes = base64Decode(photoBase64!);
        return ClipOval(
          child: Image.memory(bytes,
            width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _initialsCircle(initials)),
        );
      } catch (_) {}
    }
    return _initialsCircle(initials);
  }

  Widget _initialsCircle(String initials) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(color: AppTheme.darkNavy, shape: BoxShape.circle),
    child: Center(child: Text(initials,
      style: TextStyle(color: Colors.white, fontSize: fontSize,
        fontWeight: FontWeight.w700))),
  );

  String _initials(String n) {
    final parts = n.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

// ── Driver Profile Page ───────────────────────────────────────────────────────
class DriverProfilePage extends StatefulWidget {
  final String? userId; // null = current user
  const DriverProfilePage({super.key, this.userId});
  @override State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  final _fs      = sl<FirestoreService>();
  bool  _loading = true;
  bool  _saving  = false;
  bool  _uploading = false;

  String?  _resolvedUid;
  Map<String, dynamic> _data = {};

  late TextEditingController _firstCtrl;
  late TextEditingController _lastCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _licenseCtrl;
  late TextEditingController _expiryCtrl;
  bool _isActive = true;

  bool get _isSelf =>
      _resolvedUid == FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _resolvedUid = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    _firstCtrl   = TextEditingController();
    _lastCtrl    = TextEditingController();
    _phoneCtrl   = TextEditingController();
    _licenseCtrl = TextEditingController();
    _expiryCtrl  = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose();
    _phoneCtrl.dispose(); _licenseCtrl.dispose(); _expiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_resolvedUid == null) return;
    setState(() => _loading = true);
    try {
      final doc = await _fs.db.collection('users').doc(_resolvedUid).get();
      if (doc.exists) {
        final d = _fs.docToMap(doc);
        setState(() {
          _data      = d;
          _firstCtrl.text   = d['first_name']     ?? '';
          _lastCtrl.text    = d['last_name']       ?? '';
          _phoneCtrl.text   = d['phone']           ?? '';
          _licenseCtrl.text = d['license_number']  ?? '';
          _expiryCtrl.text  = d['license_expiry']  ?? '';
          _isActive  = d['is_active'] ?? true;
          _loading   = false;
        });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _pickPhoto() async {
    setState(() => _uploading = true);
    try {
      final input = html.FileUploadInputElement()..accept = 'image/*';
      input.click();
      final file = await input.onChange.first.then((_) => input.files?.first);
      if (file == null) { setState(() => _uploading = false); return; }

      final reader = html.FileReader()..readAsArrayBuffer(file);
      await reader.onLoad.first;
      final bytes = reader.result as Uint8List;

      if (bytes.length > 400000) {
        if (mounted) {
          _snack('Photo too large — use an image under 400 KB', AppTheme.rose);
        }
        setState(() => _uploading = false);
        return;
      }

      final b64 = base64Encode(bytes);
      await _fs.db.collection('users').doc(_resolvedUid).update({'profile_photo': b64});
      setState(() { _data['profile_photo'] = b64; });
      if (mounted) { _snack('Photo updated', AppTheme.emerald); }
    } catch (e) {
      if (mounted) { _snack('Error: $e', AppTheme.rose); }
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final first = _firstCtrl.text.trim();
      final last  = _lastCtrl.text.trim();
      await _fs.db.collection('users').doc(_resolvedUid).update({
        'first_name':      first,
        'last_name':       last,
        'full_name':       '$first $last'.trim(),
        'phone':           _phoneCtrl.text.trim(),
        'license_number':  _licenseCtrl.text.trim(),
        'license_expiry':  _expiryCtrl.text.trim(),
        'is_active':       _isActive,
      });
      if (mounted) {
        _snack('Profile saved', AppTheme.emerald);
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) { _snack('Error: $e', AppTheme.rose); }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _pickExpiry() async {
    final now    = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primary)),
        child: child!),
    );
    if (picked == null) return;
    _expiryCtrl.text =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {});
  }

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color, behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final name  = ('${_data['first_name'] ?? ''} ${_data['last_name'] ?? ''}').trim();
    final photo = _data['profile_photo'] as String?;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_isSelf ? 'My Profile' : 'Driver Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(children: [

                    // ── Photo ────────────────────────────────────────────
                    const SizedBox(height: 8),
                    Stack(alignment: Alignment.bottomRight, children: [
                      DriverAvatar(photoBase64: photo, name: name, size: 100, fontSize: 36),
                      GestureDetector(
                        onTap: _uploading ? null : _pickPhoto,
                        child: Container(
                          width: 32, height: 32,
                          decoration: const BoxDecoration(
                            color: AppTheme.primary, shape: BoxShape.circle),
                          child: _uploading
                              ? const Padding(padding: EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 16)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(name.isNotEmpty ? name : (_data['email'] ?? ''),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                    const SizedBox(height: 2),
                    Text(_data['email'] ?? '',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                    const SizedBox(height: 28),

                    // ── Form fields ──────────────────────────────────────
                    _section('Personal Information'),
                    Row(children: [
                      Expanded(child: _field(_firstCtrl, 'First Name')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_lastCtrl,  'Last Name')),
                    ]),
                    _field(_phoneCtrl, 'Phone Number',
                      keyboardType: TextInputType.phone),

                    _section('License Details'),
                    _field(_licenseCtrl, 'License Number'),
                    GestureDetector(
                      onTap: _pickExpiry,
                      child: AbsorbPointer(
                        child: _field(_expiryCtrl, 'License Expiry',
                          suffixIcon: Icons.calendar_month_outlined))),

                    _section('Status'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border, width: 0.6)),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active driver',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary)),
                        subtitle: Text(
                          _isActive ? 'Can be assigned to trips' : 'Hidden from trip assignment',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        value: _isActive,
                        activeThumbColor: AppTheme.emerald,
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                      child: _saving
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                          : const Text('Save Profile',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textMuted))),
  );

  Widget _field(TextEditingController ctrl, String label, {
    TextInputType keyboardType = TextInputType.text, IconData? suffixIcon,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, size: 18, color: AppTheme.textMuted) : null),
    ),
  );
}
