/// Whether [value] is a GTIN-8, UPC-A, EAN-13 or GTIN-14 with a valid check digit.
///
/// The server applies the same rule; checking here only saves a round trip. There is no lookup: a barcode is either
/// well formed or it is not, and the part is named by the member.
bool isValidGtin(String value) {
  final digits = value.trim();
  if (!const [8, 12, 13, 14].contains(digits.length)) return false;
  if (digits.codeUnits.any((c) => c < 0x30 || c > 0x39)) return false;

  var sum = 0;
  var weight = 3;
  for (var i = digits.length - 2; i >= 0; i--) {
    sum += (digits.codeUnitAt(i) - 0x30) * weight;
    weight = 4 - weight;
  }
  return (10 - sum % 10) % 10 == digits.codeUnitAt(digits.length - 1) - 0x30;
}
