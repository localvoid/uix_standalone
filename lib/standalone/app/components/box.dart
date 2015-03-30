library uix_standalone.app.component.box;

import 'package:uix_standalone/standalone/uix/uix.dart';
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
        vElement('div')(vElement('button', type: 'Button', attrs: const {'disabled': 'true'})('Not Mounted')),
        vElement('div')(data.message)
      ]));
    }
  }
}
