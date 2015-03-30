library uix_standalone.app.data;

class BoxData {
  static int _nextId = 0;

  final int id = _nextId++;
  final String message = 'abc';
}
