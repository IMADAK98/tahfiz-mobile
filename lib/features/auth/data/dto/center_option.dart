/// GET `/center` list item used by signup مركز العمل.
class CenterOption {
  const CenterOption({required this.id, required this.name});

  final int id;
  final String name;

  factory CenterOption.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final id = rawId is num
        ? rawId.toInt()
        : int.tryParse(rawId?.toString() ?? '') ?? 0;
    return CenterOption(
      id: id,
      name: json['name']?.toString() ?? '',
    );
  }
}
