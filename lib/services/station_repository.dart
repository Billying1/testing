import 'package:flutter/material.dart';

import '../models/charging_station.dart';

class StationRepository {
  StationRepository._();

  static final StationRepository instance = StationRepository._();

  final ValueNotifier<List<ChargingStation>> stationsNotifier =
      ValueNotifier<List<ChargingStation>>([
    const ChargingStation(
      id: 'hn-01',
      name: 'EVCS Cầu Giấy',
      city: 'Hà Nội',
      address: 'Trần Duy Hưng, Cầu Giấy',
      latitude: 21.028,
      longitude: 105.8,
      power: '120 kW',
    ),
    const ChargingStation(
      id: 'hn-02',
      name: 'EVCS Long Biên',
      city: 'Hà Nội',
      address: 'Ngô Gia Tự, Long Biên',
      latitude: 21.05,
      longitude: 105.89,
      power: '60 kW',
    ),
    const ChargingStation(
      id: 'hp-01',
      name: 'EVCS Hải Phòng',
      city: 'Hải Phòng',
      address: 'Ngô Quyền',
      latitude: 20.85,
      longitude: 106.68,
      power: '150 kW',
      network: 'Đối tác',
    ),
    const ChargingStation(
      id: 'qn-01',
      name: 'EVCS Hạ Long',
      city: 'Quảng Ninh',
      address: 'Bãi Cháy',
      latitude: 20.95,
      longitude: 107.08,
      power: '90 kW',
    ),
    const ChargingStation(
      id: 'nb-01',
      name: 'EVCS Ninh Bình',
      city: 'Ninh Bình',
      address: 'Trung tâm thành phố',
      latitude: 20.25,
      longitude: 105.97,
      power: '60 kW',
    ),
    const ChargingStation(
      id: 'th-01',
      name: 'EVCS Thanh Hóa',
      city: 'Thanh Hóa',
      address: 'TP Thanh Hóa',
      latitude: 19.8,
      longitude: 105.78,
      power: '90 kW',
    ),
    const ChargingStation(
      id: 'dn-01',
      name: 'EVCS Đà Nẵng',
      city: 'Đà Nẵng',
      address: 'Hải Châu',
      latitude: 16.05,
      longitude: 108.22,
      power: '180 kW',
    ),
    const ChargingStation(
      id: 'hue-01',
      name: 'EVCS Huế',
      city: 'Huế',
      address: 'Phú Nhuận',
      latitude: 16.46,
      longitude: 107.59,
      power: '75 kW',
    ),
    const ChargingStation(
      id: 'qn-02',
      name: 'EVCS Quy Nhơn',
      city: 'Bình Định',
      address: 'Lê Hồng Phong',
      latitude: 13.78,
      longitude: 109.22,
      power: '120 kW',
    ),
    const ChargingStation(
      id: 'nt-01',
      name: 'EVCS Nha Trang',
      city: 'Khánh Hòa',
      address: 'Trần Phú',
      latitude: 12.24,
      longitude: 109.19,
      power: '150 kW',
    ),
    const ChargingStation(
      id: 'ld-01',
      name: 'EVCS Đà Lạt',
      city: 'Lâm Đồng',
      address: 'Trung tâm Đà Lạt',
      latitude: 11.94,
      longitude: 108.44,
      power: '60 kW',
    ),
    const ChargingStation(
      id: 'hcm-01',
      name: 'EVCS Sài Gòn',
      city: 'TP.HCM',
      address: 'Quận 1',
      latitude: 10.78,
      longitude: 106.7,
      power: '180 kW',
    ),
    const ChargingStation(
      id: 'ct-01',
      name: 'EVCS Cần Thơ',
      city: 'Cần Thơ',
      address: 'Ninh Kiều',
      latitude: 10.03,
      longitude: 105.77,
      power: '90 kW',
      network: 'Đối tác',
    ),
    const ChargingStation(
      id: 'vt-01',
      name: 'EVCS Vũng Tàu',
      city: 'Bà Rịa - Vũng Tàu',
      address: 'Bãi Sau',
      latitude: 10.34,
      longitude: 107.08,
      power: '120 kW',
    ),
    const ChargingStation(
      id: 'hd-01',
      name: 'EVCS Hải Dương',
      city: 'Hải Dương',
      address: 'TP Hải Dương',
      latitude: 20.94,
      longitude: 106.33,
      power: '90 kW',
    ),
    const ChargingStation(
      id: 'bg-01',
      name: 'EVCS Bắc Giang',
      city: 'Bắc Giang',
      address: 'TP Bắc Giang',
      latitude: 21.27,
      longitude: 106.20,
      power: '60 kW',
    ),
    const ChargingStation(
      id: 'pt-01',
      name: 'EVCS Phú Thọ',
      city: 'Phú Thọ',
      address: 'Việt Trì',
      latitude: 21.32,
      longitude: 105.40,
      power: '90 kW',
    ),
    const ChargingStation(
      id: 'ng-01',
      name: 'EVCS Nghệ An',
      city: 'Nghệ An',
      address: 'TP Vinh',
      latitude: 18.68,
      longitude: 105.68,
      power: '120 kW',
    ),
    const ChargingStation(
      id: 'ht-01',
      name: 'EVCS Hà Tĩnh',
      city: 'Hà Tĩnh',
      address: 'TP Hà Tĩnh',
      latitude: 18.34,
      longitude: 105.90,
      power: '60 kW',
    ),
    const ChargingStation(
      id: 'qb-01',
      name: 'EVCS Quảng Bình',
      city: 'Quảng Bình',
      address: 'Đồng Hới',
      latitude: 17.47,
      longitude: 106.62,
      power: '90 kW',
    ),
    const ChargingStation(
      id: 'qng-01',
      name: 'EVCS Quảng Ngãi',
      city: 'Quảng Ngãi',
      address: 'TP Quảng Ngãi',
      latitude: 15.12,
      longitude: 108.80,
      power: '90 kW',
      network: 'Đối tác',
    ),
    const ChargingStation(
      id: 'pk-01',
      name: 'EVCS Phú Yên',
      city: 'Phú Yên',
      address: 'Tuy Hòa',
      latitude: 13.09,
      longitude: 109.31,
      power: '60 kW',
    ),
    const ChargingStation(
      id: 'bd-01',
      name: 'EVCS Bình Dương',
      city: 'Bình Dương',
      address: 'Thủ Dầu Một',
      latitude: 10.98,
      longitude: 106.66,
      power: '150 kW',
    ),
    const ChargingStation(
      id: 'dn2-01',
      name: 'EVCS Đồng Nai',
      city: 'Đồng Nai',
      address: 'Biên Hòa',
      latitude: 10.94,
      longitude: 106.82,
      power: '120 kW',
    ),
    const ChargingStation(
      id: 'ag-01',
      name: 'EVCS An Giang',
      city: 'An Giang',
      address: 'Long Xuyên',
      latitude: 10.38,
      longitude: 105.43,
      power: '90 kW',
      network: 'Đối tác',
    ),
  ]);

