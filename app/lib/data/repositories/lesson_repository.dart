import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:lunio_time/lunio_time.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/config.dart';
import '../local/database.dart';
import '../remote/api_client.dart';

/// What the server made of a photographed page. Held in memory only until the
/// parent decides to keep it.
class ProcessedLesson {
  const ProcessedLesson({
    required this.summary,
    required this.cards,
    required this.questions,
  });

  final String summary;
  final List<({String front, String back})> cards;
  final List<({String prompt, List<String> choices, int correctIndex})>
  questions;

  bool get isUsable => summary.trim().isNotEmpty && cards.isNotEmpty;
}

/// Lessons: send a page to the server, keep what comes back on the device.
///
/// **Article 14 draws a hard line through the middle of this class.** The image
/// goes up, is processed inside the request, and is dropped — the server keeps no
/// copy, and a test on the server fails the build if one appears. What comes back
/// is text, and that text lives on the phone and nowhere else: no sync, no backup,
/// no cloud.
///
/// The photograph itself stays on the device too, in app-private storage, until
/// the weekly purge deletes it (Art. 4.8). Never external storage, never a path
/// the gallery scans, never a path a backup agent walks — a lesson image landing
/// somewhere shared would breach Article 14 as surely as uploading it would.
/// How much material one photographed page is asked to produce.
///
/// ### Generation is not presentation, and conflating them broke capture
///
/// These used to be `rules.dailySessionCards` and `rules.dailyQuestionCount` —
/// the parent's *daily* settings. That reads as respectful of appendix §5 and
/// is the wrong quantity: those numbers say how much a child does in a day, and
/// this one says how much a page contains.
///
/// The two came apart on 2026-08-31, when the client asked for the memorization
/// cards to be removed and `dailySessionCards` became 0 (D-85). The app then
/// asked the server for **zero cards** — which the lesson serializer refuses,
/// because appendix §5 bounds a session at 5–30. **Every capture would have
/// returned a validation error**, with nothing on screen to connect it to a
/// setting about session size.
///
/// So a page now yields a fixed amount, and the daily settings decide how much
/// of it the child sees. That also keeps D-85 honest: the cards are still
/// generated and stored while they are not being asked, so the day the client
/// reverses the amendment the material for the lessons captured in between is
/// already there rather than lost.
class LessonYield {
  const LessonYield._();

  /// Kept at the appendix's own default session size — enough for a page, and
  /// comfortably inside the server's 5–30.
  static const int cards = 12;

  /// More than the daily default of 5, so raising the daily count in settings
  /// finds something to show rather than an empty review.
  static const int questions = 8;
}

class LessonRepository {
  LessonRepository(
    this._db,
    this._api, {
    Future<Directory> Function()? documentsDirectory,
  }) : _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory;

  final LunioDatabase _db;
  final ApiClient _api;

  /// Where app-private files live.
  ///
  /// Injectable because `path_provider` needs a platform binding, and a test in a
  /// plain `test()` body has none. Faking it would have meant not testing the one
  /// thing Article 14 cares about here — that the image lands somewhere private —
  /// so the seam exists to keep that assertion real rather than to be tidy.
  final Future<Directory> Function() _documentsDirectory;

