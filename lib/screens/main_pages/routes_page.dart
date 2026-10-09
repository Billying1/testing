import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/charging_station.dart';
import '../../services/station_repository.dart';
import '../widgets/brand_row.dart';

/// "Tìm trạm sạc theo lộ trình" — lets the driver pick a start city (A) and
/// destination city (B), an EV range, and a network filter (VinFast / Khác),
/// then lists charging stations along the way sorted by distance from A.
class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key});

  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

enum _NetworkFilter { vinfast, other }

class _RoutesPageState extends State<RoutesPage> {
  static const Color _green = Color(0xFF5A9B1F);
  static const Color _greenLight = Color(0xFFEAF6D0);

  double _rangeKm = 112;
  _NetworkFilter _networkFilter = _NetworkFilter.vinfast;

  String? _cityA;
  String? _cityB;

  bool _searched = false;
  List<_RouteResult> _results = const [];

  StationRepository get _repository => StationRepository.instance;

  List<String> get _cities {
    final cities = _repository.stations.map((s) => s.city).toSet().toList();
    cities.sort();
    return cities;
  }

  // Anchor point for a city: the first known station in that city.
  // Real app: replace with actual geocoding of the chosen city/district.
  ChargingStation? _anchorFor(String? city) {
    if (city == null) return null;
    for (final station in _repository.stations) {
      if (station.city == city) return station;
    }
    return null;
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _deg2rad(double deg) => deg * (math.pi / 180.0);

  void _findStations() {
    final anchorA = _anchorFor(_cityA);
    if (anchorA == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn điểm đi (A).')),
      );
      return;
    }

    final matches = _repository.stations
        .where((s) => _networkFilter == _NetworkFilter.vinfast
            ? s.network == 'VinFast'
            : s.network != 'VinFast')
        .map((s) => _RouteResult(
              station: s,
              distanceFromA: _distanceKm(
                anchorA.latitude,
                anchorA.longitude,
                s.latitude,
                s.longitude,
              ),
            ))
        .where((r) => r.distanceFromA <= _rangeKm || r.station.id == anchorA.id)
        .toList()
      ..sort((a, b) => a.distanceFromA.compareTo(b.distanceFromA));

    setState(() {
      _searched = true;
      _results = matches;
    });
  }

  void _useCurrentLocationFor(bool isA) {
    // Placeholder for real GPS: falls back to Đà Nẵng, matching HomePage's
    // "Vị trí hiện tại" anchor. Wire this up to a location package later.
    const currentCity = 'Đà Nẵng';
    setState(() {
      if (isA) {
        _cityA = _repository.stations.any((s) => s.city == currentCity)
            ? currentCity
            : _cities.first;
      } else {
        _cityB = _repository.stations.any((s) => s.city == currentCity)
            ? currentCity
            : _cities.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: BrandRow(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                const Text(
                  'Tìm trạm sạc theo lộ trình',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 20),
                _buildRangeSlider(),
                const SizedBox(height: 20),
                _buildNetworkToggle(),
                const SizedBox(height: 16),
                _buildRouteInputs(),
                const SizedBox(height: 20),
                _buildSearchButton(),
                const SizedBox(height: 24),
                if (_searched) _buildResults(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'PHẠM VI HOẠT ĐỘNG CỦA EV',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: _greenLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_rangeKm.round()} km',
                style: const TextStyle(color: _green, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _green,
            thumbColor: _green,
            overlayColor: _green.withOpacity(0.15),
            inactiveTrackColor: const Color(0xFFE0E0E0),
          ),
          child: Slider(
            value: _rangeKm,
            min: 100,
            max: 500,
            onChanged: (value) => setState(() => _rangeKm = value),
          ),
        ),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('100 km', style: TextStyle(color: Colors.black45)),
            Text('500 km', style: TextStyle(color: Colors.black45)),
          ],
        ),
      ],
    );
  }

  Widget _buildNetworkToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleOption(
              label: 'Trạm VinFast',
              selected: _networkFilter == _NetworkFilter.vinfast,
              onTap: () => setState(() => _networkFilter = _NetworkFilter.vinfast),
            ),
          ),
          Expanded(
            child: _toggleOption(
              label: 'Trạm khác',
              selected: _networkFilter == _NetworkFilter.other,
              onTap: () => setState(() => _networkFilter = _NetworkFilter.other),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black87 : Colors.black38,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInputs() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _routeRow(
            label: 'A',
            value: _cityA,
            onChanged: (city) => setState(() => _cityA = city),
            onLocate: () => _useCurrentLocationFor(true),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 15),
                Container(
                  width: 2,
                  height: 18,
                  color: Colors.black12,
                ),
              ],
            ),
          ),
          _routeRow(
            label: 'B',
            value: _cityB,
            onChanged: (city) => setState(() => _cityB = city),
            onLocate: () => _useCurrentLocationFor(false),
          ),
        ],
      ),
    );
  }

  Widget _routeRow({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required VoidCallback onLocate,
  }) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Chọn tỉnh/thành'),
                value: value,
                items: _cities
                    .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                    .toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onLocate,
          icon: const Icon(Icons.my_location, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _findStations,
        style: ElevatedButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 0,
        ),
        child: const Text(
          'Tìm trạm sạc theo lộ trình',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Không tìm thấy trạm sạc phù hợp trong phạm vi đã chọn.',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _results.length; i++) ...[
          _resultCard(index: i + 1, result: _results[i]),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _resultCard({required int index, required _RouteResult result}) {
    final station = result.station;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${station.name}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '${station.address}, ${station.city}',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            'Trạm sạc ${station.network} - cách điểm đi (A) khoảng ${result.distanceFromA.round()}km',
            style: const TextStyle(color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.bolt, size: 18, color: _green),
              const SizedBox(width: 6),
              Text(
                '${station.power} có cổng sạc',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteResult {
  final ChargingStation station;
  final double distanceFromA;

  const _RouteResult({required this.station, required this.distanceFromA});
}