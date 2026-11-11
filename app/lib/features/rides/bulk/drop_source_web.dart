import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'drop_source.dart';
import 'ride_file.dart';

/// The browser's own drag-and-drop and directory APIs, through Dart's official web interop.
DropSource createPlatformDropSource() => _WebDropSource();

class _WebDropSource implements DropSource {
  _WebDropSource() {
    web.document
      ..addEventListener('dragenter', _enter)
      ..addEventListener('dragover', _over)
      ..addEventListener('dragleave', _leave)
      ..addEventListener('drop', _drop);
  }

  final _dragging = StreamController<bool>.broadcast(sync: true);
  final _drops = StreamController<Future<List<RideFileEntry>>>.broadcast(
    sync: true,
  );

  // dragenter and dragleave fire for every element under the pointer: only the balance says whether the drag left.
  int _depth = 0;

  late final JSFunction _enter = ((web.DragEvent event) {
    if (!_hasFiles(event)) return;
    event.preventDefault();
    if (_depth++ == 0) _dragging.add(true);
  }).toJS;

  late final JSFunction _over = ((web.DragEvent event) {
    // Without this the browser would open the file instead of handing it to the page.
    if (_hasFiles(event)) event.preventDefault();
  }).toJS;

  late final JSFunction _leave = ((web.DragEvent event) {
    if (_depth == 0) return;
    if (--_depth == 0) _dragging.add(false);
  }).toJS;

  late final JSFunction _drop = ((web.DragEvent event) {
    if (!_hasFiles(event)) return;
    event.preventDefault();
    _depth = 0;
    _dragging.add(false);

    // The browser empties the drag data once this handler returns: take the entries now, walk them later.
    final entries = <web.FileSystemEntry>[];
    final loose = <web.File>[];
    final items = event.dataTransfer?.items;
    if (items != null) {
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.kind != 'file') continue;
        final entry = item.webkitGetAsEntry();
        if (entry != null) {
          entries.add(entry);
        } else if (item.getAsFile() case final file?) {
          loose.add(file);
        }
      }
    }
    _drops.add(_walk(entries, loose));
  }).toJS;

  static bool _hasFiles(web.DragEvent event) {
    final types = event.dataTransfer?.types.toDart ?? const <JSString>[];
    return types.any((type) => type.toDart == 'Files');
  }

  @override
  bool get supported => true;

  @override
  Stream<bool> get dragging => _dragging.stream;

  @override
  Stream<Future<List<RideFileEntry>>> get drops => _drops.stream;

  @override
  Future<List<RideFileEntry>> pickFolder() => _pick(folder: true);

  @override
  Future<List<RideFileEntry>> pickFiles() => _pick(folder: false);

  Future<List<RideFileEntry>> _pick({required bool folder}) {
    final done = Completer<List<RideFileEntry>>();
    final input = web.document.createElement('input') as web.HTMLInputElement
      ..type = 'file'
      ..multiple = true;
    if (folder) {
      input.webkitdirectory = true;
    } else {
      input.accept = '.fit,.gpx,.tcx,.gz';
    }
    input.style.display = 'none';

    void finish(List<RideFileEntry> files) {
      input.remove();
      if (!done.isCompleted) done.complete(files);
    }

    input.addEventListener(
      'change',
      ((web.Event _) {
        final list = input.files;
        finish([
          if (list != null)
            for (var i = 0; i < list.length; i++) _pickedFile(list.item(i)!),
        ]);
      }).toJS,
    );
    input.addEventListener('cancel', ((web.Event _) => finish(const [])).toJS);
    web.document.body?.append(input);
    input.click();
    return done.future;
  }

  @override
  void dispose() {
    web.document
      ..removeEventListener('dragenter', _enter)
      ..removeEventListener('dragover', _over)
      ..removeEventListener('dragleave', _leave)
      ..removeEventListener('drop', _drop);
    unawaited(_dragging.close());
    unawaited(_drops.close());
  }
}

/// A file from a chooser; a chosen folder gives each file its path inside it.
_WebFile _pickedFile(web.File file) => _WebFile(
  file.name,
  file.webkitRelativePath.isEmpty ? file.name : file.webkitRelativePath,
  file,
);

/// Every file under the dropped entries, folders walked to the bottom.
Future<List<RideFileEntry>> _walk(
  List<web.FileSystemEntry> entries,
  List<web.File> loose,
) async {
  final files = <RideFileEntry>[
    for (final file in loose) _WebFile(file.name, file.name, file),
  ];
  for (final entry in entries) {
    await _walkEntry(entry, files);
  }
  return files;
}

Future<void> _walkEntry(
  web.FileSystemEntry entry,
  List<RideFileEntry> into,
) async {
  try {
    if (entry.isDirectory) {
      final reader = (entry as web.FileSystemDirectoryEntry).createReader();
      // A reader hands out a directory in batches; an empty batch is the end.
      while (true) {
        final batch = await _readBatch(reader);
        if (batch.isEmpty) break;
        for (final child in batch) {
          await _walkEntry(child, into);
        }
      }
    } else {
      final file = await _fileOf(entry as web.FileSystemFileEntry);
      into.add(_WebFile(file.name, entry.fullPath, file));
    }
  } on Object {
    // One unreadable folder or file must not lose the rest of the drop.
  }
}

Future<List<web.FileSystemEntry>> _readBatch(
  web.FileSystemDirectoryReader reader,
) {
  final done = Completer<List<web.FileSystemEntry>>();
  reader.readEntries(
    ((JSArray<JSObject> found) {
      done.complete([
        for (final item in found.toDart) item as web.FileSystemEntry,
      ]);
    }).toJS,
    ((JSAny _) => done.completeError(StateError('Could not read a folder.')))
        .toJS,
  );
  return done.future;
}

Future<web.File> _fileOf(web.FileSystemFileEntry entry) {
  final done = Completer<web.File>();
  entry.file(
    ((web.File file) => done.complete(file)).toJS,
    ((JSAny _) => done.completeError(StateError('Could not open a file.')))
        .toJS,
  );
  return done.future;
}

class _WebFile implements RideFileEntry {
  _WebFile(this.name, this.path, this._file);

  @override
  final String name;

  @override
  final String path;

  final web.File _file;

  @override
  Future<Uint8List> read() async =>
      (await _file.arrayBuffer().toDart).toDart.asUint8List();
}