  /// Read-only snapshot of the current stations.
  List<ChargingStation> get stations => stationsNotifier.value;

  final ValueNotifier<Set<String>> favoriteIds = ValueNotifier<Set<String>>(
    <String>{},
  );

  void toggleFavorite(String stationId) {
    final nextFavorites = Set<String>.from(favoriteIds.value);
    if (nextFavorites.contains(stationId)) {
      nextFavorites.remove(stationId);
    } else {
      nextFavorites.add(stationId);
    }
    favoriteIds.value = nextFavorites;
  }

  bool isFavorite(String stationId) {
    return favoriteIds.value.contains(stationId);
  }

  ChargingStation? stationById(String stationId) {
    for (final station in stations) {
      if (station.id == stationId) {
        return station;
      }
    }
    return null;
  }

  /// Adds a new station and notifies any listening widgets.
  /// Returns the generated station so the caller can use its id if needed.
ChargingStation addStation({
  required String name,
  required String city,
  required String address,
  required double latitude,
  required double longitude,
  required String power,
  String network = 'VinFast',
}) {
    final newStation = ChargingStation(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      city: city,
      address: address,
      latitude: latitude,
      longitude: longitude,
      power: power,
      network: network,
    );

    stationsNotifier.value = [...stationsNotifier.value, newStation];
    return newStation;
  }

  /// Removes a station by id (in case you want an undo/delete flow too).
  void removeStation(String stationId) {
    stationsNotifier.value =
        stationsNotifier.value.where((s) => s.id != stationId).toList();
  }
}