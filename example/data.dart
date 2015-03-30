library dbmon.data;

import 'dart:math' as math;

final math.Random _r = new math.Random();

class Query {
  final double elapsed;
  final bool waiting;
  final String query;

  Query(this.elapsed, this.waiting, this.query);

  factory Query.rand() {
    double elapsed = _r.nextDouble() * 15;
    bool waiting = _r.nextBool();
    String q = 'SELECT blah FROM something';

    if (_r.nextDouble() < 0.2) {
      q = '<IDLE> in transaction';
    }

    if (_r.nextDouble() < 0.1) {
      q = 'vacuum';
    }

    return new Query(elapsed, waiting, q);
  }
}

class Database {
  static int _nextId = 0;
  final int id = _nextId++;

  final String name;
  List<Query> queries;

  Database(this.name) {
    update();
  }

  void update() {
    queries = [];
    final r = ((_r.nextDouble() * 10) + 1).floor();
    for (var i = 0; i < r; i++) {
      queries.add(new Query.rand());
    }
  }

  List getTopFiveQueries() {
    var qs = new List.from(queries);
    qs.sort((a, b) => a.elapsed - b.elapsed);
    qs = qs.sublist(0, qs.length > 5 ? 5 : qs.length);
    while (qs.length < 5) {
      qs.add(new Query(0.0, false, ''));
    }
    return qs;
  }
}
