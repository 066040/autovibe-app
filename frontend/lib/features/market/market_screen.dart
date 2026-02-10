import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'market_state.dart';
import 'market_wizard_flow.dart';
import 'listing_model.dart';
import 'market_detail_screen.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  static const _accent = Color(0xFF2D6BFF);

  final _search = TextEditingController();
  late final List<Listing> _pool = _seedPool(); // mock ilan havuzu

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = ref.watch(marketFiltersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);

    final q = _search.text.trim().toLowerCase();
    final filtered = _applyFilters(_pool, f, q);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          children: [
            // HEADER
            Row(
              children: [
                Text(
                  'Market',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                _IconPill(
                  isDark: isDark,
                  icon: Icons.tune_rounded,
                  onTap: () => _openWizard(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // SEARCH
            _SearchBox(
              controller: _search,
              isDark: isDark,
              hint: 'İlan / marka / model ara…',
              onChanged: (_) => setState(() {}),
              onClear: () {
                _search.clear();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),

            // ACTIVE FILTERS SUMMARY
            _FiltersSummary(isDark: isDark, f: f, onClear: () {
              ref.read(marketFiltersProvider.notifier).reset();
            }),

            const SizedBox(height: 12),

            // RESULTS
            if (filtered.isEmpty)
              _Empty(isDark: isDark)
            else
              ...filtered.map((x) {
                final tag = _quickPriceTag(x, _pool);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ListingCard(
                    isDark: isDark,
                    listing: x,
                    tag: tag,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MarketDetailScreen(listing: x, pool: _pool),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _openWizard(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MarketWizardFlow()));
  }

  // --------------------- Filters ---------------------

  List<Listing> _applyFilters(List<Listing> pool, MarketFilters f, String q) {
    return pool.where((e) {
      if (e.vehicleType != f.vehicleType) return false;

      if (f.brand.trim().isNotEmpty && e.brand != f.brand) return false;
      if (f.model.trim().isNotEmpty && e.model != f.model) return false;
      if (f.trim.trim().isNotEmpty && e.trim != f.trim) return false;

      if (e.year < f.yearMin || e.year > f.yearMax) return false;
      if (e.km > f.kmMax) return false;
      if (e.price < f.priceMin || e.price > f.priceMax) return false;

      if (f.fuels.isNotEmpty && !f.fuels.contains(e.fuel)) return false;
      if (f.gears.isNotEmpty && !f.gears.contains(e.gear)) return false;
      if (f.bodies.isNotEmpty && !f.bodies.contains(e.body)) return false;

      if (q.isNotEmpty) {
        final hay = '${e.title} ${e.brand} ${e.model} ${e.trim} ${e.location} ${e.seller}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }

      return true;
    }).toList();
  }

  // --------------------- Price tag (card level) ---------------------

  _Tag _quickPriceTag(Listing x, List<Listing> pool) {
    // brand+model+trim + year band +/-2
    final candidates = pool.where((e) {
      final same = e.brand == x.brand && e.model == x.model && e.trim == x.trim;
      final yearOk = (e.year - x.year).abs() <= 2;
      return same && yearOk;
    }).toList();

    List<Listing> base = candidates;
    if (base.length < 3) {
      base = pool.where((e) => e.brand == x.brand && e.model == x.model).toList();
    }
    if (base.isEmpty) {
      return const _Tag('Veri yok', _TagKind.neutral);
    }

    final prices = base.map((e) => e.price).toList()..sort();
    final n = prices.length;
    final cut = max(0, (n * 0.10).floor());
    final sliced = prices.sublist(cut, max(cut + 1, n - cut));
    final avg = (sliced.reduce((a, b) => a + b) / sliced.length);

    final ratio = avg == 0 ? 0.0 : ((x.price - avg) / avg);
    final abs = ratio.abs();

    if (abs < 0.03) return const _Tag('Piyasaya yakın', _TagKind.neutral);
    if (ratio < 0) return _Tag('Piyasanın altında', _TagKind.good, sub: '${(abs * 100).toStringAsFixed(1)}%');
    return _Tag('Piyasanın üstünde', _TagKind.bad, sub: '${(abs * 100).toStringAsFixed(1)}%');
  }

  // --------------------- Mock pool ---------------------

  List<Listing> _seedPool() {
    // Şimdilik mock. Backend bağlanınca burası provider’dan gelecek.
    return const [
      Listing(
        id: '1',
        vehicleType: VehicleType.otomobil,
        brand: 'BMW',
        model: '5 Serisi',
        trim: 'M Paket',
        year: 2011,
        km: 185000,
        price: 1150000,
        fuel: FuelType.dizel,
        gear: GearType.otomatik,
        body: BodyType.sedan,
        title: 'BMW 5 Serisi 520d M Paket',
        location: 'İstanbul',
        seller: 'Mühendis Garage',
      ),
      Listing(
        id: '2',
        vehicleType: VehicleType.otomobil,
        brand: 'BMW',
        model: '5 Serisi',
        trim: 'M Paket',
        year: 2012,
        km: 160000,
        price: 1290000,
        fuel: FuelType.dizel,
        gear: GearType.otomatik,
        body: BodyType.sedan,
        title: 'BMW 520d M Paket Temiz',
        location: 'Ankara',
        seller: 'Bireysel Satıcı',
      ),
      Listing(
        id: '3',
        vehicleType: VehicleType.otomobil,
        brand: 'BMW',
        model: '5 Serisi',
        trim: 'Luxury',
        year: 2012,
        km: 140000,
        price: 1350000,
        fuel: FuelType.dizel,
        gear: GearType.otomatik,
        body: BodyType.sedan,
        title: 'BMW 5 Serisi Luxury',
        location: 'İzmir',
        seller: 'Premium Auto',
      ),
      Listing(
        id: '4',
        vehicleType: VehicleType.otomobil,
        brand: 'Mercedes-Benz',
        model: 'C',
        trim: 'AMG Line',
        year: 2016,
        km: 98000,
        price: 1750000,
        fuel: FuelType.benzin,
        gear: GearType.otomatik,
        body: BodyType.sedan,
        title: 'C200 AMG Line',
        location: 'İstanbul',
        seller: 'Yetkili Satıcı',
      ),
      Listing(
        id: '5',
        vehicleType: VehicleType.otomobil,
        brand: 'Audi',
        model: 'A4',
        trim: 'S Line',
        year: 2017,
        km: 102000,
        price: 1820000,
        fuel: FuelType.dizel,
        gear: GearType.otomatik,
        body: BodyType.sedan,
        title: 'Audi A4 S Line',
        location: 'Bursa',
        seller: 'Bireysel Satıcı',
      ),
      Listing(
        id: '6',
        vehicleType: VehicleType.otomobil,
        brand: 'Volkswagen',
        model: 'Golf',
        trim: 'Highline',
        year: 2018,
        km: 87000,
        price: 1180000,
        fuel: FuelType.benzin,
        gear: GearType.otomatik,
        body: BodyType.hatchback,
        title: 'Golf Highline',
        location: 'Antalya',
        seller: 'Auto Spot',
      ),
      Listing(
        id: '7',
        vehicleType: VehicleType.otomobil,
        brand: 'Toyota',
        model: 'Corolla',
        trim: 'Dream',
        year: 2020,
        km: 54000,
        price: 1320000,
        fuel: FuelType.hibrit,
        gear: GearType.otomatik,
        body: BodyType.sedan,
        title: 'Corolla Hybrid Dream',
        location: 'Konya',
        seller: 'Bireysel Satıcı',
      ),
      Listing(
        id: '8',
        vehicleType: VehicleType.otomobil,
        brand: 'Tesla',
        model: 'Model Y',
        trim: 'Long Range',
        year: 2023,
        km: 21000,
        price: 3250000,
        fuel: FuelType.elektrik,
        gear: GearType.otomatik,
        body: BodyType.suv,
        title: 'Tesla Model Y Long Range',
        location: 'İstanbul',
        seller: 'EV Club',
      ),
      Listing(
        id: '9',
        vehicleType: VehicleType.motosiklet,
        brand: 'Honda',
        model: 'Civic', // mock; sonra motosiklet modelleri ayrı olacak
        trim: 'Standart',
        year: 2021,
        km: 9000,
        price: 210000,
        fuel: FuelType.benzin,
        gear: GearType.manuel,
        body: BodyType.coupe,
        title: 'Motosiklet (mock)',
        location: 'İstanbul',
        seller: 'Moto Garage',
      ),
    ];
  }
}

// ------------------ UI bits ------------------

class _IconPill extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _IconPill({required this.isDark, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
        ),
        child: Icon(icon, size: 20, color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}

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

class _FiltersSummary extends StatelessWidget {
  final bool isDark;
  final MarketFilters f;
  final VoidCallback onClear;

  const _FiltersSummary({required this.isDark, required this.f, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final chips = <String>[];
    chips.add(f.vehicleType.name);
    if (f.brand.isNotEmpty) chips.add(f.brand);
    if (f.model.isNotEmpty) chips.add(f.model);
    if (f.trim.isNotEmpty) chips.add(f.trim);

    final has = f.hasAnyFilter;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: chips.take(4).map((t) => _pill(isDark, t)).toList(),
            ),
          ),
          const SizedBox(width: 8),
          if (has)
            OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
              ),
              child: Text('Sıfırla', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : Colors.black54)),
            ),
        ],
      ),
    );
  }

  static Widget _pill(bool isDark, String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Text(t, style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black54)),
    );
  }
}

