import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:uix_standalone/uix_standalone.dart';
import 'data.dart';
import 'components/table.dart';

const int I = 0;
const int N = 100;

final List<Database> dbs = [];

void update(List<Database> dbs) {
  for (final db in dbs) {
    db.update();
  }
}

void main() {
  final handler = const shelf.Pipeline().addHandler(_echoRequest);

  for (var i = 0; i < N; i++) {
    dbs.add(new Database('cluster${i}'));
    dbs.add(new Database('cluster${i}slave'));
  }
  update(dbs);

  io.serve(handler, 'localhost', 8080).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}

shelf.Response _echoRequest(shelf.Request request) {
  initUix();

  final t = new Stopwatch()..start();

  final VNode html = vElement('html')(vElement('body')(vTable(data: dbs)));
  html.create(const VContext(true));
  html.render(const VContext(true));

  final out = html.toHtmlString();
  print(t.elapsed);

  return new shelf.Response.ok(out, headers: const {'Content-Type': 'text/html'});
}
