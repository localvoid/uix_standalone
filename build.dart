library uix_standalone.build_file;

import 'package:uix_standalone/standalone/uix/generator.dart';
import 'package:source_gen/source_gen.dart';

void main(List<String> args) {
  build(args, const [
    const ComponentGenerator()
  ], librarySearchPaths: ['lib/standalone/app/components', 'lib/browser/app/components']).then((msg) {
    print(msg);
  });
}