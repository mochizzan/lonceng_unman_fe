// QuickStats ALUMNI banner — AC6
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lonceng_unman_fe/features/home/domain/entities/home_entity.dart';
import 'package:lonceng_unman_fe/features/home/presentation/widgets/quick_stats.dart';

HomeEntity _entity({bool isAlumni = false, String tahunAjaran = '2025/2026'}) =>
    HomeEntity(
      userName: 'Budi',
      avatarUrl: '',
      nextClass: null,
      scheduleItems: const [],
      sksTaken: isAlumni ? 0 : 20,
      todayClassCount: 0,
      semester: 'GANJIL',
      tahunAjaran: tahunAjaran,
      studyProgram: 'SI',
      gpaGanjil: 3.2,
      gpaGenap: 3.5,
      isAlumni: isAlumni,
    );

void main() {
  testWidgets('isAlumni true shows banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuickStats(data: _entity(isAlumni: true))),
      ),
    );
    expect(
      find.text('KRS/Jadwal Tidak tersedia (STATUS ALUMNI)'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.school_outlined), findsOneWidget);
  });

  testWidgets('isAlumni false hides banner', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: QuickStats(data: _entity(isAlumni: false))),
      ),
    );
    expect(
      find.text('KRS/Jadwal Tidak tersedia (STATUS ALUMNI)'),
      findsNothing,
    );
  });

  testWidgets('tahunAjaran empty shows Tahun Ajaran -', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickStats(data: _entity(tahunAjaran: '')),
        ),
      ),
    );
    expect(find.text('Tahun Ajaran -'), findsOneWidget);
  });
}
