import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

import '../../models/charging_station.dart';
import '../../services/station_repository.dart';
import './../widgets/station_marker.dart';
import './../widgets/station_card.dart';
import './../widgets/brand_row.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();

  final ChargingStation _currentLocation = const ChargingStation(
    id: 'current',
    name: 'Vị trí hiện tại',
    city: 'Việt Nam',
    address: 'Thiết bị di động',
    latitude: 16.08,
    longitude: 108.18,
    power: '',
  );

  String? _selectedCity;
  String? _selectedPower;
  String? _selectedStationId;

  bool _mapReady = false;

  StationRepository get _repository => StationRepository.instance;

  @override
  void initState() {
    super.initState();
    _selectedStationId = _repository.stations.isNotEmpty
        ? _repository.stations.first.id
        : null;

    // Re-fit the map whenever the station list changes (e.g. a new
    // station is added from AddStationPage), but only once the map
    // is actually ready to accept camera commands.
    _repository.stationsNotifier.addListener(_onStationsChanged);
  }

  @override
  void dispose() {
    _repository.stationsNotifier.removeListener(_onStationsChanged);
    super.dispose();
  }

  void _onStationsChanged() {
    if (_mapReady) {
      _fitAllStations();
    }
  }

  void _onMapReady() {
    _mapReady = true;
    _fitAllStations();
  }

  void _fitAllStations() {
    if (!mounted || _repository.stations.isEmpty) {
      return;
    }

    final points = [
      latlng.LatLng(_currentLocation.latitude, _currentLocation.longitude),
      for (final station in _repository.stations)
        latlng.LatLng(station.latitude, station.longitude),
    ];

    final bounds = LatLngBounds.fromPoints(points);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 220),
      ),
    );
  }

  List<String> get _availableCities {
    final cities = _repository.stations.map((station) => station.city).toSet().toList();
    cities.sort();
    return cities;
  }

  List<String> get _powerFilterOptions => const [
    'Tất cả',
    '60 kW',
    '90 kW',
    '120 kW',
    '150 kW',
    '180 kW',
  ];

  int _powerValue(String power) {
    final match = RegExp(r'(\d+)').firstMatch(power);
    if (match == null) {
      return 0;
    }

    return int.tryParse(match.group(1) ?? '') ?? 0;
  }

  List<ChargingStation> get _filteredStations {
    return _repository.stations.where((station) {
      final matchesCity =
          _selectedCity == null ||
          _selectedCity!.isEmpty ||
          station.city == _selectedCity;
      final matchesPower = _selectedPower == null ||
          _selectedPower!.isEmpty ||
          _selectedPower == 'Tất cả' ||
          _powerValue(station.power) >= _powerValue(_selectedPower!);

      return matchesCity && matchesPower;
    }).toList();
  }

  ChargingStation? get _selectedStation {
    if (_selectedStationId == null) {
      return null;
    }

    return _repository.stationById(_selectedStationId!);
  }

  ChargingStation? _nearestStation() {
    if (_repository.stations.isEmpty) {
      return null;
    }

    ChargingStation nearestStation = _repository.stations.first;
    double bestDistance = _distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      nearestStation.latitude,
      nearestStation.longitude,
    );

    for (final station in _repository.stations.skip(1)) {
      final distance = _distanceBetween(
        _currentLocation.latitude,
        _currentLocation.longitude,
        station.latitude,
        station.longitude,
      );
      if (distance < bestDistance) {
        bestDistance = distance;
        nearestStation = station;
      }
    }

    return nearestStation;
  }

  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    final deltaLat = lat1 - lat2;
    final deltaLon = lon1 - lon2;
    return deltaLat * deltaLat + deltaLon * deltaLon;
  }

  void _goNearby() {
    final nearbyStation = _nearestStation();
    if (nearbyStation == null) {
      return;
    }

    setState(() {
      _selectedStationId = nearbyStation.id;
    });

    _mapController.move(
      latlng.LatLng(nearbyStation.latitude, nearbyStation.longitude),
      12,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chọn ${nearbyStation.name} gần vị trí của bạn nhất.'),
      ),
    );
  }

  Future<void> _openFilterDialog() async {
    String? selectedCity = _selectedCity;
    String? selectedPower = _selectedPower;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Lọc trạm sạc'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedCity,
                    decoration: const InputDecoration(labelText: 'Tỉnh / thành'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      ..._availableCities.map(
                        (city) => DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCity = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPower,
                    decoration: const InputDecoration(
                      labelText: 'Công suất tối thiểu',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Tất cả'),
                      ),
                      ..._powerFilterOptions
                          .where((option) => option != 'Tất cả')
                          .map(
                            (option) => DropdownMenuItem<String>(
                              value: option,
                              child: Text(option),
                            ),
                          ),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPower = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCity = null;
                      _selectedPower = null;
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Đặt lại'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!mounted) {
                      return;
                    }

                    setState(() {
                      _selectedCity = selectedCity;
                      _selectedPower = selectedPower;

                      if (_filteredStations.isEmpty) {
                        _selectedStationId = null;
                      } else if (_selectedStationId == null ||
                          !_filteredStations.any(
                            (station) => station.id == _selectedStationId,
                          )) {
                        _selectedStationId = _filteredStations.first.id;
                      }
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Áp dụng'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedStation = _selectedStation;
    final visibleStations = _filteredStations;

    return Container(
      color: const Color(0xFFF3F7FF),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF2FF), Color(0xFFE4E9FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Column(
              children: [
                BrandRow(),
                SizedBox(height: 8),
                Text(
                  'Electric Vehicle Charging Stations',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                SizedBox(height: 4),
                Text(
                  'Tìm kiếm trạm sạc theo thời gian thực',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: latlng.LatLng(
                            _currentLocation.latitude,
                            _currentLocation.longitude,
                          ),
                          initialZoom: 6,
                          minZoom: 4,
                          maxZoom: 18,
                          onMapReady: _onMapReady,
                        ),
                        children: [
                          // Free OpenStreetMap tiles — no API key needed.
                          // For production use, prefer a hosted tile
                          // provider (MapTiler, Stadia Maps, etc.) with your
                          // own key instead of hitting OSM's public server
                          // directly, per their usage policy.
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.tuan5',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: latlng.LatLng(
                                  _currentLocation.latitude,
                                  _currentLocation.longitude,
                                ),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.my_location,
                                  color: Color(0xFF2E7DFF),
                                  size: 30,
                                ),
                              ),
                              for (final station in visibleStations)
                                Marker(
                                  point: latlng.LatLng(
                                    station.latitude,
                                    station.longitude,
                                  ),
                                  width: 60,
                                  height: 74,
                                  alignment: Alignment.topCenter,
                                  child: StationMarker(
                                    station: station,
                                    selected:
                                        station.id == _selectedStationId,
                                    favorite: _repository.isFavorite(
                                      station.id,
                                    ),
                                    onTap: () {
                                      setState(() {
                                        _selectedStationId = station.id;
                                      });
                                    },
                                    onFavoriteTap: () {
                                      setState(() {
                                        _repository.toggleFavorite(
                                          station.id,
                                        );
                                      });
                                    },
                                  ),
                                ),
                            ],
                          ),
                          const RichAttributionWidget(
                            attributions: [
                              TextSourceAttribution('OpenStreetMap contributors'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.88),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${visibleStations.length} trạm',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: GestureDetector(
                        onTap: _fitAllStations,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.filter_center_focus,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 90,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: selectedStation == null
                            ? const SizedBox.shrink()
                            : SelectedStationCard(
                                key: ValueKey<String>(selectedStation.id),
                                station: selectedStation,
                                favorite: _repository.isFavorite(
                                  selectedStation.id,
                                ),
                                onFavoriteTap: () {
                                  setState(() {
                                    _repository.toggleFavorite(
                                      selectedStation.id,
                                    );
                                  });
                                },
                              ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: _openFilterDialog,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.88),
                                borderRadius: BorderRadius.circular(26),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.tune,
                                    color: Color(0xFF2E7D32),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _selectedCity == null &&
                                              (_selectedPower == null ||
                                                  _selectedPower == 'Tất cả')
                                          ? 'Lọc trạm theo khu vực và công suất'
                                          : 'Đã chọn: ${_selectedCity ?? 'Tất cả'} • ${_selectedPower ?? 'Tất cả'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.black45,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _goNearby,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF8BD520),
                                      Color(0xFF53C96E),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Hoặc tìm trạm quanh đây',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}