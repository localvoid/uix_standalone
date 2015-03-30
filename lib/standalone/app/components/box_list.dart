library uix_standalone.app.component.box_list;

import 'package:uix_standalone/standalone/uix/uix.dart';
import '../data.dart';
import 'box.dart';

part 'box_list.g.dart';

@ComponentMeta()
class BoxList extends Component<List<BoxData>> {
  updateView() {
    updateRoot(vRoot(type: 'BoxList')(
        data.map((d) => vBox(key: d.id, data: d))
    ));
  }
}
