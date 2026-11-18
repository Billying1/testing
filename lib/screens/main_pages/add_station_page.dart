import 'package:flutter/material.dart';

import '../../services/geocoding_service.dart';
import '../../services/station_repository.dart';

class AddStationPage extends StatefulWidget {
  const AddStationPage({super.key, this.lookupAddress});

  /// Optional injection point for deterministic integration tests.
  /// Production uses GeocodingService when null.
  final Future<GeocodeResult?> Function(String query)? lookupAddress;

  @override
  State<AddStationPage> createState() => _AddStationPageState();
}

class _AddStationPageState extends State<AddStationPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();

  static const _powerOptions = ['60 kW', '75 kW', '90 kW', '120 kW', '150 kW', '180 kW'];
  static const _networkOptions = ['VinFast', 'Đối tác'];

  String _selectedPower = _powerOptions.first;
  String _selectedNetwork = _networkOptions.first;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập thông tin';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final address = _addressController.text.trim();
      final city = _cityController.text.trim();
      final query = '$address, $city';

      final result = await (widget.lookupAddress?.call(query) ??
          GeocodingService.instance.lookup(query));

      if (result == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy vị trí cho địa chỉ này, vui lòng kiểm tra lại.'),
          ),
        );
        return;
      }

      StationRepository.instance.addStation(
        name: _nameController.text.trim(),
        city: city,
        address: address,
        latitude: result.latitude,
        longitude: result.longitude,
        power: _selectedPower,
        network: _selectedNetwork,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm trạm sạc mới')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tìm vị trí: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm trạm sạc')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên trạm',
                  border: OutlineInputBorder(),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Tỉnh / Thành phố',
                  border: OutlineInputBorder(),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Địa chỉ',
                  border: OutlineInputBorder(),
                  helperText: 'Vị trí sẽ được xác định tự động từ địa chỉ này',
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedPower,
                decoration: const InputDecoration(
                  labelText: 'Công suất',
                  border: OutlineInputBorder(),
                ),
                items: _powerOptions
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedPower = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedNetwork,
                decoration: const InputDecoration(
                  labelText: 'Đơn vị vận hành',
                  border: OutlineInputBorder(),
                ),
                items: _networkOptions
                    .map((n) => DropdownMenuItem(value: n, child: Text(n)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedNetwork = value);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu trạm'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}