import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/undo_redo.dart';

class HistoryState {
  final bool canUndo;
  final bool canRedo;
  final String? lastAction;

  const HistoryState({
    this.canUndo = false,
    this.canRedo = false,
    this.lastAction,
  });
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  static const _maxSize = 100;

  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];

  HistoryNotifier() : super(const HistoryState());

  void execute(Command cmd) {
    cmd.execute();
    _undoStack.add(cmd);
    _redoStack.clear();
    if (_undoStack.length > _maxSize) {
      _undoStack.removeAt(0);
    }
    _sync();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final cmd = _undoStack.removeLast();
    cmd.undo();
    _redoStack.add(cmd);
    _sync(action: 'Undone: ${cmd.description}');
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final cmd = _redoStack.removeLast();
    cmd.execute();
    _undoStack.add(cmd);
    _sync(action: 'Redone: ${cmd.description}');
  }

  void _sync({String? action}) {
    state = HistoryState(
      canUndo: _undoStack.isNotEmpty,
      canRedo: _redoStack.isNotEmpty,
      lastAction: action,
    );
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    _sync();
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier();
});
