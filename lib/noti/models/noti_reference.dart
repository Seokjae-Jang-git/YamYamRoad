enum NotiReferenceType {
  post('post'),
  stamp('stamp'),
  badge('badge'),
  pointTransaction('point_transaction');

  const NotiReferenceType(this.value);

  final String value;

  static NotiReferenceType? fromValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    for (final type in values) {
      if (type.value == normalized) return type;
    }
    return null;
  }
}