class _Empty extends StatelessWidget {
  final bool isDark;
  const _Empty({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Text(
        'Sonuç yok.\nFiltreleri değiştir ya da aramayı genişlet.',
        style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black54),
      ),
    );
  }
}

enum _TagKind { good, bad, neutral }

class _Tag {
  final String text;
  final _TagKind kind;
  final String? sub;
  const _Tag(this.text, this.kind, {this.sub});
}

class _ListingCard extends StatelessWidget {
  final bool isDark;
  final Listing listing;
  final _Tag tag;
  final VoidCallback onTap;

  const _ListingCard({required this.isDark, required this.listing, required this.tag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF2D6BFF);

    Color border;
    Color bgTag;
    Color fgTag;

    switch (tag.kind) {
      case _TagKind.good:
        border = const Color(0xFF22C55E).withOpacity(0.45);
        bgTag = const Color(0xFF22C55E).withOpacity(isDark ? 0.18 : 0.12);
        fgTag = isDark ? Colors.white : Colors.black;
        break;
      case _TagKind.bad:
        border = const Color(0xFFEF4444).withOpacity(0.45);
        bgTag = const Color(0xFFEF4444).withOpacity(isDark ? 0.18 : 0.12);
        fgTag = isDark ? Colors.white : Colors.black;
        break;
      case _TagKind.neutral:
        border = accent.withOpacity(0.35);
        bgTag = accent.withOpacity(isDark ? 0.18 : 0.12);
        fgTag = isDark ? Colors.white : Colors.black;
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
        ),
        child: Row(
          children: [
            // image placeholder
            Container(
              width: 86,
              height: 86,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('Foto', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black45)),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // tag row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: bgTag,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: border),
                        ),
                        child: Text(
                          tag.sub == null ? tag.text : '${tag.text} • ${tag.sub}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontWeight: FontWeight.w900, color: fgTag),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black, height: 1.15),
                  ),
                  const SizedBox(height: 6),

                  Text(
                    '₺${listing.price}  •  ${listing.year}  •  ${listing.km} km',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    '${listing.location}  •  ${listing.seller}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black45),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: isDark ? Colors.white24 : Colors.black26),
          ],
        ),
      ),
    );
  }
}
