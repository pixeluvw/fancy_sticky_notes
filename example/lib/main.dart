import 'package:flutter/material.dart';
import 'package:neuron/neuron.dart';
import 'package:fancy_sticky_notes/fancy_sticky_notes.dart';

import 'board_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BoardController.init;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fancy Sticky Notes Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

class DemoPage extends StatelessWidget {
  const DemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = BoardController.init;

    return Scaffold(
      appBar: AppBar(
        title: Slot<int>(
          connect: ctrl.noteCount,
          to: (_, count) => Text('Fancy Sticky Notes ($count)'),
        ),
        backgroundColor: Colors.amber.shade200,
        actions: [
          // ── Style picker for next note ──
          Slot<StickyNoteStyle>(
            connect: ctrl.nextStyle,
            to: (_, style) => PopupMenuButton<StickyNoteStyle>(
              tooltip: 'New note style',
              icon: const Icon(Icons.style),
              onSelected: ctrl.setNextStyle,
              itemBuilder: (_) => StickyNoteStyle.values.map((s) {
                return PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      if (s == style)
                        const Icon(Icons.check, size: 16, color: Colors.blue),
                      if (s != style) const SizedBox(width: 16),
                      const SizedBox(width: 8),
                      Text(s.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          // ── Background toggle ──
          IconButton(
            icon: const Icon(Icons.wallpaper),
            tooltip: 'Cycle background',
            onPressed: ctrl.cycleBackground,
          ),
          // ── Clear all ──
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear all notes',
            onPressed: ctrl.clearAll,
          ),
        ],
      ),
      body: Slot<BoardBackground>(
        connect: ctrl.background,
        to: (_, bg) => Slot<List<StickyNoteModel>>(
          connect: ctrl.notes,
          to: (_, noteList) => StickyNoteBoard(
            initialNotes: noteList,
            background: _backgroundWidget(bg),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ctrl.addNote,
        tooltip: 'Add note',
        backgroundColor: Colors.amber.shade300,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _backgroundWidget(BoardBackground bg) {
    switch (bg) {
      case BoardBackground.corkboard:
        return Container(color: Colors.brown.shade100);
      case BoardBackground.darkWood:
        return Container(color: const Color(0xFF3E2723));
      case BoardBackground.whiteCanvas:
        return Container(color: Colors.grey.shade50);
      case BoardBackground.chalkboard:
        return Container(color: const Color(0xFF263238));
    }
  }
}
