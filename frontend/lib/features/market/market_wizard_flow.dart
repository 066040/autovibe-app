import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'market_state.dart';
import 'market_screen.dart';

class MarketWizardFlow extends ConsumerWidget {
  const MarketWizardFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const _VehicleTypeStep();
  }
}

// -------------------- STEP 1: VEHICLE TYPE --------------------

class _VehicleTypeStep extends ConsumerWidget {
  const _VehicleTypeStep();

  String _label(VehicleType t) => switch (t) {
        VehicleType.otomobil => 'Otomobil',
        VehicleType.motosiklet => 'Motosiklet',
        VehicleType.kamyonet => 'Kamyonet',
        VehicleType.minivan => 'Minivan',
        VehicleType.otobus => 'Otobüs',
        VehicleType.kamyon => 'Kamyon',
      };

  IconData _icon(VehicleType t) => switch (t) {
        VehicleType.otomobil => Icons.directions_car_filled_rounded,
        VehicleType.motosiklet => Icons.two_wheeler_rounded,
        VehicleType.kamyonet => Icons.local_shipping_rounded,
        VehicleType.minivan => Icons.airport_shuttle_rounded,
        VehicleType.otobus => Icons.directions_bus_filled_rounded,
        VehicleType.kamyon => Icons.fire_truck_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Vasıta Türü', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: VehicleType.values.map((t) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                ref.read(marketFiltersProvider.notifier).setVehicleType(t);
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _BrandStep()));
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF2D6BFF).withOpacity(0.14),
                      ),
                      child: Icon(_icon(t), color: const Color(0xFF2D6BFF)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _label(t),
                        style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// -------------------- STEP 2: BRAND --------------------

class _BrandStep extends ConsumerStatefulWidget {
  const _BrandStep();

  @override
  ConsumerState<_BrandStep> createState() => _BrandStepState();
}

class _BrandStepState extends ConsumerState<_BrandStep> {
  final _search = TextEditingController();

  static const brands = [
    'Audi',
    'BMW',
    'Mercedes-Benz',
    'Volkswagen',
    'Toyota',
    'Honda',
    'Hyundai',
    'Kia',
    'Renault',
    'Peugeot',
    'Citroën',
    'Ford',
    'Opel',
    'Skoda',
    'Seat',
    'Volvo',
    'Fiat',
    'Nissan',
    'Mazda',
    'Tesla',
    'Porsche',
    'Jaguar',
    'Land Rover',
    'Jeep',
    'Chery',
    'MG',
    'Cupra',
    'Mini',
    'Suzuki',
    'Dacia',
    'Alfa Romeo',
    'Chevrolet',
    'Mitsubishi',
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(marketFiltersProvider);
    final c = ref.read(marketFiltersProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);

    final q = _search.text.trim().toLowerCase();
    final list = q.isEmpty ? brands : brands.where((b) => b.toLowerCase().contains(q)).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text('Marka', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SearchBox(
            controller: _search,
            isDark: isDark,
            hint: 'Marka ara…',
            onChanged: (_) => setState(() {}),
            onClear: () {
              _search.clear();
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
          ...list.map((b) {
            final selected = f.brand == b;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  c.setBrand(b);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _ModelStep()));
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFF2D6BFF).withOpacity(0.55)
                          : (isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFF2D6BFF).withOpacity(0.14),
                        ),
                        child: const Icon(Icons.directions_car, color: Color(0xFF2D6BFF)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          b,
                          style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// -------------------- STEP 3: MODEL --------------------

class _ModelStep extends ConsumerWidget {
  const _ModelStep();

  static const Map<String, List<String>> brandModels = {
    'BMW': ['3 Serisi', '5 Serisi', 'X5', 'M3', 'M5'],
    'Mercedes-Benz': ['C', 'E', 'CLA', 'GLC', 'AMG'],
    'Audi': ['A3', 'A4', 'A6', 'Q5', 'RS6'],
    'Volkswagen': ['Golf', 'Passat', 'Tiguan'],
    'Toyota': ['Corolla', 'C-HR', 'Camry'],
    'Tesla': ['Model 3', 'Model Y'],
    'Renault': ['Megane', 'Clio', 'Talisman'],
    'Honda': ['Civic', 'CR-V'],
    'Hyundai': ['i20', 'Elantra', 'Tucson'],
    'Kia': ['Ceed', 'Sportage'],
    'Porsche': ['Macan', 'Cayenne'],
    'Volvo': ['S60', 'XC60', 'S90'],
    'Ford': ['Focus', 'Kuga', 'Mondeo'],
    'Mitsubishi': ['Lancer', 'ASX', 'Outlander'],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(marketFiltersProvider);
    final c = ref.read(marketFiltersProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);

    final models = List<String>.from(brandModels[f.brand] ?? const <String>[])..sort();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(f.brand.isEmpty ? 'Model' : f.brand, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (models.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
              ),
              child: Text(
                'Bu marka için model listesi yok (şimdilik).',
                style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black54),
              ),
            )
          else
            ...models.map((m) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    c.setModel(m);
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _TrimStep()));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xFF2D6BFF).withOpacity(0.14),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Color(0xFF2D6BFF)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            m,
                            style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// -------------------- STEP 4: TRIM -> RESULTS --------------------

class _TrimStep extends ConsumerWidget {
  const _TrimStep();

  static const Map<String, List<String>> modelTrims = {
    '3 Serisi': ['Sport Line', 'Luxury', 'M Paket'],
    '5 Serisi': ['Luxury', 'M Paket'],
    'X5': ['xLine', 'M Sport'],
    'C': ['Avantgarde', 'AMG Line'],
    'E': ['Exclusive', 'AMG Line'],
    'CLA': ['Progressive', 'AMG Line'],
    'A4': ['Premium', 'S Line'],
    'A6': ['Premium', 'S Line'],
    'Golf': ['Comfortline', 'Highline', 'R-Line'],
    'Passat': ['Elegance', 'R-Line'],
    'Corolla': ['Flame', 'Dream', 'X-Pack'],
    'C-HR': ['Hybrid', 'GR Sport'],
    'Model 3': ['RWD', 'Long Range', 'Performance'],
    'Model Y': ['RWD', 'Long Range', 'Performance'],
    'Megane': ['Joy', 'Touch', 'Icon'],
    'Clio': ['Joy', 'Touch', 'Icon'],
    'Civic': ['Eco', 'Elegance', 'Sport'],
    'Tucson': ['Style', 'Prime'],
    'Sportage': ['Prestige', 'GT-Line'],
    'Macan': ['Base', 'S', 'GTS'],
    'Cayenne': ['Base', 'S', 'Turbo'],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(marketFiltersProvider);
    final c = ref.read(marketFiltersProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);

    final trims = (modelTrims[f.model] ?? const <String>['Standart']).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(f.model.isEmpty ? 'Paket' : f.model, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...trims.map((tr) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  c.setTrim(tr);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MarketScreen()),
                    (route) => route.isFirst,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: const Color(0xFF2D6BFF).withOpacity(0.14),
                        ),
                        child: const Icon(Icons.layers_rounded, color: Color(0xFF2D6BFF)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr,
                          style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// -------------------- Small Search Box --------------------

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.isDark,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black38),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                border: InputBorder.none,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, v, __) {
              if (v.text.isEmpty) return const SizedBox.shrink();
              return IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close, size: 18, color: isDark ? Colors.white54 : Colors.black38),
              );
            },
          ),
        ],
      ),
    );
  }
}
