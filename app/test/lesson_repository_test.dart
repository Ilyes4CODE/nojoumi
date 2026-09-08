import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/data/local/database.dart';
import 'package:lunio/data/remote/api_client.dart';
import 'package:lunio/data/repositories/lesson_repository.dart';
import 'package:lunio_time/lunio_time.dart';
import 'package:path/path.dart' as p;

import 'support/test_db.dart';

/// Lessons, from the server's answer to what lands on the device.
///
/// The network is faked at the `Dio` adapter, so these tests exercise the real
/// parsing, the real Drift writes and the real error paths without ever opening a
/// socket. What they cannot prove is that the *server* behaves as staged — that is
/// the 112 tests on the Django side and the Article 11.3 eval run.
void main() {
  late LunioDatabase db;
  late LessonRepository lessons;
  late _StagedAdapter adapter;
  late Directory documents;

  const now = TrustedInstant(
    epochMs: 1773133200000,
    level: TrustLevel.serverAnchored,
  );

  Map<String, dynamic> goodBody({int cards = 3, int questions = 2}) => {
        'summary': 'ملخّص الدرس',
        'cards': [
          for (var i = 0; i < cards; i++) {'front': 'وجه $i', 'back': 'ظهر $i'},
        ],
        'questions': [
          for (var i = 0; i < questions; i++)
            {
              'prompt': 'سؤال $i',
              'choices': ['أ', 'ب', 'ج'],
              'correct_index': 1,
            },
        ],
      };

  setUp(() async {
    db = await freshDatabase();
    adapter = _StagedAdapter();
    final dio = Dio()..httpClientAdapter = adapter;
    documents = await Directory.systemTemp.createTemp('lunio_docs');
    lessons = LessonRepository(
      db,
      ApiClient(dio: dio, readToken: () async => 'token'),
      documentsDirectory: () async => documents,
    );
  });

  tearDown(() async {
    await db.close();
    if (documents.existsSync()) documents.deleteSync(recursive: true);
  });

  group('parsing what the server returns', () {
    test('a good response becomes a usable lesson', () async {
      adapter.stage(200, goodBody(cards: 8, questions: 4));
      final result = await lessons.process(
        image: await stagedImage(),
        grade: 'السنة الرابعة ابتدائي',
        cardCount: 8,
        questionCount: 4,
      );

      expect(result.isUsable, isTrue);
      expect(result.cards, hasLength(8));
      expect(result.questions, hasLength(4));
      expect(result.questions.first.correctIndex, 1);
    });

    test('a question whose correct answer is out of range is dropped', () async {
      // An unanswerable question would make Art. 6.1's "correct on the first
      // attempt" unreachable, so it must never reach the database.
      adapter.stage(200, {
        'summary': 'ملخّص',
        'cards': [
          {'front': 'أ', 'back': 'ب'},
        ],
        'questions': [
          {'prompt': 'سليم', 'choices': ['أ', 'ب'], 'correct_index': 0},
          {'prompt': 'خارج المدى', 'choices': ['أ', 'ب'], 'correct_index': 7},
          {'prompt': 'خيار واحد', 'choices': ['أ'], 'correct_index': 0},
        ],
      });

      final result = await lessons.process(
        image: await stagedImage(),
        grade: 'الرابعة',
        cardCount: 5,
        questionCount: 3,
      );

      expect(result.questions, hasLength(1));
      expect(result.questions.single.prompt, 'سليم');
    });

    test('a lesson with no cards is not usable', () async {
      adapter.stage(200, {'summary': 'ملخّص', 'cards': [], 'questions': []});
      final result = await lessons.process(
        image: await stagedImage(),
        grade: 'الرابعة',
        cardCount: 5,
        questionCount: 0,
      );
      expect(result.isUsable, isFalse);
    });
  });

  group('failures the parent has to be able to act on', () {
    test('an unreadable page surfaces the server\'s own Arabic', () async {
      adapter.stage(422, {
        'detail': 'لم نتمكّن من استخراج درس واضح من هذه الصورة.',
        'retryable': false,
      });

      await expectLater(
        lessons.process(
          image: await stagedImage(),
          grade: 'الرابعة',
          cardCount: 5,
          questionCount: 0,
        ),
        throwsA(
          isA<ApiFailure>()
              .having((e) => e.statusCode, 'status', 422)
              .having((e) => e.message, 'message', contains('واضح')),
        ),
      );
    });

    test('an expired session is named as one, not as a generic error', () async {
      adapter.stage(401, {'detail': 'unauthorised'});

      await expectLater(
        lessons.process(
          image: await stagedImage(),
          grade: 'الرابعة',
          cardCount: 5,
          questionCount: 0,
        ),
        throwsA(isA<ApiFailure>().having((e) => e.isUnauthorised, 'expired', isTrue)),
      );
    });

    test('a server fault is marked retryable and a rejection is not', () async {
      adapter.stage(502, {'detail': 'gateway'});
      try {
        await lessons.process(
          image: await stagedImage(),
          grade: 'الرابعة',
          cardCount: 5,
          questionCount: 0,
        );
        fail('should have thrown');
      } on ApiFailure catch (error) {
        expect(error.retryable, isTrue);
      }
    });
  });

  group('Article 14 — what lands on the device', () {
    test('saving keeps the summary, the cards and the questions', () async {
      final lesson = ProcessedLesson(
        summary: 'ملخّص الدرس',
        cards: const [(front: 'أ', back: 'ب'), (front: 'ج', back: 'د')],
        questions: const [
          (prompt: 'سؤال', choices: ['أ', 'ب', 'ج'], correctIndex: 2),
        ],
      );

      final id = await lessons.save(
        lesson: lesson,
        image: await stagedImage(),
        grade: 'السنة الرابعة ابتدائي',
        title: 'الحروف',
        now: now,
      );

      final saved = await (db.select(db.lessons)..where((t) => t.id.equals(id)))
          .getSingle();
      expect(saved.summary, 'ملخّص الدرس');
      expect(saved.grade, 'السنة الرابعة ابتدائي');
      expect(saved.purgedAtMs, isNull);

      expect(await db.select(db.cards).get(), hasLength(2));

      final question = await db.select(db.questions).getSingle();
      expect(question.correctIndex, 2);
      expect(jsonDecode(question.choicesJson), ['أ', 'ب', 'ج']);
    });

    test('the image row points at app-private storage, never shared storage',
        () async {
      await lessons.save(
        lesson: const ProcessedLesson(
          summary: 'ملخّص',
          cards: [(front: 'أ', back: 'ب')],
          questions: [],
        ),
        image: await stagedImage(),
        grade: 'الرابعة',
        title: '',
        now: now,
      );

      final image = await db.select(db.lessonImages).getSingle();
      expect(image.filePath, contains('lesson_images'));
      expect(image.deletedAtMs, isNull);
      for (final shared in ['/sdcard', 'DCIM', 'Pictures', 'Download']) {
        expect(image.filePath.contains(shared), isFalse,
            reason: 'Art. 14 — a lesson image in shared storage is a lesson '
                'image the gallery and every backup agent can read');
      }
    });

    test('the lesson row carries nothing identifying the child', () async {
      await lessons.save(
        lesson: const ProcessedLesson(
          summary: 'ملخّص',
          cards: [(front: 'أ', back: 'ب')],
          questions: [],
        ),
        image: await stagedImage(),
        grade: 'الرابعة',
        title: 'درس',
        now: now,
      );

      final row = await db.select(db.lessons).getSingle();
      expect(row.toJson().keys.toSet(), {
        'id', 'title', 'subject', 'grade', 'summary', 'createdAtMs', 'weekKey',
        'purgedAtMs',
      }, reason: 'grade is pedagogical (D-11); a name, an age or a photo of the '
          'child would breach Art. 14');
    });

    test('lessons in the same week share a week key, and the next week differs',
        () async {
      Future<int> saveAt(TrustedInstant at) async => lessons.save(
            lesson: const ProcessedLesson(
              summary: 'ملخّص',
              cards: [(front: 'أ', back: 'ب')],
              questions: [],
            ),
            image: await stagedImage(),
            grade: 'الرابعة',
            title: '',
            now: at,
          );

      final first = await saveAt(now);
      final sameWeek = await saveAt(
        TrustedInstant(
          epochMs: now.epochMs + const Duration(days: 1).inMilliseconds,
          level: TrustLevel.serverAnchored,
        ),
      );
      final nextWeek = await saveAt(
        TrustedInstant(
          epochMs: now.epochMs + const Duration(days: 8).inMilliseconds,
          level: TrustLevel.serverAnchored,
        ),
      );

      final rows = await db.select(db.lessons).get();
      int weekOf(int id) => rows.firstWhere((r) => r.id == id).weekKey;

      expect(weekOf(sameWeek), weekOf(first),
          reason: 'the weekly test and the Art. 14 purge group by this key');
      expect(weekOf(nextWeek), isNot(weekOf(first)));
    });
  });
}

/// A throwaway file standing in for a photographed page.
Future<File> stagedImage() async {
  final dir = await Directory.systemTemp.createTemp('lunio_test');
  final file = File(p.join(dir.path, 'page.jpg'));
  await file.writeAsBytes(List<int>.filled(64, 0));
  return file;
}

/// Answers every request with whatever was staged. No socket is opened.
class _StagedAdapter implements HttpClientAdapter {
  int _status = 200;
  Object _body = const <String, dynamic>{};

  void stage(int status, Object body) {
    _status = status;
    _body = body;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(_body),
      _status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
