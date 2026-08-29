import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luckyboss_jobseeker/widgets/searchable_chip_picker.dart';

void main() {
  testWidgets('multi-select keeps every tap', (tester) async {
    final selected = <String>{};
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SearchableChipPicker(
            options: const ['Alpha', 'Bravo', 'Charlie', 'Delta'],
            selected: selected,
            onToggle: (v) => setState(
                () => selected.contains(v) ? selected.remove(v) : selected.add(v)),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Alpha'));
    await tester.pump();
    await tester.tap(find.text('Charlie'));
    await tester.pump();

    expect(selected, {'Alpha', 'Charlie'});
  });

  testWidgets('single-select replaces', (tester) async {
    var chosen = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => SearchableChipPicker(
            options: const ['Alpha', 'Bravo'],
            selected: {if (chosen.isNotEmpty) chosen},
            single: true,
            onToggle: (v) => setState(() => chosen = chosen == v ? '' : v),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Alpha'));
    await tester.pump();
    expect(chosen, 'Alpha');
    await tester.tap(find.text('Bravo'));
    await tester.pump();
    expect(chosen, 'Bravo');
  });
}
