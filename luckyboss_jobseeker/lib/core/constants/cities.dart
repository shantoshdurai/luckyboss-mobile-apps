/// A city a candidate can search or live in.
class City {
  final String name;

  /// ISO country code — 'IN', 'SG', 'MY'.
  final String country;

  /// Larger metros rank first in the picker.
  final int rank;

  const City(this.name, this.country, {this.rank = 50});
}

/// Bundled city list for the three Lucky Boss markets.
///
/// Deliberately shipped with the app rather than fetched. Location is typed at
/// the very start of search and again during onboarding, and a network round
/// trip per keystroke is exactly what made skill lookup feel sluggish. Cities
/// also do not change, so there is nothing to keep in sync.
///
/// Coverage is the tier-1 and tier-2 cities that carry recruitment volume in
/// each market, not an exhaustive gazetteer — a picker with nine hundred
/// villages in it is harder to use, not easier. Free text stays allowed
/// everywhere this list is offered, so nobody is blocked by an omission.
class Cities {
  Cities._();

  static const List<City> all = [
    // ── Singapore ────────────────────────────────────────────────────────────
    // A city-state: the districts are what people actually name.
    City('Singapore', 'SG', rank: 100),
    City('Jurong East', 'SG', rank: 80),
    City('Tampines', 'SG', rank: 80),
    City('Woodlands', 'SG', rank: 78),
    City('Changi', 'SG', rank: 78),
    City('Tuas', 'SG', rank: 76),
    City('Marina Bay', 'SG', rank: 82),
    City('Raffles Place', 'SG', rank: 80),
    City('Orchard', 'SG', rank: 78),
    City('Bukit Merah', 'SG', rank: 70),
    City('Ang Mo Kio', 'SG', rank: 70),
    City('Paya Lebar', 'SG', rank: 72),
    City('Novena', 'SG', rank: 68),
    City('Sengkang', 'SG', rank: 66),
    City('Punggol', 'SG', rank: 66),
    City('Yishun', 'SG', rank: 66),
    City('Clementi', 'SG', rank: 66),
    City('Bedok', 'SG', rank: 66),
    City('Serangoon', 'SG', rank: 64),
    City('Toa Payoh', 'SG', rank: 64),

    // ── Malaysia ─────────────────────────────────────────────────────────────
    City('Kuala Lumpur', 'MY', rank: 100),
    City('Petaling Jaya', 'MY', rank: 88),
    City('Shah Alam', 'MY', rank: 86),
    City('Subang Jaya', 'MY', rank: 84),
    City('Johor Bahru', 'MY', rank: 90),
    City('Penang', 'MY', rank: 88),
    City('George Town', 'MY', rank: 84),
    City('Ipoh', 'MY', rank: 78),
    City('Melaka', 'MY', rank: 76),
    City('Seremban', 'MY', rank: 72),
    City('Kuching', 'MY', rank: 76),
    City('Kota Kinabalu', 'MY', rank: 76),
    City('Cyberjaya', 'MY', rank: 80),
    City('Putrajaya', 'MY', rank: 78),
    City('Klang', 'MY', rank: 74),
    City('Puchong', 'MY', rank: 74),
    City('Cheras', 'MY', rank: 72),
    City('Kajang', 'MY', rank: 70),
    City('Bangi', 'MY', rank: 68),
    City('Nilai', 'MY', rank: 66),
    City('Kuantan', 'MY', rank: 68),
    City('Alor Setar', 'MY', rank: 64),
    City('Kota Bharu', 'MY', rank: 64),
    City('Miri', 'MY', rank: 64),
    City('Sandakan', 'MY', rank: 62),

    // ── India ────────────────────────────────────────────────────────────────
    City('Bengaluru', 'IN', rank: 100),
    City('Chennai', 'IN', rank: 98),
    City('Hyderabad', 'IN', rank: 96),
    City('Mumbai', 'IN', rank: 98),
    City('Pune', 'IN', rank: 94),
    City('Delhi', 'IN', rank: 96),
    City('New Delhi', 'IN', rank: 92),
    City('Gurugram', 'IN', rank: 92),
    City('Noida', 'IN', rank: 90),
    City('Kolkata', 'IN', rank: 88),
    City('Ahmedabad', 'IN', rank: 86),
    City('Coimbatore', 'IN', rank: 84),
    City('Tiruchirappalli', 'IN', rank: 78),
    City('Madurai', 'IN', rank: 78),
    City('Salem', 'IN', rank: 74),
    City('Tiruppur', 'IN', rank: 74),
    City('Erode', 'IN', rank: 70),
    City('Vellore', 'IN', rank: 70),
    City('Thanjavur', 'IN', rank: 66),
    City('Tirunelveli', 'IN', rank: 68),
    City('Puducherry', 'IN', rank: 72),
    City('Kochi', 'IN', rank: 82),
    City('Thiruvananthapuram', 'IN', rank: 78),
    City('Kozhikode', 'IN', rank: 72),
    City('Thrissur', 'IN', rank: 70),
    City('Mysuru', 'IN', rank: 76),
    City('Mangaluru', 'IN', rank: 74),
    City('Hubballi', 'IN', rank: 68),
    City('Visakhapatnam', 'IN', rank: 80),
    City('Vijayawada', 'IN', rank: 76),
    City('Guntur', 'IN', rank: 70),
    City('Tirupati', 'IN', rank: 68),
    City('Warangal', 'IN', rank: 66),
    City('Nagpur', 'IN', rank: 78),
    City('Nashik', 'IN', rank: 76),
    City('Aurangabad', 'IN', rank: 70),
    City('Thane', 'IN', rank: 80),
    City('Navi Mumbai', 'IN', rank: 84),
    City('Surat', 'IN', rank: 80),
    City('Vadodara', 'IN', rank: 76),
    City('Rajkot', 'IN', rank: 72),
    City('Jaipur', 'IN', rank: 84),
    City('Jodhpur', 'IN', rank: 68),
    City('Udaipur', 'IN', rank: 66),
    City('Lucknow', 'IN', rank: 82),
    City('Kanpur', 'IN', rank: 74),
    City('Varanasi', 'IN', rank: 70),
    City('Prayagraj', 'IN', rank: 68),
    City('Ghaziabad', 'IN', rank: 78),
    City('Faridabad', 'IN', rank: 76),
    City('Chandigarh', 'IN', rank: 82),
    City('Mohali', 'IN', rank: 72),
    City('Ludhiana', 'IN', rank: 74),
    City('Amritsar', 'IN', rank: 70),
    City('Jalandhar', 'IN', rank: 66),
    City('Dehradun', 'IN', rank: 70),
    City('Bhopal', 'IN', rank: 74),
    City('Indore', 'IN', rank: 80),
    City('Jabalpur', 'IN', rank: 64),
    City('Raipur', 'IN', rank: 70),
    City('Ranchi', 'IN', rank: 68),
    City('Patna', 'IN', rank: 74),
    City('Bhubaneswar', 'IN', rank: 76),
    City('Cuttack', 'IN', rank: 64),
    City('Guwahati', 'IN', rank: 72),
  ];

  /// Ranked prefix-first match. Prefix hits outrank substring hits so typing
  /// "Tiru" surfaces Tiruchirappalli and Tiruppur before Puducherry.
  static List<City> search(String query, {String? country, int limit = 8}) {
    final q = query.trim().toLowerCase();
    final pool = country == null || country.isEmpty
        ? all
        : all.where((c) => c.country == country).toList();

    if (q.isEmpty) {
      final top = [...pool]..sort((a, b) => b.rank.compareTo(a.rank));
      return top.take(limit).toList();
    }

    final matches = pool
        .where((c) => c.name.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) {
        final aStarts = a.name.toLowerCase().startsWith(q) ? 0 : 1;
        final bStarts = b.name.toLowerCase().startsWith(q) ? 0 : 1;
        if (aStarts != bStarts) return aStarts.compareTo(bStarts);
        return b.rank.compareTo(a.rank);
      });

    return matches.take(limit).toList();
  }
}
