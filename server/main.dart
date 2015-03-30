import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';
import 'package:uix_standalone/standalone/uix/uix.dart';
import 'package:uix_standalone/standalone/app/app.dart';

const int I = 0;
const int N = 100;

final List<BoxData> boxes = [];

void main() {
  initUix();

  final handler = new shelf.Cascade()
    .add(createStaticHandler('../build/web/', defaultDocument: 'index.html'))
    .add(_echoRequest).handler;

  for (var i = 0; i < N; i++) {
    boxes.add(new BoxData());
  }

  io.serve(handler, 'localhost', 8080).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}

shelf.Response _echoRequest(shelf.Request request) {
  final t = new Stopwatch()..start();

  final VNode html = vBoxList(data: boxes);
  html.create(const VContext(true));
  html.attach();
  html.render(const VContext(true));

  final out = '''<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>uix • isomorphic</title>
    <link rel="stylesheet" href="main.css">
  </head>
  <body>
    ${html.toHtmlString()}
    <script src="main.dart.js"></script>
  </body>
</html>
''';
  print(t.elapsed);

  return new shelf.Response.ok(out, headers: const {'Content-Type': 'text/html'});
}
