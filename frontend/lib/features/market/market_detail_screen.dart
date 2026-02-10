import 'dart:math';
import 'package:flutter/material.dart';

import 'listing_model.dart';

class MarketDetailScreen extends StatelessWidget {
  final Listing listing;
  final List<Listing> pool; // fiyat analizi + benzer ilanlar için aynı havuz

  const MarketDetailScreen({
    super.key,
    required this.listing,
    required this.pool,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final isDark = t.brightness == Brightness.dark;

    final bg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F7FA);
    final card = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.08) : Colors.black12;
    final textStrong = isDark ? Colors.white : Colors.black;
    final textSoft = isDark ? Colors.white70 : Colors.black54;

    final analysis = _priceAnalysis(listing, pool);
    final similar = _pickSimilarListings(listing, pool, take: 5);

    final why = _whyThisPrice(listing: listing, pool: pool, analysis: analysis);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          listing.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero image placeholder
          Container(
            height: 220,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Text(
              'Görsel',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title + price
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: textStrong,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _tryFormatTL(listing.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: Color(0xFF2D6BFF),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(isDark, '${listing.year}'),
                    _pill(isDark, '${_formatKm(listing.km)} km'),
                    _pill(isDark, listing.fuel.name),
                    _pill(isDark, listing.gear.name),
                    _pill(isDark, listing.body.name),
                    _pill(isDark, listing.location),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Price analysis (v1 card)
          _PriceAnalysisCard(isDark: isDark, a: analysis),

          const SizedBox(height: 12),

          // Neden bu fiyat?
          _WhyThisPriceCard(
            isDark: isDark,
            title: 'Neden bu fiyat?',
            summary: why.summary,
            bullets: why.bullets,
            confidenceNote: why.confidenceNote,
            signals: why.signals,
          ),

          const SizedBox(height: 12),

          // Benzer ilanlar
          _SimilarListingsSection(
            isDark: isDark,
            items: similar,
            onOpen: (x) {
              // Şimdilik boş: Projende "detay->detay" akışı nasıl ise
              // onu aynı şekilde burada bağlarsın (go_router vs).
              // Dosya istemediğin için burada dokunmuyorum.
            },
          ),

          const SizedBox(height: 12),

          // Seller
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF2D6BFF).withOpacity(0.14),
                  child: const Icon(Icons.person, color: Color(0xFF2D6BFF)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.seller,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: textStrong,
                        ),
                      ),
                      Text(
                        'Satıcı profili (yakında)',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  child: Text(
                    'Mesaj',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // CTA buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Favorile',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D6BFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Ara', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------- UI helpers --------------------
  static Widget _pill(bool isDark, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white70 : Colors.black54,
        ),
      ),
    );
  }

  static String _formatKm(int km) {
    if (km >= 1000) return (km / 1000).toStringAsFixed(km % 1000 == 0 ? 0 : 1) + 'k';
    return '$km';
  }

  static String _tryFormatTL(int v) {
    // paket eklemeden basit format
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write('.');
    }
    return '₺${b.toString()}';
  }
}

// -------------------- Similar listings --------------------
List<Listing> _pickSimilarListings(Listing x, List<Listing> pool, {int take = 5}) {
  final all = pool.where((e) => e != x).toList();

  // 1) brand+model+trim -> 2) brand+model -> 3) same body
  List<Listing> candidates = all.where((e) => e.brand == x.brand && e.model == x.model && e.trim == x.trim).toList();
  if (candidates.length < take) {
    candidates = all.where((e) => e.brand == x.brand && e.model == x.model).toList();
  }
  if (candidates.length < take) {
    candidates = all.where((e) => e.body == x.body).toList();
  }
  if (candidates.isEmpty) return [];

  double score(Listing e) {
    // daha yakın = daha yüksek skor
    final dy = (e.year - x.year).abs();
    final dk = (e.km - x.km).abs();
    final dp = (e.price - x.price).abs();

    // normalize
    final sy = 1 / (1 + dy.toDouble());
    final sk = 1 / (1 + (dk / 20000));
    final sp = 1 / (1 + (dp / max(1, x.price)));

    return (sy * 0.40) + (sk * 0.35) + (sp * 0.25);
  }

  candidates.sort((a, b) => score(b).compareTo(score(a)));

  // uniq (title bazlı çok tekrar olmasın)
  final out = <Listing>[];
  final seen = <String>{};
  for (final e in candidates) {
    final key = '${e.brand}-${e.model}-${e.trim}-${e.year}-${e.km}-${e.price}';
    if (seen.add(key)) out.add(e);
    if (out.length >= take) break;
  }
  return out;
}

