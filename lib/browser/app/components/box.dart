library uix_standalone.app.component.box;

import 'dart:html' as html;
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

  int _counter = 0;

  void init() {
    element.onClick.matches('.Button').listen(_handleClick);
  }

  void _handleClick(html.MouseEvent e) {
    e.preventDefault();
    _counter++;
    invalidate();
  }
  updateView() {
    if (isMounting) {
      updateRoot(vRoot(type: 'Box')([
        vElement('div')(vElement('button', type: 'Button', attrs: const {'disabled': 'true'})('Not Mounted')),
        vElement('div')(data.message)
      ]));
    }
    updateRoot(vRoot(type: 'Box')([
      vElement('div')(vElement('button', type: 'Button')('Click Me!')),
      vElement('div')('[$_counter] ${data.message}')
    ]));
  }
}