  /// Send one page for processing.
  ///
  /// Takes a file rather than bytes so the caller cannot accidentally hold the
  /// image in memory longer than the request. The counts come from the parent's
  /// settings, never from a literal here — see decisions.md D-24, which is the
  /// same mistake on the server side.
  Future<ProcessedLesson> process({
    required File image,
    required String grade,
    required int cardCount,
    required int questionCount,
    String subject = '',
  }) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        image.path,
        filename: p.basename(image.path),
      ),
      'grade': grade,
      'card_count': cardCount,
      'question_count': questionCount,
      if (subject.trim().isNotEmpty) 'subject': subject.trim(),
    });

    final response = await _api.post(
      '/api/lessons/process/',
      form: form,
      timeout: AppConfig.lessonTimeout,
    );

    if (response.statusCode == 401) {
      throw const ApiFailure(
        'انتهت جلستك. سجّل الدخول مرة أخرى.',
        statusCode: 401,
      );
    }
    if (response.statusCode == 422) {
      // The server's own Arabic: "لم نتمكّن من استخراج درس واضح من هذه الصورة."
      throw ApiFailure(
        ApiClient.messageFrom(response, 'الصورة غير واضحة.'),
        statusCode: 422,
      );
    }
    if (response.statusCode != 200) {
      throw ApiFailure(
        ApiClient.messageFrom(response, 'تعذّرت معالجة الدرس.'),
        statusCode: response.statusCode,
        retryable: (response.statusCode ?? 500) >= 500,
      );
    }

    return _parse(response.data);
  }

  static ProcessedLesson _parse(dynamic data) {
    if (data is! Map) throw const ApiFailure('ردّ الخادم غير مفهوم.');

    final cards = <({String front, String back})>[];
    for (final raw in (data['cards'] as List? ?? const [])) {
      if (raw is Map && raw['front'] is String && raw['back'] is String) {
        cards.add((front: raw['front'] as String, back: raw['back'] as String));
      }
    }

    final questions =
        <({String prompt, List<String> choices, int correctIndex})>[];
    for (final raw in (data['questions'] as List? ?? const [])) {
      if (raw is! Map) continue;
      final choices = (raw['choices'] as List? ?? const [])
          .map((c) => '$c')
          .toList(growable: false);
      final index = raw['correct_index'];
      // A question whose correct answer is out of range is not a question. Drop
      // it rather than save something that can never be answered correctly —
      // Article 6.1 pays on a correct first attempt, and an unanswerable question
      // would make that unreachable.
      if (raw['prompt'] is String &&
          choices.length >= 2 &&
          index is int &&
          index >= 0 &&
          index < choices.length) {
        questions.add((
          prompt: raw['prompt'] as String,
          choices: List<String>.from(choices),
          correctIndex: index,
        ));
      }
    }

    return ProcessedLesson(
      summary: '${data['summary'] ?? ''}',
      cards: cards,
      questions: questions,
    );
  }

  /// Keep the lesson. Everything below this line is local, permanently.
  ///
  /// One transaction, because a lesson whose cards failed to save is a lesson the
  /// child can never study and the parent cannot see the reason for.
  Future<int> save({
    required ProcessedLesson lesson,
    required File image,
    required String grade,
    required String title,
    required TrustedInstant now,
    String subject = '',
  }) async {
    final stored = await _keepImagePrivately(image);

    return _db.transaction(() async {
      final lessonId = await _db
          .into(_db.lessons)
          .insert(
            LessonsCompanion.insert(
              title: Value(title.trim()),
              subject: Value(subject.trim()),
              grade: Value(grade),
              summary: lesson.summary,
              createdAtMs: now.epochMs,
              weekKey: _weekKeyOf(now),
            ),
          );

      await _db
          .into(_db.lessonImages)
          .insert(
            LessonImagesCompanion.insert(
              lessonId: lessonId,
              filePath: stored.path,
              capturedAtMs: now.epochMs,
            ),
          );

      for (final card in lesson.cards) {
        await _db
            .into(_db.cards)
            .insert(
              CardsCompanion.insert(
                lessonId: lessonId,
                front: card.front,
                back: card.back,
              ),
            );
      }

      for (final question in lesson.questions) {
        await _db
            .into(_db.questions)
            .insert(
              QuestionsCompanion.insert(
                lessonId: lessonId,
                prompt: question.prompt,
                choicesJson: jsonEncode(question.choices),
                correctIndex: question.correctIndex,
              ),
            );
      }

      return lessonId;
    });
  }

  Stream<List<LessonRow>> watchLessons() {
    return (_db.select(
      _db.lessons,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAtMs)])).watch();
  }

  Future<int> cardCountFor(int lessonId) async {
    final rows = await (_db.select(
      _db.cards,
    )..where((t) => t.lessonId.equals(lessonId))).get();
    return rows.length;
  }

  /// Copy the picked image into app-private storage under a name of our choosing.
  ///
  /// `image_picker` hands back a file in a cache directory that the OS may clear
  /// and that other apps can sometimes reach. Article 14 says the photograph lives
  /// on the device only and is deleted after the weekly test — both of which need
  /// it somewhere we control and can delete deliberately.
  Future<File> _keepImagePrivately(File source) async {
    final dir = await _documentsDirectory();
    final lessonsDir = Directory(p.join(dir.path, 'lesson_images'));
    if (!lessonsDir.existsSync()) lessonsDir.createSync(recursive: true);

    final name =
        'lesson_${DateTime.now().microsecondsSinceEpoch}'
        '${p.extension(source.path)}';
    return source.copy(p.join(lessonsDir.path, name));
  }

  /// Which week a lesson belongs to, for the weekly test and the purge (D-13).
  static int _weekKeyOf(TrustedInstant now) {
    final day = now.dayKey();
    // 1970-01-01 was a Thursday. Grouping by whole weeks from the epoch is exact
    // integer arithmetic and needs no calendar.
    return (day.daysSinceEpoch + 3) ~/ 7;
  }
}
