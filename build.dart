library uix_standalone.build_file;

import 'package:uix_standalone/generator.dart';
import 'package:source_gen/source_gen.dart';

void main(List<String> args) {
  build(args, const [
    const ComponentGenerator()
  ], librarySearchPaths: ['example']).then((msg) {
    print(msg);
  });
}