library uix_dbmon.components.entry;

import 'package:uix_standalone/uix_standalone.dart';
import '../data.dart';
import 'popover.dart';

part 'entry.g.dart';

class EntryProps {
  final Database db;

  EntryProps(this.db);
}

@ComponentMeta()
class Entry extends Component<EntryProps> {
  final String tag = 'tr';

  updateView() {
    final db = data.db;

    final children = [
      vElement('td', type: 'dbname')(db.name),
      vElement('td', type: 'query-count')(
          vElement('span', type: 'label', classes: _countClasses(db.queries.length))(
              db.queries.length.toString()
          )
      )
    ];

    final queries = db.getTopFiveQueries();

    for (final q in queries) {
      var classes = [];
      classes.add('elapsed');
      if (q.elapsed >= 10.0) {
        classes.add('warn_long');
      } else if (q.elapsed >= 1.0) {
        classes.add('warn');
      } else {
        classes.add('short');
      }
      children.add(vElement('td', type: 'Query', classes: classes)([
        vText(_formatElapsed(q.elapsed)),
        vPopover(data: q.query)
      ]));
    }

    updateRoot(vRoot(children: children));
  }
}

String _formatElapsed(double v) {
  if (v == 0) return '';

  String result = v.toStringAsFixed(2);

  if (v > 60) {
    int minutes = (v / 60).floor();
    List<String> comps = (v % 60).toStringAsFixed(2).split('.');
    String seconds = comps[0].padLeft(2, '0');
    String ms = comps[1];
    result = '$minutes:$seconds.$ms';
  }

  return result;
}

List _countClasses(int count) {
  if (count >= 20) {
    return const ['label-important'];
  } else if (count >= 10) {
    return const ['label-warning'];
  }
  return const ['label-success'];
}
