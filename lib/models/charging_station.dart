class ChargingStation {
  final String id;
  final String name;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final String power;
  final String network;

  const ChargingStation({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.power,
    this.network = 'VinFast',
  });
}