/// One row from public `GET /center` (`{status,data:[{id,name,...}]}`).
class CenterOption {
  const CenterOption({required this.id, required this.name});

  final num id;
  final String name;

  factory CenterOption.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'] ?? json['centerName'] ?? '';
    return CenterOption(
      id: id is num ? id : num.tryParse(id?.toString() ?? '') ?? 0,
      name: name.toString(),
    );
  }
}

/// Unwraps Nest list envelope for centers.
List<CenterOption> parseCentersResponse(dynamic raw) {
  dynamic list = raw;
  if (raw is Map) {
    list = raw['data'] ?? raw['centers'] ?? raw['items'] ?? raw['results'];
  }
  if (list is! List) return const [];
  return list
      .whereType<Map>()
      .map((e) => CenterOption.fromJson(Map<String, dynamic>.from(e)))
      .where((c) => c.id != 0 && c.name.isNotEmpty)
      .toList();
}
