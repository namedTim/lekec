import 'package:drift/drift.dart';

import 'unsupported.dart'
    if (dart.library.js_interop) 'connection_web.dart'
    if (dart.library.ffi) 'connection_native.dart';

QueryExecutor createDatabaseConnection(String name) {
  return openConnection(name);
}
