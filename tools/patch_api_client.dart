import 'dart:io';

/// openapi-generator's Dart client casts every JSON number straight to `double`
/// or `int`. JSON has no integer/double distinction and the server writes whole
/// seconds as `79`, so that cast throws on native, where `79 is double` is
/// false (it works on the web, where every number is a double). Neither does the
/// cast accept a null element of a nullable array.
///
/// Rewrites `(json[r'x'] as Iterable).cast<double>()` to read any number,
/// keeping nulls where the field's element type allows them. Works on the
/// generated output, so the client stays generated; `tools/generate-api-client.sh`
/// runs this right after the generator.
void main(List<String> args) {
  final directory = Directory(
    args.isEmpty ? 'app/packages/velomine_api/lib/model' : args.single,
  );
  final declaration = RegExp(r'final List<(double|int)(\?)?>(\?)? (\w+);');
  final cast = RegExp(
    r"\(json\[r'(\w+)'\] as Iterable\)\.cast<(double|int)>\(\)\.toList\(growable: false\)",
  );

  var rewritten = 0;
  for (final file in directory.listSync().whereType<File>().where(
    (file) => file.path.endsWith('.dart'),
  )) {
    final source = file.readAsStringSync();
    final types = <String, (String, bool)>{};
    for (final match in declaration.allMatches(source)) {
      final field = match.group(4)!;
      types[field] = (match.group(1)!, match.group(2) == '?');
    }

    final patched = source.replaceAllMapped(cast, (match) {
      final type = types[match.group(1)!];
      if (type == null) return match.group(0)!;
      final (kind, nullable) = type;
      final number = nullable ? 'num?' : 'num';
      final chain = nullable ? '?.' : '.';
      final to = kind == 'double' ? 'toDouble' : 'toInt';
      return "(json[r'${match.group(1)}'] as Iterable)"
          '.map((e) => (e as $number)$chain$to()).toList(growable: false)';
    });
    if (patched != source) {
      file.writeAsStringSync(patched);
      rewritten++;
    }
  }
  stdout.writeln('Patched $rewritten model file(s) to read JSON numbers.');
}
