import 'market_state.dart';

class Listing {
  final String id;
  final VehicleType vehicleType;

  final String brand;
  final String model;
  final String trim;

  final int year;
  final int km;
  final int price;

  final FuelType fuel;
  final GearType gear;
  final BodyType body;

  final String title;
  final String location;
  final String seller;

  const Listing({
    required this.id,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.trim,
    required this.year,
    required this.km,
    required this.price,
    required this.fuel,
    required this.gear,
    required this.body,
    required this.title,
    required this.location,
    required this.seller,
  });
}
