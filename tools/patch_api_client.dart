import 'dart:io';

/// The generate script's post-step, run after openapi-generator writes the Dart
/// client. It patches three things the generator gets wrong for this project,
/// so the client stays generated and `app/packages/velomine_api` is never edited
/// by hand.
void main(List<String> args) {
  final files = args.isNotEmpty
      ? (model: args[0], apiClient: args[1])
      : (
          model: 'app/packages/velomine_api/lib/model',
          apiClient: 'app/packages/velomine_api/lib/api_client.dart',
        );
  patchModels(Directory(files.model));
  patchSerialize(File(files.apiClient));
}

/// openapi-generator's Dart client casts every JSON number straight to `double`
/// or `int`. JSON has no integer/double distinction and the server writes whole
/// seconds as `79`, so that cast throws on native, where `79 is double` is
/// false (it works on the web, where every number is a double). Neither does the
/// cast accept a null element of a nullable array.
///
/// Rewrites `(json[r'x'] as Iterable).cast<double>()` to read any number,
/// keeping nulls where the field's element type allows them.
void patchModels(Directory directory) {
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

/// The generator sends every request body through `json.encode(value)`, which
/// throws on a generated request class: a supporter key would never leave the
/// app. Writes the class's `toJson()` instead.
void patchSerialize(File file) {
  const from = "String serialize(Object? value) => value == null ? '' : json.encode(value);";
  const to =
      "String serialize(Object? value) => value == null ? '' : json.encode(value is "
      "Map || value is List ? value : (value as dynamic).toJson());";
  final source = file.readAsStringSync();
  if (!source.contains(from)) {
    stderr.writeln('${file.path}: serialize() is not the shape this patch knows.');
    exitCode = 1;
    exit(1);
  }

  file.writeAsStringSync(source.replaceFirst(from, to));
  stdout.writeln('Patched serialize() to write a request class as its toJson().');
}
