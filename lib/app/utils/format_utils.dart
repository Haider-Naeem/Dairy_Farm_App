// lib/app/utils/format_utils.dart

String formatL(double v) {
  final s = v.toStringAsFixed(2);
  if (s.endsWith('00')) return v.toStringAsFixed(0);
  if (s.endsWith('0'))  return v.toStringAsFixed(1);
  return s;
}