// Copyright (c) 2015, the uix project authors. Please see the
// AUTHORS file for details. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

/// Scheduler
///
/// It will perform write and read tasks in batches until there are no
/// write or read tasks left.
///
/// Write tasks sorted by their priority, and the tasks with the lowest
/// value in the priority property is executed first. It is implemented
/// this way because most of the time tasks priority will be its depth in
/// the DOM.
///
/// Scheduler runs in its own `Zone` and intercepts all microtasks, this
/// way it is possible to use `Future`s to track dependencies between
/// tasks.
library uix.src.scheduler;

import 'dart:html' as html;
import 'dart:async';
import 'dart:collection';
import 'package:collection/priority_queue.dart';

/// Write groups sorted by priority.
///
/// It is used as an optimization to make adding write tasks as an O(1)
/// operation.
class _WriteGroup implements Comparable {
  final int priority;

  Completer _completer;

  _WriteGroup(this.priority);

  int compareTo(_WriteGroup other) {
    if (priority < other.priority) {
      return 1;
    } else if (priority > other.priority) {
      return -1;
    }
    return 0;
  }
}

/// Frame tasks.
class Frame {
  static const int lowestPriority = (1 << 31) - 1;

  /// Write groups indexed by priority
  List<_WriteGroup> _prioWriteGroups = [];
  _WriteGroup _writeGroup;

  HeapPriorityQueue<_WriteGroup> _writeQueue =
      new HeapPriorityQueue<_WriteGroup>();

  Completer _readCompleter;
  Completer _afterCompleter;

  /// Returns `Future` that will be completed when [DOMScheduler] starts
  /// executing write tasks with this priority.
  Future write([int priority = lowestPriority]) {
    if (priority == lowestPriority) {
      if (_writeGroup == null) {
        _writeGroup = new _WriteGroup(lowestPriority);
        _writeGroup._completer = new Completer();
      }
      return _writeGroup._completer.future;
    }

    if (priority >= _prioWriteGroups.length) {
      var i = _prioWriteGroups.length;
      while (i <= priority) {
        _prioWriteGroups.add(new _WriteGroup(i++));
      }
    }

    final g = _prioWriteGroups[priority];
    if (g._completer == null) {
      g._completer = new Completer();
      _writeQueue.add(g);
    }

    return g._completer.future;
  }

  /// Returns `Future` that will be completed when [DOMScheduler] starts
  /// executing read tasks.
  Future read() {
    if (_readCompleter == null) {
      _readCompleter = new Completer();
    }
    return _readCompleter.future;
  }

  /// Returns `Future` that will be completed when [DOMScheduler] finishes
  /// executing all write and read tasks.
  Future after() {
    if (_afterCompleter == null) {
      _afterCompleter = new Completer();
    }
    return _afterCompleter.future;
  }
}

/// [Scheduler].
class Scheduler {
  static const int tickRunningFlag = 1;
  static const int frameRunningFlag = 1 << 1;
  static const int tickPendingFlag = 1 << 2;
  static const int framePendingFlag = 1 << 3;
  static const int runningFlags = tickRunningFlag | frameRunningFlag;

  int flags = 0;
  int clock = 1;

  bool get isRunning => ((flags & runningFlags) != 0);
  bool get isFrameRunning => ((flags & frameRunningFlag) != 0);

  Queue<Function> _currentTasks = new Queue<Function>();

  ZoneSpecification _zoneSpec;
  Zone _zone;

  /// Scheduler [Zone].
  Zone get zone => _zone;

  Frame _currentFrame = new Frame();
  Frame _nextFrame = new Frame();

  Completer _nextTickCompleter;

  /// [Frame] that contains tasks for the current animation frame.
  Frame get currentFrame {
    assert(isRunning);
    return _currentFrame;
  }

  /// [Frame] that contains tasks for the next animation frame.
  Frame get nextFrame {
    _requestAnimationFrame();
    return _nextFrame;
  }

  /// [Future] that will be completed on the next tick.
  Future get nextTick {
    if (_nextTickCompleter == null) {
      _nextTickCompleter = new Completer();
      _requestNextTick();
    }
    return _nextTickCompleter.future;
  }

  Scheduler() {
    _zoneSpec = new ZoneSpecification(scheduleMicrotask: _scheduleMicrotask);
    _zone = Zone.current.fork(specification: _zoneSpec);
  }

  void _scheduleMicrotask(Zone self, ZoneDelegate parent, Zone zone, void f()) {
    if (isRunning) {
      _currentTasks.add(f);
    } else {
      parent.scheduleMicrotask(zone, f);
    }
  }

  void _runTasks() {
    while (_currentTasks.isNotEmpty) {
      _currentTasks.removeFirst()();
    }
  }

  void _requestAnimationFrame() {
    if ((flags & framePendingFlag) == 0) {
      _zone.parent.scheduleMicrotask(_handleAnimationFrame);
      flags |= framePendingFlag;
    }
  }

  void _requestNextTick() {
    if ((flags & tickPendingFlag) == 0) {
      _zone.parent.scheduleMicrotask(_handleNextTick);
      flags |= tickPendingFlag;
    }
  }

  void _handleAnimationFrame() {
    if ((flags & framePendingFlag) == 0) {
      return;
    }

    _zone.run(() {
      flags &= ~framePendingFlag;
      flags |= frameRunningFlag;

      final tmp = _currentFrame;
      _currentFrame = _nextFrame;
      _nextFrame = tmp;
      final wq = _currentFrame._writeQueue;

      do {
        do {
          while (wq.isNotEmpty) {
            final writeGroup = wq.removeFirst();
            writeGroup._completer.complete();
            writeGroup._completer = null;
            _runTasks();
          }
          while (_currentFrame._writeGroup != null) {
            _currentFrame._writeGroup._completer.complete();
            _currentFrame._writeGroup = null;
            _runTasks();
          }
        } while (wq.isNotEmpty);

        while (_currentFrame._readCompleter != null) {
          _currentFrame._readCompleter.complete();
          _currentFrame._readCompleter = null;
          _runTasks();
        }
      } while (wq.isNotEmpty || (_currentFrame._writeGroup != null));

      if (_currentFrame._afterCompleter != null) {
        _currentFrame._afterCompleter.complete();
        _currentFrame._afterCompleter = null;
        _runTasks();
      }

      clock++;
      flags &= ~frameRunningFlag;
    });
  }

  void _handleNextTick() {
    if ((flags & tickPendingFlag) == 0) {
      return;
    }

    _zone.run(() {
      flags &= ~framePendingFlag;
      flags |= tickRunningFlag;

      _nextTickCompleter.complete();
      _nextTickCompleter = null;
      _runTasks();

      clock++;
      flags &= ~tickRunningFlag;
    });
  }

  /// Force [Scheduler] to run tasks for the [nextFrame].
  void forceNextFrame() {
    if ((flags & framePendingFlag) != 0) {
      _handleAnimationFrame();
    }
  }

  /// Force [Scheduler] to run tasks for the next tick.
  void forceNextTick() {
    if ((flags & tickPendingFlag) != 0) {
      _handleNextTick();
    }
  }

  void run(fn) {
    _zone.run(() {
      flags |= tickRunningFlag;

      fn();

      clock++;
      flags &= ~tickRunningFlag;
    });
  }
}
