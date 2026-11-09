import 'package:flutter_test/flutter_test.dart';
import 'package:velomine/features/bikes/part_identity.dart';

void main() {
  test('Gtin_ShouldBeAccepted_WhenTheCheckDigitIsRight', () {
    expect(isValidGtin('4006381333931'), isTrue); // EAN-13
    expect(isValidGtin('036000291452'), isTrue); // UPC-A
    expect(isValidGtin('96385074'), isTrue); // GTIN-8
    expect(isValidGtin('12345678901231'), isTrue); // GTIN-14
  });

  test('Gtin_ShouldBeRejected_WhenItIsNotAWellFormedGtin', () {
    expect(isValidGtin('4006381333932'), isFalse); // wrong check digit
    expect(isValidGtin('40063813339A1'), isFalse); // not digits
    expect(isValidGtin('400638133393'), isFalse); // wrong length
    expect(isValidGtin(''), isFalse);
  });
}
