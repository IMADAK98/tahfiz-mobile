/// Parses Nest Admin-style validation payloads:
/// `{statusCode,error,message,errors:[{fieldName,message}]}`
/// and message-only 400s (e.g. duplicate request).
class NestFieldErrors {
  const NestFieldErrors({
    required this.message,
    required this.byField,
  });

  final String message;
  final Map<String, String> byField;

  bool get hasFieldErrors => byField.isNotEmpty;

  static NestFieldErrors parse(
    dynamic data, {
    String fallback = 'تعذر إرسال الطلب',
  }) {
    if (data is! Map) {
      return NestFieldErrors(message: fallback, byField: const {});
    }
    final map = Map<String, dynamic>.from(data);
    final byField = <String, String>{};

    final errors = map['errors'];
    if (errors is List) {
      for (final item in errors) {
        if (item is! Map) continue;
        final field =
            (item['fieldName'] ?? item['field'] ?? item['path'])?.toString();
        final msg = (item['message'] ?? item['msg'])?.toString();
        if (field == null || field.isEmpty || msg == null || msg.isEmpty) {
          continue;
        }
        byField.putIfAbsent(field, () => msg);
      }
    }

    var message = fallback;
    final top = map['message'];
    if (top is String && top.isNotEmpty) {
      message = top;
    } else if (top is List && top.isNotEmpty) {
      message = top.map((e) => e.toString()).join('\n');
    } else if (byField.isNotEmpty) {
      message = byField.values.first;
    }

    return NestFieldErrors(message: message, byField: byField);
  }
}
