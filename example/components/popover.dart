library uix_dbmon.components.popover;

import 'package:uix_standalone/uix_standalone.dart';

part 'popover.g.dart';

@ComponentMeta()
class Popover extends Component<String> {
  updateView() {
    updateRoot(vRoot(classes: const ['popover', 'left'])([
      vElement('div', type: 'popover-content')(data),
      vElement('div', type: 'arrow')
    ]));
  }
}
