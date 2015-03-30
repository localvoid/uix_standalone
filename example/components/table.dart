library uix_dbmon.components.table;

import 'package:uix_standalone/uix_standalone.dart';
import '../data.dart';
import 'entry.dart';

part 'table.g.dart';

@ComponentMeta()
class Table extends Component<List<Database>> {
  final String tag = 'table';

  updateView() {
    updateRoot(vRoot(classes: const ['table', 'table-striped', 'latest-data'])(
        vElement('tbody')(data.map((db) => vEntry(key: db.id, data: new EntryProps(db))))
    ));
  }
}
