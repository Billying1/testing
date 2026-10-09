import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/preference_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  bool _editing = false;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameCtl = TextEditingController();
  final TextEditingController _emailCtl = TextEditingController();
  final TextEditingController _phoneCtl = TextEditingController();
  final TextEditingController _avatarCtl = TextEditingController();
  final TextEditingController _genderCtl = TextEditingController();
  final TextEditingController _cityCtl = TextEditingController();

  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    UserModel? u = await PreferenceService.getUser();

    setState(() {
      _user = u;

      _fullNameCtl.text = u?.fullName ?? '';
      _emailCtl.text = u?.email ?? '';
      _phoneCtl.text = u?.phone ?? '';
      _avatarCtl.text = u?.avatar ?? '';
      _genderCtl.text = u?.gender ?? '';
      _cityCtl.text = u?.city ?? '';

      _loading = false;
    });
  }

  @override
  void dispose() {
    _fullNameCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _avatarCtl.dispose();
    _genderCtl.dispose();
    _cityCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // keep existing email/password when updating
    final existing = await PreferenceService.getUser();

    final updated = UserModel(
      fullName: _fullNameCtl.text.trim(),
      email: existing?.email ?? _emailCtl.text.trim(),
      phone: _phoneCtl.text.trim(),
      password: existing?.password ?? '',
      avatar: _avatarCtl.text.trim(),
      gender: _genderCtl.text.trim(),
      city: _cityCtl.text.trim(),
    );

    await PreferenceService.updateUser(updated);

    setState(() {
      _user = updated;
      _editing = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Profile updated'),
    ));
  }

  Widget _buildAvatar() {
    final avatar = _avatarCtl.text.trim();

    if (avatar.isEmpty) {
      final initials = (_fullNameCtl.text.trim().isEmpty)
          ? '?'
          : _fullNameCtl.text.trim().split(' ').map((e) => e.isEmpty ? '' : e[0]).take(2).join();

      return CircleAvatar(radius: 48, child: Text(initials));
    }

    if (avatar.startsWith('http')) {
      return CircleAvatar(radius: 48, backgroundImage: NetworkImage(avatar));
    }

    return CircleAvatar(radius: 48, child: Text(avatar.substring(0, 1).toUpperCase()));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // discard changes
                setState(() {
                  _editing = false;
                  _fullNameCtl.text = _user?.fullName ?? '';
                  _emailCtl.text = _user?.email ?? '';
                  _phoneCtl.text = _user?.phone ?? '';
                  _avatarCtl.text = _user?.avatar ?? '';
                  _genderCtl.text = _user?.gender ?? '';
                  _cityCtl.text = _user?.city ?? '';
                });
              },
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(),
              const SizedBox(height: 12),
              if (!_editing) ...[
                Text(
                  _user?.fullName ?? '',
                  style: Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(_user?.email ?? ''),
                const SizedBox(height: 16),
                ListTile(title: const Text('Phone'), subtitle: Text(_user?.phone ?? '')),
                ListTile(title: const Text('Gender'), subtitle: Text(_user?.gender ?? '')),
                ListTile(title: const Text('City'), subtitle: Text(_user?.city ?? '')),
              ] else ...[
                TextFormField(
                  controller: _fullNameCtl,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter full name' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  readOnly: true,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtl,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _avatarCtl,
                  decoration: const InputDecoration(labelText: 'Avatar (url)'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _genderCtl,
                  decoration: const InputDecoration(labelText: 'Gender'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cityCtl,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
