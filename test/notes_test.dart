import 'package:flutter_test/flutter_test.dart';
import 'package:simply_sdk/api/notes.dart';
import 'package:simply_sdk/simply_sdk.dart';
import 'package:simply_sdk/types/document.dart';

void runTests(userId) {
  test('add note', () async {
    API().notes().add(NoteData()
      ..title = 'Hello'
      ..member = 'testMemberId'
      ..note = 'Hello there!'
      ..color = '#ffffff'
      ..date = DateTime.now().millisecondsSinceEpoch);
    await Future.delayed(const Duration(seconds: 1));
  });

  test('update note', () async {
    List<Document<NoteData>> notes = await API().notes().getNotesForMember('testMemberId', API().auth().getUid()!);
    API().notes().update(
        notes[0].id,
        NoteData()
          ..title = 'Hello again'
          ..note = 'Hello there again!');
    await Future.delayed(const Duration(seconds: 1));
  });

  test('get note for member', () async {
    List<Document<NoteData>> notes = await API().notes().getNotesForMember('testMemberId', API().auth().getUid()!);
    expect(notes.length, 1);
  });

  test('delete note', () async {
    List<Document<NoteData>> notes = await API().notes().getNotesForMember('testMemberId', API().auth().getUid()!);
    API().notes().delete(notes[0].id, notes[0]);
    await Future.delayed(const Duration(seconds: 1));
  });
}