class _SimilarListingsSection extends StatelessWidget {
  final bool isDark;
  final List<Listing> items;
  final void Function(Listing) onOpen;

  const _SimilarListingsSection({
    required this.isDark,
    required this.items,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.08) : Colors.black12;
    final textStrong = isDark ? Colors.white : Colors.black;
    final textSoft = isDark ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Benzer ilanlar', style: TextStyle(fontWeight: FontWeight.w900, color: textStrong)),
          const SizedBox(height: 6),
          Text(
            items.isEmpty ? 'Şimdilik benzer ilan bulunamadı.' : 'Piyasayı kıyaslamak için hızlı örnekler.',
            style: TextStyle(fontWeight: FontWeight.w700, color: textSoft),
          ),
          const SizedBox(height: 12),
          if (items.isNotEmpty)
            SizedBox(
              height: 156,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _MiniListingCard(
                  isDark: isDark,
                  x: items[i],
                  onTap: () => onOpen(items[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniListingCard extends StatelessWidget {
  final bool isDark;
  final Listing x;
  final VoidCallback onTap;

  const _MiniListingCard({
    required this.isDark,
    required this.x,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.08) : Colors.black12;
    final textStrong = isDark ? Colors.white : Colors.black;
    final textSoft = isDark ? Colors.white70 : Colors.black54;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // mini "image"
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF2F4F7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
              ),
              alignment: Alignment.center,
              child: Text(
                'Görsel',
                style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white54 : Colors.black45, fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              x.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w900, color: textStrong, height: 1.1),
            ),
            const SizedBox(height: 6),
            Text(
  _tryFormatTL(x.price),
  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2D6BFF)),
),
const SizedBox(height: 8),
Text(
  '${x.year} • ${_formatKm(x.km)} km • ${x.location}',

              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, color: textSoft, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatKm(int km) {
    if (km >= 1000) return (km / 1000).toStringAsFixed(km % 1000 == 0 ? 0 : 1) + 'k';
    return '$km';
  }

  static String _tryFormatTL(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idx = s.length - i;
      b.write(s[i]);
      if (idx > 1 && idx % 3 == 1) b.write('.');
    }
    return '₺${b.toString()}';
  }
}

// -------------------- "Neden bu fiyat?" --------------------
class _WhyThisPriceResult {
  final String summary;
  final String confidenceNote;
  final List<String> bullets;
  final List<_SignalChip> signals;

  const _WhyThisPriceResult({
    required this.summary,
    required this.confidenceNote,
    required this.bullets,
    required this.signals,
  });
}

class _SignalChip {
  final String text;
  final _SignalType type; // good/bad/neutral

  const _SignalChip(this.text, this.type);
}

enum _SignalType { good, bad, neutral }

_WhyThisPriceResult _whyThisPrice({
  required Listing listing,
  required List<Listing> pool,
  required _PriceAnalysis analysis,
}) {
  // Aynı brand+model (+ trim varsa) üzerinden referans metrik çıkaralım.
  List<Listing> base = pool.where((e) => e.brand == listing.brand && e.model == listing.model && e != listing).toList();
  final strict = base.where((e) => e.trim == listing.trim).toList();
  if (strict.length >= 6) base = strict;

  // median year/km
  int medianInt(List<int> a) {
    if (a.isEmpty) return 0;
    a.sort();
    final mid = a.length ~/ 2;
    return a.length.isOdd ? a[mid] : ((a[mid - 1] + a[mid]) / 2).round();
  }

  final years = base.map((e) => e.year).toList();
  final kms = base.map((e) => e.km).toList();
  final medYear = medianInt(years);
  final medKm = medianInt(kms);

  // trim rarity: aynı model içinde aynı trim oranı (yaklaşık)
  final sameModel = pool.where((e) => e.brand == listing.brand && e.model == listing.model).toList();
  final sameTrim = sameModel.where((e) => e.trim == listing.trim).toList();
  final trimShare = sameModel.isEmpty ? 0.0 : (sameTrim.length / sameModel.length);

  // confidence degrade: sample küçükse ve trim çok azsa
  final lowSample = analysis.sample < 8;
  final veryLowSample = analysis.sample < 4;
  final rareTrim = trimShare > 0 && trimShare <= 0.18;

  // “Neden” maddeleri
  final bullets = <String>[];
  final signals = <_SignalChip>[];

  // KM signal
  if (medKm > 0) {
    final dk = listing.km - medKm;
    if (dk >= 30000) {
      bullets.add('KM, benzer ilanların medyanına göre daha yüksek. Bu genelde fiyatı aşağı iter.');
      signals.add(const _SignalChip('KM yüksek', _SignalType.bad));
    } else if (dk <= -30000) {
      bullets.add('KM, benzer ilanların medyanına göre düşük. Bu fiyatı yukarı çekebilir.');
      signals.add(const _SignalChip('KM düşük', _SignalType.good));
    } else {
      bullets.add('KM seviyesi benzer ilanlara yakın; fiyatı tek başına çok bozmaz.');
      signals.add(const _SignalChip('KM normal', _SignalType.neutral));
    }
  } else {
    bullets.add('KM karşılaştırması için yeterli veri yok.');
    signals.add(const _SignalChip('KM verisi az', _SignalType.neutral));
  }

  // Year signal
  if (medYear > 0) {
    final dy = listing.year - medYear;
    if (dy <= -2) {
      bullets.add('Yıl, benzer ilanların medyanına göre düşük. Bu fiyatı aşağı yönlü baskılar.');
      signals.add(const _SignalChip('Yıl düşük', _SignalType.bad));
    } else if (dy >= 2) {
      bullets.add('Yıl, benzer ilanlara göre daha yeni. Bu fiyatı yukarı taşıyabilir.');
      signals.add(const _SignalChip('Yıl yüksek', _SignalType.good));
    } else {
      bullets.add('Yıl bandı benzer ilanlara yakın.');
      signals.add(const _SignalChip('Yıl normal', _SignalType.neutral));
    }
  } else {
    bullets.add('Yıl karşılaştırması için yeterli veri yok.');
    signals.add(const _SignalChip('Yıl verisi az', _SignalType.neutral));
  }

  // Trim / paket rarity
  if (listing.trim.trim().isNotEmpty && trimShare > 0) {
    if (rareTrim) {
      bullets.add('Paket/Donanım (trim) daha nadir görünüyor. Nadir paketler fiyatı yukarı taşıyabilir ama kıyaslama verisini azaltır.');
      signals.add(const _SignalChip('Paket nadir', _SignalType.neutral));
    } else {
      bullets.add('Paket/Donanım piyasada yaygın; kıyas yapmak daha sağlıklı.');
      signals.add(const _SignalChip('Paket yaygın', _SignalType.good));
    }
  } else {
    bullets.add('Paket/Donanım dağılımı için yeterli veri yok (trim boş veya havuz zayıf).');
    signals.add(const _SignalChip('Paket verisi az', _SignalType.neutral));
  }

  // Listing count effect
  if (analysis.sample <= 5) {
    bullets.add('Benzer ilan sayısı düşük. Bu nedenle fiyat kıyası daha az güvenilir (güven düşer).');
    signals.add(const _SignalChip('İlan sayısı az', _SignalType.bad));
  } else if (analysis.sample <= 10) {
    bullets.add('Benzer ilan sayısı sınırlı; sonuçları “yaklaşık” kabul etmek daha doğru.');
    signals.add(const _SignalChip('İlan sayısı sınırlı', _SignalType.neutral));
  } else {
    bullets.add('Benzer ilan sayısı iyi; kıyas daha güvenilir.');
    signals.add(const _SignalChip('Veri yeterli', _SignalType.good));
  }

  // Price position highlight
  if (analysis.average > 0) {
    final p = (analysis.diffRatio * 100).toStringAsFixed(1);
    if (analysis.diffRatio.abs() < 0.03) {
      bullets.add('Fiyat, piyasa ortalamasına çok yakın ($p%).');
      signals.add(const _SignalChip('Piyasaya yakın', _SignalType.good));
    } else if (analysis.diffRatio < 0) {
      bullets.add('Fiyat, piyasa ortalamasının altında ($p%). Sebep genelde KM/yıl/şehir/satıcı aciliyeti olabilir.');
      signals.add(const _SignalChip('Fiyat düşük', _SignalType.good));
    } else {
      bullets.add('Fiyat, piyasa ortalamasının üstünde ($p%). Sebep genelde daha iyi kondisyon/paket/şehir/az bulunan kombinasyon olabilir.');
      signals.add(const _SignalChip('Fiyat yüksek', _SignalType.neutral));
    }
  }

  // summary & confidence
  String summary;
  if (analysis.average == 0) {
    summary = 'Kıyas için yeterli veri yok. Daha geniş havuzla analiz güçlenir.';
  } else if (analysis.diffRatio.abs() < 0.03) {
    summary = 'Bu ilan “piyasaya yakın” görünüyor. KM ve yıl bandı benzer; belirleyici detaylar paket/şehir/kondisyon olabilir.';
  } else if (analysis.diffRatio < 0) {
    summary = 'Bu ilan “piyasanın altında” görünüyor. KM ve yıl farkları bu sonucu destekliyorsa fırsat olabilir.';
  } else {
    summary = 'Bu ilan “piyasanın üstünde” görünüyor. Daha yeni yıl, düşük KM veya nadir paket gibi faktörler bu farkı açıklayabilir.';
  }

  String confidenceNote;
  if (veryLowSample) {
    confidenceNote = 'Güven düşük: benzer ilan sayısı çok az. “Tahmini” olarak değerlendir.';
  } else if (lowSample || rareTrim) {
    confidenceNote = 'Güven orta/düşük: veri sınırlı veya paket nadir. Kıyas yaparken dikkat.';
  } else {
    confidenceNote = 'Güven iyi: benzer ilan sayısı yeterli. Yine de kondisyon/hasar/ekspertiz gibi detaylar sonucu değiştirir.';
  }

  return _WhyThisPriceResult(
    summary: summary,
    confidenceNote: confidenceNote,
    bullets: bullets,
    signals: signals,
  );
}

class _WhyThisPriceCard extends StatelessWidget {
  final bool isDark;
  final String title;
  final String summary;
  final String confidenceNote;
  final List<String> bullets;
  final List<_SignalChip> signals;

  const _WhyThisPriceCard({
    required this.isDark,
    required this.title,
    required this.summary,
    required this.bullets,
    required this.confidenceNote,
    required this.signals,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? Colors.white.withOpacity(0.06) : Colors.white;
    final border = isDark ? Colors.white.withOpacity(0.08) : Colors.black12;
    final textStrong = isDark ? Colors.white : Colors.black;
    final textSoft = isDark ? Colors.white70 : Colors.black54;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: textStrong)),
          const SizedBox(height: 8),
          Text(
            summary,
            style: TextStyle(fontWeight: FontWeight.w800, color: textSoft, height: 1.25),
          ),
          const SizedBox(height: 10),

          // signals row
          if (signals.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: signals.map((s) => _signalChip(isDark, s)).toList(),
            ),

          const SizedBox(height: 10),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.bolt, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(fontWeight: FontWeight.w700, color: textSoft, height: 1.2),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 2),
          Text(
            confidenceNote,
            style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white60 : Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _signalChip(bool isDark, _SignalChip s) {
    Color base;
    switch (s.type) {
      case _SignalType.good:
        base = const Color(0xFF22C55E); // green-ish
        break;
      case _SignalType.bad:
        base = const Color(0xFFF97316); // orange-ish
        break;
      case _SignalType.neutral:
        base = const Color(0xFF2D6BFF); // accent
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: base.withOpacity(isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: base.withOpacity(0.35)),
      ),
      child: Text(
        s.text,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white : Colors.black,
          fontSize: 12,
        ),
      ),
    );
  }
}

// -------------------- Price analysis (v1) --------------------
class _PriceAnalysis {
  final int sample;
  final int average;
  final double diffRatio; // + üstü / - altı
  final String label;
  final String confidence; // Yüksek / Orta / Düşük
  const _PriceAnalysis({
    required this.sample,
    required this.average,
    required this.diffRatio,
    required this.label,
    required this.confidence,
  });
}

_PriceAnalysis _priceAnalysis(Listing x, List<Listing> pool) {
  // 1) temel adaylar: brand+model+trim
  var candidates = pool
      .where((e) => e.brand == x.brand && e.model == x.model && e.trim == x.trim)
      .toList();

  if (candidates.length < 5) {
    // fallback: brand+model
    candidates = pool.where((e) => e.brand == x.brand && e.model == x.model).toList();
  }

  if (candidates.isEmpty) {
    return const _PriceAnalysis(
      sample: 0,
      average: 0,
      diffRatio: 0,
      label: 'Yeterli veri yok',
      confidence: 'Düşük',
    );
  }

  // 2) benzerlik ağırlığı: yıl + km
  double weight(Listing e) {
    final dy = (e.year - x.year).abs();
    final dk = (e.km - x.km).abs();

    // yıl yakınsa güçlü ağırlık
    final wy = dy <= 1 ? 1.0 : (dy == 2 ? 0.7 : 0.4);

    // km yakınsa güçlü ağırlık
    final wk = dk <= 20000 ? 1.0 : (dk <= 40000 ? 0.75 : (dk <= 80000 ? 0.55 : 0.35));

    return wy * wk;
  }

  // 3) uç değer kırpma (IQR) - fiyatlar
  final prices = candidates.map((e) => e.price).toList()..sort();
  if (prices.length < 3) {
    final avg = (prices.reduce((a, b) => a + b) / prices.length).round();
    final ratio = avg == 0 ? 0.0 : ((x.price - avg) / avg);
    return _finalize(x, avg, ratio, candidates.length);
  }

  int qIndex(double q) => ((prices.length - 1) * q).round();
  final q1 = prices[qIndex(0.25)];
  final q3 = prices[qIndex(0.75)];
  final iqr = (q3 - q1).toDouble();
  final low = (q1 - 1.5 * iqr);
  final high = (q3 + 1.5 * iqr);

  final trimmed = candidates.where((e) => e.price >= low && e.price <= high).toList();
  final used = trimmed.isEmpty ? candidates : trimmed;

  // 4) ağırlıklı ortalama
  double sumW = 0;
  double sum = 0;
  for (final e in used) {
    final w = weight(e);
    sumW += w;
    sum += e.price * w;
  }
  final avg = (sumW == 0
          ? used.map((e) => e.price).reduce((a, b) => a + b) / used.length
          : sum / sumW)
      .round();

  final ratio = avg == 0 ? 0.0 : ((x.price - avg) / avg);

  return _finalize(x, avg, ratio, used.length);
}

_PriceAnalysis _finalize(Listing x, int avg, double ratio, int sample) {
  final abs = ratio.abs();
  String label;
  if (avg == 0) {
    label = 'Yeterli veri yok';
  } else if (abs < 0.03) {
    label = 'Piyasaya yakın';
  } else if (ratio < 0) {
    label = 'Piyasanın altında';
  } else {
    label = 'Piyasanın üstünde';
  }

  // confidence: sample + farkın stabilitesi (basit)
  String conf;
  if (sample >= 18) conf = 'Yüksek';
  else if (sample >= 8) conf = 'Orta';
  else conf = 'Düşük';

  return _PriceAnalysis(
    sample: sample,
    average: avg,
    diffRatio: ratio,
    label: label,
    confidence: conf,
  );
}

class _PriceAnalysisCard extends StatelessWidget {
  final bool isDark;
  final _PriceAnalysis a;
  const _PriceAnalysisCard({required this.isDark, required this.a});

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF2D6BFF);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fiyat Analizi', style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: accent.withOpacity(0.35)),
                ),
                child: Text(a.label, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
              ),
              const SizedBox(width: 10),
              Text('Örnek: ${a.sample} • Güven: ${a.confidence}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white60 : Colors.black54)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            a.average == 0 ? 'Yeterli veri yok' : 'Ortalama: ₺${a.average}',
            style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
          ),
          const SizedBox(height: 6),
          Text(
            a.average == 0
                ? 'Bu model için yeterli ilan verisi yok.'
                : 'Bu ilanın fiyatı ortalamaya göre ${(a.diffRatio * 100).toStringAsFixed(1)}% ${a.diffRatio < 0 ? 'daha düşük' : 'daha yüksek'}.',
            style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.black54, height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            'Not: v1 hesaplama; yıl bandı ve ilan dağılımına göre geliştireceğiz (KM/hasar/şehir ağırlıkları eklenecek).',
            style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : Colors.black45, height: 1.2),
          ),
        ],
      ),
    );
  }
}
