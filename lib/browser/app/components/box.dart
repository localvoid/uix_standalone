library uix_standalone.app.component.box;

import 'package:uix_standalone/browser/uix/uix.dart' hide ComponentMeta;
import 'package:uix_standalone/standalone/uix/src/annotations.dart';
import '../data.dart';

part 'box.g.dart';

@ComponentMeta()
class Box extends Component<BoxData> {
  set data(BoxData newData) {
    data_ = newData;
    invalidate();
  }

  updateView() {
    if (isMounting) {
      updateRoot(vRoot(type: 'Box')([
        vElement('div')('Not Mounted'),
        vElement('div')(data.message)
      ]));
    }
    updateRoot(vRoot(type: 'Box')([
      vElement('div')('Mounted'),
      vElement('div')(data.message)
    ]));
  }
}
