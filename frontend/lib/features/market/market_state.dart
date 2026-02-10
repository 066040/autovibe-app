import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VehicleType { otomobil, motosiklet, kamyonet, minivan, otobus, kamyon }
enum FuelType { benzin, dizel, hibrit, elektrik, lpg }
enum GearType { manuel, otomatik, yariOtomatik }
enum BodyType { sedan, hatchback, suv, coupe, pickup, wagon, van }

class MarketFilters {
  final VehicleType vehicleType;

  final String brand;
  final String model;
  final String trim;

  final int yearMin;
  final int yearMax;
  final int kmMax;
  final int priceMin;
  final int priceMax;

  final Set<FuelType> fuels;
  final Set<GearType> gears;
  final Set<BodyType> bodies;

  const MarketFilters({
    this.vehicleType = VehicleType.otomobil,
    this.brand = '',
    this.model = '',
    this.trim = '',
    this.yearMin = 2005,
    this.yearMax = 2026,
    this.kmMax = 250000,
    this.priceMin = 0,
    this.priceMax = 5000000,
    this.fuels = const {},
    this.gears = const {},
    this.bodies = const {},
  });

  MarketFilters copyWith({
    VehicleType? vehicleType,
    String? brand,
    String? model,
    String? trim,
    int? yearMin,
    int? yearMax,
    int? kmMax,
    int? priceMin,
    int? priceMax,
    Set<FuelType>? fuels,
    Set<GearType>? gears,
    Set<BodyType>? bodies,
  }) {
    return MarketFilters(
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      trim: trim ?? this.trim,
      yearMin: yearMin ?? this.yearMin,
      yearMax: yearMax ?? this.yearMax,
      kmMax: kmMax ?? this.kmMax,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      fuels: fuels ?? this.fuels,
      gears: gears ?? this.gears,
      bodies: bodies ?? this.bodies,
    );
  }

  bool get hasAnyFilter =>
      vehicleType != VehicleType.otomobil ||
      brand.trim().isNotEmpty ||
      model.trim().isNotEmpty ||
      trim.trim().isNotEmpty ||
      yearMin != 2005 ||
      yearMax != 2026 ||
      kmMax != 250000 ||
      priceMin != 0 ||
      priceMax != 5000000 ||
      fuels.isNotEmpty ||
      gears.isNotEmpty ||
      bodies.isNotEmpty;

  int get activeCount {
    int c = 0;
    if (vehicleType != VehicleType.otomobil) c++;
    if (brand.trim().isNotEmpty) c++;
    if (model.trim().isNotEmpty) c++;
    if (trim.trim().isNotEmpty) c++;
    if (yearMin != 2005 || yearMax != 2026) c++;
    if (kmMax != 250000) c++;
    if (priceMin != 0 || priceMax != 5000000) c++;
    if (fuels.isNotEmpty) c++;
    if (gears.isNotEmpty) c++;
    if (bodies.isNotEmpty) c++;
    return c;
  }
}

class MarketFiltersController extends Notifier<MarketFilters> {
  @override
  MarketFilters build() => const MarketFilters();

  void setVehicleType(VehicleType v) => state = state.copyWith(
        vehicleType: v,
        brand: '',
        model: '',
        trim: '',
      );

  void setBrand(String v) => state = state.copyWith(brand: v, model: '', trim: '');
  void setModel(String v) => state = state.copyWith(model: v, trim: '');
  void setTrim(String v) => state = state.copyWith(trim: v);

  void setYearRange(int min, int max) => state = state.copyWith(yearMin: min, yearMax: max);
  void setKmMax(int v) => state = state.copyWith(kmMax: v);
  void setPriceRange(int min, int max) => state = state.copyWith(priceMin: min, priceMax: max);

  void toggleFuel(FuelType t) {
    final s = {...state.fuels};
    s.contains(t) ? s.remove(t) : s.add(t);
    state = state.copyWith(fuels: s);
  }

  void toggleGear(GearType t) {
    final s = {...state.gears};
    s.contains(t) ? s.remove(t) : s.add(t);
    state = state.copyWith(gears: s);
  }

  void toggleBody(BodyType t) {
    final s = {...state.bodies};
    s.contains(t) ? s.remove(t) : s.add(t);
    state = state.copyWith(bodies: s);
  }

  void reset() => state = const MarketFilters();
}

final marketFiltersProvider =
    NotifierProvider<MarketFiltersController, MarketFilters>(MarketFiltersController.new);
