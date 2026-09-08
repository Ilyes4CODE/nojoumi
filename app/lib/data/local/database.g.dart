// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  @override
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _pinSaltMeta = const VerificationMeta(
    'pinSalt',
  );
  @override
  late final GeneratedColumn<String> pinSalt = GeneratedColumn<String>(
    'pin_salt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _starValueSecondsMeta = const VerificationMeta(
    'starValueSeconds',
  );
  @override
  late final GeneratedColumn<int> starValueSeconds = GeneratedColumn<int>(
    'star_value_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _dailyCeilingUnitsMeta = const VerificationMeta(
    'dailyCeilingUnits',
  );
  @override
  late final GeneratedColumn<int> dailyCeilingUnits = GeneratedColumn<int>(
    'daily_ceiling_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(6000),
  );
  static const VerificationMeta _minimumTimeOnTargetMsMeta =
      const VerificationMeta('minimumTimeOnTargetMs');
  @override
  late final GeneratedColumn<int> minimumTimeOnTargetMs = GeneratedColumn<int>(
    'minimum_time_on_target_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1500),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ExpiryModeRow, int> expiryMode =
      GeneratedColumn<int>(
        'expiry_mode',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<ExpiryModeRow>($AppSettingsTable.$converterexpiryMode);
  static const VerificationMeta _welcomeUnitsMeta = const VerificationMeta(
    'welcomeUnits',
  );
  @override
  late final GeneratedColumn<int> welcomeUnits = GeneratedColumn<int>(
    'welcome_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
  );
  static const VerificationMeta _welcomeGrantedMeta = const VerificationMeta(
    'welcomeGranted',
  );
  @override
  late final GeneratedColumn<bool> welcomeGranted = GeneratedColumn<bool>(
    'welcome_granted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("welcome_granted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _dailySessionCardsMeta = const VerificationMeta(
    'dailySessionCards',
  );
  @override
  late final GeneratedColumn<int> dailySessionCards = GeneratedColumn<int>(
    'daily_session_cards',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dailyQuestionCountMeta =
      const VerificationMeta('dailyQuestionCount');
  @override
  late final GeneratedColumn<int> dailyQuestionCount = GeneratedColumn<int>(
    'daily_question_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _expiryWeekdayMeta = const VerificationMeta(
    'expiryWeekday',
  );
  @override
  late final GeneratedColumn<int> expiryWeekday = GeneratedColumn<int>(
    'expiry_weekday',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(5),
  );
  static const VerificationMeta _blockingEnabledMeta = const VerificationMeta(
    'blockingEnabled',
  );
  @override
  late final GeneratedColumn<bool> blockingEnabled = GeneratedColumn<bool>(
    'blocking_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("blocking_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _launcherModeMeta = const VerificationMeta(
    'launcherMode',
  );
  @override
  late final GeneratedColumn<bool> launcherMode = GeneratedColumn<bool>(
    'launcher_mode',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("launcher_mode" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _playPausedMeta = const VerificationMeta(
    'playPaused',
  );
  @override
  late final GeneratedColumn<bool> playPaused = GeneratedColumn<bool>(
    'play_paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("play_paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _onboardingStepMeta = const VerificationMeta(
    'onboardingStep',
  );
  @override
  late final GeneratedColumn<int> onboardingStep = GeneratedColumn<int>(
    'onboarding_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _utcOffsetMinutesMeta = const VerificationMeta(
    'utcOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> utcOffsetMinutes = GeneratedColumn<int>(
    'utc_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(60),
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    pinHash,
    pinSalt,
    starValueSeconds,
    dailyCeilingUnits,
    minimumTimeOnTargetMs,
    expiryMode,
    welcomeUnits,
    welcomeGranted,
    dailySessionCards,
    dailyQuestionCount,
    expiryWeekday,
    blockingEnabled,
    launcherMode,
    playPaused,
    grade,
    onboardingStep,
    utcOffsetMinutes,
    installId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    }
    if (data.containsKey('pin_salt')) {
      context.handle(
        _pinSaltMeta,
        pinSalt.isAcceptableOrUnknown(data['pin_salt']!, _pinSaltMeta),
      );
    }
    if (data.containsKey('star_value_seconds')) {
      context.handle(
        _starValueSecondsMeta,
        starValueSeconds.isAcceptableOrUnknown(
          data['star_value_seconds']!,
          _starValueSecondsMeta,
        ),
      );
    }
    if (data.containsKey('daily_ceiling_units')) {
      context.handle(
        _dailyCeilingUnitsMeta,
        dailyCeilingUnits.isAcceptableOrUnknown(
          data['daily_ceiling_units']!,
          _dailyCeilingUnitsMeta,
        ),
      );
    }
    if (data.containsKey('minimum_time_on_target_ms')) {
      context.handle(
        _minimumTimeOnTargetMsMeta,
        minimumTimeOnTargetMs.isAcceptableOrUnknown(
          data['minimum_time_on_target_ms']!,
          _minimumTimeOnTargetMsMeta,
        ),
      );
    }
    if (data.containsKey('welcome_units')) {
      context.handle(
        _welcomeUnitsMeta,
        welcomeUnits.isAcceptableOrUnknown(
          data['welcome_units']!,
          _welcomeUnitsMeta,
        ),
      );
    }
    if (data.containsKey('welcome_granted')) {
      context.handle(
        _welcomeGrantedMeta,
        welcomeGranted.isAcceptableOrUnknown(
          data['welcome_granted']!,
          _welcomeGrantedMeta,
        ),
      );
    }
    if (data.containsKey('daily_session_cards')) {
      context.handle(
        _dailySessionCardsMeta,
        dailySessionCards.isAcceptableOrUnknown(
          data['daily_session_cards']!,
          _dailySessionCardsMeta,
        ),
      );
    }
    if (data.containsKey('daily_question_count')) {
      context.handle(
        _dailyQuestionCountMeta,
        dailyQuestionCount.isAcceptableOrUnknown(
          data['daily_question_count']!,
          _dailyQuestionCountMeta,
        ),
      );
    }
    if (data.containsKey('expiry_weekday')) {
      context.handle(
        _expiryWeekdayMeta,
        expiryWeekday.isAcceptableOrUnknown(
          data['expiry_weekday']!,
          _expiryWeekdayMeta,
        ),
      );
    }
    if (data.containsKey('blocking_enabled')) {
      context.handle(
        _blockingEnabledMeta,
        blockingEnabled.isAcceptableOrUnknown(
          data['blocking_enabled']!,
          _blockingEnabledMeta,
        ),
      );
    }
    if (data.containsKey('launcher_mode')) {
      context.handle(
        _launcherModeMeta,
        launcherMode.isAcceptableOrUnknown(
          data['launcher_mode']!,
          _launcherModeMeta,
        ),
      );
    }
    if (data.containsKey('play_paused')) {
      context.handle(
        _playPausedMeta,
        playPaused.isAcceptableOrUnknown(data['play_paused']!, _playPausedMeta),
      );
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    }
    if (data.containsKey('onboarding_step')) {
      context.handle(
        _onboardingStepMeta,
        onboardingStep.isAcceptableOrUnknown(
          data['onboarding_step']!,
          _onboardingStepMeta,
        ),
      );
    }
    if (data.containsKey('utc_offset_minutes')) {
      context.handle(
        _utcOffsetMinutesMeta,
        utcOffsetMinutes.isAcceptableOrUnknown(
          data['utc_offset_minutes']!,
          _utcOffsetMinutesMeta,
        ),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
      )!,
      pinSalt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_salt'],
      )!,
      starValueSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}star_value_seconds'],
      )!,
      dailyCeilingUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_ceiling_units'],
      )!,
      minimumTimeOnTargetMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minimum_time_on_target_ms'],
      )!,
      expiryMode: $AppSettingsTable.$converterexpiryMode.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}expiry_mode'],
        )!,
      ),
      welcomeUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}welcome_units'],
      )!,
      welcomeGranted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}welcome_granted'],
      )!,
      dailySessionCards: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_session_cards'],
      )!,
      dailyQuestionCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_question_count'],
      )!,
      expiryWeekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expiry_weekday'],
      )!,
      blockingEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}blocking_enabled'],
      )!,
      launcherMode: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}launcher_mode'],
      )!,
      playPaused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}play_paused'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      )!,
      onboardingStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}onboarding_step'],
      )!,
      utcOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}utc_offset_minutes'],
      )!,
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ExpiryModeRow, int, int> $converterexpiryMode =
      const EnumIndexConverter<ExpiryModeRow>(ExpiryModeRow.values);
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final String pinHash;
  final String pinSalt;

  /// 0.5–3 minutes, in half-minute steps (D-20). Default 1 minute.
  final int starValueSeconds;

  /// 20–150 stars, in units. Default 60 stars.
  final int dailyCeilingUnits;

  /// 1–5 seconds. Default 1.5 s.
  final int minimumTimeOnTargetMs;
  final ExpiryModeRow expiryMode;

  /// 0–30 stars, in units. Default 10 stars. Granted once, ever.
  final int welcomeUnits;
  final bool welcomeGranted;

  /// 5–30 cards. Default 12.
  final int dailySessionCards;
  final int dailyQuestionCount;

  /// Which weekday closes the week for the test and the purge (D-13, Friday).
  final int expiryWeekday;
  final bool blockingEnabled;
  final bool launcherMode;

  /// Appendix §4 — the parent may pause play without destroying the balance.
  final bool playPaused;

  /// School level, e.g. «السنة الرابعة ابتدائي». Not an identifier (D-11).
  final String grade;

  /// How far the setup wizard has progressed.
  final int onboardingStep;

  /// Minutes east of UTC. Injected into DayKey rather than read from the device,
  /// so a timezone change cannot silently move the day boundary.
  final int utcOffsetMinutes;

  /// A random UUID this app generates once, at first launch.
  ///
  /// It anchors two rules that the contract puts on the **device** rather than
  /// on the account: Article 7.1's free trial, «مرة واحدة لكل جهاز», and the
  /// one-account-per-phone rule the client asked for on 2026-08-28.
  ///
  /// **It identifies an installation, never a person or a child.** Not an
  /// advertising ID — forbidden for Designed for Families (Art. 15.3); not
  /// IMEI, serial or MAC, which describe a person's hardware and are
  /// unavailable to ordinary apps in any case; nothing derived from the child
  /// (Art. 14). Clearing the app's data produces a new one, and that limitation
  /// is accepted and documented rather than worked around.
  final String installId;
  const SettingsRow({
    required this.id,
    required this.pinHash,
    required this.pinSalt,
    required this.starValueSeconds,
    required this.dailyCeilingUnits,
    required this.minimumTimeOnTargetMs,
    required this.expiryMode,
    required this.welcomeUnits,
    required this.welcomeGranted,
    required this.dailySessionCards,
    required this.dailyQuestionCount,
    required this.expiryWeekday,
    required this.blockingEnabled,
    required this.launcherMode,
    required this.playPaused,
    required this.grade,
    required this.onboardingStep,
    required this.utcOffsetMinutes,
    required this.installId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['pin_hash'] = Variable<String>(pinHash);
    map['pin_salt'] = Variable<String>(pinSalt);
    map['star_value_seconds'] = Variable<int>(starValueSeconds);
    map['daily_ceiling_units'] = Variable<int>(dailyCeilingUnits);
    map['minimum_time_on_target_ms'] = Variable<int>(minimumTimeOnTargetMs);
    {
      map['expiry_mode'] = Variable<int>(
        $AppSettingsTable.$converterexpiryMode.toSql(expiryMode),
      );
    }
    map['welcome_units'] = Variable<int>(welcomeUnits);
    map['welcome_granted'] = Variable<bool>(welcomeGranted);
    map['daily_session_cards'] = Variable<int>(dailySessionCards);
    map['daily_question_count'] = Variable<int>(dailyQuestionCount);
    map['expiry_weekday'] = Variable<int>(expiryWeekday);
    map['blocking_enabled'] = Variable<bool>(blockingEnabled);
    map['launcher_mode'] = Variable<bool>(launcherMode);
    map['play_paused'] = Variable<bool>(playPaused);
    map['grade'] = Variable<String>(grade);
    map['onboarding_step'] = Variable<int>(onboardingStep);
    map['utc_offset_minutes'] = Variable<int>(utcOffsetMinutes);
    map['install_id'] = Variable<String>(installId);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      id: Value(id),
      pinHash: Value(pinHash),
      pinSalt: Value(pinSalt),
      starValueSeconds: Value(starValueSeconds),
      dailyCeilingUnits: Value(dailyCeilingUnits),
      minimumTimeOnTargetMs: Value(minimumTimeOnTargetMs),
      expiryMode: Value(expiryMode),
      welcomeUnits: Value(welcomeUnits),
      welcomeGranted: Value(welcomeGranted),
      dailySessionCards: Value(dailySessionCards),
      dailyQuestionCount: Value(dailyQuestionCount),
      expiryWeekday: Value(expiryWeekday),
      blockingEnabled: Value(blockingEnabled),
      launcherMode: Value(launcherMode),
      playPaused: Value(playPaused),
      grade: Value(grade),
      onboardingStep: Value(onboardingStep),
      utcOffsetMinutes: Value(utcOffsetMinutes),
      installId: Value(installId),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      pinHash: serializer.fromJson<String>(json['pinHash']),
      pinSalt: serializer.fromJson<String>(json['pinSalt']),
      starValueSeconds: serializer.fromJson<int>(json['starValueSeconds']),
      dailyCeilingUnits: serializer.fromJson<int>(json['dailyCeilingUnits']),
      minimumTimeOnTargetMs: serializer.fromJson<int>(
        json['minimumTimeOnTargetMs'],
      ),
      expiryMode: $AppSettingsTable.$converterexpiryMode.fromJson(
        serializer.fromJson<int>(json['expiryMode']),
      ),
      welcomeUnits: serializer.fromJson<int>(json['welcomeUnits']),
      welcomeGranted: serializer.fromJson<bool>(json['welcomeGranted']),
      dailySessionCards: serializer.fromJson<int>(json['dailySessionCards']),
      dailyQuestionCount: serializer.fromJson<int>(json['dailyQuestionCount']),
      expiryWeekday: serializer.fromJson<int>(json['expiryWeekday']),
      blockingEnabled: serializer.fromJson<bool>(json['blockingEnabled']),
      launcherMode: serializer.fromJson<bool>(json['launcherMode']),
      playPaused: serializer.fromJson<bool>(json['playPaused']),
      grade: serializer.fromJson<String>(json['grade']),
      onboardingStep: serializer.fromJson<int>(json['onboardingStep']),
      utcOffsetMinutes: serializer.fromJson<int>(json['utcOffsetMinutes']),
      installId: serializer.fromJson<String>(json['installId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'pinHash': serializer.toJson<String>(pinHash),
      'pinSalt': serializer.toJson<String>(pinSalt),
      'starValueSeconds': serializer.toJson<int>(starValueSeconds),
      'dailyCeilingUnits': serializer.toJson<int>(dailyCeilingUnits),
      'minimumTimeOnTargetMs': serializer.toJson<int>(minimumTimeOnTargetMs),
      'expiryMode': serializer.toJson<int>(
        $AppSettingsTable.$converterexpiryMode.toJson(expiryMode),
      ),
      'welcomeUnits': serializer.toJson<int>(welcomeUnits),
      'welcomeGranted': serializer.toJson<bool>(welcomeGranted),
      'dailySessionCards': serializer.toJson<int>(dailySessionCards),
      'dailyQuestionCount': serializer.toJson<int>(dailyQuestionCount),
      'expiryWeekday': serializer.toJson<int>(expiryWeekday),
      'blockingEnabled': serializer.toJson<bool>(blockingEnabled),
      'launcherMode': serializer.toJson<bool>(launcherMode),
      'playPaused': serializer.toJson<bool>(playPaused),
      'grade': serializer.toJson<String>(grade),
      'onboardingStep': serializer.toJson<int>(onboardingStep),
      'utcOffsetMinutes': serializer.toJson<int>(utcOffsetMinutes),
      'installId': serializer.toJson<String>(installId),
    };
  }

  SettingsRow copyWith({
    int? id,
    String? pinHash,
    String? pinSalt,
    int? starValueSeconds,
    int? dailyCeilingUnits,
    int? minimumTimeOnTargetMs,
    ExpiryModeRow? expiryMode,
    int? welcomeUnits,
    bool? welcomeGranted,
    int? dailySessionCards,
    int? dailyQuestionCount,
    int? expiryWeekday,
    bool? blockingEnabled,
    bool? launcherMode,
    bool? playPaused,
    String? grade,
    int? onboardingStep,
    int? utcOffsetMinutes,
    String? installId,
  }) => SettingsRow(
    id: id ?? this.id,
    pinHash: pinHash ?? this.pinHash,
    pinSalt: pinSalt ?? this.pinSalt,
    starValueSeconds: starValueSeconds ?? this.starValueSeconds,
    dailyCeilingUnits: dailyCeilingUnits ?? this.dailyCeilingUnits,
    minimumTimeOnTargetMs: minimumTimeOnTargetMs ?? this.minimumTimeOnTargetMs,
    expiryMode: expiryMode ?? this.expiryMode,
    welcomeUnits: welcomeUnits ?? this.welcomeUnits,
    welcomeGranted: welcomeGranted ?? this.welcomeGranted,
    dailySessionCards: dailySessionCards ?? this.dailySessionCards,
    dailyQuestionCount: dailyQuestionCount ?? this.dailyQuestionCount,
    expiryWeekday: expiryWeekday ?? this.expiryWeekday,
    blockingEnabled: blockingEnabled ?? this.blockingEnabled,
    launcherMode: launcherMode ?? this.launcherMode,
    playPaused: playPaused ?? this.playPaused,
    grade: grade ?? this.grade,
    onboardingStep: onboardingStep ?? this.onboardingStep,
    utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
    installId: installId ?? this.installId,
  );
  SettingsRow copyWithCompanion(AppSettingsCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
      pinSalt: data.pinSalt.present ? data.pinSalt.value : this.pinSalt,
      starValueSeconds: data.starValueSeconds.present
          ? data.starValueSeconds.value
          : this.starValueSeconds,
      dailyCeilingUnits: data.dailyCeilingUnits.present
          ? data.dailyCeilingUnits.value
          : this.dailyCeilingUnits,
      minimumTimeOnTargetMs: data.minimumTimeOnTargetMs.present
          ? data.minimumTimeOnTargetMs.value
          : this.minimumTimeOnTargetMs,
      expiryMode: data.expiryMode.present
          ? data.expiryMode.value
          : this.expiryMode,
      welcomeUnits: data.welcomeUnits.present
          ? data.welcomeUnits.value
          : this.welcomeUnits,
      welcomeGranted: data.welcomeGranted.present
          ? data.welcomeGranted.value
          : this.welcomeGranted,
      dailySessionCards: data.dailySessionCards.present
          ? data.dailySessionCards.value
          : this.dailySessionCards,
      dailyQuestionCount: data.dailyQuestionCount.present
          ? data.dailyQuestionCount.value
          : this.dailyQuestionCount,
      expiryWeekday: data.expiryWeekday.present
          ? data.expiryWeekday.value
          : this.expiryWeekday,
      blockingEnabled: data.blockingEnabled.present
          ? data.blockingEnabled.value
          : this.blockingEnabled,
      launcherMode: data.launcherMode.present
          ? data.launcherMode.value
          : this.launcherMode,
      playPaused: data.playPaused.present
          ? data.playPaused.value
          : this.playPaused,
      grade: data.grade.present ? data.grade.value : this.grade,
      onboardingStep: data.onboardingStep.present
          ? data.onboardingStep.value
          : this.onboardingStep,
      utcOffsetMinutes: data.utcOffsetMinutes.present
          ? data.utcOffsetMinutes.value
          : this.utcOffsetMinutes,
      installId: data.installId.present ? data.installId.value : this.installId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('pinHash: $pinHash, ')
          ..write('pinSalt: $pinSalt, ')
          ..write('starValueSeconds: $starValueSeconds, ')
          ..write('dailyCeilingUnits: $dailyCeilingUnits, ')
          ..write('minimumTimeOnTargetMs: $minimumTimeOnTargetMs, ')
          ..write('expiryMode: $expiryMode, ')
          ..write('welcomeUnits: $welcomeUnits, ')
          ..write('welcomeGranted: $welcomeGranted, ')
          ..write('dailySessionCards: $dailySessionCards, ')
          ..write('dailyQuestionCount: $dailyQuestionCount, ')
          ..write('expiryWeekday: $expiryWeekday, ')
          ..write('blockingEnabled: $blockingEnabled, ')
          ..write('launcherMode: $launcherMode, ')
          ..write('playPaused: $playPaused, ')
          ..write('grade: $grade, ')
          ..write('onboardingStep: $onboardingStep, ')
          ..write('utcOffsetMinutes: $utcOffsetMinutes, ')
          ..write('installId: $installId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    pinHash,
    pinSalt,
    starValueSeconds,
    dailyCeilingUnits,
    minimumTimeOnTargetMs,
    expiryMode,
    welcomeUnits,
    welcomeGranted,
    dailySessionCards,
    dailyQuestionCount,
    expiryWeekday,
    blockingEnabled,
    launcherMode,
    playPaused,
    grade,
    onboardingStep,
    utcOffsetMinutes,
    installId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.pinHash == this.pinHash &&
          other.pinSalt == this.pinSalt &&
          other.starValueSeconds == this.starValueSeconds &&
          other.dailyCeilingUnits == this.dailyCeilingUnits &&
          other.minimumTimeOnTargetMs == this.minimumTimeOnTargetMs &&
          other.expiryMode == this.expiryMode &&
          other.welcomeUnits == this.welcomeUnits &&
          other.welcomeGranted == this.welcomeGranted &&
          other.dailySessionCards == this.dailySessionCards &&
          other.dailyQuestionCount == this.dailyQuestionCount &&
          other.expiryWeekday == this.expiryWeekday &&
          other.blockingEnabled == this.blockingEnabled &&
          other.launcherMode == this.launcherMode &&
          other.playPaused == this.playPaused &&
          other.grade == this.grade &&
          other.onboardingStep == this.onboardingStep &&
          other.utcOffsetMinutes == this.utcOffsetMinutes &&
          other.installId == this.installId);
}

class AppSettingsCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String> pinHash;
  final Value<String> pinSalt;
  final Value<int> starValueSeconds;
  final Value<int> dailyCeilingUnits;
  final Value<int> minimumTimeOnTargetMs;
  final Value<ExpiryModeRow> expiryMode;
  final Value<int> welcomeUnits;
  final Value<bool> welcomeGranted;
  final Value<int> dailySessionCards;
  final Value<int> dailyQuestionCount;
  final Value<int> expiryWeekday;
  final Value<bool> blockingEnabled;
  final Value<bool> launcherMode;
  final Value<bool> playPaused;
  final Value<String> grade;
  final Value<int> onboardingStep;
  final Value<int> utcOffsetMinutes;
  final Value<String> installId;
  const AppSettingsCompanion({
    this.id = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.pinSalt = const Value.absent(),
    this.starValueSeconds = const Value.absent(),
    this.dailyCeilingUnits = const Value.absent(),
    this.minimumTimeOnTargetMs = const Value.absent(),
    this.expiryMode = const Value.absent(),
    this.welcomeUnits = const Value.absent(),
    this.welcomeGranted = const Value.absent(),
    this.dailySessionCards = const Value.absent(),
    this.dailyQuestionCount = const Value.absent(),
    this.expiryWeekday = const Value.absent(),
    this.blockingEnabled = const Value.absent(),
    this.launcherMode = const Value.absent(),
    this.playPaused = const Value.absent(),
    this.grade = const Value.absent(),
    this.onboardingStep = const Value.absent(),
    this.utcOffsetMinutes = const Value.absent(),
    this.installId = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    this.id = const Value.absent(),
    this.pinHash = const Value.absent(),
    this.pinSalt = const Value.absent(),
    this.starValueSeconds = const Value.absent(),
    this.dailyCeilingUnits = const Value.absent(),
    this.minimumTimeOnTargetMs = const Value.absent(),
    this.expiryMode = const Value.absent(),
    this.welcomeUnits = const Value.absent(),
    this.welcomeGranted = const Value.absent(),
    this.dailySessionCards = const Value.absent(),
    this.dailyQuestionCount = const Value.absent(),
    this.expiryWeekday = const Value.absent(),
    this.blockingEnabled = const Value.absent(),
    this.launcherMode = const Value.absent(),
    this.playPaused = const Value.absent(),
    this.grade = const Value.absent(),
    this.onboardingStep = const Value.absent(),
    this.utcOffsetMinutes = const Value.absent(),
    this.installId = const Value.absent(),
  });
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? pinHash,
    Expression<String>? pinSalt,
    Expression<int>? starValueSeconds,
    Expression<int>? dailyCeilingUnits,
    Expression<int>? minimumTimeOnTargetMs,
    Expression<int>? expiryMode,
    Expression<int>? welcomeUnits,
    Expression<bool>? welcomeGranted,
    Expression<int>? dailySessionCards,
    Expression<int>? dailyQuestionCount,
    Expression<int>? expiryWeekday,
    Expression<bool>? blockingEnabled,
    Expression<bool>? launcherMode,
    Expression<bool>? playPaused,
    Expression<String>? grade,
    Expression<int>? onboardingStep,
    Expression<int>? utcOffsetMinutes,
    Expression<String>? installId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (pinHash != null) 'pin_hash': pinHash,
      if (pinSalt != null) 'pin_salt': pinSalt,
      if (starValueSeconds != null) 'star_value_seconds': starValueSeconds,
      if (dailyCeilingUnits != null) 'daily_ceiling_units': dailyCeilingUnits,
      if (minimumTimeOnTargetMs != null)
        'minimum_time_on_target_ms': minimumTimeOnTargetMs,
      if (expiryMode != null) 'expiry_mode': expiryMode,
      if (welcomeUnits != null) 'welcome_units': welcomeUnits,
      if (welcomeGranted != null) 'welcome_granted': welcomeGranted,
      if (dailySessionCards != null) 'daily_session_cards': dailySessionCards,
      if (dailyQuestionCount != null)
        'daily_question_count': dailyQuestionCount,
      if (expiryWeekday != null) 'expiry_weekday': expiryWeekday,
      if (blockingEnabled != null) 'blocking_enabled': blockingEnabled,
      if (launcherMode != null) 'launcher_mode': launcherMode,
      if (playPaused != null) 'play_paused': playPaused,
      if (grade != null) 'grade': grade,
      if (onboardingStep != null) 'onboarding_step': onboardingStep,
      if (utcOffsetMinutes != null) 'utc_offset_minutes': utcOffsetMinutes,
      if (installId != null) 'install_id': installId,
    });
  }

  AppSettingsCompanion copyWith({
    Value<int>? id,
    Value<String>? pinHash,
    Value<String>? pinSalt,
    Value<int>? starValueSeconds,
    Value<int>? dailyCeilingUnits,
    Value<int>? minimumTimeOnTargetMs,
    Value<ExpiryModeRow>? expiryMode,
    Value<int>? welcomeUnits,
    Value<bool>? welcomeGranted,
    Value<int>? dailySessionCards,
    Value<int>? dailyQuestionCount,
    Value<int>? expiryWeekday,
    Value<bool>? blockingEnabled,
    Value<bool>? launcherMode,
    Value<bool>? playPaused,
    Value<String>? grade,
    Value<int>? onboardingStep,
    Value<int>? utcOffsetMinutes,
    Value<String>? installId,
  }) {
    return AppSettingsCompanion(
      id: id ?? this.id,
      pinHash: pinHash ?? this.pinHash,
      pinSalt: pinSalt ?? this.pinSalt,
      starValueSeconds: starValueSeconds ?? this.starValueSeconds,
      dailyCeilingUnits: dailyCeilingUnits ?? this.dailyCeilingUnits,
      minimumTimeOnTargetMs:
          minimumTimeOnTargetMs ?? this.minimumTimeOnTargetMs,
      expiryMode: expiryMode ?? this.expiryMode,
      welcomeUnits: welcomeUnits ?? this.welcomeUnits,
      welcomeGranted: welcomeGranted ?? this.welcomeGranted,
      dailySessionCards: dailySessionCards ?? this.dailySessionCards,
      dailyQuestionCount: dailyQuestionCount ?? this.dailyQuestionCount,
      expiryWeekday: expiryWeekday ?? this.expiryWeekday,
      blockingEnabled: blockingEnabled ?? this.blockingEnabled,
      launcherMode: launcherMode ?? this.launcherMode,
      playPaused: playPaused ?? this.playPaused,
      grade: grade ?? this.grade,
      onboardingStep: onboardingStep ?? this.onboardingStep,
      utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
      installId: installId ?? this.installId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    if (pinSalt.present) {
      map['pin_salt'] = Variable<String>(pinSalt.value);
    }
    if (starValueSeconds.present) {
      map['star_value_seconds'] = Variable<int>(starValueSeconds.value);
    }
    if (dailyCeilingUnits.present) {
      map['daily_ceiling_units'] = Variable<int>(dailyCeilingUnits.value);
    }
    if (minimumTimeOnTargetMs.present) {
      map['minimum_time_on_target_ms'] = Variable<int>(
        minimumTimeOnTargetMs.value,
      );
    }
    if (expiryMode.present) {
      map['expiry_mode'] = Variable<int>(
        $AppSettingsTable.$converterexpiryMode.toSql(expiryMode.value),
      );
    }
    if (welcomeUnits.present) {
      map['welcome_units'] = Variable<int>(welcomeUnits.value);
    }
    if (welcomeGranted.present) {
      map['welcome_granted'] = Variable<bool>(welcomeGranted.value);
    }
    if (dailySessionCards.present) {
      map['daily_session_cards'] = Variable<int>(dailySessionCards.value);
    }
    if (dailyQuestionCount.present) {
      map['daily_question_count'] = Variable<int>(dailyQuestionCount.value);
    }
    if (expiryWeekday.present) {
      map['expiry_weekday'] = Variable<int>(expiryWeekday.value);
    }
    if (blockingEnabled.present) {
      map['blocking_enabled'] = Variable<bool>(blockingEnabled.value);
    }
    if (launcherMode.present) {
      map['launcher_mode'] = Variable<bool>(launcherMode.value);
    }
    if (playPaused.present) {
      map['play_paused'] = Variable<bool>(playPaused.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (onboardingStep.present) {
      map['onboarding_step'] = Variable<int>(onboardingStep.value);
    }
    if (utcOffsetMinutes.present) {
      map['utc_offset_minutes'] = Variable<int>(utcOffsetMinutes.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('id: $id, ')
          ..write('pinHash: $pinHash, ')
          ..write('pinSalt: $pinSalt, ')
          ..write('starValueSeconds: $starValueSeconds, ')
          ..write('dailyCeilingUnits: $dailyCeilingUnits, ')
          ..write('minimumTimeOnTargetMs: $minimumTimeOnTargetMs, ')
          ..write('expiryMode: $expiryMode, ')
          ..write('welcomeUnits: $welcomeUnits, ')
          ..write('welcomeGranted: $welcomeGranted, ')
          ..write('dailySessionCards: $dailySessionCards, ')
          ..write('dailyQuestionCount: $dailyQuestionCount, ')
          ..write('expiryWeekday: $expiryWeekday, ')
          ..write('blockingEnabled: $blockingEnabled, ')
          ..write('launcherMode: $launcherMode, ')
          ..write('playPaused: $playPaused, ')
          ..write('grade: $grade, ')
          ..write('onboardingStep: $onboardingStep, ')
          ..write('utcOffsetMinutes: $utcOffsetMinutes, ')
          ..write('installId: $installId')
          ..write(')'))
        .toString();
  }
}

class $ManagedAppsTable extends ManagedApps
    with TableInfo<$ManagedAppsTable, ManagedAppRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManagedAppsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  late final GeneratedColumnWithTypeConverter<AppPolicy, int> policy =
      GeneratedColumn<int>(
        'policy',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<AppPolicy>($ManagedAppsTable.$converterpolicy);
  static const VerificationMeta _isGameByStoreMeta = const VerificationMeta(
    'isGameByStore',
  );
  @override
  late final GeneratedColumn<bool> isGameByStore = GeneratedColumn<bool>(
    'is_game_by_store',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_game_by_store" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _addedAtMsMeta = const VerificationMeta(
    'addedAtMs',
  );
  @override
  late final GeneratedColumn<int> addedAtMs = GeneratedColumn<int>(
    'added_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    packageName,
    label,
    policy,
    isGameByStore,
    addedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'managed_apps';
  @override
  VerificationContext validateIntegrity(
    Insertable<ManagedAppRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('is_game_by_store')) {
      context.handle(
        _isGameByStoreMeta,
        isGameByStore.isAcceptableOrUnknown(
          data['is_game_by_store']!,
          _isGameByStoreMeta,
        ),
      );
    }
    if (data.containsKey('added_at_ms')) {
      context.handle(
        _addedAtMsMeta,
        addedAtMs.isAcceptableOrUnknown(data['added_at_ms']!, _addedAtMsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {packageName};
  @override
  ManagedAppRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManagedAppRow(
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      policy: $ManagedAppsTable.$converterpolicy.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}policy'],
        )!,
      ),
      isGameByStore: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_game_by_store'],
      )!,
      addedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at_ms'],
      )!,
    );
  }

  @override
  $ManagedAppsTable createAlias(String alias) {
    return $ManagedAppsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AppPolicy, int, int> $converterpolicy =
      const EnumIndexConverter<AppPolicy>(AppPolicy.values);
}

class ManagedAppRow extends DataClass implements Insertable<ManagedAppRow> {
  final String packageName;
  final String label;
  final AppPolicy policy;
  final bool isGameByStore;
  final int addedAtMs;
  const ManagedAppRow({
    required this.packageName,
    required this.label,
    required this.policy,
    required this.isGameByStore,
    required this.addedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['package_name'] = Variable<String>(packageName);
    map['label'] = Variable<String>(label);
    {
      map['policy'] = Variable<int>(
        $ManagedAppsTable.$converterpolicy.toSql(policy),
      );
    }
    map['is_game_by_store'] = Variable<bool>(isGameByStore);
    map['added_at_ms'] = Variable<int>(addedAtMs);
    return map;
  }

  ManagedAppsCompanion toCompanion(bool nullToAbsent) {
    return ManagedAppsCompanion(
      packageName: Value(packageName),
      label: Value(label),
      policy: Value(policy),
      isGameByStore: Value(isGameByStore),
      addedAtMs: Value(addedAtMs),
    );
  }

  factory ManagedAppRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManagedAppRow(
      packageName: serializer.fromJson<String>(json['packageName']),
      label: serializer.fromJson<String>(json['label']),
      policy: $ManagedAppsTable.$converterpolicy.fromJson(
        serializer.fromJson<int>(json['policy']),
      ),
      isGameByStore: serializer.fromJson<bool>(json['isGameByStore']),
      addedAtMs: serializer.fromJson<int>(json['addedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'packageName': serializer.toJson<String>(packageName),
      'label': serializer.toJson<String>(label),
      'policy': serializer.toJson<int>(
        $ManagedAppsTable.$converterpolicy.toJson(policy),
      ),
      'isGameByStore': serializer.toJson<bool>(isGameByStore),
      'addedAtMs': serializer.toJson<int>(addedAtMs),
    };
  }

  ManagedAppRow copyWith({
    String? packageName,
    String? label,
    AppPolicy? policy,
    bool? isGameByStore,
    int? addedAtMs,
  }) => ManagedAppRow(
    packageName: packageName ?? this.packageName,
    label: label ?? this.label,
    policy: policy ?? this.policy,
    isGameByStore: isGameByStore ?? this.isGameByStore,
    addedAtMs: addedAtMs ?? this.addedAtMs,
  );
  ManagedAppRow copyWithCompanion(ManagedAppsCompanion data) {
    return ManagedAppRow(
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      label: data.label.present ? data.label.value : this.label,
      policy: data.policy.present ? data.policy.value : this.policy,
      isGameByStore: data.isGameByStore.present
          ? data.isGameByStore.value
          : this.isGameByStore,
      addedAtMs: data.addedAtMs.present ? data.addedAtMs.value : this.addedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManagedAppRow(')
          ..write('packageName: $packageName, ')
          ..write('label: $label, ')
          ..write('policy: $policy, ')
          ..write('isGameByStore: $isGameByStore, ')
          ..write('addedAtMs: $addedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(packageName, label, policy, isGameByStore, addedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManagedAppRow &&
          other.packageName == this.packageName &&
          other.label == this.label &&
          other.policy == this.policy &&
          other.isGameByStore == this.isGameByStore &&
          other.addedAtMs == this.addedAtMs);
}

class ManagedAppsCompanion extends UpdateCompanion<ManagedAppRow> {
  final Value<String> packageName;
  final Value<String> label;
  final Value<AppPolicy> policy;
  final Value<bool> isGameByStore;
  final Value<int> addedAtMs;
  final Value<int> rowid;
  const ManagedAppsCompanion({
    this.packageName = const Value.absent(),
    this.label = const Value.absent(),
    this.policy = const Value.absent(),
    this.isGameByStore = const Value.absent(),
    this.addedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManagedAppsCompanion.insert({
    required String packageName,
    this.label = const Value.absent(),
    required AppPolicy policy,
    this.isGameByStore = const Value.absent(),
    this.addedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : packageName = Value(packageName),
       policy = Value(policy);
  static Insertable<ManagedAppRow> custom({
    Expression<String>? packageName,
    Expression<String>? label,
    Expression<int>? policy,
    Expression<bool>? isGameByStore,
    Expression<int>? addedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (packageName != null) 'package_name': packageName,
      if (label != null) 'label': label,
      if (policy != null) 'policy': policy,
      if (isGameByStore != null) 'is_game_by_store': isGameByStore,
      if (addedAtMs != null) 'added_at_ms': addedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManagedAppsCompanion copyWith({
    Value<String>? packageName,
    Value<String>? label,
    Value<AppPolicy>? policy,
    Value<bool>? isGameByStore,
    Value<int>? addedAtMs,
    Value<int>? rowid,
  }) {
    return ManagedAppsCompanion(
      packageName: packageName ?? this.packageName,
      label: label ?? this.label,
      policy: policy ?? this.policy,
      isGameByStore: isGameByStore ?? this.isGameByStore,
      addedAtMs: addedAtMs ?? this.addedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (policy.present) {
      map['policy'] = Variable<int>(
        $ManagedAppsTable.$converterpolicy.toSql(policy.value),
      );
    }
    if (isGameByStore.present) {
      map['is_game_by_store'] = Variable<bool>(isGameByStore.value);
    }
    if (addedAtMs.present) {
      map['added_at_ms'] = Variable<int>(addedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManagedAppsCompanion(')
          ..write('packageName: $packageName, ')
          ..write('label: $label, ')
          ..write('policy: $policy, ')
          ..write('isGameByStore: $isGameByStore, ')
          ..write('addedAtMs: $addedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LessonsTable extends Lessons with TableInfo<$LessonsTable, LessonRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _subjectMeta = const VerificationMeta(
    'subject',
  );
  @override
  late final GeneratedColumn<String> subject = GeneratedColumn<String>(
    'subject',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekKeyMeta = const VerificationMeta(
    'weekKey',
  );
  @override
  late final GeneratedColumn<int> weekKey = GeneratedColumn<int>(
    'week_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purgedAtMsMeta = const VerificationMeta(
    'purgedAtMs',
  );
  @override
  late final GeneratedColumn<int> purgedAtMs = GeneratedColumn<int>(
    'purged_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    subject,
    grade,
    summary,
    createdAtMs,
    weekKey,
    purgedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lessons';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('subject')) {
      context.handle(
        _subjectMeta,
        subject.isAcceptableOrUnknown(data['subject']!, _subjectMeta),
      );
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('week_key')) {
      context.handle(
        _weekKeyMeta,
        weekKey.isAcceptableOrUnknown(data['week_key']!, _weekKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_weekKeyMeta);
    }
    if (data.containsKey('purged_at_ms')) {
      context.handle(
        _purgedAtMsMeta,
        purgedAtMs.isAcceptableOrUnknown(
          data['purged_at_ms']!,
          _purgedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      subject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}subject'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      weekKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_key'],
      )!,
      purgedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purged_at_ms'],
      ),
    );
  }

  @override
  $LessonsTable createAlias(String alias) {
    return $LessonsTable(attachedDatabase, alias);
  }
}

class LessonRow extends DataClass implements Insertable<LessonRow> {
  final int id;
  final String title;
  final String subject;
  final String grade;
  final String summary;
  final int createdAtMs;
  final int weekKey;

  /// Set when the weekly purge removed this lesson's images and questions. The
  /// lesson row and its summary are kept — Art. 14 deletes only images and
  /// exercises.
  final int? purgedAtMs;
  const LessonRow({
    required this.id,
    required this.title,
    required this.subject,
    required this.grade,
    required this.summary,
    required this.createdAtMs,
    required this.weekKey,
    this.purgedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['subject'] = Variable<String>(subject);
    map['grade'] = Variable<String>(grade);
    map['summary'] = Variable<String>(summary);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['week_key'] = Variable<int>(weekKey);
    if (!nullToAbsent || purgedAtMs != null) {
      map['purged_at_ms'] = Variable<int>(purgedAtMs);
    }
    return map;
  }

  LessonsCompanion toCompanion(bool nullToAbsent) {
    return LessonsCompanion(
      id: Value(id),
      title: Value(title),
      subject: Value(subject),
      grade: Value(grade),
      summary: Value(summary),
      createdAtMs: Value(createdAtMs),
      weekKey: Value(weekKey),
      purgedAtMs: purgedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(purgedAtMs),
    );
  }

  factory LessonRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonRow(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      subject: serializer.fromJson<String>(json['subject']),
      grade: serializer.fromJson<String>(json['grade']),
      summary: serializer.fromJson<String>(json['summary']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      weekKey: serializer.fromJson<int>(json['weekKey']),
      purgedAtMs: serializer.fromJson<int?>(json['purgedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'subject': serializer.toJson<String>(subject),
      'grade': serializer.toJson<String>(grade),
      'summary': serializer.toJson<String>(summary),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'weekKey': serializer.toJson<int>(weekKey),
      'purgedAtMs': serializer.toJson<int?>(purgedAtMs),
    };
  }

  LessonRow copyWith({
    int? id,
    String? title,
    String? subject,
    String? grade,
    String? summary,
    int? createdAtMs,
    int? weekKey,
    Value<int?> purgedAtMs = const Value.absent(),
  }) => LessonRow(
    id: id ?? this.id,
    title: title ?? this.title,
    subject: subject ?? this.subject,
    grade: grade ?? this.grade,
    summary: summary ?? this.summary,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    weekKey: weekKey ?? this.weekKey,
    purgedAtMs: purgedAtMs.present ? purgedAtMs.value : this.purgedAtMs,
  );
  LessonRow copyWithCompanion(LessonsCompanion data) {
    return LessonRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      subject: data.subject.present ? data.subject.value : this.subject,
      grade: data.grade.present ? data.grade.value : this.grade,
      summary: data.summary.present ? data.summary.value : this.summary,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      weekKey: data.weekKey.present ? data.weekKey.value : this.weekKey,
      purgedAtMs: data.purgedAtMs.present
          ? data.purgedAtMs.value
          : this.purgedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('grade: $grade, ')
          ..write('summary: $summary, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('weekKey: $weekKey, ')
          ..write('purgedAtMs: $purgedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    subject,
    grade,
    summary,
    createdAtMs,
    weekKey,
    purgedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.subject == this.subject &&
          other.grade == this.grade &&
          other.summary == this.summary &&
          other.createdAtMs == this.createdAtMs &&
          other.weekKey == this.weekKey &&
          other.purgedAtMs == this.purgedAtMs);
}

class LessonsCompanion extends UpdateCompanion<LessonRow> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> subject;
  final Value<String> grade;
  final Value<String> summary;
  final Value<int> createdAtMs;
  final Value<int> weekKey;
  final Value<int?> purgedAtMs;
  const LessonsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.subject = const Value.absent(),
    this.grade = const Value.absent(),
    this.summary = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.weekKey = const Value.absent(),
    this.purgedAtMs = const Value.absent(),
  });
  LessonsCompanion.insert({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.subject = const Value.absent(),
    this.grade = const Value.absent(),
    required String summary,
    required int createdAtMs,
    required int weekKey,
    this.purgedAtMs = const Value.absent(),
  }) : summary = Value(summary),
       createdAtMs = Value(createdAtMs),
       weekKey = Value(weekKey);
  static Insertable<LessonRow> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? subject,
    Expression<String>? grade,
    Expression<String>? summary,
    Expression<int>? createdAtMs,
    Expression<int>? weekKey,
    Expression<int>? purgedAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (subject != null) 'subject': subject,
      if (grade != null) 'grade': grade,
      if (summary != null) 'summary': summary,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (weekKey != null) 'week_key': weekKey,
      if (purgedAtMs != null) 'purged_at_ms': purgedAtMs,
    });
  }

  LessonsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? subject,
    Value<String>? grade,
    Value<String>? summary,
    Value<int>? createdAtMs,
    Value<int>? weekKey,
    Value<int?>? purgedAtMs,
  }) {
    return LessonsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      summary: summary ?? this.summary,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      weekKey: weekKey ?? this.weekKey,
      purgedAtMs: purgedAtMs ?? this.purgedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (subject.present) {
      map['subject'] = Variable<String>(subject.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (weekKey.present) {
      map['week_key'] = Variable<int>(weekKey.value);
    }
    if (purgedAtMs.present) {
      map['purged_at_ms'] = Variable<int>(purgedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('subject: $subject, ')
          ..write('grade: $grade, ')
          ..write('summary: $summary, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('weekKey: $weekKey, ')
          ..write('purgedAtMs: $purgedAtMs')
          ..write(')'))
        .toString();
  }
}

class $LessonImagesTable extends LessonImages
    with TableInfo<$LessonImagesTable, LessonImageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LessonImagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<int> lessonId = GeneratedColumn<int>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lessons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _filePathMeta = const VerificationMeta(
    'filePath',
  );
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
    'file_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMsMeta = const VerificationMeta(
    'capturedAtMs',
  );
  @override
  late final GeneratedColumn<int> capturedAtMs = GeneratedColumn<int>(
    'captured_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMsMeta = const VerificationMeta(
    'deletedAtMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtMs = GeneratedColumn<int>(
    'deleted_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lessonId,
    filePath,
    capturedAtMs,
    deletedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lesson_images';
  @override
  VerificationContext validateIntegrity(
    Insertable<LessonImageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('file_path')) {
      context.handle(
        _filePathMeta,
        filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta),
      );
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('captured_at_ms')) {
      context.handle(
        _capturedAtMsMeta,
        capturedAtMs.isAcceptableOrUnknown(
          data['captured_at_ms']!,
          _capturedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMsMeta);
    }
    if (data.containsKey('deleted_at_ms')) {
      context.handle(
        _deletedAtMsMeta,
        deletedAtMs.isAcceptableOrUnknown(
          data['deleted_at_ms']!,
          _deletedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LessonImageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LessonImageRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lesson_id'],
      )!,
      filePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_path'],
      )!,
      capturedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}captured_at_ms'],
      )!,
      deletedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_ms'],
      ),
    );
  }

  @override
  $LessonImagesTable createAlias(String alias) {
    return $LessonImagesTable(attachedDatabase, alias);
  }
}

class LessonImageRow extends DataClass implements Insertable<LessonImageRow> {
  final int id;
  final int lessonId;

  /// Absolute path inside the app's private storage. Never shared storage,
  /// never the gallery, never backed up.
  final String filePath;
  final int capturedAtMs;
  final int? deletedAtMs;
  const LessonImageRow({
    required this.id,
    required this.lessonId,
    required this.filePath,
    required this.capturedAtMs,
    this.deletedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lesson_id'] = Variable<int>(lessonId);
    map['file_path'] = Variable<String>(filePath);
    map['captured_at_ms'] = Variable<int>(capturedAtMs);
    if (!nullToAbsent || deletedAtMs != null) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs);
    }
    return map;
  }

  LessonImagesCompanion toCompanion(bool nullToAbsent) {
    return LessonImagesCompanion(
      id: Value(id),
      lessonId: Value(lessonId),
      filePath: Value(filePath),
      capturedAtMs: Value(capturedAtMs),
      deletedAtMs: deletedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtMs),
    );
  }

  factory LessonImageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LessonImageRow(
      id: serializer.fromJson<int>(json['id']),
      lessonId: serializer.fromJson<int>(json['lessonId']),
      filePath: serializer.fromJson<String>(json['filePath']),
      capturedAtMs: serializer.fromJson<int>(json['capturedAtMs']),
      deletedAtMs: serializer.fromJson<int?>(json['deletedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lessonId': serializer.toJson<int>(lessonId),
      'filePath': serializer.toJson<String>(filePath),
      'capturedAtMs': serializer.toJson<int>(capturedAtMs),
      'deletedAtMs': serializer.toJson<int?>(deletedAtMs),
    };
  }

  LessonImageRow copyWith({
    int? id,
    int? lessonId,
    String? filePath,
    int? capturedAtMs,
    Value<int?> deletedAtMs = const Value.absent(),
  }) => LessonImageRow(
    id: id ?? this.id,
    lessonId: lessonId ?? this.lessonId,
    filePath: filePath ?? this.filePath,
    capturedAtMs: capturedAtMs ?? this.capturedAtMs,
    deletedAtMs: deletedAtMs.present ? deletedAtMs.value : this.deletedAtMs,
  );
  LessonImageRow copyWithCompanion(LessonImagesCompanion data) {
    return LessonImageRow(
      id: data.id.present ? data.id.value : this.id,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      capturedAtMs: data.capturedAtMs.present
          ? data.capturedAtMs.value
          : this.capturedAtMs,
      deletedAtMs: data.deletedAtMs.present
          ? data.deletedAtMs.value
          : this.deletedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LessonImageRow(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('filePath: $filePath, ')
          ..write('capturedAtMs: $capturedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, lessonId, filePath, capturedAtMs, deletedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LessonImageRow &&
          other.id == this.id &&
          other.lessonId == this.lessonId &&
          other.filePath == this.filePath &&
          other.capturedAtMs == this.capturedAtMs &&
          other.deletedAtMs == this.deletedAtMs);
}

class LessonImagesCompanion extends UpdateCompanion<LessonImageRow> {
  final Value<int> id;
  final Value<int> lessonId;
  final Value<String> filePath;
  final Value<int> capturedAtMs;
  final Value<int?> deletedAtMs;
  const LessonImagesCompanion({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.filePath = const Value.absent(),
    this.capturedAtMs = const Value.absent(),
    this.deletedAtMs = const Value.absent(),
  });
  LessonImagesCompanion.insert({
    this.id = const Value.absent(),
    required int lessonId,
    required String filePath,
    required int capturedAtMs,
    this.deletedAtMs = const Value.absent(),
  }) : lessonId = Value(lessonId),
       filePath = Value(filePath),
       capturedAtMs = Value(capturedAtMs);
  static Insertable<LessonImageRow> custom({
    Expression<int>? id,
    Expression<int>? lessonId,
    Expression<String>? filePath,
    Expression<int>? capturedAtMs,
    Expression<int>? deletedAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      if (filePath != null) 'file_path': filePath,
      if (capturedAtMs != null) 'captured_at_ms': capturedAtMs,
      if (deletedAtMs != null) 'deleted_at_ms': deletedAtMs,
    });
  }

  LessonImagesCompanion copyWith({
    Value<int>? id,
    Value<int>? lessonId,
    Value<String>? filePath,
    Value<int>? capturedAtMs,
    Value<int?>? deletedAtMs,
  }) {
    return LessonImagesCompanion(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      filePath: filePath ?? this.filePath,
      capturedAtMs: capturedAtMs ?? this.capturedAtMs,
      deletedAtMs: deletedAtMs ?? this.deletedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<int>(lessonId.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (capturedAtMs.present) {
      map['captured_at_ms'] = Variable<int>(capturedAtMs.value);
    }
    if (deletedAtMs.present) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LessonImagesCompanion(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('filePath: $filePath, ')
          ..write('capturedAtMs: $capturedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs')
          ..write(')'))
        .toString();
  }
}

class $CardsTable extends Cards with TableInfo<$CardsTable, CardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<int> lessonId = GeneratedColumn<int>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lessons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _frontMeta = const VerificationMeta('front');
  @override
  late final GeneratedColumn<String> front = GeneratedColumn<String>(
    'front',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backMeta = const VerificationMeta('back');
  @override
  late final GeneratedColumn<String> back = GeneratedColumn<String>(
    'back',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _repetitionsMeta = const VerificationMeta(
    'repetitions',
  );
  @override
  late final GeneratedColumn<int> repetitions = GeneratedColumn<int>(
    'repetitions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _intervalDaysMeta = const VerificationMeta(
    'intervalDays',
  );
  @override
  late final GeneratedColumn<int> intervalDays = GeneratedColumn<int>(
    'interval_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _easePermilleMeta = const VerificationMeta(
    'easePermille',
  );
  @override
  late final GeneratedColumn<int> easePermille = GeneratedColumn<int>(
    'ease_permille',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2500),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastReviewedDayMeta = const VerificationMeta(
    'lastReviewedDay',
  );
  @override
  late final GeneratedColumn<int> lastReviewedDay = GeneratedColumn<int>(
    'last_reviewed_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firstCorrectAtMsMeta = const VerificationMeta(
    'firstCorrectAtMs',
  );
  @override
  late final GeneratedColumn<int> firstCorrectAtMs = GeneratedColumn<int>(
    'first_correct_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lessonId,
    front,
    back,
    repetitions,
    intervalDays,
    easePermille,
    lapses,
    dueDay,
    lastReviewedDay,
    firstCorrectAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CardRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('front')) {
      context.handle(
        _frontMeta,
        front.isAcceptableOrUnknown(data['front']!, _frontMeta),
      );
    } else if (isInserting) {
      context.missing(_frontMeta);
    }
    if (data.containsKey('back')) {
      context.handle(
        _backMeta,
        back.isAcceptableOrUnknown(data['back']!, _backMeta),
      );
    } else if (isInserting) {
      context.missing(_backMeta);
    }
    if (data.containsKey('repetitions')) {
      context.handle(
        _repetitionsMeta,
        repetitions.isAcceptableOrUnknown(
          data['repetitions']!,
          _repetitionsMeta,
        ),
      );
    }
    if (data.containsKey('interval_days')) {
      context.handle(
        _intervalDaysMeta,
        intervalDays.isAcceptableOrUnknown(
          data['interval_days']!,
          _intervalDaysMeta,
        ),
      );
    }
    if (data.containsKey('ease_permille')) {
      context.handle(
        _easePermilleMeta,
        easePermille.isAcceptableOrUnknown(
          data['ease_permille']!,
          _easePermilleMeta,
        ),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('last_reviewed_day')) {
      context.handle(
        _lastReviewedDayMeta,
        lastReviewedDay.isAcceptableOrUnknown(
          data['last_reviewed_day']!,
          _lastReviewedDayMeta,
        ),
      );
    }
    if (data.containsKey('first_correct_at_ms')) {
      context.handle(
        _firstCorrectAtMsMeta,
        firstCorrectAtMs.isAcceptableOrUnknown(
          data['first_correct_at_ms']!,
          _firstCorrectAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lesson_id'],
      )!,
      front: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}front'],
      )!,
      back: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}back'],
      )!,
      repetitions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetitions'],
      )!,
      intervalDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_days'],
      )!,
      easePermille: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ease_permille'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      ),
      lastReviewedDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_reviewed_day'],
      ),
      firstCorrectAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_correct_at_ms'],
      ),
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class CardRow extends DataClass implements Insertable<CardRow> {
  final int id;
  final int lessonId;
  final String front;
  final String back;
  final int repetitions;
  final int intervalDays;
  final int easePermille;
  final int lapses;

  /// Days since the Unix epoch, matching DayKey. Null means never scheduled.
  final int? dueDay;
  final int? lastReviewedDay;

  /// When this card was first answered correctly — the difference between
  /// Article 5's 1 star and 0.5 stars.
  final int? firstCorrectAtMs;
  const CardRow({
    required this.id,
    required this.lessonId,
    required this.front,
    required this.back,
    required this.repetitions,
    required this.intervalDays,
    required this.easePermille,
    required this.lapses,
    this.dueDay,
    this.lastReviewedDay,
    this.firstCorrectAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lesson_id'] = Variable<int>(lessonId);
    map['front'] = Variable<String>(front);
    map['back'] = Variable<String>(back);
    map['repetitions'] = Variable<int>(repetitions);
    map['interval_days'] = Variable<int>(intervalDays);
    map['ease_permille'] = Variable<int>(easePermille);
    map['lapses'] = Variable<int>(lapses);
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    if (!nullToAbsent || lastReviewedDay != null) {
      map['last_reviewed_day'] = Variable<int>(lastReviewedDay);
    }
    if (!nullToAbsent || firstCorrectAtMs != null) {
      map['first_correct_at_ms'] = Variable<int>(firstCorrectAtMs);
    }
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      lessonId: Value(lessonId),
      front: Value(front),
      back: Value(back),
      repetitions: Value(repetitions),
      intervalDays: Value(intervalDays),
      easePermille: Value(easePermille),
      lapses: Value(lapses),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      lastReviewedDay: lastReviewedDay == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedDay),
      firstCorrectAtMs: firstCorrectAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(firstCorrectAtMs),
    );
  }

  factory CardRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardRow(
      id: serializer.fromJson<int>(json['id']),
      lessonId: serializer.fromJson<int>(json['lessonId']),
      front: serializer.fromJson<String>(json['front']),
      back: serializer.fromJson<String>(json['back']),
      repetitions: serializer.fromJson<int>(json['repetitions']),
      intervalDays: serializer.fromJson<int>(json['intervalDays']),
      easePermille: serializer.fromJson<int>(json['easePermille']),
      lapses: serializer.fromJson<int>(json['lapses']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      lastReviewedDay: serializer.fromJson<int?>(json['lastReviewedDay']),
      firstCorrectAtMs: serializer.fromJson<int?>(json['firstCorrectAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lessonId': serializer.toJson<int>(lessonId),
      'front': serializer.toJson<String>(front),
      'back': serializer.toJson<String>(back),
      'repetitions': serializer.toJson<int>(repetitions),
      'intervalDays': serializer.toJson<int>(intervalDays),
      'easePermille': serializer.toJson<int>(easePermille),
      'lapses': serializer.toJson<int>(lapses),
      'dueDay': serializer.toJson<int?>(dueDay),
      'lastReviewedDay': serializer.toJson<int?>(lastReviewedDay),
      'firstCorrectAtMs': serializer.toJson<int?>(firstCorrectAtMs),
    };
  }

  CardRow copyWith({
    int? id,
    int? lessonId,
    String? front,
    String? back,
    int? repetitions,
    int? intervalDays,
    int? easePermille,
    int? lapses,
    Value<int?> dueDay = const Value.absent(),
    Value<int?> lastReviewedDay = const Value.absent(),
    Value<int?> firstCorrectAtMs = const Value.absent(),
  }) => CardRow(
    id: id ?? this.id,
    lessonId: lessonId ?? this.lessonId,
    front: front ?? this.front,
    back: back ?? this.back,
    repetitions: repetitions ?? this.repetitions,
    intervalDays: intervalDays ?? this.intervalDays,
    easePermille: easePermille ?? this.easePermille,
    lapses: lapses ?? this.lapses,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    lastReviewedDay: lastReviewedDay.present
        ? lastReviewedDay.value
        : this.lastReviewedDay,
    firstCorrectAtMs: firstCorrectAtMs.present
        ? firstCorrectAtMs.value
        : this.firstCorrectAtMs,
  );
  CardRow copyWithCompanion(CardsCompanion data) {
    return CardRow(
      id: data.id.present ? data.id.value : this.id,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      front: data.front.present ? data.front.value : this.front,
      back: data.back.present ? data.back.value : this.back,
      repetitions: data.repetitions.present
          ? data.repetitions.value
          : this.repetitions,
      intervalDays: data.intervalDays.present
          ? data.intervalDays.value
          : this.intervalDays,
      easePermille: data.easePermille.present
          ? data.easePermille.value
          : this.easePermille,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      lastReviewedDay: data.lastReviewedDay.present
          ? data.lastReviewedDay.value
          : this.lastReviewedDay,
      firstCorrectAtMs: data.firstCorrectAtMs.present
          ? data.firstCorrectAtMs.value
          : this.firstCorrectAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardRow(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('repetitions: $repetitions, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('easePermille: $easePermille, ')
          ..write('lapses: $lapses, ')
          ..write('dueDay: $dueDay, ')
          ..write('lastReviewedDay: $lastReviewedDay, ')
          ..write('firstCorrectAtMs: $firstCorrectAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    lessonId,
    front,
    back,
    repetitions,
    intervalDays,
    easePermille,
    lapses,
    dueDay,
    lastReviewedDay,
    firstCorrectAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardRow &&
          other.id == this.id &&
          other.lessonId == this.lessonId &&
          other.front == this.front &&
          other.back == this.back &&
          other.repetitions == this.repetitions &&
          other.intervalDays == this.intervalDays &&
          other.easePermille == this.easePermille &&
          other.lapses == this.lapses &&
          other.dueDay == this.dueDay &&
          other.lastReviewedDay == this.lastReviewedDay &&
          other.firstCorrectAtMs == this.firstCorrectAtMs);
}

class CardsCompanion extends UpdateCompanion<CardRow> {
  final Value<int> id;
  final Value<int> lessonId;
  final Value<String> front;
  final Value<String> back;
  final Value<int> repetitions;
  final Value<int> intervalDays;
  final Value<int> easePermille;
  final Value<int> lapses;
  final Value<int?> dueDay;
  final Value<int?> lastReviewedDay;
  final Value<int?> firstCorrectAtMs;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.front = const Value.absent(),
    this.back = const Value.absent(),
    this.repetitions = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.easePermille = const Value.absent(),
    this.lapses = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.lastReviewedDay = const Value.absent(),
    this.firstCorrectAtMs = const Value.absent(),
  });
  CardsCompanion.insert({
    this.id = const Value.absent(),
    required int lessonId,
    required String front,
    required String back,
    this.repetitions = const Value.absent(),
    this.intervalDays = const Value.absent(),
    this.easePermille = const Value.absent(),
    this.lapses = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.lastReviewedDay = const Value.absent(),
    this.firstCorrectAtMs = const Value.absent(),
  }) : lessonId = Value(lessonId),
       front = Value(front),
       back = Value(back);
  static Insertable<CardRow> custom({
    Expression<int>? id,
    Expression<int>? lessonId,
    Expression<String>? front,
    Expression<String>? back,
    Expression<int>? repetitions,
    Expression<int>? intervalDays,
    Expression<int>? easePermille,
    Expression<int>? lapses,
    Expression<int>? dueDay,
    Expression<int>? lastReviewedDay,
    Expression<int>? firstCorrectAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      if (front != null) 'front': front,
      if (back != null) 'back': back,
      if (repetitions != null) 'repetitions': repetitions,
      if (intervalDays != null) 'interval_days': intervalDays,
      if (easePermille != null) 'ease_permille': easePermille,
      if (lapses != null) 'lapses': lapses,
      if (dueDay != null) 'due_day': dueDay,
      if (lastReviewedDay != null) 'last_reviewed_day': lastReviewedDay,
      if (firstCorrectAtMs != null) 'first_correct_at_ms': firstCorrectAtMs,
    });
  }

  CardsCompanion copyWith({
    Value<int>? id,
    Value<int>? lessonId,
    Value<String>? front,
    Value<String>? back,
    Value<int>? repetitions,
    Value<int>? intervalDays,
    Value<int>? easePermille,
    Value<int>? lapses,
    Value<int?>? dueDay,
    Value<int?>? lastReviewedDay,
    Value<int?>? firstCorrectAtMs,
  }) {
    return CardsCompanion(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      front: front ?? this.front,
      back: back ?? this.back,
      repetitions: repetitions ?? this.repetitions,
      intervalDays: intervalDays ?? this.intervalDays,
      easePermille: easePermille ?? this.easePermille,
      lapses: lapses ?? this.lapses,
      dueDay: dueDay ?? this.dueDay,
      lastReviewedDay: lastReviewedDay ?? this.lastReviewedDay,
      firstCorrectAtMs: firstCorrectAtMs ?? this.firstCorrectAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<int>(lessonId.value);
    }
    if (front.present) {
      map['front'] = Variable<String>(front.value);
    }
    if (back.present) {
      map['back'] = Variable<String>(back.value);
    }
    if (repetitions.present) {
      map['repetitions'] = Variable<int>(repetitions.value);
    }
    if (intervalDays.present) {
      map['interval_days'] = Variable<int>(intervalDays.value);
    }
    if (easePermille.present) {
      map['ease_permille'] = Variable<int>(easePermille.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (lastReviewedDay.present) {
      map['last_reviewed_day'] = Variable<int>(lastReviewedDay.value);
    }
    if (firstCorrectAtMs.present) {
      map['first_correct_at_ms'] = Variable<int>(firstCorrectAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('front: $front, ')
          ..write('back: $back, ')
          ..write('repetitions: $repetitions, ')
          ..write('intervalDays: $intervalDays, ')
          ..write('easePermille: $easePermille, ')
          ..write('lapses: $lapses, ')
          ..write('dueDay: $dueDay, ')
          ..write('lastReviewedDay: $lastReviewedDay, ')
          ..write('firstCorrectAtMs: $firstCorrectAtMs')
          ..write(')'))
        .toString();
  }
}

class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, QuestionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _lessonIdMeta = const VerificationMeta(
    'lessonId',
  );
  @override
  late final GeneratedColumn<int> lessonId = GeneratedColumn<int>(
    'lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES lessons (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _promptMeta = const VerificationMeta('prompt');
  @override
  late final GeneratedColumn<String> prompt = GeneratedColumn<String>(
    'prompt',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _choicesJsonMeta = const VerificationMeta(
    'choicesJson',
  );
  @override
  late final GeneratedColumn<String> choicesJson = GeneratedColumn<String>(
    'choices_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctIndexMeta = const VerificationMeta(
    'correctIndex',
  );
  @override
  late final GeneratedColumn<int> correctIndex = GeneratedColumn<int>(
    'correct_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purgedAtMsMeta = const VerificationMeta(
    'purgedAtMs',
  );
  @override
  late final GeneratedColumn<int> purgedAtMs = GeneratedColumn<int>(
    'purged_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lessonId,
    prompt,
    choicesJson,
    correctIndex,
    purgedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(
    Insertable<QuestionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('lesson_id')) {
      context.handle(
        _lessonIdMeta,
        lessonId.isAcceptableOrUnknown(data['lesson_id']!, _lessonIdMeta),
      );
    } else if (isInserting) {
      context.missing(_lessonIdMeta);
    }
    if (data.containsKey('prompt')) {
      context.handle(
        _promptMeta,
        prompt.isAcceptableOrUnknown(data['prompt']!, _promptMeta),
      );
    } else if (isInserting) {
      context.missing(_promptMeta);
    }
    if (data.containsKey('choices_json')) {
      context.handle(
        _choicesJsonMeta,
        choicesJson.isAcceptableOrUnknown(
          data['choices_json']!,
          _choicesJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_choicesJsonMeta);
    }
    if (data.containsKey('correct_index')) {
      context.handle(
        _correctIndexMeta,
        correctIndex.isAcceptableOrUnknown(
          data['correct_index']!,
          _correctIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_correctIndexMeta);
    }
    if (data.containsKey('purged_at_ms')) {
      context.handle(
        _purgedAtMsMeta,
        purgedAtMs.isAcceptableOrUnknown(
          data['purged_at_ms']!,
          _purgedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  QuestionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuestionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lesson_id'],
      )!,
      prompt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt'],
      )!,
      choicesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}choices_json'],
      )!,
      correctIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_index'],
      )!,
      purgedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purged_at_ms'],
      ),
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class QuestionRow extends DataClass implements Insertable<QuestionRow> {
  final int id;
  final int lessonId;
  final String prompt;

  /// JSON array of choice strings. A child-facing quiz has 2–4 of them; a
  /// separate table would buy nothing and cost a join on every question.
  final String choicesJson;
  final int correctIndex;
  final int? purgedAtMs;
  const QuestionRow({
    required this.id,
    required this.lessonId,
    required this.prompt,
    required this.choicesJson,
    required this.correctIndex,
    this.purgedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['lesson_id'] = Variable<int>(lessonId);
    map['prompt'] = Variable<String>(prompt);
    map['choices_json'] = Variable<String>(choicesJson);
    map['correct_index'] = Variable<int>(correctIndex);
    if (!nullToAbsent || purgedAtMs != null) {
      map['purged_at_ms'] = Variable<int>(purgedAtMs);
    }
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      id: Value(id),
      lessonId: Value(lessonId),
      prompt: Value(prompt),
      choicesJson: Value(choicesJson),
      correctIndex: Value(correctIndex),
      purgedAtMs: purgedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(purgedAtMs),
    );
  }

  factory QuestionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuestionRow(
      id: serializer.fromJson<int>(json['id']),
      lessonId: serializer.fromJson<int>(json['lessonId']),
      prompt: serializer.fromJson<String>(json['prompt']),
      choicesJson: serializer.fromJson<String>(json['choicesJson']),
      correctIndex: serializer.fromJson<int>(json['correctIndex']),
      purgedAtMs: serializer.fromJson<int?>(json['purgedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lessonId': serializer.toJson<int>(lessonId),
      'prompt': serializer.toJson<String>(prompt),
      'choicesJson': serializer.toJson<String>(choicesJson),
      'correctIndex': serializer.toJson<int>(correctIndex),
      'purgedAtMs': serializer.toJson<int?>(purgedAtMs),
    };
  }

  QuestionRow copyWith({
    int? id,
    int? lessonId,
    String? prompt,
    String? choicesJson,
    int? correctIndex,
    Value<int?> purgedAtMs = const Value.absent(),
  }) => QuestionRow(
    id: id ?? this.id,
    lessonId: lessonId ?? this.lessonId,
    prompt: prompt ?? this.prompt,
    choicesJson: choicesJson ?? this.choicesJson,
    correctIndex: correctIndex ?? this.correctIndex,
    purgedAtMs: purgedAtMs.present ? purgedAtMs.value : this.purgedAtMs,
  );
  QuestionRow copyWithCompanion(QuestionsCompanion data) {
    return QuestionRow(
      id: data.id.present ? data.id.value : this.id,
      lessonId: data.lessonId.present ? data.lessonId.value : this.lessonId,
      prompt: data.prompt.present ? data.prompt.value : this.prompt,
      choicesJson: data.choicesJson.present
          ? data.choicesJson.value
          : this.choicesJson,
      correctIndex: data.correctIndex.present
          ? data.correctIndex.value
          : this.correctIndex,
      purgedAtMs: data.purgedAtMs.present
          ? data.purgedAtMs.value
          : this.purgedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuestionRow(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('prompt: $prompt, ')
          ..write('choicesJson: $choicesJson, ')
          ..write('correctIndex: $correctIndex, ')
          ..write('purgedAtMs: $purgedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, lessonId, prompt, choicesJson, correctIndex, purgedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuestionRow &&
          other.id == this.id &&
          other.lessonId == this.lessonId &&
          other.prompt == this.prompt &&
          other.choicesJson == this.choicesJson &&
          other.correctIndex == this.correctIndex &&
          other.purgedAtMs == this.purgedAtMs);
}

class QuestionsCompanion extends UpdateCompanion<QuestionRow> {
  final Value<int> id;
  final Value<int> lessonId;
  final Value<String> prompt;
  final Value<String> choicesJson;
  final Value<int> correctIndex;
  final Value<int?> purgedAtMs;
  const QuestionsCompanion({
    this.id = const Value.absent(),
    this.lessonId = const Value.absent(),
    this.prompt = const Value.absent(),
    this.choicesJson = const Value.absent(),
    this.correctIndex = const Value.absent(),
    this.purgedAtMs = const Value.absent(),
  });
  QuestionsCompanion.insert({
    this.id = const Value.absent(),
    required int lessonId,
    required String prompt,
    required String choicesJson,
    required int correctIndex,
    this.purgedAtMs = const Value.absent(),
  }) : lessonId = Value(lessonId),
       prompt = Value(prompt),
       choicesJson = Value(choicesJson),
       correctIndex = Value(correctIndex);
  static Insertable<QuestionRow> custom({
    Expression<int>? id,
    Expression<int>? lessonId,
    Expression<String>? prompt,
    Expression<String>? choicesJson,
    Expression<int>? correctIndex,
    Expression<int>? purgedAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lessonId != null) 'lesson_id': lessonId,
      if (prompt != null) 'prompt': prompt,
      if (choicesJson != null) 'choices_json': choicesJson,
      if (correctIndex != null) 'correct_index': correctIndex,
      if (purgedAtMs != null) 'purged_at_ms': purgedAtMs,
    });
  }

  QuestionsCompanion copyWith({
    Value<int>? id,
    Value<int>? lessonId,
    Value<String>? prompt,
    Value<String>? choicesJson,
    Value<int>? correctIndex,
    Value<int?>? purgedAtMs,
  }) {
    return QuestionsCompanion(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      prompt: prompt ?? this.prompt,
      choicesJson: choicesJson ?? this.choicesJson,
      correctIndex: correctIndex ?? this.correctIndex,
      purgedAtMs: purgedAtMs ?? this.purgedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lessonId.present) {
      map['lesson_id'] = Variable<int>(lessonId.value);
    }
    if (prompt.present) {
      map['prompt'] = Variable<String>(prompt.value);
    }
    if (choicesJson.present) {
      map['choices_json'] = Variable<String>(choicesJson.value);
    }
    if (correctIndex.present) {
      map['correct_index'] = Variable<int>(correctIndex.value);
    }
    if (purgedAtMs.present) {
      map['purged_at_ms'] = Variable<int>(purgedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('id: $id, ')
          ..write('lessonId: $lessonId, ')
          ..write('prompt: $prompt, ')
          ..write('choicesJson: $choicesJson, ')
          ..write('correctIndex: $correctIndex, ')
          ..write('purgedAtMs: $purgedAtMs')
          ..write(')'))
        .toString();
  }
}

class $TaskInstancesTable extends TaskInstances
    with TableInfo<$TaskInstancesTable, TaskInstanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskInstancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<int> dayKey = GeneratedColumn<int>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TaskKind>($TaskInstancesTable.$converterkind);
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<int> targetId = GeneratedColumn<int>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskState, int> state =
      GeneratedColumn<int>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<TaskState>($TaskInstancesTable.$converterstate);
  static const VerificationMeta _answeredAtMsMeta = const VerificationMeta(
    'answeredAtMs',
  );
  @override
  late final GeneratedColumn<int> answeredAtMs = GeneratedColumn<int>(
    'answered_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayKey,
    kind,
    targetId,
    position,
    state,
    answeredAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'task_instances';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskInstanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('answered_at_ms')) {
      context.handle(
        _answeredAtMsMeta,
        answeredAtMs.isAcceptableOrUnknown(
          data['answered_at_ms']!,
          _answeredAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskInstanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskInstanceRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_key'],
      )!,
      kind: $TaskInstancesTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      state: $TaskInstancesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}state'],
        )!,
      ),
      answeredAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}answered_at_ms'],
      ),
    );
  }

  @override
  $TaskInstancesTable createAlias(String alias) {
    return $TaskInstancesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskKind, int, int> $converterkind =
      const EnumIndexConverter<TaskKind>(TaskKind.values);
  static JsonTypeConverter2<TaskState, int, int> $converterstate =
      const EnumIndexConverter<TaskState>(TaskState.values);
}

class TaskInstanceRow extends DataClass implements Insertable<TaskInstanceRow> {
  final int id;
  final int dayKey;
  final TaskKind kind;

  /// Card id or question id, depending on [kind].
  final int targetId;
  final int position;
  final TaskState state;
  final int? answeredAtMs;
  const TaskInstanceRow({
    required this.id,
    required this.dayKey,
    required this.kind,
    required this.targetId,
    required this.position,
    required this.state,
    this.answeredAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_key'] = Variable<int>(dayKey);
    {
      map['kind'] = Variable<int>(
        $TaskInstancesTable.$converterkind.toSql(kind),
      );
    }
    map['target_id'] = Variable<int>(targetId);
    map['position'] = Variable<int>(position);
    {
      map['state'] = Variable<int>(
        $TaskInstancesTable.$converterstate.toSql(state),
      );
    }
    if (!nullToAbsent || answeredAtMs != null) {
      map['answered_at_ms'] = Variable<int>(answeredAtMs);
    }
    return map;
  }

  TaskInstancesCompanion toCompanion(bool nullToAbsent) {
    return TaskInstancesCompanion(
      id: Value(id),
      dayKey: Value(dayKey),
      kind: Value(kind),
      targetId: Value(targetId),
      position: Value(position),
      state: Value(state),
      answeredAtMs: answeredAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(answeredAtMs),
    );
  }

  factory TaskInstanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskInstanceRow(
      id: serializer.fromJson<int>(json['id']),
      dayKey: serializer.fromJson<int>(json['dayKey']),
      kind: $TaskInstancesTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
      targetId: serializer.fromJson<int>(json['targetId']),
      position: serializer.fromJson<int>(json['position']),
      state: $TaskInstancesTable.$converterstate.fromJson(
        serializer.fromJson<int>(json['state']),
      ),
      answeredAtMs: serializer.fromJson<int?>(json['answeredAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayKey': serializer.toJson<int>(dayKey),
      'kind': serializer.toJson<int>(
        $TaskInstancesTable.$converterkind.toJson(kind),
      ),
      'targetId': serializer.toJson<int>(targetId),
      'position': serializer.toJson<int>(position),
      'state': serializer.toJson<int>(
        $TaskInstancesTable.$converterstate.toJson(state),
      ),
      'answeredAtMs': serializer.toJson<int?>(answeredAtMs),
    };
  }

  TaskInstanceRow copyWith({
    int? id,
    int? dayKey,
    TaskKind? kind,
    int? targetId,
    int? position,
    TaskState? state,
    Value<int?> answeredAtMs = const Value.absent(),
  }) => TaskInstanceRow(
    id: id ?? this.id,
    dayKey: dayKey ?? this.dayKey,
    kind: kind ?? this.kind,
    targetId: targetId ?? this.targetId,
    position: position ?? this.position,
    state: state ?? this.state,
    answeredAtMs: answeredAtMs.present ? answeredAtMs.value : this.answeredAtMs,
  );
  TaskInstanceRow copyWithCompanion(TaskInstancesCompanion data) {
    return TaskInstanceRow(
      id: data.id.present ? data.id.value : this.id,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      position: data.position.present ? data.position.value : this.position,
      state: data.state.present ? data.state.value : this.state,
      answeredAtMs: data.answeredAtMs.present
          ? data.answeredAtMs.value
          : this.answeredAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskInstanceRow(')
          ..write('id: $id, ')
          ..write('dayKey: $dayKey, ')
          ..write('kind: $kind, ')
          ..write('targetId: $targetId, ')
          ..write('position: $position, ')
          ..write('state: $state, ')
          ..write('answeredAtMs: $answeredAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, dayKey, kind, targetId, position, state, answeredAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskInstanceRow &&
          other.id == this.id &&
          other.dayKey == this.dayKey &&
          other.kind == this.kind &&
          other.targetId == this.targetId &&
          other.position == this.position &&
          other.state == this.state &&
          other.answeredAtMs == this.answeredAtMs);
}

class TaskInstancesCompanion extends UpdateCompanion<TaskInstanceRow> {
  final Value<int> id;
  final Value<int> dayKey;
  final Value<TaskKind> kind;
  final Value<int> targetId;
  final Value<int> position;
  final Value<TaskState> state;
  final Value<int?> answeredAtMs;
  const TaskInstancesCompanion({
    this.id = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.targetId = const Value.absent(),
    this.position = const Value.absent(),
    this.state = const Value.absent(),
    this.answeredAtMs = const Value.absent(),
  });
  TaskInstancesCompanion.insert({
    this.id = const Value.absent(),
    required int dayKey,
    required TaskKind kind,
    required int targetId,
    required int position,
    this.state = const Value.absent(),
    this.answeredAtMs = const Value.absent(),
  }) : dayKey = Value(dayKey),
       kind = Value(kind),
       targetId = Value(targetId),
       position = Value(position);
  static Insertable<TaskInstanceRow> custom({
    Expression<int>? id,
    Expression<int>? dayKey,
    Expression<int>? kind,
    Expression<int>? targetId,
    Expression<int>? position,
    Expression<int>? state,
    Expression<int>? answeredAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayKey != null) 'day_key': dayKey,
      if (kind != null) 'kind': kind,
      if (targetId != null) 'target_id': targetId,
      if (position != null) 'position': position,
      if (state != null) 'state': state,
      if (answeredAtMs != null) 'answered_at_ms': answeredAtMs,
    });
  }

  TaskInstancesCompanion copyWith({
    Value<int>? id,
    Value<int>? dayKey,
    Value<TaskKind>? kind,
    Value<int>? targetId,
    Value<int>? position,
    Value<TaskState>? state,
    Value<int?>? answeredAtMs,
  }) {
    return TaskInstancesCompanion(
      id: id ?? this.id,
      dayKey: dayKey ?? this.dayKey,
      kind: kind ?? this.kind,
      targetId: targetId ?? this.targetId,
      position: position ?? this.position,
      state: state ?? this.state,
      answeredAtMs: answeredAtMs ?? this.answeredAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<int>(dayKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $TaskInstancesTable.$converterkind.toSql(kind.value),
      );
    }
    if (targetId.present) {
      map['target_id'] = Variable<int>(targetId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(
        $TaskInstancesTable.$converterstate.toSql(state.value),
      );
    }
    if (answeredAtMs.present) {
      map['answered_at_ms'] = Variable<int>(answeredAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskInstancesCompanion(')
          ..write('id: $id, ')
          ..write('dayKey: $dayKey, ')
          ..write('kind: $kind, ')
          ..write('targetId: $targetId, ')
          ..write('position: $position, ')
          ..write('state: $state, ')
          ..write('answeredAtMs: $answeredAtMs')
          ..write(')'))
        .toString();
  }
}

class $AttemptsTable extends Attempts
    with TableInfo<$AttemptsTable, AttemptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<int> dayKey = GeneratedColumn<int>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TaskKind>($AttemptsTable.$converterkind);
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<int> targetId = GeneratedColumn<int>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptNumberMeta = const VerificationMeta(
    'attemptNumber',
  );
  @override
  late final GeneratedColumn<int> attemptNumber = GeneratedColumn<int>(
    'attempt_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<bool> correct = GeneratedColumn<bool>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _msOnTargetMeta = const VerificationMeta(
    'msOnTarget',
  );
  @override
  late final GeneratedColumn<int> msOnTarget = GeneratedColumn<int>(
    'ms_on_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _solutionRevealedMeta = const VerificationMeta(
    'solutionRevealed',
  );
  @override
  late final GeneratedColumn<bool> solutionRevealed = GeneratedColumn<bool>(
    'solution_revealed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("solution_revealed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _awardedUnitsMeta = const VerificationMeta(
    'awardedUnits',
  );
  @override
  late final GeneratedColumn<int> awardedUnits = GeneratedColumn<int>(
    'awarded_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<RejectionRow, int> rejection =
      GeneratedColumn<int>(
        'rejection',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<RejectionRow>($AttemptsTable.$converterrejection);
  static const VerificationMeta _cappedByCeilingMeta = const VerificationMeta(
    'cappedByCeiling',
  );
  @override
  late final GeneratedColumn<bool> cappedByCeiling = GeneratedColumn<bool>(
    'capped_by_ceiling',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("capped_by_ceiling" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _atMsMeta = const VerificationMeta('atMs');
  @override
  late final GeneratedColumn<int> atMs = GeneratedColumn<int>(
    'at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TrustLevelRow, int> trustLevel =
      GeneratedColumn<int>(
        'trust_level',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TrustLevelRow>($AttemptsTable.$convertertrustLevel);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayKey,
    kind,
    targetId,
    attemptNumber,
    correct,
    msOnTarget,
    solutionRevealed,
    awardedUnits,
    rejection,
    cappedByCeiling,
    atMs,
    trustLevel,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttemptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('attempt_number')) {
      context.handle(
        _attemptNumberMeta,
        attemptNumber.isAcceptableOrUnknown(
          data['attempt_number']!,
          _attemptNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptNumberMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('ms_on_target')) {
      context.handle(
        _msOnTargetMeta,
        msOnTarget.isAcceptableOrUnknown(
          data['ms_on_target']!,
          _msOnTargetMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_msOnTargetMeta);
    }
    if (data.containsKey('solution_revealed')) {
      context.handle(
        _solutionRevealedMeta,
        solutionRevealed.isAcceptableOrUnknown(
          data['solution_revealed']!,
          _solutionRevealedMeta,
        ),
      );
    }
    if (data.containsKey('awarded_units')) {
      context.handle(
        _awardedUnitsMeta,
        awardedUnits.isAcceptableOrUnknown(
          data['awarded_units']!,
          _awardedUnitsMeta,
        ),
      );
    }
    if (data.containsKey('capped_by_ceiling')) {
      context.handle(
        _cappedByCeilingMeta,
        cappedByCeiling.isAcceptableOrUnknown(
          data['capped_by_ceiling']!,
          _cappedByCeilingMeta,
        ),
      );
    }
    if (data.containsKey('at_ms')) {
      context.handle(
        _atMsMeta,
        atMs.isAcceptableOrUnknown(data['at_ms']!, _atMsMeta),
      );
    } else if (isInserting) {
      context.missing(_atMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AttemptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttemptRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_key'],
      )!,
      kind: $AttemptsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_id'],
      )!,
      attemptNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_number'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}correct'],
      )!,
      msOnTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ms_on_target'],
      )!,
      solutionRevealed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}solution_revealed'],
      )!,
      awardedUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}awarded_units'],
      )!,
      rejection: $AttemptsTable.$converterrejection.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}rejection'],
        )!,
      ),
      cappedByCeiling: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}capped_by_ceiling'],
      )!,
      atMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_ms'],
      )!,
      trustLevel: $AttemptsTable.$convertertrustLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}trust_level'],
        )!,
      ),
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskKind, int, int> $converterkind =
      const EnumIndexConverter<TaskKind>(TaskKind.values);
  static JsonTypeConverter2<RejectionRow, int, int> $converterrejection =
      const EnumIndexConverter<RejectionRow>(RejectionRow.values);
  static JsonTypeConverter2<TrustLevelRow, int, int> $convertertrustLevel =
      const EnumIndexConverter<TrustLevelRow>(TrustLevelRow.values);
}

class AttemptRow extends DataClass implements Insertable<AttemptRow> {
  final int id;
  final int dayKey;
  final TaskKind kind;
  final int targetId;
  final int attemptNumber;
  final bool correct;
  final int msOnTarget;
  final bool solutionRevealed;
  final int awardedUnits;
  final RejectionRow rejection;
  final bool cappedByCeiling;
  final int atMs;
  final TrustLevelRow trustLevel;
  const AttemptRow({
    required this.id,
    required this.dayKey,
    required this.kind,
    required this.targetId,
    required this.attemptNumber,
    required this.correct,
    required this.msOnTarget,
    required this.solutionRevealed,
    required this.awardedUnits,
    required this.rejection,
    required this.cappedByCeiling,
    required this.atMs,
    required this.trustLevel,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_key'] = Variable<int>(dayKey);
    {
      map['kind'] = Variable<int>($AttemptsTable.$converterkind.toSql(kind));
    }
    map['target_id'] = Variable<int>(targetId);
    map['attempt_number'] = Variable<int>(attemptNumber);
    map['correct'] = Variable<bool>(correct);
    map['ms_on_target'] = Variable<int>(msOnTarget);
    map['solution_revealed'] = Variable<bool>(solutionRevealed);
    map['awarded_units'] = Variable<int>(awardedUnits);
    {
      map['rejection'] = Variable<int>(
        $AttemptsTable.$converterrejection.toSql(rejection),
      );
    }
    map['capped_by_ceiling'] = Variable<bool>(cappedByCeiling);
    map['at_ms'] = Variable<int>(atMs);
    {
      map['trust_level'] = Variable<int>(
        $AttemptsTable.$convertertrustLevel.toSql(trustLevel),
      );
    }
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      id: Value(id),
      dayKey: Value(dayKey),
      kind: Value(kind),
      targetId: Value(targetId),
      attemptNumber: Value(attemptNumber),
      correct: Value(correct),
      msOnTarget: Value(msOnTarget),
      solutionRevealed: Value(solutionRevealed),
      awardedUnits: Value(awardedUnits),
      rejection: Value(rejection),
      cappedByCeiling: Value(cappedByCeiling),
      atMs: Value(atMs),
      trustLevel: Value(trustLevel),
    );
  }

  factory AttemptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttemptRow(
      id: serializer.fromJson<int>(json['id']),
      dayKey: serializer.fromJson<int>(json['dayKey']),
      kind: $AttemptsTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
      targetId: serializer.fromJson<int>(json['targetId']),
      attemptNumber: serializer.fromJson<int>(json['attemptNumber']),
      correct: serializer.fromJson<bool>(json['correct']),
      msOnTarget: serializer.fromJson<int>(json['msOnTarget']),
      solutionRevealed: serializer.fromJson<bool>(json['solutionRevealed']),
      awardedUnits: serializer.fromJson<int>(json['awardedUnits']),
      rejection: $AttemptsTable.$converterrejection.fromJson(
        serializer.fromJson<int>(json['rejection']),
      ),
      cappedByCeiling: serializer.fromJson<bool>(json['cappedByCeiling']),
      atMs: serializer.fromJson<int>(json['atMs']),
      trustLevel: $AttemptsTable.$convertertrustLevel.fromJson(
        serializer.fromJson<int>(json['trustLevel']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayKey': serializer.toJson<int>(dayKey),
      'kind': serializer.toJson<int>(
        $AttemptsTable.$converterkind.toJson(kind),
      ),
      'targetId': serializer.toJson<int>(targetId),
      'attemptNumber': serializer.toJson<int>(attemptNumber),
      'correct': serializer.toJson<bool>(correct),
      'msOnTarget': serializer.toJson<int>(msOnTarget),
      'solutionRevealed': serializer.toJson<bool>(solutionRevealed),
      'awardedUnits': serializer.toJson<int>(awardedUnits),
      'rejection': serializer.toJson<int>(
        $AttemptsTable.$converterrejection.toJson(rejection),
      ),
      'cappedByCeiling': serializer.toJson<bool>(cappedByCeiling),
      'atMs': serializer.toJson<int>(atMs),
      'trustLevel': serializer.toJson<int>(
        $AttemptsTable.$convertertrustLevel.toJson(trustLevel),
      ),
    };
  }

  AttemptRow copyWith({
    int? id,
    int? dayKey,
    TaskKind? kind,
    int? targetId,
    int? attemptNumber,
    bool? correct,
    int? msOnTarget,
    bool? solutionRevealed,
    int? awardedUnits,
    RejectionRow? rejection,
    bool? cappedByCeiling,
    int? atMs,
    TrustLevelRow? trustLevel,
  }) => AttemptRow(
    id: id ?? this.id,
    dayKey: dayKey ?? this.dayKey,
    kind: kind ?? this.kind,
    targetId: targetId ?? this.targetId,
    attemptNumber: attemptNumber ?? this.attemptNumber,
    correct: correct ?? this.correct,
    msOnTarget: msOnTarget ?? this.msOnTarget,
    solutionRevealed: solutionRevealed ?? this.solutionRevealed,
    awardedUnits: awardedUnits ?? this.awardedUnits,
    rejection: rejection ?? this.rejection,
    cappedByCeiling: cappedByCeiling ?? this.cappedByCeiling,
    atMs: atMs ?? this.atMs,
    trustLevel: trustLevel ?? this.trustLevel,
  );
  AttemptRow copyWithCompanion(AttemptsCompanion data) {
    return AttemptRow(
      id: data.id.present ? data.id.value : this.id,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      attemptNumber: data.attemptNumber.present
          ? data.attemptNumber.value
          : this.attemptNumber,
      correct: data.correct.present ? data.correct.value : this.correct,
      msOnTarget: data.msOnTarget.present
          ? data.msOnTarget.value
          : this.msOnTarget,
      solutionRevealed: data.solutionRevealed.present
          ? data.solutionRevealed.value
          : this.solutionRevealed,
      awardedUnits: data.awardedUnits.present
          ? data.awardedUnits.value
          : this.awardedUnits,
      rejection: data.rejection.present ? data.rejection.value : this.rejection,
      cappedByCeiling: data.cappedByCeiling.present
          ? data.cappedByCeiling.value
          : this.cappedByCeiling,
      atMs: data.atMs.present ? data.atMs.value : this.atMs,
      trustLevel: data.trustLevel.present
          ? data.trustLevel.value
          : this.trustLevel,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttemptRow(')
          ..write('id: $id, ')
          ..write('dayKey: $dayKey, ')
          ..write('kind: $kind, ')
          ..write('targetId: $targetId, ')
          ..write('attemptNumber: $attemptNumber, ')
          ..write('correct: $correct, ')
          ..write('msOnTarget: $msOnTarget, ')
          ..write('solutionRevealed: $solutionRevealed, ')
          ..write('awardedUnits: $awardedUnits, ')
          ..write('rejection: $rejection, ')
          ..write('cappedByCeiling: $cappedByCeiling, ')
          ..write('atMs: $atMs, ')
          ..write('trustLevel: $trustLevel')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayKey,
    kind,
    targetId,
    attemptNumber,
    correct,
    msOnTarget,
    solutionRevealed,
    awardedUnits,
    rejection,
    cappedByCeiling,
    atMs,
    trustLevel,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttemptRow &&
          other.id == this.id &&
          other.dayKey == this.dayKey &&
          other.kind == this.kind &&
          other.targetId == this.targetId &&
          other.attemptNumber == this.attemptNumber &&
          other.correct == this.correct &&
          other.msOnTarget == this.msOnTarget &&
          other.solutionRevealed == this.solutionRevealed &&
          other.awardedUnits == this.awardedUnits &&
          other.rejection == this.rejection &&
          other.cappedByCeiling == this.cappedByCeiling &&
          other.atMs == this.atMs &&
          other.trustLevel == this.trustLevel);
}

class AttemptsCompanion extends UpdateCompanion<AttemptRow> {
  final Value<int> id;
  final Value<int> dayKey;
  final Value<TaskKind> kind;
  final Value<int> targetId;
  final Value<int> attemptNumber;
  final Value<bool> correct;
  final Value<int> msOnTarget;
  final Value<bool> solutionRevealed;
  final Value<int> awardedUnits;
  final Value<RejectionRow> rejection;
  final Value<bool> cappedByCeiling;
  final Value<int> atMs;
  final Value<TrustLevelRow> trustLevel;
  const AttemptsCompanion({
    this.id = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.targetId = const Value.absent(),
    this.attemptNumber = const Value.absent(),
    this.correct = const Value.absent(),
    this.msOnTarget = const Value.absent(),
    this.solutionRevealed = const Value.absent(),
    this.awardedUnits = const Value.absent(),
    this.rejection = const Value.absent(),
    this.cappedByCeiling = const Value.absent(),
    this.atMs = const Value.absent(),
    this.trustLevel = const Value.absent(),
  });
  AttemptsCompanion.insert({
    this.id = const Value.absent(),
    required int dayKey,
    required TaskKind kind,
    required int targetId,
    required int attemptNumber,
    required bool correct,
    required int msOnTarget,
    this.solutionRevealed = const Value.absent(),
    this.awardedUnits = const Value.absent(),
    this.rejection = const Value.absent(),
    this.cappedByCeiling = const Value.absent(),
    required int atMs,
    required TrustLevelRow trustLevel,
  }) : dayKey = Value(dayKey),
       kind = Value(kind),
       targetId = Value(targetId),
       attemptNumber = Value(attemptNumber),
       correct = Value(correct),
       msOnTarget = Value(msOnTarget),
       atMs = Value(atMs),
       trustLevel = Value(trustLevel);
  static Insertable<AttemptRow> custom({
    Expression<int>? id,
    Expression<int>? dayKey,
    Expression<int>? kind,
    Expression<int>? targetId,
    Expression<int>? attemptNumber,
    Expression<bool>? correct,
    Expression<int>? msOnTarget,
    Expression<bool>? solutionRevealed,
    Expression<int>? awardedUnits,
    Expression<int>? rejection,
    Expression<bool>? cappedByCeiling,
    Expression<int>? atMs,
    Expression<int>? trustLevel,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayKey != null) 'day_key': dayKey,
      if (kind != null) 'kind': kind,
      if (targetId != null) 'target_id': targetId,
      if (attemptNumber != null) 'attempt_number': attemptNumber,
      if (correct != null) 'correct': correct,
      if (msOnTarget != null) 'ms_on_target': msOnTarget,
      if (solutionRevealed != null) 'solution_revealed': solutionRevealed,
      if (awardedUnits != null) 'awarded_units': awardedUnits,
      if (rejection != null) 'rejection': rejection,
      if (cappedByCeiling != null) 'capped_by_ceiling': cappedByCeiling,
      if (atMs != null) 'at_ms': atMs,
      if (trustLevel != null) 'trust_level': trustLevel,
    });
  }

  AttemptsCompanion copyWith({
    Value<int>? id,
    Value<int>? dayKey,
    Value<TaskKind>? kind,
    Value<int>? targetId,
    Value<int>? attemptNumber,
    Value<bool>? correct,
    Value<int>? msOnTarget,
    Value<bool>? solutionRevealed,
    Value<int>? awardedUnits,
    Value<RejectionRow>? rejection,
    Value<bool>? cappedByCeiling,
    Value<int>? atMs,
    Value<TrustLevelRow>? trustLevel,
  }) {
    return AttemptsCompanion(
      id: id ?? this.id,
      dayKey: dayKey ?? this.dayKey,
      kind: kind ?? this.kind,
      targetId: targetId ?? this.targetId,
      attemptNumber: attemptNumber ?? this.attemptNumber,
      correct: correct ?? this.correct,
      msOnTarget: msOnTarget ?? this.msOnTarget,
      solutionRevealed: solutionRevealed ?? this.solutionRevealed,
      awardedUnits: awardedUnits ?? this.awardedUnits,
      rejection: rejection ?? this.rejection,
      cappedByCeiling: cappedByCeiling ?? this.cappedByCeiling,
      atMs: atMs ?? this.atMs,
      trustLevel: trustLevel ?? this.trustLevel,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<int>(dayKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $AttemptsTable.$converterkind.toSql(kind.value),
      );
    }
    if (targetId.present) {
      map['target_id'] = Variable<int>(targetId.value);
    }
    if (attemptNumber.present) {
      map['attempt_number'] = Variable<int>(attemptNumber.value);
    }
    if (correct.present) {
      map['correct'] = Variable<bool>(correct.value);
    }
    if (msOnTarget.present) {
      map['ms_on_target'] = Variable<int>(msOnTarget.value);
    }
    if (solutionRevealed.present) {
      map['solution_revealed'] = Variable<bool>(solutionRevealed.value);
    }
    if (awardedUnits.present) {
      map['awarded_units'] = Variable<int>(awardedUnits.value);
    }
    if (rejection.present) {
      map['rejection'] = Variable<int>(
        $AttemptsTable.$converterrejection.toSql(rejection.value),
      );
    }
    if (cappedByCeiling.present) {
      map['capped_by_ceiling'] = Variable<bool>(cappedByCeiling.value);
    }
    if (atMs.present) {
      map['at_ms'] = Variable<int>(atMs.value);
    }
    if (trustLevel.present) {
      map['trust_level'] = Variable<int>(
        $AttemptsTable.$convertertrustLevel.toSql(trustLevel.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('id: $id, ')
          ..write('dayKey: $dayKey, ')
          ..write('kind: $kind, ')
          ..write('targetId: $targetId, ')
          ..write('attemptNumber: $attemptNumber, ')
          ..write('correct: $correct, ')
          ..write('msOnTarget: $msOnTarget, ')
          ..write('solutionRevealed: $solutionRevealed, ')
          ..write('awardedUnits: $awardedUnits, ')
          ..write('rejection: $rejection, ')
          ..write('cappedByCeiling: $cappedByCeiling, ')
          ..write('atMs: $atMs, ')
          ..write('trustLevel: $trustLevel')
          ..write(')'))
        .toString();
  }
}

class $StarLedgerTable extends StarLedger
    with TableInfo<$StarLedgerTable, StarLedgerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StarLedgerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<int> dayKey = GeneratedColumn<int>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LedgerKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<LedgerKind>($StarLedgerTable.$converterkind);
  static const VerificationMeta _starUnitsMeta = const VerificationMeta(
    'starUnits',
  );
  @override
  late final GeneratedColumn<int> starUnits = GeneratedColumn<int>(
    'star_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceAfterUnitsMeta = const VerificationMeta(
    'balanceAfterUnits',
  );
  @override
  late final GeneratedColumn<int> balanceAfterUnits = GeneratedColumn<int>(
    'balance_after_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceRefMeta = const VerificationMeta(
    'sourceRef',
  );
  @override
  late final GeneratedColumn<int> sourceRef = GeneratedColumn<int>(
    'source_ref',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMsMeta = const VerificationMeta('atMs');
  @override
  late final GeneratedColumn<int> atMs = GeneratedColumn<int>(
    'at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TrustLevelRow, int> trustLevel =
      GeneratedColumn<int>(
        'trust_level',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TrustLevelRow>($StarLedgerTable.$convertertrustLevel);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayKey,
    kind,
    starUnits,
    balanceAfterUnits,
    sourceRef,
    atMs,
    trustLevel,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'star_ledger';
  @override
  VerificationContext validateIntegrity(
    Insertable<StarLedgerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('star_units')) {
      context.handle(
        _starUnitsMeta,
        starUnits.isAcceptableOrUnknown(data['star_units']!, _starUnitsMeta),
      );
    } else if (isInserting) {
      context.missing(_starUnitsMeta);
    }
    if (data.containsKey('balance_after_units')) {
      context.handle(
        _balanceAfterUnitsMeta,
        balanceAfterUnits.isAcceptableOrUnknown(
          data['balance_after_units']!,
          _balanceAfterUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_balanceAfterUnitsMeta);
    }
    if (data.containsKey('source_ref')) {
      context.handle(
        _sourceRefMeta,
        sourceRef.isAcceptableOrUnknown(data['source_ref']!, _sourceRefMeta),
      );
    }
    if (data.containsKey('at_ms')) {
      context.handle(
        _atMsMeta,
        atMs.isAcceptableOrUnknown(data['at_ms']!, _atMsMeta),
      );
    } else if (isInserting) {
      context.missing(_atMsMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StarLedgerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StarLedgerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_key'],
      )!,
      kind: $StarLedgerTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
      starUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}star_units'],
      )!,
      balanceAfterUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_after_units'],
      )!,
      sourceRef: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_ref'],
      ),
      atMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_ms'],
      )!,
      trustLevel: $StarLedgerTable.$convertertrustLevel.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}trust_level'],
        )!,
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $StarLedgerTable createAlias(String alias) {
    return $StarLedgerTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LedgerKind, int, int> $converterkind =
      const EnumIndexConverter<LedgerKind>(LedgerKind.values);
  static JsonTypeConverter2<TrustLevelRow, int, int> $convertertrustLevel =
      const EnumIndexConverter<TrustLevelRow>(TrustLevelRow.values);
}

class StarLedgerRow extends DataClass implements Insertable<StarLedgerRow> {
  final int id;
  final int dayKey;
  final LedgerKind kind;

  /// Signed: positive for an award, negative for a deduction or expiry.
  final int starUnits;
  final int balanceAfterUnits;

  /// Card id, question id, weekly-test id, or null for a parent action.
  final int? sourceRef;
  final int atMs;
  final TrustLevelRow trustLevel;
  final String note;
  const StarLedgerRow({
    required this.id,
    required this.dayKey,
    required this.kind,
    required this.starUnits,
    required this.balanceAfterUnits,
    this.sourceRef,
    required this.atMs,
    required this.trustLevel,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_key'] = Variable<int>(dayKey);
    {
      map['kind'] = Variable<int>($StarLedgerTable.$converterkind.toSql(kind));
    }
    map['star_units'] = Variable<int>(starUnits);
    map['balance_after_units'] = Variable<int>(balanceAfterUnits);
    if (!nullToAbsent || sourceRef != null) {
      map['source_ref'] = Variable<int>(sourceRef);
    }
    map['at_ms'] = Variable<int>(atMs);
    {
      map['trust_level'] = Variable<int>(
        $StarLedgerTable.$convertertrustLevel.toSql(trustLevel),
      );
    }
    map['note'] = Variable<String>(note);
    return map;
  }

  StarLedgerCompanion toCompanion(bool nullToAbsent) {
    return StarLedgerCompanion(
      id: Value(id),
      dayKey: Value(dayKey),
      kind: Value(kind),
      starUnits: Value(starUnits),
      balanceAfterUnits: Value(balanceAfterUnits),
      sourceRef: sourceRef == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceRef),
      atMs: Value(atMs),
      trustLevel: Value(trustLevel),
      note: Value(note),
    );
  }

  factory StarLedgerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StarLedgerRow(
      id: serializer.fromJson<int>(json['id']),
      dayKey: serializer.fromJson<int>(json['dayKey']),
      kind: $StarLedgerTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
      starUnits: serializer.fromJson<int>(json['starUnits']),
      balanceAfterUnits: serializer.fromJson<int>(json['balanceAfterUnits']),
      sourceRef: serializer.fromJson<int?>(json['sourceRef']),
      atMs: serializer.fromJson<int>(json['atMs']),
      trustLevel: $StarLedgerTable.$convertertrustLevel.fromJson(
        serializer.fromJson<int>(json['trustLevel']),
      ),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayKey': serializer.toJson<int>(dayKey),
      'kind': serializer.toJson<int>(
        $StarLedgerTable.$converterkind.toJson(kind),
      ),
      'starUnits': serializer.toJson<int>(starUnits),
      'balanceAfterUnits': serializer.toJson<int>(balanceAfterUnits),
      'sourceRef': serializer.toJson<int?>(sourceRef),
      'atMs': serializer.toJson<int>(atMs),
      'trustLevel': serializer.toJson<int>(
        $StarLedgerTable.$convertertrustLevel.toJson(trustLevel),
      ),
      'note': serializer.toJson<String>(note),
    };
  }

  StarLedgerRow copyWith({
    int? id,
    int? dayKey,
    LedgerKind? kind,
    int? starUnits,
    int? balanceAfterUnits,
    Value<int?> sourceRef = const Value.absent(),
    int? atMs,
    TrustLevelRow? trustLevel,
    String? note,
  }) => StarLedgerRow(
    id: id ?? this.id,
    dayKey: dayKey ?? this.dayKey,
    kind: kind ?? this.kind,
    starUnits: starUnits ?? this.starUnits,
    balanceAfterUnits: balanceAfterUnits ?? this.balanceAfterUnits,
    sourceRef: sourceRef.present ? sourceRef.value : this.sourceRef,
    atMs: atMs ?? this.atMs,
    trustLevel: trustLevel ?? this.trustLevel,
    note: note ?? this.note,
  );
  StarLedgerRow copyWithCompanion(StarLedgerCompanion data) {
    return StarLedgerRow(
      id: data.id.present ? data.id.value : this.id,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      starUnits: data.starUnits.present ? data.starUnits.value : this.starUnits,
      balanceAfterUnits: data.balanceAfterUnits.present
          ? data.balanceAfterUnits.value
          : this.balanceAfterUnits,
      sourceRef: data.sourceRef.present ? data.sourceRef.value : this.sourceRef,
      atMs: data.atMs.present ? data.atMs.value : this.atMs,
      trustLevel: data.trustLevel.present
          ? data.trustLevel.value
          : this.trustLevel,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StarLedgerRow(')
          ..write('id: $id, ')
          ..write('dayKey: $dayKey, ')
          ..write('kind: $kind, ')
          ..write('starUnits: $starUnits, ')
          ..write('balanceAfterUnits: $balanceAfterUnits, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('atMs: $atMs, ')
          ..write('trustLevel: $trustLevel, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayKey,
    kind,
    starUnits,
    balanceAfterUnits,
    sourceRef,
    atMs,
    trustLevel,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StarLedgerRow &&
          other.id == this.id &&
          other.dayKey == this.dayKey &&
          other.kind == this.kind &&
          other.starUnits == this.starUnits &&
          other.balanceAfterUnits == this.balanceAfterUnits &&
          other.sourceRef == this.sourceRef &&
          other.atMs == this.atMs &&
          other.trustLevel == this.trustLevel &&
          other.note == this.note);
}

class StarLedgerCompanion extends UpdateCompanion<StarLedgerRow> {
  final Value<int> id;
  final Value<int> dayKey;
  final Value<LedgerKind> kind;
  final Value<int> starUnits;
  final Value<int> balanceAfterUnits;
  final Value<int?> sourceRef;
  final Value<int> atMs;
  final Value<TrustLevelRow> trustLevel;
  final Value<String> note;
  const StarLedgerCompanion({
    this.id = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.starUnits = const Value.absent(),
    this.balanceAfterUnits = const Value.absent(),
    this.sourceRef = const Value.absent(),
    this.atMs = const Value.absent(),
    this.trustLevel = const Value.absent(),
    this.note = const Value.absent(),
  });
  StarLedgerCompanion.insert({
    this.id = const Value.absent(),
    required int dayKey,
    required LedgerKind kind,
    required int starUnits,
    required int balanceAfterUnits,
    this.sourceRef = const Value.absent(),
    required int atMs,
    required TrustLevelRow trustLevel,
    this.note = const Value.absent(),
  }) : dayKey = Value(dayKey),
       kind = Value(kind),
       starUnits = Value(starUnits),
       balanceAfterUnits = Value(balanceAfterUnits),
       atMs = Value(atMs),
       trustLevel = Value(trustLevel);
  static Insertable<StarLedgerRow> custom({
    Expression<int>? id,
    Expression<int>? dayKey,
    Expression<int>? kind,
    Expression<int>? starUnits,
    Expression<int>? balanceAfterUnits,
    Expression<int>? sourceRef,
    Expression<int>? atMs,
    Expression<int>? trustLevel,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayKey != null) 'day_key': dayKey,
      if (kind != null) 'kind': kind,
      if (starUnits != null) 'star_units': starUnits,
      if (balanceAfterUnits != null) 'balance_after_units': balanceAfterUnits,
      if (sourceRef != null) 'source_ref': sourceRef,
      if (atMs != null) 'at_ms': atMs,
      if (trustLevel != null) 'trust_level': trustLevel,
      if (note != null) 'note': note,
    });
  }

  StarLedgerCompanion copyWith({
    Value<int>? id,
    Value<int>? dayKey,
    Value<LedgerKind>? kind,
    Value<int>? starUnits,
    Value<int>? balanceAfterUnits,
    Value<int?>? sourceRef,
    Value<int>? atMs,
    Value<TrustLevelRow>? trustLevel,
    Value<String>? note,
  }) {
    return StarLedgerCompanion(
      id: id ?? this.id,
      dayKey: dayKey ?? this.dayKey,
      kind: kind ?? this.kind,
      starUnits: starUnits ?? this.starUnits,
      balanceAfterUnits: balanceAfterUnits ?? this.balanceAfterUnits,
      sourceRef: sourceRef ?? this.sourceRef,
      atMs: atMs ?? this.atMs,
      trustLevel: trustLevel ?? this.trustLevel,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<int>(dayKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $StarLedgerTable.$converterkind.toSql(kind.value),
      );
    }
    if (starUnits.present) {
      map['star_units'] = Variable<int>(starUnits.value);
    }
    if (balanceAfterUnits.present) {
      map['balance_after_units'] = Variable<int>(balanceAfterUnits.value);
    }
    if (sourceRef.present) {
      map['source_ref'] = Variable<int>(sourceRef.value);
    }
    if (atMs.present) {
      map['at_ms'] = Variable<int>(atMs.value);
    }
    if (trustLevel.present) {
      map['trust_level'] = Variable<int>(
        $StarLedgerTable.$convertertrustLevel.toSql(trustLevel.value),
      );
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StarLedgerCompanion(')
          ..write('id: $id, ')
          ..write('dayKey: $dayKey, ')
          ..write('kind: $kind, ')
          ..write('starUnits: $starUnits, ')
          ..write('balanceAfterUnits: $balanceAfterUnits, ')
          ..write('sourceRef: $sourceRef, ')
          ..write('atMs: $atMs, ')
          ..write('trustLevel: $trustLevel, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

class $DayProgressRowsTable extends DayProgressRows
    with TableInfo<$DayProgressRowsTable, DayProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayProgressRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<int> dayKey = GeneratedColumn<int>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _earnedUnitsMeta = const VerificationMeta(
    'earnedUnits',
  );
  @override
  late final GeneratedColumn<int> earnedUnits = GeneratedColumn<int>(
    'earned_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _grantedUnitsMeta = const VerificationMeta(
    'grantedUnits',
  );
  @override
  late final GeneratedColumn<int> grantedUnits = GeneratedColumn<int>(
    'granted_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _usedPlaySecondsMeta = const VerificationMeta(
    'usedPlaySeconds',
  );
  @override
  late final GeneratedColumn<int> usedPlaySeconds = GeneratedColumn<int>(
    'used_play_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _freePlaySecondsMeta = const VerificationMeta(
    'freePlaySeconds',
  );
  @override
  late final GeneratedColumn<int> freePlaySeconds = GeneratedColumn<int>(
    'free_play_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tasksTotalMeta = const VerificationMeta(
    'tasksTotal',
  );
  @override
  late final GeneratedColumn<int> tasksTotal = GeneratedColumn<int>(
    'tasks_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tasksAnsweredMeta = const VerificationMeta(
    'tasksAnswered',
  );
  @override
  late final GeneratedColumn<int> tasksAnswered = GeneratedColumn<int>(
    'tasks_answered',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sessionBonusAwardedMeta =
      const VerificationMeta('sessionBonusAwarded');
  @override
  late final GeneratedColumn<bool> sessionBonusAwarded = GeneratedColumn<bool>(
    'session_bonus_awarded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("session_bonus_awarded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _streakBonusAwardedMeta =
      const VerificationMeta('streakBonusAwarded');
  @override
  late final GeneratedColumn<bool> streakBonusAwarded = GeneratedColumn<bool>(
    'streak_bonus_awarded',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("streak_bonus_awarded" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _expiredAtMsMeta = const VerificationMeta(
    'expiredAtMs',
  );
  @override
  late final GeneratedColumn<int> expiredAtMs = GeneratedColumn<int>(
    'expired_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    dayKey,
    earnedUnits,
    grantedUnits,
    usedPlaySeconds,
    freePlaySeconds,
    tasksTotal,
    tasksAnswered,
    sessionBonusAwarded,
    streakBonusAwarded,
    expiredAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_progress_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    }
    if (data.containsKey('earned_units')) {
      context.handle(
        _earnedUnitsMeta,
        earnedUnits.isAcceptableOrUnknown(
          data['earned_units']!,
          _earnedUnitsMeta,
        ),
      );
    }
    if (data.containsKey('granted_units')) {
      context.handle(
        _grantedUnitsMeta,
        grantedUnits.isAcceptableOrUnknown(
          data['granted_units']!,
          _grantedUnitsMeta,
        ),
      );
    }
    if (data.containsKey('used_play_seconds')) {
      context.handle(
        _usedPlaySecondsMeta,
        usedPlaySeconds.isAcceptableOrUnknown(
          data['used_play_seconds']!,
          _usedPlaySecondsMeta,
        ),
      );
    }
    if (data.containsKey('free_play_seconds')) {
      context.handle(
        _freePlaySecondsMeta,
        freePlaySeconds.isAcceptableOrUnknown(
          data['free_play_seconds']!,
          _freePlaySecondsMeta,
        ),
      );
    }
    if (data.containsKey('tasks_total')) {
      context.handle(
        _tasksTotalMeta,
        tasksTotal.isAcceptableOrUnknown(data['tasks_total']!, _tasksTotalMeta),
      );
    }
    if (data.containsKey('tasks_answered')) {
      context.handle(
        _tasksAnsweredMeta,
        tasksAnswered.isAcceptableOrUnknown(
          data['tasks_answered']!,
          _tasksAnsweredMeta,
        ),
      );
    }
    if (data.containsKey('session_bonus_awarded')) {
      context.handle(
        _sessionBonusAwardedMeta,
        sessionBonusAwarded.isAcceptableOrUnknown(
          data['session_bonus_awarded']!,
          _sessionBonusAwardedMeta,
        ),
      );
    }
    if (data.containsKey('streak_bonus_awarded')) {
      context.handle(
        _streakBonusAwardedMeta,
        streakBonusAwarded.isAcceptableOrUnknown(
          data['streak_bonus_awarded']!,
          _streakBonusAwardedMeta,
        ),
      );
    }
    if (data.containsKey('expired_at_ms')) {
      context.handle(
        _expiredAtMsMeta,
        expiredAtMs.isAcceptableOrUnknown(
          data['expired_at_ms']!,
          _expiredAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dayKey};
  @override
  DayProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayProgressRow(
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_key'],
      )!,
      earnedUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}earned_units'],
      )!,
      grantedUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}granted_units'],
      )!,
      usedPlaySeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_play_seconds'],
      )!,
      freePlaySeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}free_play_seconds'],
      )!,
      tasksTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tasks_total'],
      )!,
      tasksAnswered: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tasks_answered'],
      )!,
      sessionBonusAwarded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}session_bonus_awarded'],
      )!,
      streakBonusAwarded: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}streak_bonus_awarded'],
      )!,
      expiredAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expired_at_ms'],
      ),
    );
  }

  @override
  $DayProgressRowsTable createAlias(String alias) {
    return $DayProgressRowsTable(attachedDatabase, alias);
  }
}

class DayProgressRow extends DataClass implements Insertable<DayProgressRow> {
  final int dayKey;

  /// Earned by the child. Counts against the daily ceiling.
  final int earnedUnits;

  /// Parent grants, welcome balance, weekly test, carried-over balance. Exempt
  /// from the ceiling — the parent's authority is "فوق النظام" (appendix §4).
  final int grantedUnits;
  final int usedPlaySeconds;

  /// Play seconds the parent handed over directly today — see
  /// `DayProgress.freePlaySeconds`. Not stars, and never in the star ledger.
  final int freePlaySeconds;
  final int tasksTotal;
  final int tasksAnswered;
  final bool sessionBonusAwarded;
  final bool streakBonusAwarded;
  final int? expiredAtMs;
  const DayProgressRow({
    required this.dayKey,
    required this.earnedUnits,
    required this.grantedUnits,
    required this.usedPlaySeconds,
    required this.freePlaySeconds,
    required this.tasksTotal,
    required this.tasksAnswered,
    required this.sessionBonusAwarded,
    required this.streakBonusAwarded,
    this.expiredAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day_key'] = Variable<int>(dayKey);
    map['earned_units'] = Variable<int>(earnedUnits);
    map['granted_units'] = Variable<int>(grantedUnits);
    map['used_play_seconds'] = Variable<int>(usedPlaySeconds);
    map['free_play_seconds'] = Variable<int>(freePlaySeconds);
    map['tasks_total'] = Variable<int>(tasksTotal);
    map['tasks_answered'] = Variable<int>(tasksAnswered);
    map['session_bonus_awarded'] = Variable<bool>(sessionBonusAwarded);
    map['streak_bonus_awarded'] = Variable<bool>(streakBonusAwarded);
    if (!nullToAbsent || expiredAtMs != null) {
      map['expired_at_ms'] = Variable<int>(expiredAtMs);
    }
    return map;
  }

  DayProgressRowsCompanion toCompanion(bool nullToAbsent) {
    return DayProgressRowsCompanion(
      dayKey: Value(dayKey),
      earnedUnits: Value(earnedUnits),
      grantedUnits: Value(grantedUnits),
      usedPlaySeconds: Value(usedPlaySeconds),
      freePlaySeconds: Value(freePlaySeconds),
      tasksTotal: Value(tasksTotal),
      tasksAnswered: Value(tasksAnswered),
      sessionBonusAwarded: Value(sessionBonusAwarded),
      streakBonusAwarded: Value(streakBonusAwarded),
      expiredAtMs: expiredAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(expiredAtMs),
    );
  }

  factory DayProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayProgressRow(
      dayKey: serializer.fromJson<int>(json['dayKey']),
      earnedUnits: serializer.fromJson<int>(json['earnedUnits']),
      grantedUnits: serializer.fromJson<int>(json['grantedUnits']),
      usedPlaySeconds: serializer.fromJson<int>(json['usedPlaySeconds']),
      freePlaySeconds: serializer.fromJson<int>(json['freePlaySeconds']),
      tasksTotal: serializer.fromJson<int>(json['tasksTotal']),
      tasksAnswered: serializer.fromJson<int>(json['tasksAnswered']),
      sessionBonusAwarded: serializer.fromJson<bool>(
        json['sessionBonusAwarded'],
      ),
      streakBonusAwarded: serializer.fromJson<bool>(json['streakBonusAwarded']),
      expiredAtMs: serializer.fromJson<int?>(json['expiredAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dayKey': serializer.toJson<int>(dayKey),
      'earnedUnits': serializer.toJson<int>(earnedUnits),
      'grantedUnits': serializer.toJson<int>(grantedUnits),
      'usedPlaySeconds': serializer.toJson<int>(usedPlaySeconds),
      'freePlaySeconds': serializer.toJson<int>(freePlaySeconds),
      'tasksTotal': serializer.toJson<int>(tasksTotal),
      'tasksAnswered': serializer.toJson<int>(tasksAnswered),
      'sessionBonusAwarded': serializer.toJson<bool>(sessionBonusAwarded),
      'streakBonusAwarded': serializer.toJson<bool>(streakBonusAwarded),
      'expiredAtMs': serializer.toJson<int?>(expiredAtMs),
    };
  }

  DayProgressRow copyWith({
    int? dayKey,
    int? earnedUnits,
    int? grantedUnits,
    int? usedPlaySeconds,
    int? freePlaySeconds,
    int? tasksTotal,
    int? tasksAnswered,
    bool? sessionBonusAwarded,
    bool? streakBonusAwarded,
    Value<int?> expiredAtMs = const Value.absent(),
  }) => DayProgressRow(
    dayKey: dayKey ?? this.dayKey,
    earnedUnits: earnedUnits ?? this.earnedUnits,
    grantedUnits: grantedUnits ?? this.grantedUnits,
    usedPlaySeconds: usedPlaySeconds ?? this.usedPlaySeconds,
    freePlaySeconds: freePlaySeconds ?? this.freePlaySeconds,
    tasksTotal: tasksTotal ?? this.tasksTotal,
    tasksAnswered: tasksAnswered ?? this.tasksAnswered,
    sessionBonusAwarded: sessionBonusAwarded ?? this.sessionBonusAwarded,
    streakBonusAwarded: streakBonusAwarded ?? this.streakBonusAwarded,
    expiredAtMs: expiredAtMs.present ? expiredAtMs.value : this.expiredAtMs,
  );
  DayProgressRow copyWithCompanion(DayProgressRowsCompanion data) {
    return DayProgressRow(
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      earnedUnits: data.earnedUnits.present
          ? data.earnedUnits.value
          : this.earnedUnits,
      grantedUnits: data.grantedUnits.present
          ? data.grantedUnits.value
          : this.grantedUnits,
      usedPlaySeconds: data.usedPlaySeconds.present
          ? data.usedPlaySeconds.value
          : this.usedPlaySeconds,
      freePlaySeconds: data.freePlaySeconds.present
          ? data.freePlaySeconds.value
          : this.freePlaySeconds,
      tasksTotal: data.tasksTotal.present
          ? data.tasksTotal.value
          : this.tasksTotal,
      tasksAnswered: data.tasksAnswered.present
          ? data.tasksAnswered.value
          : this.tasksAnswered,
      sessionBonusAwarded: data.sessionBonusAwarded.present
          ? data.sessionBonusAwarded.value
          : this.sessionBonusAwarded,
      streakBonusAwarded: data.streakBonusAwarded.present
          ? data.streakBonusAwarded.value
          : this.streakBonusAwarded,
      expiredAtMs: data.expiredAtMs.present
          ? data.expiredAtMs.value
          : this.expiredAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayProgressRow(')
          ..write('dayKey: $dayKey, ')
          ..write('earnedUnits: $earnedUnits, ')
          ..write('grantedUnits: $grantedUnits, ')
          ..write('usedPlaySeconds: $usedPlaySeconds, ')
          ..write('freePlaySeconds: $freePlaySeconds, ')
          ..write('tasksTotal: $tasksTotal, ')
          ..write('tasksAnswered: $tasksAnswered, ')
          ..write('sessionBonusAwarded: $sessionBonusAwarded, ')
          ..write('streakBonusAwarded: $streakBonusAwarded, ')
          ..write('expiredAtMs: $expiredAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dayKey,
    earnedUnits,
    grantedUnits,
    usedPlaySeconds,
    freePlaySeconds,
    tasksTotal,
    tasksAnswered,
    sessionBonusAwarded,
    streakBonusAwarded,
    expiredAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayProgressRow &&
          other.dayKey == this.dayKey &&
          other.earnedUnits == this.earnedUnits &&
          other.grantedUnits == this.grantedUnits &&
          other.usedPlaySeconds == this.usedPlaySeconds &&
          other.freePlaySeconds == this.freePlaySeconds &&
          other.tasksTotal == this.tasksTotal &&
          other.tasksAnswered == this.tasksAnswered &&
          other.sessionBonusAwarded == this.sessionBonusAwarded &&
          other.streakBonusAwarded == this.streakBonusAwarded &&
          other.expiredAtMs == this.expiredAtMs);
}

class DayProgressRowsCompanion extends UpdateCompanion<DayProgressRow> {
  final Value<int> dayKey;
  final Value<int> earnedUnits;
  final Value<int> grantedUnits;
  final Value<int> usedPlaySeconds;
  final Value<int> freePlaySeconds;
  final Value<int> tasksTotal;
  final Value<int> tasksAnswered;
  final Value<bool> sessionBonusAwarded;
  final Value<bool> streakBonusAwarded;
  final Value<int?> expiredAtMs;
  const DayProgressRowsCompanion({
    this.dayKey = const Value.absent(),
    this.earnedUnits = const Value.absent(),
    this.grantedUnits = const Value.absent(),
    this.usedPlaySeconds = const Value.absent(),
    this.freePlaySeconds = const Value.absent(),
    this.tasksTotal = const Value.absent(),
    this.tasksAnswered = const Value.absent(),
    this.sessionBonusAwarded = const Value.absent(),
    this.streakBonusAwarded = const Value.absent(),
    this.expiredAtMs = const Value.absent(),
  });
  DayProgressRowsCompanion.insert({
    this.dayKey = const Value.absent(),
    this.earnedUnits = const Value.absent(),
    this.grantedUnits = const Value.absent(),
    this.usedPlaySeconds = const Value.absent(),
    this.freePlaySeconds = const Value.absent(),
    this.tasksTotal = const Value.absent(),
    this.tasksAnswered = const Value.absent(),
    this.sessionBonusAwarded = const Value.absent(),
    this.streakBonusAwarded = const Value.absent(),
    this.expiredAtMs = const Value.absent(),
  });
  static Insertable<DayProgressRow> custom({
    Expression<int>? dayKey,
    Expression<int>? earnedUnits,
    Expression<int>? grantedUnits,
    Expression<int>? usedPlaySeconds,
    Expression<int>? freePlaySeconds,
    Expression<int>? tasksTotal,
    Expression<int>? tasksAnswered,
    Expression<bool>? sessionBonusAwarded,
    Expression<bool>? streakBonusAwarded,
    Expression<int>? expiredAtMs,
  }) {
    return RawValuesInsertable({
      if (dayKey != null) 'day_key': dayKey,
      if (earnedUnits != null) 'earned_units': earnedUnits,
      if (grantedUnits != null) 'granted_units': grantedUnits,
      if (usedPlaySeconds != null) 'used_play_seconds': usedPlaySeconds,
      if (freePlaySeconds != null) 'free_play_seconds': freePlaySeconds,
      if (tasksTotal != null) 'tasks_total': tasksTotal,
      if (tasksAnswered != null) 'tasks_answered': tasksAnswered,
      if (sessionBonusAwarded != null)
        'session_bonus_awarded': sessionBonusAwarded,
      if (streakBonusAwarded != null)
        'streak_bonus_awarded': streakBonusAwarded,
      if (expiredAtMs != null) 'expired_at_ms': expiredAtMs,
    });
  }

  DayProgressRowsCompanion copyWith({
    Value<int>? dayKey,
    Value<int>? earnedUnits,
    Value<int>? grantedUnits,
    Value<int>? usedPlaySeconds,
    Value<int>? freePlaySeconds,
    Value<int>? tasksTotal,
    Value<int>? tasksAnswered,
    Value<bool>? sessionBonusAwarded,
    Value<bool>? streakBonusAwarded,
    Value<int?>? expiredAtMs,
  }) {
    return DayProgressRowsCompanion(
      dayKey: dayKey ?? this.dayKey,
      earnedUnits: earnedUnits ?? this.earnedUnits,
      grantedUnits: grantedUnits ?? this.grantedUnits,
      usedPlaySeconds: usedPlaySeconds ?? this.usedPlaySeconds,
      freePlaySeconds: freePlaySeconds ?? this.freePlaySeconds,
      tasksTotal: tasksTotal ?? this.tasksTotal,
      tasksAnswered: tasksAnswered ?? this.tasksAnswered,
      sessionBonusAwarded: sessionBonusAwarded ?? this.sessionBonusAwarded,
      streakBonusAwarded: streakBonusAwarded ?? this.streakBonusAwarded,
      expiredAtMs: expiredAtMs ?? this.expiredAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dayKey.present) {
      map['day_key'] = Variable<int>(dayKey.value);
    }
    if (earnedUnits.present) {
      map['earned_units'] = Variable<int>(earnedUnits.value);
    }
    if (grantedUnits.present) {
      map['granted_units'] = Variable<int>(grantedUnits.value);
    }
    if (usedPlaySeconds.present) {
      map['used_play_seconds'] = Variable<int>(usedPlaySeconds.value);
    }
    if (freePlaySeconds.present) {
      map['free_play_seconds'] = Variable<int>(freePlaySeconds.value);
    }
    if (tasksTotal.present) {
      map['tasks_total'] = Variable<int>(tasksTotal.value);
    }
    if (tasksAnswered.present) {
      map['tasks_answered'] = Variable<int>(tasksAnswered.value);
    }
    if (sessionBonusAwarded.present) {
      map['session_bonus_awarded'] = Variable<bool>(sessionBonusAwarded.value);
    }
    if (streakBonusAwarded.present) {
      map['streak_bonus_awarded'] = Variable<bool>(streakBonusAwarded.value);
    }
    if (expiredAtMs.present) {
      map['expired_at_ms'] = Variable<int>(expiredAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayProgressRowsCompanion(')
          ..write('dayKey: $dayKey, ')
          ..write('earnedUnits: $earnedUnits, ')
          ..write('grantedUnits: $grantedUnits, ')
          ..write('usedPlaySeconds: $usedPlaySeconds, ')
          ..write('freePlaySeconds: $freePlaySeconds, ')
          ..write('tasksTotal: $tasksTotal, ')
          ..write('tasksAnswered: $tasksAnswered, ')
          ..write('sessionBonusAwarded: $sessionBonusAwarded, ')
          ..write('streakBonusAwarded: $streakBonusAwarded, ')
          ..write('expiredAtMs: $expiredAtMs')
          ..write(')'))
        .toString();
  }
}

class $CountedTargetsTable extends CountedTargets
    with TableInfo<$CountedTargetsTable, CountedTargetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CountedTargetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<int> dayKey = GeneratedColumn<int>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<TaskKind, int> kind =
      GeneratedColumn<int>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<TaskKind>($CountedTargetsTable.$converterkind);
  static const VerificationMeta _targetIdMeta = const VerificationMeta(
    'targetId',
  );
  @override
  late final GeneratedColumn<int> targetId = GeneratedColumn<int>(
    'target_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMsMeta = const VerificationMeta('atMs');
  @override
  late final GeneratedColumn<int> atMs = GeneratedColumn<int>(
    'at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [dayKey, kind, targetId, atMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'counted_targets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CountedTargetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('target_id')) {
      context.handle(
        _targetIdMeta,
        targetId.isAcceptableOrUnknown(data['target_id']!, _targetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_targetIdMeta);
    }
    if (data.containsKey('at_ms')) {
      context.handle(
        _atMsMeta,
        atMs.isAcceptableOrUnknown(data['at_ms']!, _atMsMeta),
      );
    } else if (isInserting) {
      context.missing(_atMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dayKey, kind, targetId};
  @override
  CountedTargetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CountedTargetRow(
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_key'],
      )!,
      kind: $CountedTargetsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}kind'],
        )!,
      ),
      targetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_id'],
      )!,
      atMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_ms'],
      )!,
    );
  }

  @override
  $CountedTargetsTable createAlias(String alias) {
    return $CountedTargetsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TaskKind, int, int> $converterkind =
      const EnumIndexConverter<TaskKind>(TaskKind.values);
}

class CountedTargetRow extends DataClass
    implements Insertable<CountedTargetRow> {
  final int dayKey;
  final TaskKind kind;
  final int targetId;
  final int atMs;
  const CountedTargetRow({
    required this.dayKey,
    required this.kind,
    required this.targetId,
    required this.atMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['day_key'] = Variable<int>(dayKey);
    {
      map['kind'] = Variable<int>(
        $CountedTargetsTable.$converterkind.toSql(kind),
      );
    }
    map['target_id'] = Variable<int>(targetId);
    map['at_ms'] = Variable<int>(atMs);
    return map;
  }

  CountedTargetsCompanion toCompanion(bool nullToAbsent) {
    return CountedTargetsCompanion(
      dayKey: Value(dayKey),
      kind: Value(kind),
      targetId: Value(targetId),
      atMs: Value(atMs),
    );
  }

  factory CountedTargetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CountedTargetRow(
      dayKey: serializer.fromJson<int>(json['dayKey']),
      kind: $CountedTargetsTable.$converterkind.fromJson(
        serializer.fromJson<int>(json['kind']),
      ),
      targetId: serializer.fromJson<int>(json['targetId']),
      atMs: serializer.fromJson<int>(json['atMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dayKey': serializer.toJson<int>(dayKey),
      'kind': serializer.toJson<int>(
        $CountedTargetsTable.$converterkind.toJson(kind),
      ),
      'targetId': serializer.toJson<int>(targetId),
      'atMs': serializer.toJson<int>(atMs),
    };
  }

  CountedTargetRow copyWith({
    int? dayKey,
    TaskKind? kind,
    int? targetId,
    int? atMs,
  }) => CountedTargetRow(
    dayKey: dayKey ?? this.dayKey,
    kind: kind ?? this.kind,
    targetId: targetId ?? this.targetId,
    atMs: atMs ?? this.atMs,
  );
  CountedTargetRow copyWithCompanion(CountedTargetsCompanion data) {
    return CountedTargetRow(
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      targetId: data.targetId.present ? data.targetId.value : this.targetId,
      atMs: data.atMs.present ? data.atMs.value : this.atMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CountedTargetRow(')
          ..write('dayKey: $dayKey, ')
          ..write('kind: $kind, ')
          ..write('targetId: $targetId, ')
          ..write('atMs: $atMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(dayKey, kind, targetId, atMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CountedTargetRow &&
          other.dayKey == this.dayKey &&
          other.kind == this.kind &&
          other.targetId == this.targetId &&
          other.atMs == this.atMs);
}

class CountedTargetsCompanion extends UpdateCompanion<CountedTargetRow> {
  final Value<int> dayKey;
  final Value<TaskKind> kind;
  final Value<int> targetId;
  final Value<int> atMs;
  final Value<int> rowid;
  const CountedTargetsCompanion({
    this.dayKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.targetId = const Value.absent(),
    this.atMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CountedTargetsCompanion.insert({
    required int dayKey,
    required TaskKind kind,
    required int targetId,
    required int atMs,
    this.rowid = const Value.absent(),
  }) : dayKey = Value(dayKey),
       kind = Value(kind),
       targetId = Value(targetId),
       atMs = Value(atMs);
  static Insertable<CountedTargetRow> custom({
    Expression<int>? dayKey,
    Expression<int>? kind,
    Expression<int>? targetId,
    Expression<int>? atMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dayKey != null) 'day_key': dayKey,
      if (kind != null) 'kind': kind,
      if (targetId != null) 'target_id': targetId,
      if (atMs != null) 'at_ms': atMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CountedTargetsCompanion copyWith({
    Value<int>? dayKey,
    Value<TaskKind>? kind,
    Value<int>? targetId,
    Value<int>? atMs,
    Value<int>? rowid,
  }) {
    return CountedTargetsCompanion(
      dayKey: dayKey ?? this.dayKey,
      kind: kind ?? this.kind,
      targetId: targetId ?? this.targetId,
      atMs: atMs ?? this.atMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dayKey.present) {
      map['day_key'] = Variable<int>(dayKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(
        $CountedTargetsTable.$converterkind.toSql(kind.value),
      );
    }
    if (targetId.present) {
      map['target_id'] = Variable<int>(targetId.value);
    }
    if (atMs.present) {
      map['at_ms'] = Variable<int>(atMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CountedTargetsCompanion(')
          ..write('dayKey: $dayKey, ')
          ..write('kind: $kind, ')
          ..write('targetId: $targetId, ')
          ..write('atMs: $atMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StreakStatesTable extends StreakStates
    with TableInfo<$StreakStatesTable, StreakRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StreakStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastActiveDayMeta = const VerificationMeta(
    'lastActiveDay',
  );
  @override
  late final GeneratedColumn<int> lastActiveDay = GeneratedColumn<int>(
    'last_active_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _consecutiveDaysMeta = const VerificationMeta(
    'consecutiveDays',
  );
  @override
  late final GeneratedColumn<int> consecutiveDays = GeneratedColumn<int>(
    'consecutive_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _bestMeta = const VerificationMeta('best');
  @override
  late final GeneratedColumn<int> best = GeneratedColumn<int>(
    'best',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    lastActiveDay,
    consecutiveDays,
    best,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'streak_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<StreakRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('last_active_day')) {
      context.handle(
        _lastActiveDayMeta,
        lastActiveDay.isAcceptableOrUnknown(
          data['last_active_day']!,
          _lastActiveDayMeta,
        ),
      );
    }
    if (data.containsKey('consecutive_days')) {
      context.handle(
        _consecutiveDaysMeta,
        consecutiveDays.isAcceptableOrUnknown(
          data['consecutive_days']!,
          _consecutiveDaysMeta,
        ),
      );
    }
    if (data.containsKey('best')) {
      context.handle(
        _bestMeta,
        best.isAcceptableOrUnknown(data['best']!, _bestMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StreakRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StreakRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      lastActiveDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_active_day'],
      ),
      consecutiveDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consecutive_days'],
      )!,
      best: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best'],
      )!,
    );
  }

  @override
  $StreakStatesTable createAlias(String alias) {
    return $StreakStatesTable(attachedDatabase, alias);
  }
}

class StreakRow extends DataClass implements Insertable<StreakRow> {
  final int id;
  final int? lastActiveDay;
  final int consecutiveDays;
  final int best;
  const StreakRow({
    required this.id,
    this.lastActiveDay,
    required this.consecutiveDays,
    required this.best,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || lastActiveDay != null) {
      map['last_active_day'] = Variable<int>(lastActiveDay);
    }
    map['consecutive_days'] = Variable<int>(consecutiveDays);
    map['best'] = Variable<int>(best);
    return map;
  }

  StreakStatesCompanion toCompanion(bool nullToAbsent) {
    return StreakStatesCompanion(
      id: Value(id),
      lastActiveDay: lastActiveDay == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActiveDay),
      consecutiveDays: Value(consecutiveDays),
      best: Value(best),
    );
  }

  factory StreakRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StreakRow(
      id: serializer.fromJson<int>(json['id']),
      lastActiveDay: serializer.fromJson<int?>(json['lastActiveDay']),
      consecutiveDays: serializer.fromJson<int>(json['consecutiveDays']),
      best: serializer.fromJson<int>(json['best']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'lastActiveDay': serializer.toJson<int?>(lastActiveDay),
      'consecutiveDays': serializer.toJson<int>(consecutiveDays),
      'best': serializer.toJson<int>(best),
    };
  }

  StreakRow copyWith({
    int? id,
    Value<int?> lastActiveDay = const Value.absent(),
    int? consecutiveDays,
    int? best,
  }) => StreakRow(
    id: id ?? this.id,
    lastActiveDay: lastActiveDay.present
        ? lastActiveDay.value
        : this.lastActiveDay,
    consecutiveDays: consecutiveDays ?? this.consecutiveDays,
    best: best ?? this.best,
  );
  StreakRow copyWithCompanion(StreakStatesCompanion data) {
    return StreakRow(
      id: data.id.present ? data.id.value : this.id,
      lastActiveDay: data.lastActiveDay.present
          ? data.lastActiveDay.value
          : this.lastActiveDay,
      consecutiveDays: data.consecutiveDays.present
          ? data.consecutiveDays.value
          : this.consecutiveDays,
      best: data.best.present ? data.best.value : this.best,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StreakRow(')
          ..write('id: $id, ')
          ..write('lastActiveDay: $lastActiveDay, ')
          ..write('consecutiveDays: $consecutiveDays, ')
          ..write('best: $best')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, lastActiveDay, consecutiveDays, best);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StreakRow &&
          other.id == this.id &&
          other.lastActiveDay == this.lastActiveDay &&
          other.consecutiveDays == this.consecutiveDays &&
          other.best == this.best);
}

class StreakStatesCompanion extends UpdateCompanion<StreakRow> {
  final Value<int> id;
  final Value<int?> lastActiveDay;
  final Value<int> consecutiveDays;
  final Value<int> best;
  const StreakStatesCompanion({
    this.id = const Value.absent(),
    this.lastActiveDay = const Value.absent(),
    this.consecutiveDays = const Value.absent(),
    this.best = const Value.absent(),
  });
  StreakStatesCompanion.insert({
    this.id = const Value.absent(),
    this.lastActiveDay = const Value.absent(),
    this.consecutiveDays = const Value.absent(),
    this.best = const Value.absent(),
  });
  static Insertable<StreakRow> custom({
    Expression<int>? id,
    Expression<int>? lastActiveDay,
    Expression<int>? consecutiveDays,
    Expression<int>? best,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (lastActiveDay != null) 'last_active_day': lastActiveDay,
      if (consecutiveDays != null) 'consecutive_days': consecutiveDays,
      if (best != null) 'best': best,
    });
  }

  StreakStatesCompanion copyWith({
    Value<int>? id,
    Value<int?>? lastActiveDay,
    Value<int>? consecutiveDays,
    Value<int>? best,
  }) {
    return StreakStatesCompanion(
      id: id ?? this.id,
      lastActiveDay: lastActiveDay ?? this.lastActiveDay,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      best: best ?? this.best,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (lastActiveDay.present) {
      map['last_active_day'] = Variable<int>(lastActiveDay.value);
    }
    if (consecutiveDays.present) {
      map['consecutive_days'] = Variable<int>(consecutiveDays.value);
    }
    if (best.present) {
      map['best'] = Variable<int>(best.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StreakStatesCompanion(')
          ..write('id: $id, ')
          ..write('lastActiveDay: $lastActiveDay, ')
          ..write('consecutiveDays: $consecutiveDays, ')
          ..write('best: $best')
          ..write(')'))
        .toString();
  }
}

class $WeeklyTestsTable extends WeeklyTests
    with TableInfo<$WeeklyTestsTable, WeeklyTestRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyTestsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _weekKeyMeta = const VerificationMeta(
    'weekKey',
  );
  @override
  late final GeneratedColumn<int> weekKey = GeneratedColumn<int>(
    'week_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  @override
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _finishedAtMsMeta = const VerificationMeta(
    'finishedAtMs',
  );
  @override
  late final GeneratedColumn<int> finishedAtMs = GeneratedColumn<int>(
    'finished_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalQuestionsMeta = const VerificationMeta(
    'totalQuestions',
  );
  @override
  late final GeneratedColumn<int> totalQuestions = GeneratedColumn<int>(
    'total_questions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _correctAnswersMeta = const VerificationMeta(
    'correctAnswers',
  );
  @override
  late final GeneratedColumn<int> correctAnswers = GeneratedColumn<int>(
    'correct_answers',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _percentBasisPointsMeta =
      const VerificationMeta('percentBasisPoints');
  @override
  late final GeneratedColumn<int> percentBasisPoints = GeneratedColumn<int>(
    'percent_basis_points',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _awardedUnitsMeta = const VerificationMeta(
    'awardedUnits',
  );
  @override
  late final GeneratedColumn<int> awardedUnits = GeneratedColumn<int>(
    'awarded_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _purgeDoneAtMsMeta = const VerificationMeta(
    'purgeDoneAtMs',
  );
  @override
  late final GeneratedColumn<int> purgeDoneAtMs = GeneratedColumn<int>(
    'purge_done_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    weekKey,
    startedAtMs,
    finishedAtMs,
    totalQuestions,
    correctAnswers,
    percentBasisPoints,
    awardedUnits,
    purgeDoneAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_tests';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyTestRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('week_key')) {
      context.handle(
        _weekKeyMeta,
        weekKey.isAcceptableOrUnknown(data['week_key']!, _weekKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_weekKeyMeta);
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('finished_at_ms')) {
      context.handle(
        _finishedAtMsMeta,
        finishedAtMs.isAcceptableOrUnknown(
          data['finished_at_ms']!,
          _finishedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('total_questions')) {
      context.handle(
        _totalQuestionsMeta,
        totalQuestions.isAcceptableOrUnknown(
          data['total_questions']!,
          _totalQuestionsMeta,
        ),
      );
    }
    if (data.containsKey('correct_answers')) {
      context.handle(
        _correctAnswersMeta,
        correctAnswers.isAcceptableOrUnknown(
          data['correct_answers']!,
          _correctAnswersMeta,
        ),
      );
    }
    if (data.containsKey('percent_basis_points')) {
      context.handle(
        _percentBasisPointsMeta,
        percentBasisPoints.isAcceptableOrUnknown(
          data['percent_basis_points']!,
          _percentBasisPointsMeta,
        ),
      );
    }
    if (data.containsKey('awarded_units')) {
      context.handle(
        _awardedUnitsMeta,
        awardedUnits.isAcceptableOrUnknown(
          data['awarded_units']!,
          _awardedUnitsMeta,
        ),
      );
    }
    if (data.containsKey('purge_done_at_ms')) {
      context.handle(
        _purgeDoneAtMsMeta,
        purgeDoneAtMs.isAcceptableOrUnknown(
          data['purge_done_at_ms']!,
          _purgeDoneAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeeklyTestRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyTestRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      weekKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}week_key'],
      )!,
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      )!,
      finishedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}finished_at_ms'],
      ),
      totalQuestions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_questions'],
      )!,
      correctAnswers: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}correct_answers'],
      )!,
      percentBasisPoints: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}percent_basis_points'],
      )!,
      awardedUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}awarded_units'],
      )!,
      purgeDoneAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}purge_done_at_ms'],
      ),
    );
  }

  @override
  $WeeklyTestsTable createAlias(String alias) {
    return $WeeklyTestsTable(attachedDatabase, alias);
  }
}

class WeeklyTestRow extends DataClass implements Insertable<WeeklyTestRow> {
  final int id;
  final int weekKey;
  final int startedAtMs;
  final int? finishedAtMs;
  final int totalQuestions;
  final int correctAnswers;

  /// Percentage times 100, so 87.5% is stored as 8750. Integer, like everything
  /// else a contract number depends on.
  final int percentBasisPoints;
  final int awardedUnits;

  /// Set when the automatic deletion that follows the test has completed
  /// (Art. 11.6). Null means the purge still owes work.
  final int? purgeDoneAtMs;
  const WeeklyTestRow({
    required this.id,
    required this.weekKey,
    required this.startedAtMs,
    this.finishedAtMs,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.percentBasisPoints,
    required this.awardedUnits,
    this.purgeDoneAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['week_key'] = Variable<int>(weekKey);
    map['started_at_ms'] = Variable<int>(startedAtMs);
    if (!nullToAbsent || finishedAtMs != null) {
      map['finished_at_ms'] = Variable<int>(finishedAtMs);
    }
    map['total_questions'] = Variable<int>(totalQuestions);
    map['correct_answers'] = Variable<int>(correctAnswers);
    map['percent_basis_points'] = Variable<int>(percentBasisPoints);
    map['awarded_units'] = Variable<int>(awardedUnits);
    if (!nullToAbsent || purgeDoneAtMs != null) {
      map['purge_done_at_ms'] = Variable<int>(purgeDoneAtMs);
    }
    return map;
  }

  WeeklyTestsCompanion toCompanion(bool nullToAbsent) {
    return WeeklyTestsCompanion(
      id: Value(id),
      weekKey: Value(weekKey),
      startedAtMs: Value(startedAtMs),
      finishedAtMs: finishedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(finishedAtMs),
      totalQuestions: Value(totalQuestions),
      correctAnswers: Value(correctAnswers),
      percentBasisPoints: Value(percentBasisPoints),
      awardedUnits: Value(awardedUnits),
      purgeDoneAtMs: purgeDoneAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(purgeDoneAtMs),
    );
  }

  factory WeeklyTestRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyTestRow(
      id: serializer.fromJson<int>(json['id']),
      weekKey: serializer.fromJson<int>(json['weekKey']),
      startedAtMs: serializer.fromJson<int>(json['startedAtMs']),
      finishedAtMs: serializer.fromJson<int?>(json['finishedAtMs']),
      totalQuestions: serializer.fromJson<int>(json['totalQuestions']),
      correctAnswers: serializer.fromJson<int>(json['correctAnswers']),
      percentBasisPoints: serializer.fromJson<int>(json['percentBasisPoints']),
      awardedUnits: serializer.fromJson<int>(json['awardedUnits']),
      purgeDoneAtMs: serializer.fromJson<int?>(json['purgeDoneAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'weekKey': serializer.toJson<int>(weekKey),
      'startedAtMs': serializer.toJson<int>(startedAtMs),
      'finishedAtMs': serializer.toJson<int?>(finishedAtMs),
      'totalQuestions': serializer.toJson<int>(totalQuestions),
      'correctAnswers': serializer.toJson<int>(correctAnswers),
      'percentBasisPoints': serializer.toJson<int>(percentBasisPoints),
      'awardedUnits': serializer.toJson<int>(awardedUnits),
      'purgeDoneAtMs': serializer.toJson<int?>(purgeDoneAtMs),
    };
  }

  WeeklyTestRow copyWith({
    int? id,
    int? weekKey,
    int? startedAtMs,
    Value<int?> finishedAtMs = const Value.absent(),
    int? totalQuestions,
    int? correctAnswers,
    int? percentBasisPoints,
    int? awardedUnits,
    Value<int?> purgeDoneAtMs = const Value.absent(),
  }) => WeeklyTestRow(
    id: id ?? this.id,
    weekKey: weekKey ?? this.weekKey,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    finishedAtMs: finishedAtMs.present ? finishedAtMs.value : this.finishedAtMs,
    totalQuestions: totalQuestions ?? this.totalQuestions,
    correctAnswers: correctAnswers ?? this.correctAnswers,
    percentBasisPoints: percentBasisPoints ?? this.percentBasisPoints,
    awardedUnits: awardedUnits ?? this.awardedUnits,
    purgeDoneAtMs: purgeDoneAtMs.present
        ? purgeDoneAtMs.value
        : this.purgeDoneAtMs,
  );
  WeeklyTestRow copyWithCompanion(WeeklyTestsCompanion data) {
    return WeeklyTestRow(
      id: data.id.present ? data.id.value : this.id,
      weekKey: data.weekKey.present ? data.weekKey.value : this.weekKey,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      finishedAtMs: data.finishedAtMs.present
          ? data.finishedAtMs.value
          : this.finishedAtMs,
      totalQuestions: data.totalQuestions.present
          ? data.totalQuestions.value
          : this.totalQuestions,
      correctAnswers: data.correctAnswers.present
          ? data.correctAnswers.value
          : this.correctAnswers,
      percentBasisPoints: data.percentBasisPoints.present
          ? data.percentBasisPoints.value
          : this.percentBasisPoints,
      awardedUnits: data.awardedUnits.present
          ? data.awardedUnits.value
          : this.awardedUnits,
      purgeDoneAtMs: data.purgeDoneAtMs.present
          ? data.purgeDoneAtMs.value
          : this.purgeDoneAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyTestRow(')
          ..write('id: $id, ')
          ..write('weekKey: $weekKey, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('finishedAtMs: $finishedAtMs, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctAnswers: $correctAnswers, ')
          ..write('percentBasisPoints: $percentBasisPoints, ')
          ..write('awardedUnits: $awardedUnits, ')
          ..write('purgeDoneAtMs: $purgeDoneAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    weekKey,
    startedAtMs,
    finishedAtMs,
    totalQuestions,
    correctAnswers,
    percentBasisPoints,
    awardedUnits,
    purgeDoneAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyTestRow &&
          other.id == this.id &&
          other.weekKey == this.weekKey &&
          other.startedAtMs == this.startedAtMs &&
          other.finishedAtMs == this.finishedAtMs &&
          other.totalQuestions == this.totalQuestions &&
          other.correctAnswers == this.correctAnswers &&
          other.percentBasisPoints == this.percentBasisPoints &&
          other.awardedUnits == this.awardedUnits &&
          other.purgeDoneAtMs == this.purgeDoneAtMs);
}

class WeeklyTestsCompanion extends UpdateCompanion<WeeklyTestRow> {
  final Value<int> id;
  final Value<int> weekKey;
  final Value<int> startedAtMs;
  final Value<int?> finishedAtMs;
  final Value<int> totalQuestions;
  final Value<int> correctAnswers;
  final Value<int> percentBasisPoints;
  final Value<int> awardedUnits;
  final Value<int?> purgeDoneAtMs;
  const WeeklyTestsCompanion({
    this.id = const Value.absent(),
    this.weekKey = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.finishedAtMs = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.correctAnswers = const Value.absent(),
    this.percentBasisPoints = const Value.absent(),
    this.awardedUnits = const Value.absent(),
    this.purgeDoneAtMs = const Value.absent(),
  });
  WeeklyTestsCompanion.insert({
    this.id = const Value.absent(),
    required int weekKey,
    required int startedAtMs,
    this.finishedAtMs = const Value.absent(),
    this.totalQuestions = const Value.absent(),
    this.correctAnswers = const Value.absent(),
    this.percentBasisPoints = const Value.absent(),
    this.awardedUnits = const Value.absent(),
    this.purgeDoneAtMs = const Value.absent(),
  }) : weekKey = Value(weekKey),
       startedAtMs = Value(startedAtMs);
  static Insertable<WeeklyTestRow> custom({
    Expression<int>? id,
    Expression<int>? weekKey,
    Expression<int>? startedAtMs,
    Expression<int>? finishedAtMs,
    Expression<int>? totalQuestions,
    Expression<int>? correctAnswers,
    Expression<int>? percentBasisPoints,
    Expression<int>? awardedUnits,
    Expression<int>? purgeDoneAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (weekKey != null) 'week_key': weekKey,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (finishedAtMs != null) 'finished_at_ms': finishedAtMs,
      if (totalQuestions != null) 'total_questions': totalQuestions,
      if (correctAnswers != null) 'correct_answers': correctAnswers,
      if (percentBasisPoints != null)
        'percent_basis_points': percentBasisPoints,
      if (awardedUnits != null) 'awarded_units': awardedUnits,
      if (purgeDoneAtMs != null) 'purge_done_at_ms': purgeDoneAtMs,
    });
  }

  WeeklyTestsCompanion copyWith({
    Value<int>? id,
    Value<int>? weekKey,
    Value<int>? startedAtMs,
    Value<int?>? finishedAtMs,
    Value<int>? totalQuestions,
    Value<int>? correctAnswers,
    Value<int>? percentBasisPoints,
    Value<int>? awardedUnits,
    Value<int?>? purgeDoneAtMs,
  }) {
    return WeeklyTestsCompanion(
      id: id ?? this.id,
      weekKey: weekKey ?? this.weekKey,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      finishedAtMs: finishedAtMs ?? this.finishedAtMs,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      percentBasisPoints: percentBasisPoints ?? this.percentBasisPoints,
      awardedUnits: awardedUnits ?? this.awardedUnits,
      purgeDoneAtMs: purgeDoneAtMs ?? this.purgeDoneAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (weekKey.present) {
      map['week_key'] = Variable<int>(weekKey.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (finishedAtMs.present) {
      map['finished_at_ms'] = Variable<int>(finishedAtMs.value);
    }
    if (totalQuestions.present) {
      map['total_questions'] = Variable<int>(totalQuestions.value);
    }
    if (correctAnswers.present) {
      map['correct_answers'] = Variable<int>(correctAnswers.value);
    }
    if (percentBasisPoints.present) {
      map['percent_basis_points'] = Variable<int>(percentBasisPoints.value);
    }
    if (awardedUnits.present) {
      map['awarded_units'] = Variable<int>(awardedUnits.value);
    }
    if (purgeDoneAtMs.present) {
      map['purge_done_at_ms'] = Variable<int>(purgeDoneAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyTestsCompanion(')
          ..write('id: $id, ')
          ..write('weekKey: $weekKey, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('finishedAtMs: $finishedAtMs, ')
          ..write('totalQuestions: $totalQuestions, ')
          ..write('correctAnswers: $correctAnswers, ')
          ..write('percentBasisPoints: $percentBasisPoints, ')
          ..write('awardedUnits: $awardedUnits, ')
          ..write('purgeDoneAtMs: $purgeDoneAtMs')
          ..write(')'))
        .toString();
  }
}

class $WeeklyTestItemsTable extends WeeklyTestItems
    with TableInfo<$WeeklyTestItemsTable, WeeklyTestItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeeklyTestItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _testIdMeta = const VerificationMeta('testId');
  @override
  late final GeneratedColumn<int> testId = GeneratedColumn<int>(
    'test_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES weekly_tests (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _promptSnapshotMeta = const VerificationMeta(
    'promptSnapshot',
  );
  @override
  late final GeneratedColumn<String> promptSnapshot = GeneratedColumn<String>(
    'prompt_snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<bool> correct = GeneratedColumn<bool>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _answeredAtMsMeta = const VerificationMeta(
    'answeredAtMs',
  );
  @override
  late final GeneratedColumn<int> answeredAtMs = GeneratedColumn<int>(
    'answered_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    testId,
    promptSnapshot,
    correct,
    answeredAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekly_test_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<WeeklyTestItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('test_id')) {
      context.handle(
        _testIdMeta,
        testId.isAcceptableOrUnknown(data['test_id']!, _testIdMeta),
      );
    } else if (isInserting) {
      context.missing(_testIdMeta);
    }
    if (data.containsKey('prompt_snapshot')) {
      context.handle(
        _promptSnapshotMeta,
        promptSnapshot.isAcceptableOrUnknown(
          data['prompt_snapshot']!,
          _promptSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_promptSnapshotMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('answered_at_ms')) {
      context.handle(
        _answeredAtMsMeta,
        answeredAtMs.isAcceptableOrUnknown(
          data['answered_at_ms']!,
          _answeredAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_answeredAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WeeklyTestItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WeeklyTestItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      testId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}test_id'],
      )!,
      promptSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prompt_snapshot'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}correct'],
      )!,
      answeredAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}answered_at_ms'],
      )!,
    );
  }

  @override
  $WeeklyTestItemsTable createAlias(String alias) {
    return $WeeklyTestItemsTable(attachedDatabase, alias);
  }
}

class WeeklyTestItemRow extends DataClass
    implements Insertable<WeeklyTestItemRow> {
  final int id;
  final int testId;

  /// Snapshotted, because the question itself is purged after the test but the
  /// result must remain explainable.
  final String promptSnapshot;
  final bool correct;
  final int answeredAtMs;
  const WeeklyTestItemRow({
    required this.id,
    required this.testId,
    required this.promptSnapshot,
    required this.correct,
    required this.answeredAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['test_id'] = Variable<int>(testId);
    map['prompt_snapshot'] = Variable<String>(promptSnapshot);
    map['correct'] = Variable<bool>(correct);
    map['answered_at_ms'] = Variable<int>(answeredAtMs);
    return map;
  }

  WeeklyTestItemsCompanion toCompanion(bool nullToAbsent) {
    return WeeklyTestItemsCompanion(
      id: Value(id),
      testId: Value(testId),
      promptSnapshot: Value(promptSnapshot),
      correct: Value(correct),
      answeredAtMs: Value(answeredAtMs),
    );
  }

  factory WeeklyTestItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WeeklyTestItemRow(
      id: serializer.fromJson<int>(json['id']),
      testId: serializer.fromJson<int>(json['testId']),
      promptSnapshot: serializer.fromJson<String>(json['promptSnapshot']),
      correct: serializer.fromJson<bool>(json['correct']),
      answeredAtMs: serializer.fromJson<int>(json['answeredAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'testId': serializer.toJson<int>(testId),
      'promptSnapshot': serializer.toJson<String>(promptSnapshot),
      'correct': serializer.toJson<bool>(correct),
      'answeredAtMs': serializer.toJson<int>(answeredAtMs),
    };
  }

  WeeklyTestItemRow copyWith({
    int? id,
    int? testId,
    String? promptSnapshot,
    bool? correct,
    int? answeredAtMs,
  }) => WeeklyTestItemRow(
    id: id ?? this.id,
    testId: testId ?? this.testId,
    promptSnapshot: promptSnapshot ?? this.promptSnapshot,
    correct: correct ?? this.correct,
    answeredAtMs: answeredAtMs ?? this.answeredAtMs,
  );
  WeeklyTestItemRow copyWithCompanion(WeeklyTestItemsCompanion data) {
    return WeeklyTestItemRow(
      id: data.id.present ? data.id.value : this.id,
      testId: data.testId.present ? data.testId.value : this.testId,
      promptSnapshot: data.promptSnapshot.present
          ? data.promptSnapshot.value
          : this.promptSnapshot,
      correct: data.correct.present ? data.correct.value : this.correct,
      answeredAtMs: data.answeredAtMs.present
          ? data.answeredAtMs.value
          : this.answeredAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyTestItemRow(')
          ..write('id: $id, ')
          ..write('testId: $testId, ')
          ..write('promptSnapshot: $promptSnapshot, ')
          ..write('correct: $correct, ')
          ..write('answeredAtMs: $answeredAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, testId, promptSnapshot, correct, answeredAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WeeklyTestItemRow &&
          other.id == this.id &&
          other.testId == this.testId &&
          other.promptSnapshot == this.promptSnapshot &&
          other.correct == this.correct &&
          other.answeredAtMs == this.answeredAtMs);
}

class WeeklyTestItemsCompanion extends UpdateCompanion<WeeklyTestItemRow> {
  final Value<int> id;
  final Value<int> testId;
  final Value<String> promptSnapshot;
  final Value<bool> correct;
  final Value<int> answeredAtMs;
  const WeeklyTestItemsCompanion({
    this.id = const Value.absent(),
    this.testId = const Value.absent(),
    this.promptSnapshot = const Value.absent(),
    this.correct = const Value.absent(),
    this.answeredAtMs = const Value.absent(),
  });
  WeeklyTestItemsCompanion.insert({
    this.id = const Value.absent(),
    required int testId,
    required String promptSnapshot,
    required bool correct,
    required int answeredAtMs,
  }) : testId = Value(testId),
       promptSnapshot = Value(promptSnapshot),
       correct = Value(correct),
       answeredAtMs = Value(answeredAtMs);
  static Insertable<WeeklyTestItemRow> custom({
    Expression<int>? id,
    Expression<int>? testId,
    Expression<String>? promptSnapshot,
    Expression<bool>? correct,
    Expression<int>? answeredAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (testId != null) 'test_id': testId,
      if (promptSnapshot != null) 'prompt_snapshot': promptSnapshot,
      if (correct != null) 'correct': correct,
      if (answeredAtMs != null) 'answered_at_ms': answeredAtMs,
    });
  }

  WeeklyTestItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? testId,
    Value<String>? promptSnapshot,
    Value<bool>? correct,
    Value<int>? answeredAtMs,
  }) {
    return WeeklyTestItemsCompanion(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      promptSnapshot: promptSnapshot ?? this.promptSnapshot,
      correct: correct ?? this.correct,
      answeredAtMs: answeredAtMs ?? this.answeredAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (testId.present) {
      map['test_id'] = Variable<int>(testId.value);
    }
    if (promptSnapshot.present) {
      map['prompt_snapshot'] = Variable<String>(promptSnapshot.value);
    }
    if (correct.present) {
      map['correct'] = Variable<bool>(correct.value);
    }
    if (answeredAtMs.present) {
      map['answered_at_ms'] = Variable<int>(answeredAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeeklyTestItemsCompanion(')
          ..write('id: $id, ')
          ..write('testId: $testId, ')
          ..write('promptSnapshot: $promptSnapshot, ')
          ..write('correct: $correct, ')
          ..write('answeredAtMs: $answeredAtMs')
          ..write(')'))
        .toString();
  }
}

class $PlaySessionsTable extends PlaySessions
    with TableInfo<$PlaySessionsTable, PlaySessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaySessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<int> dayKey = GeneratedColumn<int>(
    'day_key',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMsMeta = const VerificationMeta(
    'startedAtMs',
  );
  @override
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
    'started_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMsMeta = const VerificationMeta(
    'endedAtMs',
  );
  @override
  late final GeneratedColumn<int> endedAtMs = GeneratedColumn<int>(
    'ended_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secondsConsumedMeta = const VerificationMeta(
    'secondsConsumed',
  );
  @override
  late final GeneratedColumn<int> secondsConsumed = GeneratedColumn<int>(
    'seconds_consumed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<PlayEndReason?, int> endReason =
      GeneratedColumn<int>(
        'end_reason',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<PlayEndReason?>($PlaySessionsTable.$converterendReasonn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    packageName,
    dayKey,
    startedAtMs,
    endedAtMs,
    secondsConsumed,
    endReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'play_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaySessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
        _startedAtMsMeta,
        startedAtMs.isAcceptableOrUnknown(
          data['started_at_ms']!,
          _startedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('ended_at_ms')) {
      context.handle(
        _endedAtMsMeta,
        endedAtMs.isAcceptableOrUnknown(data['ended_at_ms']!, _endedAtMsMeta),
      );
    }
    if (data.containsKey('seconds_consumed')) {
      context.handle(
        _secondsConsumedMeta,
        secondsConsumed.isAcceptableOrUnknown(
          data['seconds_consumed']!,
          _secondsConsumedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaySessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaySessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_key'],
      )!,
      startedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_ms'],
      )!,
      endedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at_ms'],
      ),
      secondsConsumed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds_consumed'],
      )!,
      endReason: $PlaySessionsTable.$converterendReasonn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}end_reason'],
        ),
      ),
    );
  }

  @override
  $PlaySessionsTable createAlias(String alias) {
    return $PlaySessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<PlayEndReason, int, int> $converterendReason =
      const EnumIndexConverter<PlayEndReason>(PlayEndReason.values);
  static JsonTypeConverter2<PlayEndReason?, int?, int?> $converterendReasonn =
      JsonTypeConverter2.asNullable($converterendReason);
}

class PlaySessionRow extends DataClass implements Insertable<PlaySessionRow> {
  final int id;
  final String packageName;
  final int dayKey;
  final int startedAtMs;
  final int? endedAtMs;

  /// Measured foreground seconds, not a wall-clock difference. This is what
  /// makes the appendix's "الطفل لا يخسر دقائق وهو لا يلعب" exact.
  final int secondsConsumed;
  final PlayEndReason? endReason;
  const PlaySessionRow({
    required this.id,
    required this.packageName,
    required this.dayKey,
    required this.startedAtMs,
    this.endedAtMs,
    required this.secondsConsumed,
    this.endReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['package_name'] = Variable<String>(packageName);
    map['day_key'] = Variable<int>(dayKey);
    map['started_at_ms'] = Variable<int>(startedAtMs);
    if (!nullToAbsent || endedAtMs != null) {
      map['ended_at_ms'] = Variable<int>(endedAtMs);
    }
    map['seconds_consumed'] = Variable<int>(secondsConsumed);
    if (!nullToAbsent || endReason != null) {
      map['end_reason'] = Variable<int>(
        $PlaySessionsTable.$converterendReasonn.toSql(endReason),
      );
    }
    return map;
  }

  PlaySessionsCompanion toCompanion(bool nullToAbsent) {
    return PlaySessionsCompanion(
      id: Value(id),
      packageName: Value(packageName),
      dayKey: Value(dayKey),
      startedAtMs: Value(startedAtMs),
      endedAtMs: endedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAtMs),
      secondsConsumed: Value(secondsConsumed),
      endReason: endReason == null && nullToAbsent
          ? const Value.absent()
          : Value(endReason),
    );
  }

  factory PlaySessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaySessionRow(
      id: serializer.fromJson<int>(json['id']),
      packageName: serializer.fromJson<String>(json['packageName']),
      dayKey: serializer.fromJson<int>(json['dayKey']),
      startedAtMs: serializer.fromJson<int>(json['startedAtMs']),
      endedAtMs: serializer.fromJson<int?>(json['endedAtMs']),
      secondsConsumed: serializer.fromJson<int>(json['secondsConsumed']),
      endReason: $PlaySessionsTable.$converterendReasonn.fromJson(
        serializer.fromJson<int?>(json['endReason']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'packageName': serializer.toJson<String>(packageName),
      'dayKey': serializer.toJson<int>(dayKey),
      'startedAtMs': serializer.toJson<int>(startedAtMs),
      'endedAtMs': serializer.toJson<int?>(endedAtMs),
      'secondsConsumed': serializer.toJson<int>(secondsConsumed),
      'endReason': serializer.toJson<int?>(
        $PlaySessionsTable.$converterendReasonn.toJson(endReason),
      ),
    };
  }

  PlaySessionRow copyWith({
    int? id,
    String? packageName,
    int? dayKey,
    int? startedAtMs,
    Value<int?> endedAtMs = const Value.absent(),
    int? secondsConsumed,
    Value<PlayEndReason?> endReason = const Value.absent(),
  }) => PlaySessionRow(
    id: id ?? this.id,
    packageName: packageName ?? this.packageName,
    dayKey: dayKey ?? this.dayKey,
    startedAtMs: startedAtMs ?? this.startedAtMs,
    endedAtMs: endedAtMs.present ? endedAtMs.value : this.endedAtMs,
    secondsConsumed: secondsConsumed ?? this.secondsConsumed,
    endReason: endReason.present ? endReason.value : this.endReason,
  );
  PlaySessionRow copyWithCompanion(PlaySessionsCompanion data) {
    return PlaySessionRow(
      id: data.id.present ? data.id.value : this.id,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      startedAtMs: data.startedAtMs.present
          ? data.startedAtMs.value
          : this.startedAtMs,
      endedAtMs: data.endedAtMs.present ? data.endedAtMs.value : this.endedAtMs,
      secondsConsumed: data.secondsConsumed.present
          ? data.secondsConsumed.value
          : this.secondsConsumed,
      endReason: data.endReason.present ? data.endReason.value : this.endReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaySessionRow(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('dayKey: $dayKey, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs, ')
          ..write('secondsConsumed: $secondsConsumed, ')
          ..write('endReason: $endReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    packageName,
    dayKey,
    startedAtMs,
    endedAtMs,
    secondsConsumed,
    endReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaySessionRow &&
          other.id == this.id &&
          other.packageName == this.packageName &&
          other.dayKey == this.dayKey &&
          other.startedAtMs == this.startedAtMs &&
          other.endedAtMs == this.endedAtMs &&
          other.secondsConsumed == this.secondsConsumed &&
          other.endReason == this.endReason);
}

class PlaySessionsCompanion extends UpdateCompanion<PlaySessionRow> {
  final Value<int> id;
  final Value<String> packageName;
  final Value<int> dayKey;
  final Value<int> startedAtMs;
  final Value<int?> endedAtMs;
  final Value<int> secondsConsumed;
  final Value<PlayEndReason?> endReason;
  const PlaySessionsCompanion({
    this.id = const Value.absent(),
    this.packageName = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.endedAtMs = const Value.absent(),
    this.secondsConsumed = const Value.absent(),
    this.endReason = const Value.absent(),
  });
  PlaySessionsCompanion.insert({
    this.id = const Value.absent(),
    required String packageName,
    required int dayKey,
    required int startedAtMs,
    this.endedAtMs = const Value.absent(),
    this.secondsConsumed = const Value.absent(),
    this.endReason = const Value.absent(),
  }) : packageName = Value(packageName),
       dayKey = Value(dayKey),
       startedAtMs = Value(startedAtMs);
  static Insertable<PlaySessionRow> custom({
    Expression<int>? id,
    Expression<String>? packageName,
    Expression<int>? dayKey,
    Expression<int>? startedAtMs,
    Expression<int>? endedAtMs,
    Expression<int>? secondsConsumed,
    Expression<int>? endReason,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (packageName != null) 'package_name': packageName,
      if (dayKey != null) 'day_key': dayKey,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (endedAtMs != null) 'ended_at_ms': endedAtMs,
      if (secondsConsumed != null) 'seconds_consumed': secondsConsumed,
      if (endReason != null) 'end_reason': endReason,
    });
  }

  PlaySessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? packageName,
    Value<int>? dayKey,
    Value<int>? startedAtMs,
    Value<int?>? endedAtMs,
    Value<int>? secondsConsumed,
    Value<PlayEndReason?>? endReason,
  }) {
    return PlaySessionsCompanion(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      dayKey: dayKey ?? this.dayKey,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      endedAtMs: endedAtMs ?? this.endedAtMs,
      secondsConsumed: secondsConsumed ?? this.secondsConsumed,
      endReason: endReason ?? this.endReason,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<int>(dayKey.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (endedAtMs.present) {
      map['ended_at_ms'] = Variable<int>(endedAtMs.value);
    }
    if (secondsConsumed.present) {
      map['seconds_consumed'] = Variable<int>(secondsConsumed.value);
    }
    if (endReason.present) {
      map['end_reason'] = Variable<int>(
        $PlaySessionsTable.$converterendReasonn.toSql(endReason.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaySessionsCompanion(')
          ..write('id: $id, ')
          ..write('packageName: $packageName, ')
          ..write('dayKey: $dayKey, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('endedAtMs: $endedAtMs, ')
          ..write('secondsConsumed: $secondsConsumed, ')
          ..write('endReason: $endReason')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionCachesTable extends SubscriptionCaches
    with TableInfo<$SubscriptionCachesTable, SubscriptionCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _signatureHexMeta = const VerificationMeta(
    'signatureHex',
  );
  @override
  late final GeneratedColumn<String> signatureHex = GeneratedColumn<String>(
    'signature_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _fetchedAtMsMeta = const VerificationMeta(
    'fetchedAtMs',
  );
  @override
  late final GeneratedColumn<int> fetchedAtMs = GeneratedColumn<int>(
    'fetched_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SubscriptionStateRow, int> state =
      GeneratedColumn<int>(
        'state',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(3),
      ).withConverter<SubscriptionStateRow>(
        $SubscriptionCachesTable.$converterstate,
      );
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _endsAtMsMeta = const VerificationMeta(
    'endsAtMs',
  );
  @override
  late final GeneratedColumn<int> endsAtMs = GeneratedColumn<int>(
    'ends_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _graceEndsAtMsMeta = const VerificationMeta(
    'graceEndsAtMs',
  );
  @override
  late final GeneratedColumn<int> graceEndsAtMs = GeneratedColumn<int>(
    'grace_ends_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    payloadJson,
    signatureHex,
    fetchedAtMs,
    state,
    plan,
    endsAtMs,
    graceEndsAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscription_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubscriptionCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    }
    if (data.containsKey('signature_hex')) {
      context.handle(
        _signatureHexMeta,
        signatureHex.isAcceptableOrUnknown(
          data['signature_hex']!,
          _signatureHexMeta,
        ),
      );
    }
    if (data.containsKey('fetched_at_ms')) {
      context.handle(
        _fetchedAtMsMeta,
        fetchedAtMs.isAcceptableOrUnknown(
          data['fetched_at_ms']!,
          _fetchedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('plan')) {
      context.handle(
        _planMeta,
        plan.isAcceptableOrUnknown(data['plan']!, _planMeta),
      );
    }
    if (data.containsKey('ends_at_ms')) {
      context.handle(
        _endsAtMsMeta,
        endsAtMs.isAcceptableOrUnknown(data['ends_at_ms']!, _endsAtMsMeta),
      );
    }
    if (data.containsKey('grace_ends_at_ms')) {
      context.handle(
        _graceEndsAtMsMeta,
        graceEndsAtMs.isAcceptableOrUnknown(
          data['grace_ends_at_ms']!,
          _graceEndsAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubscriptionCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubscriptionCacheRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      signatureHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}signature_hex'],
      )!,
      fetchedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at_ms'],
      ),
      state: $SubscriptionCachesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}state'],
        )!,
      ),
      plan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan'],
      )!,
      endsAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ends_at_ms'],
      ),
      graceEndsAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grace_ends_at_ms'],
      ),
    );
  }

  @override
  $SubscriptionCachesTable createAlias(String alias) {
    return $SubscriptionCachesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SubscriptionStateRow, int, int> $converterstate =
      const EnumIndexConverter<SubscriptionStateRow>(
        SubscriptionStateRow.values,
      );
}

class SubscriptionCacheRow extends DataClass
    implements Insertable<SubscriptionCacheRow> {
  final int id;

  /// The exact canonical JSON the server signed. Stored verbatim, because
  /// re-serialising it locally would change the bytes and break verification.
  final String payloadJson;
  final String signatureHex;

  /// Trusted time at which this was fetched — the anchor for the 7-day offline
  /// window. Storing an untrusted timestamp here would let a child extend the
  /// window by moving the clock.
  final int? fetchedAtMs;
  final SubscriptionStateRow state;
  final String plan;
  final int? endsAtMs;
  final int? graceEndsAtMs;
  const SubscriptionCacheRow({
    required this.id,
    required this.payloadJson,
    required this.signatureHex,
    this.fetchedAtMs,
    required this.state,
    required this.plan,
    this.endsAtMs,
    this.graceEndsAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload_json'] = Variable<String>(payloadJson);
    map['signature_hex'] = Variable<String>(signatureHex);
    if (!nullToAbsent || fetchedAtMs != null) {
      map['fetched_at_ms'] = Variable<int>(fetchedAtMs);
    }
    {
      map['state'] = Variable<int>(
        $SubscriptionCachesTable.$converterstate.toSql(state),
      );
    }
    map['plan'] = Variable<String>(plan);
    if (!nullToAbsent || endsAtMs != null) {
      map['ends_at_ms'] = Variable<int>(endsAtMs);
    }
    if (!nullToAbsent || graceEndsAtMs != null) {
      map['grace_ends_at_ms'] = Variable<int>(graceEndsAtMs);
    }
    return map;
  }

  SubscriptionCachesCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionCachesCompanion(
      id: Value(id),
      payloadJson: Value(payloadJson),
      signatureHex: Value(signatureHex),
      fetchedAtMs: fetchedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(fetchedAtMs),
      state: Value(state),
      plan: Value(plan),
      endsAtMs: endsAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(endsAtMs),
      graceEndsAtMs: graceEndsAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(graceEndsAtMs),
    );
  }

  factory SubscriptionCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubscriptionCacheRow(
      id: serializer.fromJson<int>(json['id']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      signatureHex: serializer.fromJson<String>(json['signatureHex']),
      fetchedAtMs: serializer.fromJson<int?>(json['fetchedAtMs']),
      state: $SubscriptionCachesTable.$converterstate.fromJson(
        serializer.fromJson<int>(json['state']),
      ),
      plan: serializer.fromJson<String>(json['plan']),
      endsAtMs: serializer.fromJson<int?>(json['endsAtMs']),
      graceEndsAtMs: serializer.fromJson<int?>(json['graceEndsAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'signatureHex': serializer.toJson<String>(signatureHex),
      'fetchedAtMs': serializer.toJson<int?>(fetchedAtMs),
      'state': serializer.toJson<int>(
        $SubscriptionCachesTable.$converterstate.toJson(state),
      ),
      'plan': serializer.toJson<String>(plan),
      'endsAtMs': serializer.toJson<int?>(endsAtMs),
      'graceEndsAtMs': serializer.toJson<int?>(graceEndsAtMs),
    };
  }

  SubscriptionCacheRow copyWith({
    int? id,
    String? payloadJson,
    String? signatureHex,
    Value<int?> fetchedAtMs = const Value.absent(),
    SubscriptionStateRow? state,
    String? plan,
    Value<int?> endsAtMs = const Value.absent(),
    Value<int?> graceEndsAtMs = const Value.absent(),
  }) => SubscriptionCacheRow(
    id: id ?? this.id,
    payloadJson: payloadJson ?? this.payloadJson,
    signatureHex: signatureHex ?? this.signatureHex,
    fetchedAtMs: fetchedAtMs.present ? fetchedAtMs.value : this.fetchedAtMs,
    state: state ?? this.state,
    plan: plan ?? this.plan,
    endsAtMs: endsAtMs.present ? endsAtMs.value : this.endsAtMs,
    graceEndsAtMs: graceEndsAtMs.present
        ? graceEndsAtMs.value
        : this.graceEndsAtMs,
  );
  SubscriptionCacheRow copyWithCompanion(SubscriptionCachesCompanion data) {
    return SubscriptionCacheRow(
      id: data.id.present ? data.id.value : this.id,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      signatureHex: data.signatureHex.present
          ? data.signatureHex.value
          : this.signatureHex,
      fetchedAtMs: data.fetchedAtMs.present
          ? data.fetchedAtMs.value
          : this.fetchedAtMs,
      state: data.state.present ? data.state.value : this.state,
      plan: data.plan.present ? data.plan.value : this.plan,
      endsAtMs: data.endsAtMs.present ? data.endsAtMs.value : this.endsAtMs,
      graceEndsAtMs: data.graceEndsAtMs.present
          ? data.graceEndsAtMs.value
          : this.graceEndsAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionCacheRow(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('signatureHex: $signatureHex, ')
          ..write('fetchedAtMs: $fetchedAtMs, ')
          ..write('state: $state, ')
          ..write('plan: $plan, ')
          ..write('endsAtMs: $endsAtMs, ')
          ..write('graceEndsAtMs: $graceEndsAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    payloadJson,
    signatureHex,
    fetchedAtMs,
    state,
    plan,
    endsAtMs,
    graceEndsAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubscriptionCacheRow &&
          other.id == this.id &&
          other.payloadJson == this.payloadJson &&
          other.signatureHex == this.signatureHex &&
          other.fetchedAtMs == this.fetchedAtMs &&
          other.state == this.state &&
          other.plan == this.plan &&
          other.endsAtMs == this.endsAtMs &&
          other.graceEndsAtMs == this.graceEndsAtMs);
}

class SubscriptionCachesCompanion
    extends UpdateCompanion<SubscriptionCacheRow> {
  final Value<int> id;
  final Value<String> payloadJson;
  final Value<String> signatureHex;
  final Value<int?> fetchedAtMs;
  final Value<SubscriptionStateRow> state;
  final Value<String> plan;
  final Value<int?> endsAtMs;
  final Value<int?> graceEndsAtMs;
  const SubscriptionCachesCompanion({
    this.id = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.signatureHex = const Value.absent(),
    this.fetchedAtMs = const Value.absent(),
    this.state = const Value.absent(),
    this.plan = const Value.absent(),
    this.endsAtMs = const Value.absent(),
    this.graceEndsAtMs = const Value.absent(),
  });
  SubscriptionCachesCompanion.insert({
    this.id = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.signatureHex = const Value.absent(),
    this.fetchedAtMs = const Value.absent(),
    this.state = const Value.absent(),
    this.plan = const Value.absent(),
    this.endsAtMs = const Value.absent(),
    this.graceEndsAtMs = const Value.absent(),
  });
  static Insertable<SubscriptionCacheRow> custom({
    Expression<int>? id,
    Expression<String>? payloadJson,
    Expression<String>? signatureHex,
    Expression<int>? fetchedAtMs,
    Expression<int>? state,
    Expression<String>? plan,
    Expression<int>? endsAtMs,
    Expression<int>? graceEndsAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (signatureHex != null) 'signature_hex': signatureHex,
      if (fetchedAtMs != null) 'fetched_at_ms': fetchedAtMs,
      if (state != null) 'state': state,
      if (plan != null) 'plan': plan,
      if (endsAtMs != null) 'ends_at_ms': endsAtMs,
      if (graceEndsAtMs != null) 'grace_ends_at_ms': graceEndsAtMs,
    });
  }

  SubscriptionCachesCompanion copyWith({
    Value<int>? id,
    Value<String>? payloadJson,
    Value<String>? signatureHex,
    Value<int?>? fetchedAtMs,
    Value<SubscriptionStateRow>? state,
    Value<String>? plan,
    Value<int?>? endsAtMs,
    Value<int?>? graceEndsAtMs,
  }) {
    return SubscriptionCachesCompanion(
      id: id ?? this.id,
      payloadJson: payloadJson ?? this.payloadJson,
      signatureHex: signatureHex ?? this.signatureHex,
      fetchedAtMs: fetchedAtMs ?? this.fetchedAtMs,
      state: state ?? this.state,
      plan: plan ?? this.plan,
      endsAtMs: endsAtMs ?? this.endsAtMs,
      graceEndsAtMs: graceEndsAtMs ?? this.graceEndsAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (signatureHex.present) {
      map['signature_hex'] = Variable<String>(signatureHex.value);
    }
    if (fetchedAtMs.present) {
      map['fetched_at_ms'] = Variable<int>(fetchedAtMs.value);
    }
    if (state.present) {
      map['state'] = Variable<int>(
        $SubscriptionCachesTable.$converterstate.toSql(state.value),
      );
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (endsAtMs.present) {
      map['ends_at_ms'] = Variable<int>(endsAtMs.value);
    }
    if (graceEndsAtMs.present) {
      map['grace_ends_at_ms'] = Variable<int>(graceEndsAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionCachesCompanion(')
          ..write('id: $id, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('signatureHex: $signatureHex, ')
          ..write('fetchedAtMs: $fetchedAtMs, ')
          ..write('state: $state, ')
          ..write('plan: $plan, ')
          ..write('endsAtMs: $endsAtMs, ')
          ..write('graceEndsAtMs: $graceEndsAtMs')
          ..write(')'))
        .toString();
  }
}

class $ClockStatesTable extends ClockStates
    with TableInfo<$ClockStatesTable, ClockStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClockStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _anchorServerEpochMsMeta =
      const VerificationMeta('anchorServerEpochMs');
  @override
  late final GeneratedColumn<int> anchorServerEpochMs = GeneratedColumn<int>(
    'anchor_server_epoch_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _anchorElapsedRealtimeMsMeta =
      const VerificationMeta('anchorElapsedRealtimeMs');
  @override
  late final GeneratedColumn<int> anchorElapsedRealtimeMs =
      GeneratedColumn<int>(
        'anchor_elapsed_realtime_ms',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _anchorBootIdMeta = const VerificationMeta(
    'anchorBootId',
  );
  @override
  late final GeneratedColumn<String> anchorBootId = GeneratedColumn<String>(
    'anchor_boot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _highWaterEpochMsMeta = const VerificationMeta(
    'highWaterEpochMs',
  );
  @override
  late final GeneratedColumn<int> highWaterEpochMs = GeneratedColumn<int>(
    'high_water_epoch_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastBootIdMeta = const VerificationMeta(
    'lastBootId',
  );
  @override
  late final GeneratedColumn<String> lastBootId = GeneratedColumn<String>(
    'last_boot_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastElapsedRealtimeMsMeta =
      const VerificationMeta('lastElapsedRealtimeMs');
  @override
  late final GeneratedColumn<int> lastElapsedRealtimeMs = GeneratedColumn<int>(
    'last_elapsed_realtime_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tamperCountMeta = const VerificationMeta(
    'tamperCount',
  );
  @override
  late final GeneratedColumn<int> tamperCount = GeneratedColumn<int>(
    'tamper_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastTamperSignalMeta = const VerificationMeta(
    'lastTamperSignal',
  );
  @override
  late final GeneratedColumn<String> lastTamperSignal = GeneratedColumn<String>(
    'last_tamper_signal',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    anchorServerEpochMs,
    anchorElapsedRealtimeMs,
    anchorBootId,
    highWaterEpochMs,
    lastBootId,
    lastElapsedRealtimeMs,
    tamperCount,
    lastTamperSignal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clock_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClockStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('anchor_server_epoch_ms')) {
      context.handle(
        _anchorServerEpochMsMeta,
        anchorServerEpochMs.isAcceptableOrUnknown(
          data['anchor_server_epoch_ms']!,
          _anchorServerEpochMsMeta,
        ),
      );
    }
    if (data.containsKey('anchor_elapsed_realtime_ms')) {
      context.handle(
        _anchorElapsedRealtimeMsMeta,
        anchorElapsedRealtimeMs.isAcceptableOrUnknown(
          data['anchor_elapsed_realtime_ms']!,
          _anchorElapsedRealtimeMsMeta,
        ),
      );
    }
    if (data.containsKey('anchor_boot_id')) {
      context.handle(
        _anchorBootIdMeta,
        anchorBootId.isAcceptableOrUnknown(
          data['anchor_boot_id']!,
          _anchorBootIdMeta,
        ),
      );
    }
    if (data.containsKey('high_water_epoch_ms')) {
      context.handle(
        _highWaterEpochMsMeta,
        highWaterEpochMs.isAcceptableOrUnknown(
          data['high_water_epoch_ms']!,
          _highWaterEpochMsMeta,
        ),
      );
    }
    if (data.containsKey('last_boot_id')) {
      context.handle(
        _lastBootIdMeta,
        lastBootId.isAcceptableOrUnknown(
          data['last_boot_id']!,
          _lastBootIdMeta,
        ),
      );
    }
    if (data.containsKey('last_elapsed_realtime_ms')) {
      context.handle(
        _lastElapsedRealtimeMsMeta,
        lastElapsedRealtimeMs.isAcceptableOrUnknown(
          data['last_elapsed_realtime_ms']!,
          _lastElapsedRealtimeMsMeta,
        ),
      );
    }
    if (data.containsKey('tamper_count')) {
      context.handle(
        _tamperCountMeta,
        tamperCount.isAcceptableOrUnknown(
          data['tamper_count']!,
          _tamperCountMeta,
        ),
      );
    }
    if (data.containsKey('last_tamper_signal')) {
      context.handle(
        _lastTamperSignalMeta,
        lastTamperSignal.isAcceptableOrUnknown(
          data['last_tamper_signal']!,
          _lastTamperSignalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClockStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClockStateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      anchorServerEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anchor_server_epoch_ms'],
      ),
      anchorElapsedRealtimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anchor_elapsed_realtime_ms'],
      ),
      anchorBootId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_boot_id'],
      ),
      highWaterEpochMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}high_water_epoch_ms'],
      )!,
      lastBootId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_boot_id'],
      ),
      lastElapsedRealtimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_elapsed_realtime_ms'],
      )!,
      tamperCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tamper_count'],
      )!,
      lastTamperSignal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_tamper_signal'],
      ),
    );
  }

  @override
  $ClockStatesTable createAlias(String alias) {
    return $ClockStatesTable(attachedDatabase, alias);
  }
}

class ClockStateRow extends DataClass implements Insertable<ClockStateRow> {
  final int id;
  final int? anchorServerEpochMs;
  final int? anchorElapsedRealtimeMs;
  final String? anchorBootId;

  /// The latest instant ever resolved. Forward-only: this single value is what
  /// makes "set the clock back to replay yesterday" pointless.
  final int highWaterEpochMs;
  final String? lastBootId;
  final int lastElapsedRealtimeMs;
  final int tamperCount;
  final String? lastTamperSignal;
  const ClockStateRow({
    required this.id,
    this.anchorServerEpochMs,
    this.anchorElapsedRealtimeMs,
    this.anchorBootId,
    required this.highWaterEpochMs,
    this.lastBootId,
    required this.lastElapsedRealtimeMs,
    required this.tamperCount,
    this.lastTamperSignal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || anchorServerEpochMs != null) {
      map['anchor_server_epoch_ms'] = Variable<int>(anchorServerEpochMs);
    }
    if (!nullToAbsent || anchorElapsedRealtimeMs != null) {
      map['anchor_elapsed_realtime_ms'] = Variable<int>(
        anchorElapsedRealtimeMs,
      );
    }
    if (!nullToAbsent || anchorBootId != null) {
      map['anchor_boot_id'] = Variable<String>(anchorBootId);
    }
    map['high_water_epoch_ms'] = Variable<int>(highWaterEpochMs);
    if (!nullToAbsent || lastBootId != null) {
      map['last_boot_id'] = Variable<String>(lastBootId);
    }
    map['last_elapsed_realtime_ms'] = Variable<int>(lastElapsedRealtimeMs);
    map['tamper_count'] = Variable<int>(tamperCount);
    if (!nullToAbsent || lastTamperSignal != null) {
      map['last_tamper_signal'] = Variable<String>(lastTamperSignal);
    }
    return map;
  }

  ClockStatesCompanion toCompanion(bool nullToAbsent) {
    return ClockStatesCompanion(
      id: Value(id),
      anchorServerEpochMs: anchorServerEpochMs == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorServerEpochMs),
      anchorElapsedRealtimeMs: anchorElapsedRealtimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorElapsedRealtimeMs),
      anchorBootId: anchorBootId == null && nullToAbsent
          ? const Value.absent()
          : Value(anchorBootId),
      highWaterEpochMs: Value(highWaterEpochMs),
      lastBootId: lastBootId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBootId),
      lastElapsedRealtimeMs: Value(lastElapsedRealtimeMs),
      tamperCount: Value(tamperCount),
      lastTamperSignal: lastTamperSignal == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTamperSignal),
    );
  }

  factory ClockStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClockStateRow(
      id: serializer.fromJson<int>(json['id']),
      anchorServerEpochMs: serializer.fromJson<int?>(
        json['anchorServerEpochMs'],
      ),
      anchorElapsedRealtimeMs: serializer.fromJson<int?>(
        json['anchorElapsedRealtimeMs'],
      ),
      anchorBootId: serializer.fromJson<String?>(json['anchorBootId']),
      highWaterEpochMs: serializer.fromJson<int>(json['highWaterEpochMs']),
      lastBootId: serializer.fromJson<String?>(json['lastBootId']),
      lastElapsedRealtimeMs: serializer.fromJson<int>(
        json['lastElapsedRealtimeMs'],
      ),
      tamperCount: serializer.fromJson<int>(json['tamperCount']),
      lastTamperSignal: serializer.fromJson<String?>(json['lastTamperSignal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'anchorServerEpochMs': serializer.toJson<int?>(anchorServerEpochMs),
      'anchorElapsedRealtimeMs': serializer.toJson<int?>(
        anchorElapsedRealtimeMs,
      ),
      'anchorBootId': serializer.toJson<String?>(anchorBootId),
      'highWaterEpochMs': serializer.toJson<int>(highWaterEpochMs),
      'lastBootId': serializer.toJson<String?>(lastBootId),
      'lastElapsedRealtimeMs': serializer.toJson<int>(lastElapsedRealtimeMs),
      'tamperCount': serializer.toJson<int>(tamperCount),
      'lastTamperSignal': serializer.toJson<String?>(lastTamperSignal),
    };
  }

  ClockStateRow copyWith({
    int? id,
    Value<int?> anchorServerEpochMs = const Value.absent(),
    Value<int?> anchorElapsedRealtimeMs = const Value.absent(),
    Value<String?> anchorBootId = const Value.absent(),
    int? highWaterEpochMs,
    Value<String?> lastBootId = const Value.absent(),
    int? lastElapsedRealtimeMs,
    int? tamperCount,
    Value<String?> lastTamperSignal = const Value.absent(),
  }) => ClockStateRow(
    id: id ?? this.id,
    anchorServerEpochMs: anchorServerEpochMs.present
        ? anchorServerEpochMs.value
        : this.anchorServerEpochMs,
    anchorElapsedRealtimeMs: anchorElapsedRealtimeMs.present
        ? anchorElapsedRealtimeMs.value
        : this.anchorElapsedRealtimeMs,
    anchorBootId: anchorBootId.present ? anchorBootId.value : this.anchorBootId,
    highWaterEpochMs: highWaterEpochMs ?? this.highWaterEpochMs,
    lastBootId: lastBootId.present ? lastBootId.value : this.lastBootId,
    lastElapsedRealtimeMs: lastElapsedRealtimeMs ?? this.lastElapsedRealtimeMs,
    tamperCount: tamperCount ?? this.tamperCount,
    lastTamperSignal: lastTamperSignal.present
        ? lastTamperSignal.value
        : this.lastTamperSignal,
  );
  ClockStateRow copyWithCompanion(ClockStatesCompanion data) {
    return ClockStateRow(
      id: data.id.present ? data.id.value : this.id,
      anchorServerEpochMs: data.anchorServerEpochMs.present
          ? data.anchorServerEpochMs.value
          : this.anchorServerEpochMs,
      anchorElapsedRealtimeMs: data.anchorElapsedRealtimeMs.present
          ? data.anchorElapsedRealtimeMs.value
          : this.anchorElapsedRealtimeMs,
      anchorBootId: data.anchorBootId.present
          ? data.anchorBootId.value
          : this.anchorBootId,
      highWaterEpochMs: data.highWaterEpochMs.present
          ? data.highWaterEpochMs.value
          : this.highWaterEpochMs,
      lastBootId: data.lastBootId.present
          ? data.lastBootId.value
          : this.lastBootId,
      lastElapsedRealtimeMs: data.lastElapsedRealtimeMs.present
          ? data.lastElapsedRealtimeMs.value
          : this.lastElapsedRealtimeMs,
      tamperCount: data.tamperCount.present
          ? data.tamperCount.value
          : this.tamperCount,
      lastTamperSignal: data.lastTamperSignal.present
          ? data.lastTamperSignal.value
          : this.lastTamperSignal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClockStateRow(')
          ..write('id: $id, ')
          ..write('anchorServerEpochMs: $anchorServerEpochMs, ')
          ..write('anchorElapsedRealtimeMs: $anchorElapsedRealtimeMs, ')
          ..write('anchorBootId: $anchorBootId, ')
          ..write('highWaterEpochMs: $highWaterEpochMs, ')
          ..write('lastBootId: $lastBootId, ')
          ..write('lastElapsedRealtimeMs: $lastElapsedRealtimeMs, ')
          ..write('tamperCount: $tamperCount, ')
          ..write('lastTamperSignal: $lastTamperSignal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    anchorServerEpochMs,
    anchorElapsedRealtimeMs,
    anchorBootId,
    highWaterEpochMs,
    lastBootId,
    lastElapsedRealtimeMs,
    tamperCount,
    lastTamperSignal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClockStateRow &&
          other.id == this.id &&
          other.anchorServerEpochMs == this.anchorServerEpochMs &&
          other.anchorElapsedRealtimeMs == this.anchorElapsedRealtimeMs &&
          other.anchorBootId == this.anchorBootId &&
          other.highWaterEpochMs == this.highWaterEpochMs &&
          other.lastBootId == this.lastBootId &&
          other.lastElapsedRealtimeMs == this.lastElapsedRealtimeMs &&
          other.tamperCount == this.tamperCount &&
          other.lastTamperSignal == this.lastTamperSignal);
}

class ClockStatesCompanion extends UpdateCompanion<ClockStateRow> {
  final Value<int> id;
  final Value<int?> anchorServerEpochMs;
  final Value<int?> anchorElapsedRealtimeMs;
  final Value<String?> anchorBootId;
  final Value<int> highWaterEpochMs;
  final Value<String?> lastBootId;
  final Value<int> lastElapsedRealtimeMs;
  final Value<int> tamperCount;
  final Value<String?> lastTamperSignal;
  const ClockStatesCompanion({
    this.id = const Value.absent(),
    this.anchorServerEpochMs = const Value.absent(),
    this.anchorElapsedRealtimeMs = const Value.absent(),
    this.anchorBootId = const Value.absent(),
    this.highWaterEpochMs = const Value.absent(),
    this.lastBootId = const Value.absent(),
    this.lastElapsedRealtimeMs = const Value.absent(),
    this.tamperCount = const Value.absent(),
    this.lastTamperSignal = const Value.absent(),
  });
  ClockStatesCompanion.insert({
    this.id = const Value.absent(),
    this.anchorServerEpochMs = const Value.absent(),
    this.anchorElapsedRealtimeMs = const Value.absent(),
    this.anchorBootId = const Value.absent(),
    this.highWaterEpochMs = const Value.absent(),
    this.lastBootId = const Value.absent(),
    this.lastElapsedRealtimeMs = const Value.absent(),
    this.tamperCount = const Value.absent(),
    this.lastTamperSignal = const Value.absent(),
  });
  static Insertable<ClockStateRow> custom({
    Expression<int>? id,
    Expression<int>? anchorServerEpochMs,
    Expression<int>? anchorElapsedRealtimeMs,
    Expression<String>? anchorBootId,
    Expression<int>? highWaterEpochMs,
    Expression<String>? lastBootId,
    Expression<int>? lastElapsedRealtimeMs,
    Expression<int>? tamperCount,
    Expression<String>? lastTamperSignal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (anchorServerEpochMs != null)
        'anchor_server_epoch_ms': anchorServerEpochMs,
      if (anchorElapsedRealtimeMs != null)
        'anchor_elapsed_realtime_ms': anchorElapsedRealtimeMs,
      if (anchorBootId != null) 'anchor_boot_id': anchorBootId,
      if (highWaterEpochMs != null) 'high_water_epoch_ms': highWaterEpochMs,
      if (lastBootId != null) 'last_boot_id': lastBootId,
      if (lastElapsedRealtimeMs != null)
        'last_elapsed_realtime_ms': lastElapsedRealtimeMs,
      if (tamperCount != null) 'tamper_count': tamperCount,
      if (lastTamperSignal != null) 'last_tamper_signal': lastTamperSignal,
    });
  }

  ClockStatesCompanion copyWith({
    Value<int>? id,
    Value<int?>? anchorServerEpochMs,
    Value<int?>? anchorElapsedRealtimeMs,
    Value<String?>? anchorBootId,
    Value<int>? highWaterEpochMs,
    Value<String?>? lastBootId,
    Value<int>? lastElapsedRealtimeMs,
    Value<int>? tamperCount,
    Value<String?>? lastTamperSignal,
  }) {
    return ClockStatesCompanion(
      id: id ?? this.id,
      anchorServerEpochMs: anchorServerEpochMs ?? this.anchorServerEpochMs,
      anchorElapsedRealtimeMs:
          anchorElapsedRealtimeMs ?? this.anchorElapsedRealtimeMs,
      anchorBootId: anchorBootId ?? this.anchorBootId,
      highWaterEpochMs: highWaterEpochMs ?? this.highWaterEpochMs,
      lastBootId: lastBootId ?? this.lastBootId,
      lastElapsedRealtimeMs:
          lastElapsedRealtimeMs ?? this.lastElapsedRealtimeMs,
      tamperCount: tamperCount ?? this.tamperCount,
      lastTamperSignal: lastTamperSignal ?? this.lastTamperSignal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (anchorServerEpochMs.present) {
      map['anchor_server_epoch_ms'] = Variable<int>(anchorServerEpochMs.value);
    }
    if (anchorElapsedRealtimeMs.present) {
      map['anchor_elapsed_realtime_ms'] = Variable<int>(
        anchorElapsedRealtimeMs.value,
      );
    }
    if (anchorBootId.present) {
      map['anchor_boot_id'] = Variable<String>(anchorBootId.value);
    }
    if (highWaterEpochMs.present) {
      map['high_water_epoch_ms'] = Variable<int>(highWaterEpochMs.value);
    }
    if (lastBootId.present) {
      map['last_boot_id'] = Variable<String>(lastBootId.value);
    }
    if (lastElapsedRealtimeMs.present) {
      map['last_elapsed_realtime_ms'] = Variable<int>(
        lastElapsedRealtimeMs.value,
      );
    }
    if (tamperCount.present) {
      map['tamper_count'] = Variable<int>(tamperCount.value);
    }
    if (lastTamperSignal.present) {
      map['last_tamper_signal'] = Variable<String>(lastTamperSignal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClockStatesCompanion(')
          ..write('id: $id, ')
          ..write('anchorServerEpochMs: $anchorServerEpochMs, ')
          ..write('anchorElapsedRealtimeMs: $anchorElapsedRealtimeMs, ')
          ..write('anchorBootId: $anchorBootId, ')
          ..write('highWaterEpochMs: $highWaterEpochMs, ')
          ..write('lastBootId: $lastBootId, ')
          ..write('lastElapsedRealtimeMs: $lastElapsedRealtimeMs, ')
          ..write('tamperCount: $tamperCount, ')
          ..write('lastTamperSignal: $lastTamperSignal')
          ..write(')'))
        .toString();
  }
}

class $AuthTokensTable extends AuthTokens
    with TableInfo<$AuthTokensTable, AuthTokenRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuthTokensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _accessTokenMeta = const VerificationMeta(
    'accessToken',
  );
  @override
  late final GeneratedColumn<String> accessToken = GeneratedColumn<String>(
    'access_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _refreshTokenMeta = const VerificationMeta(
    'refreshToken',
  );
  @override
  late final GeneratedColumn<String> refreshToken = GeneratedColumn<String>(
    'refresh_token',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _signedInAtMsMeta = const VerificationMeta(
    'signedInAtMs',
  );
  @override
  late final GeneratedColumn<int> signedInAtMs = GeneratedColumn<int>(
    'signed_in_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accessToken,
    refreshToken,
    email,
    signedInAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'auth_tokens';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuthTokenRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('access_token')) {
      context.handle(
        _accessTokenMeta,
        accessToken.isAcceptableOrUnknown(
          data['access_token']!,
          _accessTokenMeta,
        ),
      );
    }
    if (data.containsKey('refresh_token')) {
      context.handle(
        _refreshTokenMeta,
        refreshToken.isAcceptableOrUnknown(
          data['refresh_token']!,
          _refreshTokenMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('signed_in_at_ms')) {
      context.handle(
        _signedInAtMsMeta,
        signedInAtMs.isAcceptableOrUnknown(
          data['signed_in_at_ms']!,
          _signedInAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuthTokenRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuthTokenRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accessToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_token'],
      )!,
      refreshToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refresh_token'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      signedInAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}signed_in_at_ms'],
      ),
    );
  }

  @override
  $AuthTokensTable createAlias(String alias) {
    return $AuthTokensTable(attachedDatabase, alias);
  }
}

class AuthTokenRow extends DataClass implements Insertable<AuthTokenRow> {
  final int id;
  final String accessToken;
  final String refreshToken;

  /// The account the tokens belong to, for the parent's own reference. An email
  /// is a parent identifier, which Article 14 permits — it forbids identifiers of
  /// the **child**.
  final String email;

  /// Trusted time of the last successful sign-in.
  final int? signedInAtMs;
  const AuthTokenRow({
    required this.id,
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    this.signedInAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['access_token'] = Variable<String>(accessToken);
    map['refresh_token'] = Variable<String>(refreshToken);
    map['email'] = Variable<String>(email);
    if (!nullToAbsent || signedInAtMs != null) {
      map['signed_in_at_ms'] = Variable<int>(signedInAtMs);
    }
    return map;
  }

  AuthTokensCompanion toCompanion(bool nullToAbsent) {
    return AuthTokensCompanion(
      id: Value(id),
      accessToken: Value(accessToken),
      refreshToken: Value(refreshToken),
      email: Value(email),
      signedInAtMs: signedInAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(signedInAtMs),
    );
  }

  factory AuthTokenRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuthTokenRow(
      id: serializer.fromJson<int>(json['id']),
      accessToken: serializer.fromJson<String>(json['accessToken']),
      refreshToken: serializer.fromJson<String>(json['refreshToken']),
      email: serializer.fromJson<String>(json['email']),
      signedInAtMs: serializer.fromJson<int?>(json['signedInAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accessToken': serializer.toJson<String>(accessToken),
      'refreshToken': serializer.toJson<String>(refreshToken),
      'email': serializer.toJson<String>(email),
      'signedInAtMs': serializer.toJson<int?>(signedInAtMs),
    };
  }

  AuthTokenRow copyWith({
    int? id,
    String? accessToken,
    String? refreshToken,
    String? email,
    Value<int?> signedInAtMs = const Value.absent(),
  }) => AuthTokenRow(
    id: id ?? this.id,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    email: email ?? this.email,
    signedInAtMs: signedInAtMs.present ? signedInAtMs.value : this.signedInAtMs,
  );
  AuthTokenRow copyWithCompanion(AuthTokensCompanion data) {
    return AuthTokenRow(
      id: data.id.present ? data.id.value : this.id,
      accessToken: data.accessToken.present
          ? data.accessToken.value
          : this.accessToken,
      refreshToken: data.refreshToken.present
          ? data.refreshToken.value
          : this.refreshToken,
      email: data.email.present ? data.email.value : this.email,
      signedInAtMs: data.signedInAtMs.present
          ? data.signedInAtMs.value
          : this.signedInAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuthTokenRow(')
          ..write('id: $id, ')
          ..write('accessToken: $accessToken, ')
          ..write('refreshToken: $refreshToken, ')
          ..write('email: $email, ')
          ..write('signedInAtMs: $signedInAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, accessToken, refreshToken, email, signedInAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuthTokenRow &&
          other.id == this.id &&
          other.accessToken == this.accessToken &&
          other.refreshToken == this.refreshToken &&
          other.email == this.email &&
          other.signedInAtMs == this.signedInAtMs);
}

class AuthTokensCompanion extends UpdateCompanion<AuthTokenRow> {
  final Value<int> id;
  final Value<String> accessToken;
  final Value<String> refreshToken;
  final Value<String> email;
  final Value<int?> signedInAtMs;
  const AuthTokensCompanion({
    this.id = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.refreshToken = const Value.absent(),
    this.email = const Value.absent(),
    this.signedInAtMs = const Value.absent(),
  });
  AuthTokensCompanion.insert({
    this.id = const Value.absent(),
    this.accessToken = const Value.absent(),
    this.refreshToken = const Value.absent(),
    this.email = const Value.absent(),
    this.signedInAtMs = const Value.absent(),
  });
  static Insertable<AuthTokenRow> custom({
    Expression<int>? id,
    Expression<String>? accessToken,
    Expression<String>? refreshToken,
    Expression<String>? email,
    Expression<int>? signedInAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accessToken != null) 'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (email != null) 'email': email,
      if (signedInAtMs != null) 'signed_in_at_ms': signedInAtMs,
    });
  }

  AuthTokensCompanion copyWith({
    Value<int>? id,
    Value<String>? accessToken,
    Value<String>? refreshToken,
    Value<String>? email,
    Value<int?>? signedInAtMs,
  }) {
    return AuthTokensCompanion(
      id: id ?? this.id,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      email: email ?? this.email,
      signedInAtMs: signedInAtMs ?? this.signedInAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accessToken.present) {
      map['access_token'] = Variable<String>(accessToken.value);
    }
    if (refreshToken.present) {
      map['refresh_token'] = Variable<String>(refreshToken.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (signedInAtMs.present) {
      map['signed_in_at_ms'] = Variable<int>(signedInAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuthTokensCompanion(')
          ..write('id: $id, ')
          ..write('accessToken: $accessToken, ')
          ..write('refreshToken: $refreshToken, ')
          ..write('email: $email, ')
          ..write('signedInAtMs: $signedInAtMs')
          ..write(')'))
        .toString();
  }
}

class $EventLogTable extends EventLog
    with TableInfo<$EventLogTable, EventLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailMeta = const VerificationMeta('detail');
  @override
  late final GeneratedColumn<String> detail = GeneratedColumn<String>(
    'detail',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _atMsMeta = const VerificationMeta('atMs');
  @override
  late final GeneratedColumn<int> atMs = GeneratedColumn<int>(
    'at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, type, detail, atMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('detail')) {
      context.handle(
        _detailMeta,
        detail.isAcceptableOrUnknown(data['detail']!, _detailMeta),
      );
    }
    if (data.containsKey('at_ms')) {
      context.handle(
        _atMsMeta,
        atMs.isAcceptableOrUnknown(data['at_ms']!, _atMsMeta),
      );
    } else if (isInserting) {
      context.missing(_atMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      detail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}detail'],
      )!,
      atMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}at_ms'],
      )!,
    );
  }

  @override
  $EventLogTable createAlias(String alias) {
    return $EventLogTable(attachedDatabase, alias);
  }
}

class EventLogRow extends DataClass implements Insertable<EventLogRow> {
  final int id;
  final String type;
  final String detail;
  final int atMs;
  const EventLogRow({
    required this.id,
    required this.type,
    required this.detail,
    required this.atMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<String>(type);
    map['detail'] = Variable<String>(detail);
    map['at_ms'] = Variable<int>(atMs);
    return map;
  }

  EventLogCompanion toCompanion(bool nullToAbsent) {
    return EventLogCompanion(
      id: Value(id),
      type: Value(type),
      detail: Value(detail),
      atMs: Value(atMs),
    );
  }

  factory EventLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventLogRow(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      detail: serializer.fromJson<String>(json['detail']),
      atMs: serializer.fromJson<int>(json['atMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<String>(type),
      'detail': serializer.toJson<String>(detail),
      'atMs': serializer.toJson<int>(atMs),
    };
  }

  EventLogRow copyWith({int? id, String? type, String? detail, int? atMs}) =>
      EventLogRow(
        id: id ?? this.id,
        type: type ?? this.type,
        detail: detail ?? this.detail,
        atMs: atMs ?? this.atMs,
      );
  EventLogRow copyWithCompanion(EventLogCompanion data) {
    return EventLogRow(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      detail: data.detail.present ? data.detail.value : this.detail,
      atMs: data.atMs.present ? data.atMs.value : this.atMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventLogRow(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('detail: $detail, ')
          ..write('atMs: $atMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, type, detail, atMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventLogRow &&
          other.id == this.id &&
          other.type == this.type &&
          other.detail == this.detail &&
          other.atMs == this.atMs);
}

class EventLogCompanion extends UpdateCompanion<EventLogRow> {
  final Value<int> id;
  final Value<String> type;
  final Value<String> detail;
  final Value<int> atMs;
  const EventLogCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.detail = const Value.absent(),
    this.atMs = const Value.absent(),
  });
  EventLogCompanion.insert({
    this.id = const Value.absent(),
    required String type,
    this.detail = const Value.absent(),
    required int atMs,
  }) : type = Value(type),
       atMs = Value(atMs);
  static Insertable<EventLogRow> custom({
    Expression<int>? id,
    Expression<String>? type,
    Expression<String>? detail,
    Expression<int>? atMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (detail != null) 'detail': detail,
      if (atMs != null) 'at_ms': atMs,
    });
  }

  EventLogCompanion copyWith({
    Value<int>? id,
    Value<String>? type,
    Value<String>? detail,
    Value<int>? atMs,
  }) {
    return EventLogCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      detail: detail ?? this.detail,
      atMs: atMs ?? this.atMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (detail.present) {
      map['detail'] = Variable<String>(detail.value);
    }
    if (atMs.present) {
      map['at_ms'] = Variable<int>(atMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventLogCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('detail: $detail, ')
          ..write('atMs: $atMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$LunioDatabase extends GeneratedDatabase {
  _$LunioDatabase(QueryExecutor e) : super(e);
  $LunioDatabaseManager get managers => $LunioDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $ManagedAppsTable managedApps = $ManagedAppsTable(this);
  late final $LessonsTable lessons = $LessonsTable(this);
  late final $LessonImagesTable lessonImages = $LessonImagesTable(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $TaskInstancesTable taskInstances = $TaskInstancesTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  late final $StarLedgerTable starLedger = $StarLedgerTable(this);
  late final $DayProgressRowsTable dayProgressRows = $DayProgressRowsTable(
    this,
  );
  late final $CountedTargetsTable countedTargets = $CountedTargetsTable(this);
  late final $StreakStatesTable streakStates = $StreakStatesTable(this);
  late final $WeeklyTestsTable weeklyTests = $WeeklyTestsTable(this);
  late final $WeeklyTestItemsTable weeklyTestItems = $WeeklyTestItemsTable(
    this,
  );
  late final $PlaySessionsTable playSessions = $PlaySessionsTable(this);
  late final $SubscriptionCachesTable subscriptionCaches =
      $SubscriptionCachesTable(this);
  late final $ClockStatesTable clockStates = $ClockStatesTable(this);
  late final $AuthTokensTable authTokens = $AuthTokensTable(this);
  late final $EventLogTable eventLog = $EventLogTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    managedApps,
    lessons,
    lessonImages,
    cards,
    questions,
    taskInstances,
    attempts,
    starLedger,
    dayProgressRows,
    countedTargets,
    streakStates,
    weeklyTests,
    weeklyTestItems,
    playSessions,
    subscriptionCaches,
    clockStates,
    authTokens,
    eventLog,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'lessons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lesson_images', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'lessons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cards', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'lessons',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('questions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'weekly_tests',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('weekly_test_items', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> pinHash,
      Value<String> pinSalt,
      Value<int> starValueSeconds,
      Value<int> dailyCeilingUnits,
      Value<int> minimumTimeOnTargetMs,
      Value<ExpiryModeRow> expiryMode,
      Value<int> welcomeUnits,
      Value<bool> welcomeGranted,
      Value<int> dailySessionCards,
      Value<int> dailyQuestionCount,
      Value<int> expiryWeekday,
      Value<bool> blockingEnabled,
      Value<bool> launcherMode,
      Value<bool> playPaused,
      Value<String> grade,
      Value<int> onboardingStep,
      Value<int> utcOffsetMinutes,
      Value<String> installId,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<int> id,
      Value<String> pinHash,
      Value<String> pinSalt,
      Value<int> starValueSeconds,
      Value<int> dailyCeilingUnits,
      Value<int> minimumTimeOnTargetMs,
      Value<ExpiryModeRow> expiryMode,
      Value<int> welcomeUnits,
      Value<bool> welcomeGranted,
      Value<int> dailySessionCards,
      Value<int> dailyQuestionCount,
      Value<int> expiryWeekday,
      Value<bool> blockingEnabled,
      Value<bool> launcherMode,
      Value<bool> playPaused,
      Value<String> grade,
      Value<int> onboardingStep,
      Value<int> utcOffsetMinutes,
      Value<String> installId,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$LunioDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pinSalt => $composableBuilder(
    column: $table.pinSalt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get starValueSeconds => $composableBuilder(
    column: $table.starValueSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyCeilingUnits => $composableBuilder(
    column: $table.dailyCeilingUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minimumTimeOnTargetMs => $composableBuilder(
    column: $table.minimumTimeOnTargetMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ExpiryModeRow, ExpiryModeRow, int>
  get expiryMode => $composableBuilder(
    column: $table.expiryMode,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get welcomeUnits => $composableBuilder(
    column: $table.welcomeUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get welcomeGranted => $composableBuilder(
    column: $table.welcomeGranted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailySessionCards => $composableBuilder(
    column: $table.dailySessionCards,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyQuestionCount => $composableBuilder(
    column: $table.dailyQuestionCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiryWeekday => $composableBuilder(
    column: $table.expiryWeekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get blockingEnabled => $composableBuilder(
    column: $table.blockingEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get launcherMode => $composableBuilder(
    column: $table.launcherMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get playPaused => $composableBuilder(
    column: $table.playPaused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get onboardingStep => $composableBuilder(
    column: $table.onboardingStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$LunioDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinSalt => $composableBuilder(
    column: $table.pinSalt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get starValueSeconds => $composableBuilder(
    column: $table.starValueSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyCeilingUnits => $composableBuilder(
    column: $table.dailyCeilingUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minimumTimeOnTargetMs => $composableBuilder(
    column: $table.minimumTimeOnTargetMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiryMode => $composableBuilder(
    column: $table.expiryMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get welcomeUnits => $composableBuilder(
    column: $table.welcomeUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get welcomeGranted => $composableBuilder(
    column: $table.welcomeGranted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailySessionCards => $composableBuilder(
    column: $table.dailySessionCards,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyQuestionCount => $composableBuilder(
    column: $table.dailyQuestionCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiryWeekday => $composableBuilder(
    column: $table.expiryWeekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get blockingEnabled => $composableBuilder(
    column: $table.blockingEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get launcherMode => $composableBuilder(
    column: $table.launcherMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get playPaused => $composableBuilder(
    column: $table.playPaused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get onboardingStep => $composableBuilder(
    column: $table.onboardingStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$LunioDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

  GeneratedColumn<String> get pinSalt =>
      $composableBuilder(column: $table.pinSalt, builder: (column) => column);

  GeneratedColumn<int> get starValueSeconds => $composableBuilder(
    column: $table.starValueSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyCeilingUnits => $composableBuilder(
    column: $table.dailyCeilingUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minimumTimeOnTargetMs => $composableBuilder(
    column: $table.minimumTimeOnTargetMs,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ExpiryModeRow, int> get expiryMode =>
      $composableBuilder(
        column: $table.expiryMode,
        builder: (column) => column,
      );

  GeneratedColumn<int> get welcomeUnits => $composableBuilder(
    column: $table.welcomeUnits,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get welcomeGranted => $composableBuilder(
    column: $table.welcomeGranted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailySessionCards => $composableBuilder(
    column: $table.dailySessionCards,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dailyQuestionCount => $composableBuilder(
    column: $table.dailyQuestionCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiryWeekday => $composableBuilder(
    column: $table.expiryWeekday,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get blockingEnabled => $composableBuilder(
    column: $table.blockingEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get launcherMode => $composableBuilder(
    column: $table.launcherMode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get playPaused => $composableBuilder(
    column: $table.playPaused,
    builder: (column) => column,
  );

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<int> get onboardingStep => $composableBuilder(
    column: $table.onboardingStep,
    builder: (column) => column,
  );

  GeneratedColumn<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $AppSettingsTable,
          SettingsRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$LunioDatabase, $AppSettingsTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$LunioDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> pinHash = const Value.absent(),
                Value<String> pinSalt = const Value.absent(),
                Value<int> starValueSeconds = const Value.absent(),
                Value<int> dailyCeilingUnits = const Value.absent(),
                Value<int> minimumTimeOnTargetMs = const Value.absent(),
                Value<ExpiryModeRow> expiryMode = const Value.absent(),
                Value<int> welcomeUnits = const Value.absent(),
                Value<bool> welcomeGranted = const Value.absent(),
                Value<int> dailySessionCards = const Value.absent(),
                Value<int> dailyQuestionCount = const Value.absent(),
                Value<int> expiryWeekday = const Value.absent(),
                Value<bool> blockingEnabled = const Value.absent(),
                Value<bool> launcherMode = const Value.absent(),
                Value<bool> playPaused = const Value.absent(),
                Value<String> grade = const Value.absent(),
                Value<int> onboardingStep = const Value.absent(),
                Value<int> utcOffsetMinutes = const Value.absent(),
                Value<String> installId = const Value.absent(),
              }) => AppSettingsCompanion(
                id: id,
                pinHash: pinHash,
                pinSalt: pinSalt,
                starValueSeconds: starValueSeconds,
                dailyCeilingUnits: dailyCeilingUnits,
                minimumTimeOnTargetMs: minimumTimeOnTargetMs,
                expiryMode: expiryMode,
                welcomeUnits: welcomeUnits,
                welcomeGranted: welcomeGranted,
                dailySessionCards: dailySessionCards,
                dailyQuestionCount: dailyQuestionCount,
                expiryWeekday: expiryWeekday,
                blockingEnabled: blockingEnabled,
                launcherMode: launcherMode,
                playPaused: playPaused,
                grade: grade,
                onboardingStep: onboardingStep,
                utcOffsetMinutes: utcOffsetMinutes,
                installId: installId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> pinHash = const Value.absent(),
                Value<String> pinSalt = const Value.absent(),
                Value<int> starValueSeconds = const Value.absent(),
                Value<int> dailyCeilingUnits = const Value.absent(),
                Value<int> minimumTimeOnTargetMs = const Value.absent(),
                Value<ExpiryModeRow> expiryMode = const Value.absent(),
                Value<int> welcomeUnits = const Value.absent(),
                Value<bool> welcomeGranted = const Value.absent(),
                Value<int> dailySessionCards = const Value.absent(),
                Value<int> dailyQuestionCount = const Value.absent(),
                Value<int> expiryWeekday = const Value.absent(),
                Value<bool> blockingEnabled = const Value.absent(),
                Value<bool> launcherMode = const Value.absent(),
                Value<bool> playPaused = const Value.absent(),
                Value<String> grade = const Value.absent(),
                Value<int> onboardingStep = const Value.absent(),
                Value<int> utcOffsetMinutes = const Value.absent(),
                Value<String> installId = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                id: id,
                pinHash: pinHash,
                pinSalt: pinSalt,
                starValueSeconds: starValueSeconds,
                dailyCeilingUnits: dailyCeilingUnits,
                minimumTimeOnTargetMs: minimumTimeOnTargetMs,
                expiryMode: expiryMode,
                welcomeUnits: welcomeUnits,
                welcomeGranted: welcomeGranted,
                dailySessionCards: dailySessionCards,
                dailyQuestionCount: dailyQuestionCount,
                expiryWeekday: expiryWeekday,
                blockingEnabled: blockingEnabled,
                launcherMode: launcherMode,
                playPaused: playPaused,
                grade: grade,
                onboardingStep: onboardingStep,
                utcOffsetMinutes: utcOffsetMinutes,
                installId: installId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $AppSettingsTable,
      SettingsRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$LunioDatabase, $AppSettingsTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;
typedef $$ManagedAppsTableCreateCompanionBuilder =
    ManagedAppsCompanion Function({
      required String packageName,
      Value<String> label,
      required AppPolicy policy,
      Value<bool> isGameByStore,
      Value<int> addedAtMs,
      Value<int> rowid,
    });
typedef $$ManagedAppsTableUpdateCompanionBuilder =
    ManagedAppsCompanion Function({
      Value<String> packageName,
      Value<String> label,
      Value<AppPolicy> policy,
      Value<bool> isGameByStore,
      Value<int> addedAtMs,
      Value<int> rowid,
    });

class $$ManagedAppsTableFilterComposer
    extends Composer<_$LunioDatabase, $ManagedAppsTable> {
  $$ManagedAppsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AppPolicy, AppPolicy, int> get policy =>
      $composableBuilder(
        column: $table.policy,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<bool> get isGameByStore => $composableBuilder(
    column: $table.isGameByStore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAtMs => $composableBuilder(
    column: $table.addedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ManagedAppsTableOrderingComposer
    extends Composer<_$LunioDatabase, $ManagedAppsTable> {
  $$ManagedAppsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get policy => $composableBuilder(
    column: $table.policy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGameByStore => $composableBuilder(
    column: $table.isGameByStore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAtMs => $composableBuilder(
    column: $table.addedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ManagedAppsTableAnnotationComposer
    extends Composer<_$LunioDatabase, $ManagedAppsTable> {
  $$ManagedAppsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AppPolicy, int> get policy =>
      $composableBuilder(column: $table.policy, builder: (column) => column);

  GeneratedColumn<bool> get isGameByStore => $composableBuilder(
    column: $table.isGameByStore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get addedAtMs =>
      $composableBuilder(column: $table.addedAtMs, builder: (column) => column);
}

class $$ManagedAppsTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $ManagedAppsTable,
          ManagedAppRow,
          $$ManagedAppsTableFilterComposer,
          $$ManagedAppsTableOrderingComposer,
          $$ManagedAppsTableAnnotationComposer,
          $$ManagedAppsTableCreateCompanionBuilder,
          $$ManagedAppsTableUpdateCompanionBuilder,
          (
            ManagedAppRow,
            BaseReferences<_$LunioDatabase, $ManagedAppsTable, ManagedAppRow>,
          ),
          ManagedAppRow,
          PrefetchHooks Function()
        > {
  $$ManagedAppsTableTableManager(_$LunioDatabase db, $ManagedAppsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManagedAppsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ManagedAppsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManagedAppsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> packageName = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<AppPolicy> policy = const Value.absent(),
                Value<bool> isGameByStore = const Value.absent(),
                Value<int> addedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManagedAppsCompanion(
                packageName: packageName,
                label: label,
                policy: policy,
                isGameByStore: isGameByStore,
                addedAtMs: addedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String packageName,
                Value<String> label = const Value.absent(),
                required AppPolicy policy,
                Value<bool> isGameByStore = const Value.absent(),
                Value<int> addedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ManagedAppsCompanion.insert(
                packageName: packageName,
                label: label,
                policy: policy,
                isGameByStore: isGameByStore,
                addedAtMs: addedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ManagedAppsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $ManagedAppsTable,
      ManagedAppRow,
      $$ManagedAppsTableFilterComposer,
      $$ManagedAppsTableOrderingComposer,
      $$ManagedAppsTableAnnotationComposer,
      $$ManagedAppsTableCreateCompanionBuilder,
      $$ManagedAppsTableUpdateCompanionBuilder,
      (
        ManagedAppRow,
        BaseReferences<_$LunioDatabase, $ManagedAppsTable, ManagedAppRow>,
      ),
      ManagedAppRow,
      PrefetchHooks Function()
    >;
typedef $$LessonsTableCreateCompanionBuilder =
    LessonsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> subject,
      Value<String> grade,
      required String summary,
      required int createdAtMs,
      required int weekKey,
      Value<int?> purgedAtMs,
    });
typedef $$LessonsTableUpdateCompanionBuilder =
    LessonsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> subject,
      Value<String> grade,
      Value<String> summary,
      Value<int> createdAtMs,
      Value<int> weekKey,
      Value<int?> purgedAtMs,
    });

final class $$LessonsTableReferences
    extends BaseReferences<_$LunioDatabase, $LessonsTable, LessonRow> {
  $$LessonsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LessonImagesTable, List<LessonImageRow>>
  _lessonImagesRefsTable(_$LunioDatabase db) => MultiTypedResultKey.fromTable(
    db.lessonImages,
    aliasName: $_aliasNameGenerator(db.lessons.id, db.lessonImages.lessonId),
  );

  $$LessonImagesTableProcessedTableManager get lessonImagesRefs {
    final manager = $$LessonImagesTableTableManager(
      $_db,
      $_db.lessonImages,
    ).filter((f) => f.lessonId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_lessonImagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CardsTable, List<CardRow>> _cardsRefsTable(
    _$LunioDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cards,
    aliasName: $_aliasNameGenerator(db.lessons.id, db.cards.lessonId),
  );

  $$CardsTableProcessedTableManager get cardsRefs {
    final manager = $$CardsTableTableManager(
      $_db,
      $_db.cards,
    ).filter((f) => f.lessonId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$QuestionsTable, List<QuestionRow>>
  _questionsRefsTable(_$LunioDatabase db) => MultiTypedResultKey.fromTable(
    db.questions,
    aliasName: $_aliasNameGenerator(db.lessons.id, db.questions.lessonId),
  );

  $$QuestionsTableProcessedTableManager get questionsRefs {
    final manager = $$QuestionsTableTableManager(
      $_db,
      $_db.questions,
    ).filter((f) => f.lessonId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_questionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LessonsTableFilterComposer
    extends Composer<_$LunioDatabase, $LessonsTable> {
  $$LessonsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekKey => $composableBuilder(
    column: $table.weekKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgedAtMs => $composableBuilder(
    column: $table.purgedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> lessonImagesRefs(
    Expression<bool> Function($$LessonImagesTableFilterComposer f) f,
  ) {
    final $$LessonImagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lessonImages,
      getReferencedColumn: (t) => t.lessonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonImagesTableFilterComposer(
            $db: $db,
            $table: $db.lessonImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cardsRefs(
    Expression<bool> Function($$CardsTableFilterComposer f) f,
  ) {
    final $$CardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.lessonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableFilterComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> questionsRefs(
    Expression<bool> Function($$QuestionsTableFilterComposer f) f,
  ) {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.lessonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableFilterComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LessonsTableOrderingComposer
    extends Composer<_$LunioDatabase, $LessonsTable> {
  $$LessonsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subject => $composableBuilder(
    column: $table.subject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekKey => $composableBuilder(
    column: $table.weekKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgedAtMs => $composableBuilder(
    column: $table.purgedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LessonsTableAnnotationComposer
    extends Composer<_$LunioDatabase, $LessonsTable> {
  $$LessonsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get subject =>
      $composableBuilder(column: $table.subject, builder: (column) => column);

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weekKey =>
      $composableBuilder(column: $table.weekKey, builder: (column) => column);

  GeneratedColumn<int> get purgedAtMs => $composableBuilder(
    column: $table.purgedAtMs,
    builder: (column) => column,
  );

  Expression<T> lessonImagesRefs<T extends Object>(
    Expression<T> Function($$LessonImagesTableAnnotationComposer a) f,
  ) {
    final $$LessonImagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.lessonImages,
      getReferencedColumn: (t) => t.lessonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonImagesTableAnnotationComposer(
            $db: $db,
            $table: $db.lessonImages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cardsRefs<T extends Object>(
    Expression<T> Function($$CardsTableAnnotationComposer a) f,
  ) {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cards,
      getReferencedColumn: (t) => t.lessonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CardsTableAnnotationComposer(
            $db: $db,
            $table: $db.cards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> questionsRefs<T extends Object>(
    Expression<T> Function($$QuestionsTableAnnotationComposer a) f,
  ) {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.questions,
      getReferencedColumn: (t) => t.lessonId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$QuestionsTableAnnotationComposer(
            $db: $db,
            $table: $db.questions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LessonsTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $LessonsTable,
          LessonRow,
          $$LessonsTableFilterComposer,
          $$LessonsTableOrderingComposer,
          $$LessonsTableAnnotationComposer,
          $$LessonsTableCreateCompanionBuilder,
          $$LessonsTableUpdateCompanionBuilder,
          (LessonRow, $$LessonsTableReferences),
          LessonRow,
          PrefetchHooks Function({
            bool lessonImagesRefs,
            bool cardsRefs,
            bool questionsRefs,
          })
        > {
  $$LessonsTableTableManager(_$LunioDatabase db, $LessonsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> grade = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> weekKey = const Value.absent(),
                Value<int?> purgedAtMs = const Value.absent(),
              }) => LessonsCompanion(
                id: id,
                title: title,
                subject: subject,
                grade: grade,
                summary: summary,
                createdAtMs: createdAtMs,
                weekKey: weekKey,
                purgedAtMs: purgedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> subject = const Value.absent(),
                Value<String> grade = const Value.absent(),
                required String summary,
                required int createdAtMs,
                required int weekKey,
                Value<int?> purgedAtMs = const Value.absent(),
              }) => LessonsCompanion.insert(
                id: id,
                title: title,
                subject: subject,
                grade: grade,
                summary: summary,
                createdAtMs: createdAtMs,
                weekKey: weekKey,
                purgedAtMs: purgedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LessonsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                lessonImagesRefs = false,
                cardsRefs = false,
                questionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (lessonImagesRefs) db.lessonImages,
                    if (cardsRefs) db.cards,
                    if (questionsRefs) db.questions,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (lessonImagesRefs)
                        await $_getPrefetchedData<
                          LessonRow,
                          $LessonsTable,
                          LessonImageRow
                        >(
                          currentTable: table,
                          referencedTable: $$LessonsTableReferences
                              ._lessonImagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LessonsTableReferences(
                                db,
                                table,
                                p0,
                              ).lessonImagesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lessonId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cardsRefs)
                        await $_getPrefetchedData<
                          LessonRow,
                          $LessonsTable,
                          CardRow
                        >(
                          currentTable: table,
                          referencedTable: $$LessonsTableReferences
                              ._cardsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LessonsTableReferences(db, table, p0).cardsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lessonId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (questionsRefs)
                        await $_getPrefetchedData<
                          LessonRow,
                          $LessonsTable,
                          QuestionRow
                        >(
                          currentTable: table,
                          referencedTable: $$LessonsTableReferences
                              ._questionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LessonsTableReferences(
                                db,
                                table,
                                p0,
                              ).questionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.lessonId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LessonsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $LessonsTable,
      LessonRow,
      $$LessonsTableFilterComposer,
      $$LessonsTableOrderingComposer,
      $$LessonsTableAnnotationComposer,
      $$LessonsTableCreateCompanionBuilder,
      $$LessonsTableUpdateCompanionBuilder,
      (LessonRow, $$LessonsTableReferences),
      LessonRow,
      PrefetchHooks Function({
        bool lessonImagesRefs,
        bool cardsRefs,
        bool questionsRefs,
      })
    >;
typedef $$LessonImagesTableCreateCompanionBuilder =
    LessonImagesCompanion Function({
      Value<int> id,
      required int lessonId,
      required String filePath,
      required int capturedAtMs,
      Value<int?> deletedAtMs,
    });
typedef $$LessonImagesTableUpdateCompanionBuilder =
    LessonImagesCompanion Function({
      Value<int> id,
      Value<int> lessonId,
      Value<String> filePath,
      Value<int> capturedAtMs,
      Value<int?> deletedAtMs,
    });

final class $$LessonImagesTableReferences
    extends
        BaseReferences<_$LunioDatabase, $LessonImagesTable, LessonImageRow> {
  $$LessonImagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LessonsTable _lessonIdTable(_$LunioDatabase db) =>
      db.lessons.createAlias(
        $_aliasNameGenerator(db.lessonImages.lessonId, db.lessons.id),
      );

  $$LessonsTableProcessedTableManager get lessonId {
    final $_column = $_itemColumn<int>('lesson_id')!;

    final manager = $$LessonsTableTableManager(
      $_db,
      $_db.lessons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LessonImagesTableFilterComposer
    extends Composer<_$LunioDatabase, $LessonImagesTable> {
  $$LessonImagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  $$LessonsTableFilterComposer get lessonId {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableFilterComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonImagesTableOrderingComposer
    extends Composer<_$LunioDatabase, $LessonImagesTable> {
  $$LessonImagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filePath => $composableBuilder(
    column: $table.filePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$LessonsTableOrderingComposer get lessonId {
    final $$LessonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableOrderingComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonImagesTableAnnotationComposer
    extends Composer<_$LunioDatabase, $LessonImagesTable> {
  $$LessonImagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<int> get capturedAtMs => $composableBuilder(
    column: $table.capturedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => column,
  );

  $$LessonsTableAnnotationComposer get lessonId {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableAnnotationComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LessonImagesTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $LessonImagesTable,
          LessonImageRow,
          $$LessonImagesTableFilterComposer,
          $$LessonImagesTableOrderingComposer,
          $$LessonImagesTableAnnotationComposer,
          $$LessonImagesTableCreateCompanionBuilder,
          $$LessonImagesTableUpdateCompanionBuilder,
          (LessonImageRow, $$LessonImagesTableReferences),
          LessonImageRow,
          PrefetchHooks Function({bool lessonId})
        > {
  $$LessonImagesTableTableManager(_$LunioDatabase db, $LessonImagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LessonImagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LessonImagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LessonImagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> lessonId = const Value.absent(),
                Value<String> filePath = const Value.absent(),
                Value<int> capturedAtMs = const Value.absent(),
                Value<int?> deletedAtMs = const Value.absent(),
              }) => LessonImagesCompanion(
                id: id,
                lessonId: lessonId,
                filePath: filePath,
                capturedAtMs: capturedAtMs,
                deletedAtMs: deletedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int lessonId,
                required String filePath,
                required int capturedAtMs,
                Value<int?> deletedAtMs = const Value.absent(),
              }) => LessonImagesCompanion.insert(
                id: id,
                lessonId: lessonId,
                filePath: filePath,
                capturedAtMs: capturedAtMs,
                deletedAtMs: deletedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LessonImagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lessonId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (lessonId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.lessonId,
                                referencedTable: $$LessonImagesTableReferences
                                    ._lessonIdTable(db),
                                referencedColumn: $$LessonImagesTableReferences
                                    ._lessonIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LessonImagesTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $LessonImagesTable,
      LessonImageRow,
      $$LessonImagesTableFilterComposer,
      $$LessonImagesTableOrderingComposer,
      $$LessonImagesTableAnnotationComposer,
      $$LessonImagesTableCreateCompanionBuilder,
      $$LessonImagesTableUpdateCompanionBuilder,
      (LessonImageRow, $$LessonImagesTableReferences),
      LessonImageRow,
      PrefetchHooks Function({bool lessonId})
    >;
typedef $$CardsTableCreateCompanionBuilder =
    CardsCompanion Function({
      Value<int> id,
      required int lessonId,
      required String front,
      required String back,
      Value<int> repetitions,
      Value<int> intervalDays,
      Value<int> easePermille,
      Value<int> lapses,
      Value<int?> dueDay,
      Value<int?> lastReviewedDay,
      Value<int?> firstCorrectAtMs,
    });
typedef $$CardsTableUpdateCompanionBuilder =
    CardsCompanion Function({
      Value<int> id,
      Value<int> lessonId,
      Value<String> front,
      Value<String> back,
      Value<int> repetitions,
      Value<int> intervalDays,
      Value<int> easePermille,
      Value<int> lapses,
      Value<int?> dueDay,
      Value<int?> lastReviewedDay,
      Value<int?> firstCorrectAtMs,
    });

final class $$CardsTableReferences
    extends BaseReferences<_$LunioDatabase, $CardsTable, CardRow> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LessonsTable _lessonIdTable(_$LunioDatabase db) => db.lessons
      .createAlias($_aliasNameGenerator(db.cards.lessonId, db.lessons.id));

  $$LessonsTableProcessedTableManager get lessonId {
    final $_column = $_itemColumn<int>('lesson_id')!;

    final manager = $$LessonsTableTableManager(
      $_db,
      $_db.lessons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CardsTableFilterComposer
    extends Composer<_$LunioDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get easePermille => $composableBuilder(
    column: $table.easePermille,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastReviewedDay => $composableBuilder(
    column: $table.lastReviewedDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstCorrectAtMs => $composableBuilder(
    column: $table.firstCorrectAtMs,
    builder: (column) => ColumnFilters(column),
  );

  $$LessonsTableFilterComposer get lessonId {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableFilterComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsTableOrderingComposer
    extends Composer<_$LunioDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get front => $composableBuilder(
    column: $table.front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get back => $composableBuilder(
    column: $table.back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get easePermille => $composableBuilder(
    column: $table.easePermille,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastReviewedDay => $composableBuilder(
    column: $table.lastReviewedDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstCorrectAtMs => $composableBuilder(
    column: $table.firstCorrectAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$LessonsTableOrderingComposer get lessonId {
    final $$LessonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableOrderingComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsTableAnnotationComposer
    extends Composer<_$LunioDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get front =>
      $composableBuilder(column: $table.front, builder: (column) => column);

  GeneratedColumn<String> get back =>
      $composableBuilder(column: $table.back, builder: (column) => column);

  GeneratedColumn<int> get repetitions => $composableBuilder(
    column: $table.repetitions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get intervalDays => $composableBuilder(
    column: $table.intervalDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get easePermille => $composableBuilder(
    column: $table.easePermille,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<int> get lastReviewedDay => $composableBuilder(
    column: $table.lastReviewedDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstCorrectAtMs => $composableBuilder(
    column: $table.firstCorrectAtMs,
    builder: (column) => column,
  );

  $$LessonsTableAnnotationComposer get lessonId {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableAnnotationComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CardsTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $CardsTable,
          CardRow,
          $$CardsTableFilterComposer,
          $$CardsTableOrderingComposer,
          $$CardsTableAnnotationComposer,
          $$CardsTableCreateCompanionBuilder,
          $$CardsTableUpdateCompanionBuilder,
          (CardRow, $$CardsTableReferences),
          CardRow,
          PrefetchHooks Function({bool lessonId})
        > {
  $$CardsTableTableManager(_$LunioDatabase db, $CardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> lessonId = const Value.absent(),
                Value<String> front = const Value.absent(),
                Value<String> back = const Value.absent(),
                Value<int> repetitions = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> easePermille = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<int?> lastReviewedDay = const Value.absent(),
                Value<int?> firstCorrectAtMs = const Value.absent(),
              }) => CardsCompanion(
                id: id,
                lessonId: lessonId,
                front: front,
                back: back,
                repetitions: repetitions,
                intervalDays: intervalDays,
                easePermille: easePermille,
                lapses: lapses,
                dueDay: dueDay,
                lastReviewedDay: lastReviewedDay,
                firstCorrectAtMs: firstCorrectAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int lessonId,
                required String front,
                required String back,
                Value<int> repetitions = const Value.absent(),
                Value<int> intervalDays = const Value.absent(),
                Value<int> easePermille = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<int?> lastReviewedDay = const Value.absent(),
                Value<int?> firstCorrectAtMs = const Value.absent(),
              }) => CardsCompanion.insert(
                id: id,
                lessonId: lessonId,
                front: front,
                back: back,
                repetitions: repetitions,
                intervalDays: intervalDays,
                easePermille: easePermille,
                lapses: lapses,
                dueDay: dueDay,
                lastReviewedDay: lastReviewedDay,
                firstCorrectAtMs: firstCorrectAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CardsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({lessonId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (lessonId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.lessonId,
                                referencedTable: $$CardsTableReferences
                                    ._lessonIdTable(db),
                                referencedColumn: $$CardsTableReferences
                                    ._lessonIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CardsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $CardsTable,
      CardRow,
      $$CardsTableFilterComposer,
      $$CardsTableOrderingComposer,
      $$CardsTableAnnotationComposer,
      $$CardsTableCreateCompanionBuilder,
      $$CardsTableUpdateCompanionBuilder,
      (CardRow, $$CardsTableReferences),
      CardRow,
      PrefetchHooks Function({bool lessonId})
    >;
typedef $$QuestionsTableCreateCompanionBuilder =
    QuestionsCompanion Function({
      Value<int> id,
      required int lessonId,
      required String prompt,
      required String choicesJson,
      required int correctIndex,
      Value<int?> purgedAtMs,
    });
typedef $$QuestionsTableUpdateCompanionBuilder =
    QuestionsCompanion Function({
      Value<int> id,
      Value<int> lessonId,
      Value<String> prompt,
      Value<String> choicesJson,
      Value<int> correctIndex,
      Value<int?> purgedAtMs,
    });

final class $$QuestionsTableReferences
    extends BaseReferences<_$LunioDatabase, $QuestionsTable, QuestionRow> {
  $$QuestionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LessonsTable _lessonIdTable(_$LunioDatabase db) => db.lessons
      .createAlias($_aliasNameGenerator(db.questions.lessonId, db.lessons.id));

  $$LessonsTableProcessedTableManager get lessonId {
    final $_column = $_itemColumn<int>('lesson_id')!;

    final manager = $$LessonsTableTableManager(
      $_db,
      $_db.lessons,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_lessonIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$QuestionsTableFilterComposer
    extends Composer<_$LunioDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get choicesJson => $composableBuilder(
    column: $table.choicesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctIndex => $composableBuilder(
    column: $table.correctIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgedAtMs => $composableBuilder(
    column: $table.purgedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  $$LessonsTableFilterComposer get lessonId {
    final $$LessonsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableFilterComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$LunioDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prompt => $composableBuilder(
    column: $table.prompt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get choicesJson => $composableBuilder(
    column: $table.choicesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctIndex => $composableBuilder(
    column: $table.correctIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgedAtMs => $composableBuilder(
    column: $table.purgedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$LessonsTableOrderingComposer get lessonId {
    final $$LessonsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableOrderingComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$LunioDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get prompt =>
      $composableBuilder(column: $table.prompt, builder: (column) => column);

  GeneratedColumn<String> get choicesJson => $composableBuilder(
    column: $table.choicesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctIndex => $composableBuilder(
    column: $table.correctIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purgedAtMs => $composableBuilder(
    column: $table.purgedAtMs,
    builder: (column) => column,
  );

  $$LessonsTableAnnotationComposer get lessonId {
    final $$LessonsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lessonId,
      referencedTable: $db.lessons,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LessonsTableAnnotationComposer(
            $db: $db,
            $table: $db.lessons,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$QuestionsTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $QuestionsTable,
          QuestionRow,
          $$QuestionsTableFilterComposer,
          $$QuestionsTableOrderingComposer,
          $$QuestionsTableAnnotationComposer,
          $$QuestionsTableCreateCompanionBuilder,
          $$QuestionsTableUpdateCompanionBuilder,
          (QuestionRow, $$QuestionsTableReferences),
          QuestionRow,
          PrefetchHooks Function({bool lessonId})
        > {
  $$QuestionsTableTableManager(_$LunioDatabase db, $QuestionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> lessonId = const Value.absent(),
                Value<String> prompt = const Value.absent(),
                Value<String> choicesJson = const Value.absent(),
                Value<int> correctIndex = const Value.absent(),
                Value<int?> purgedAtMs = const Value.absent(),
              }) => QuestionsCompanion(
                id: id,
                lessonId: lessonId,
                prompt: prompt,
                choicesJson: choicesJson,
                correctIndex: correctIndex,
                purgedAtMs: purgedAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int lessonId,
                required String prompt,
                required String choicesJson,
                required int correctIndex,
                Value<int?> purgedAtMs = const Value.absent(),
              }) => QuestionsCompanion.insert(
                id: id,
                lessonId: lessonId,
                prompt: prompt,
                choicesJson: choicesJson,
                correctIndex: correctIndex,
                purgedAtMs: purgedAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$QuestionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({lessonId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (lessonId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.lessonId,
                                referencedTable: $$QuestionsTableReferences
                                    ._lessonIdTable(db),
                                referencedColumn: $$QuestionsTableReferences
                                    ._lessonIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$QuestionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $QuestionsTable,
      QuestionRow,
      $$QuestionsTableFilterComposer,
      $$QuestionsTableOrderingComposer,
      $$QuestionsTableAnnotationComposer,
      $$QuestionsTableCreateCompanionBuilder,
      $$QuestionsTableUpdateCompanionBuilder,
      (QuestionRow, $$QuestionsTableReferences),
      QuestionRow,
      PrefetchHooks Function({bool lessonId})
    >;
typedef $$TaskInstancesTableCreateCompanionBuilder =
    TaskInstancesCompanion Function({
      Value<int> id,
      required int dayKey,
      required TaskKind kind,
      required int targetId,
      required int position,
      Value<TaskState> state,
      Value<int?> answeredAtMs,
    });
typedef $$TaskInstancesTableUpdateCompanionBuilder =
    TaskInstancesCompanion Function({
      Value<int> id,
      Value<int> dayKey,
      Value<TaskKind> kind,
      Value<int> targetId,
      Value<int> position,
      Value<TaskState> state,
      Value<int?> answeredAtMs,
    });

class $$TaskInstancesTableFilterComposer
    extends Composer<_$LunioDatabase, $TaskInstancesTable> {
  $$TaskInstancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskKind, TaskKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskState, TaskState, int> get state =>
      $composableBuilder(
        column: $table.state,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get answeredAtMs => $composableBuilder(
    column: $table.answeredAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TaskInstancesTableOrderingComposer
    extends Composer<_$LunioDatabase, $TaskInstancesTable> {
  $$TaskInstancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get answeredAtMs => $composableBuilder(
    column: $table.answeredAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TaskInstancesTableAnnotationComposer
    extends Composer<_$LunioDatabase, $TaskInstancesTable> {
  $$TaskInstancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskState, int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<int> get answeredAtMs => $composableBuilder(
    column: $table.answeredAtMs,
    builder: (column) => column,
  );
}

class $$TaskInstancesTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $TaskInstancesTable,
          TaskInstanceRow,
          $$TaskInstancesTableFilterComposer,
          $$TaskInstancesTableOrderingComposer,
          $$TaskInstancesTableAnnotationComposer,
          $$TaskInstancesTableCreateCompanionBuilder,
          $$TaskInstancesTableUpdateCompanionBuilder,
          (
            TaskInstanceRow,
            BaseReferences<
              _$LunioDatabase,
              $TaskInstancesTable,
              TaskInstanceRow
            >,
          ),
          TaskInstanceRow,
          PrefetchHooks Function()
        > {
  $$TaskInstancesTableTableManager(
    _$LunioDatabase db,
    $TaskInstancesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskInstancesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskInstancesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskInstancesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayKey = const Value.absent(),
                Value<TaskKind> kind = const Value.absent(),
                Value<int> targetId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<TaskState> state = const Value.absent(),
                Value<int?> answeredAtMs = const Value.absent(),
              }) => TaskInstancesCompanion(
                id: id,
                dayKey: dayKey,
                kind: kind,
                targetId: targetId,
                position: position,
                state: state,
                answeredAtMs: answeredAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dayKey,
                required TaskKind kind,
                required int targetId,
                required int position,
                Value<TaskState> state = const Value.absent(),
                Value<int?> answeredAtMs = const Value.absent(),
              }) => TaskInstancesCompanion.insert(
                id: id,
                dayKey: dayKey,
                kind: kind,
                targetId: targetId,
                position: position,
                state: state,
                answeredAtMs: answeredAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TaskInstancesTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $TaskInstancesTable,
      TaskInstanceRow,
      $$TaskInstancesTableFilterComposer,
      $$TaskInstancesTableOrderingComposer,
      $$TaskInstancesTableAnnotationComposer,
      $$TaskInstancesTableCreateCompanionBuilder,
      $$TaskInstancesTableUpdateCompanionBuilder,
      (
        TaskInstanceRow,
        BaseReferences<_$LunioDatabase, $TaskInstancesTable, TaskInstanceRow>,
      ),
      TaskInstanceRow,
      PrefetchHooks Function()
    >;
typedef $$AttemptsTableCreateCompanionBuilder =
    AttemptsCompanion Function({
      Value<int> id,
      required int dayKey,
      required TaskKind kind,
      required int targetId,
      required int attemptNumber,
      required bool correct,
      required int msOnTarget,
      Value<bool> solutionRevealed,
      Value<int> awardedUnits,
      Value<RejectionRow> rejection,
      Value<bool> cappedByCeiling,
      required int atMs,
      required TrustLevelRow trustLevel,
    });
typedef $$AttemptsTableUpdateCompanionBuilder =
    AttemptsCompanion Function({
      Value<int> id,
      Value<int> dayKey,
      Value<TaskKind> kind,
      Value<int> targetId,
      Value<int> attemptNumber,
      Value<bool> correct,
      Value<int> msOnTarget,
      Value<bool> solutionRevealed,
      Value<int> awardedUnits,
      Value<RejectionRow> rejection,
      Value<bool> cappedByCeiling,
      Value<int> atMs,
      Value<TrustLevelRow> trustLevel,
    });

class $$AttemptsTableFilterComposer
    extends Composer<_$LunioDatabase, $AttemptsTable> {
  $$AttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskKind, TaskKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get msOnTarget => $composableBuilder(
    column: $table.msOnTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get solutionRevealed => $composableBuilder(
    column: $table.solutionRevealed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awardedUnits => $composableBuilder(
    column: $table.awardedUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RejectionRow, RejectionRow, int>
  get rejection => $composableBuilder(
    column: $table.rejection,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<bool> get cappedByCeiling => $composableBuilder(
    column: $table.cappedByCeiling,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TrustLevelRow, TrustLevelRow, int>
  get trustLevel => $composableBuilder(
    column: $table.trustLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$AttemptsTableOrderingComposer
    extends Composer<_$LunioDatabase, $AttemptsTable> {
  $$AttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get msOnTarget => $composableBuilder(
    column: $table.msOnTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get solutionRevealed => $composableBuilder(
    column: $table.solutionRevealed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awardedUnits => $composableBuilder(
    column: $table.awardedUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rejection => $composableBuilder(
    column: $table.rejection,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cappedByCeiling => $composableBuilder(
    column: $table.cappedByCeiling,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trustLevel => $composableBuilder(
    column: $table.trustLevel,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttemptsTableAnnotationComposer
    extends Composer<_$LunioDatabase, $AttemptsTable> {
  $$AttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get attemptNumber => $composableBuilder(
    column: $table.attemptNumber,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get msOnTarget => $composableBuilder(
    column: $table.msOnTarget,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get solutionRevealed => $composableBuilder(
    column: $table.solutionRevealed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get awardedUnits => $composableBuilder(
    column: $table.awardedUnits,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<RejectionRow, int> get rejection =>
      $composableBuilder(column: $table.rejection, builder: (column) => column);

  GeneratedColumn<bool> get cappedByCeiling => $composableBuilder(
    column: $table.cappedByCeiling,
    builder: (column) => column,
  );

  GeneratedColumn<int> get atMs =>
      $composableBuilder(column: $table.atMs, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrustLevelRow, int> get trustLevel =>
      $composableBuilder(
        column: $table.trustLevel,
        builder: (column) => column,
      );
}

class $$AttemptsTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $AttemptsTable,
          AttemptRow,
          $$AttemptsTableFilterComposer,
          $$AttemptsTableOrderingComposer,
          $$AttemptsTableAnnotationComposer,
          $$AttemptsTableCreateCompanionBuilder,
          $$AttemptsTableUpdateCompanionBuilder,
          (
            AttemptRow,
            BaseReferences<_$LunioDatabase, $AttemptsTable, AttemptRow>,
          ),
          AttemptRow,
          PrefetchHooks Function()
        > {
  $$AttemptsTableTableManager(_$LunioDatabase db, $AttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayKey = const Value.absent(),
                Value<TaskKind> kind = const Value.absent(),
                Value<int> targetId = const Value.absent(),
                Value<int> attemptNumber = const Value.absent(),
                Value<bool> correct = const Value.absent(),
                Value<int> msOnTarget = const Value.absent(),
                Value<bool> solutionRevealed = const Value.absent(),
                Value<int> awardedUnits = const Value.absent(),
                Value<RejectionRow> rejection = const Value.absent(),
                Value<bool> cappedByCeiling = const Value.absent(),
                Value<int> atMs = const Value.absent(),
                Value<TrustLevelRow> trustLevel = const Value.absent(),
              }) => AttemptsCompanion(
                id: id,
                dayKey: dayKey,
                kind: kind,
                targetId: targetId,
                attemptNumber: attemptNumber,
                correct: correct,
                msOnTarget: msOnTarget,
                solutionRevealed: solutionRevealed,
                awardedUnits: awardedUnits,
                rejection: rejection,
                cappedByCeiling: cappedByCeiling,
                atMs: atMs,
                trustLevel: trustLevel,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dayKey,
                required TaskKind kind,
                required int targetId,
                required int attemptNumber,
                required bool correct,
                required int msOnTarget,
                Value<bool> solutionRevealed = const Value.absent(),
                Value<int> awardedUnits = const Value.absent(),
                Value<RejectionRow> rejection = const Value.absent(),
                Value<bool> cappedByCeiling = const Value.absent(),
                required int atMs,
                required TrustLevelRow trustLevel,
              }) => AttemptsCompanion.insert(
                id: id,
                dayKey: dayKey,
                kind: kind,
                targetId: targetId,
                attemptNumber: attemptNumber,
                correct: correct,
                msOnTarget: msOnTarget,
                solutionRevealed: solutionRevealed,
                awardedUnits: awardedUnits,
                rejection: rejection,
                cappedByCeiling: cappedByCeiling,
                atMs: atMs,
                trustLevel: trustLevel,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $AttemptsTable,
      AttemptRow,
      $$AttemptsTableFilterComposer,
      $$AttemptsTableOrderingComposer,
      $$AttemptsTableAnnotationComposer,
      $$AttemptsTableCreateCompanionBuilder,
      $$AttemptsTableUpdateCompanionBuilder,
      (AttemptRow, BaseReferences<_$LunioDatabase, $AttemptsTable, AttemptRow>),
      AttemptRow,
      PrefetchHooks Function()
    >;
typedef $$StarLedgerTableCreateCompanionBuilder =
    StarLedgerCompanion Function({
      Value<int> id,
      required int dayKey,
      required LedgerKind kind,
      required int starUnits,
      required int balanceAfterUnits,
      Value<int?> sourceRef,
      required int atMs,
      required TrustLevelRow trustLevel,
      Value<String> note,
    });
typedef $$StarLedgerTableUpdateCompanionBuilder =
    StarLedgerCompanion Function({
      Value<int> id,
      Value<int> dayKey,
      Value<LedgerKind> kind,
      Value<int> starUnits,
      Value<int> balanceAfterUnits,
      Value<int?> sourceRef,
      Value<int> atMs,
      Value<TrustLevelRow> trustLevel,
      Value<String> note,
    });

class $$StarLedgerTableFilterComposer
    extends Composer<_$LunioDatabase, $StarLedgerTable> {
  $$StarLedgerTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LedgerKind, LedgerKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get starUnits => $composableBuilder(
    column: $table.starUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceAfterUnits => $composableBuilder(
    column: $table.balanceAfterUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TrustLevelRow, TrustLevelRow, int>
  get trustLevel => $composableBuilder(
    column: $table.trustLevel,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StarLedgerTableOrderingComposer
    extends Composer<_$LunioDatabase, $StarLedgerTable> {
  $$StarLedgerTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get starUnits => $composableBuilder(
    column: $table.starUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceAfterUnits => $composableBuilder(
    column: $table.balanceAfterUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourceRef => $composableBuilder(
    column: $table.sourceRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get trustLevel => $composableBuilder(
    column: $table.trustLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StarLedgerTableAnnotationComposer
    extends Composer<_$LunioDatabase, $StarLedgerTable> {
  $$StarLedgerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LedgerKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get starUnits =>
      $composableBuilder(column: $table.starUnits, builder: (column) => column);

  GeneratedColumn<int> get balanceAfterUnits => $composableBuilder(
    column: $table.balanceAfterUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourceRef =>
      $composableBuilder(column: $table.sourceRef, builder: (column) => column);

  GeneratedColumn<int> get atMs =>
      $composableBuilder(column: $table.atMs, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TrustLevelRow, int> get trustLevel =>
      $composableBuilder(
        column: $table.trustLevel,
        builder: (column) => column,
      );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$StarLedgerTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $StarLedgerTable,
          StarLedgerRow,
          $$StarLedgerTableFilterComposer,
          $$StarLedgerTableOrderingComposer,
          $$StarLedgerTableAnnotationComposer,
          $$StarLedgerTableCreateCompanionBuilder,
          $$StarLedgerTableUpdateCompanionBuilder,
          (
            StarLedgerRow,
            BaseReferences<_$LunioDatabase, $StarLedgerTable, StarLedgerRow>,
          ),
          StarLedgerRow,
          PrefetchHooks Function()
        > {
  $$StarLedgerTableTableManager(_$LunioDatabase db, $StarLedgerTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StarLedgerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StarLedgerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StarLedgerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayKey = const Value.absent(),
                Value<LedgerKind> kind = const Value.absent(),
                Value<int> starUnits = const Value.absent(),
                Value<int> balanceAfterUnits = const Value.absent(),
                Value<int?> sourceRef = const Value.absent(),
                Value<int> atMs = const Value.absent(),
                Value<TrustLevelRow> trustLevel = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => StarLedgerCompanion(
                id: id,
                dayKey: dayKey,
                kind: kind,
                starUnits: starUnits,
                balanceAfterUnits: balanceAfterUnits,
                sourceRef: sourceRef,
                atMs: atMs,
                trustLevel: trustLevel,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int dayKey,
                required LedgerKind kind,
                required int starUnits,
                required int balanceAfterUnits,
                Value<int?> sourceRef = const Value.absent(),
                required int atMs,
                required TrustLevelRow trustLevel,
                Value<String> note = const Value.absent(),
              }) => StarLedgerCompanion.insert(
                id: id,
                dayKey: dayKey,
                kind: kind,
                starUnits: starUnits,
                balanceAfterUnits: balanceAfterUnits,
                sourceRef: sourceRef,
                atMs: atMs,
                trustLevel: trustLevel,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StarLedgerTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $StarLedgerTable,
      StarLedgerRow,
      $$StarLedgerTableFilterComposer,
      $$StarLedgerTableOrderingComposer,
      $$StarLedgerTableAnnotationComposer,
      $$StarLedgerTableCreateCompanionBuilder,
      $$StarLedgerTableUpdateCompanionBuilder,
      (
        StarLedgerRow,
        BaseReferences<_$LunioDatabase, $StarLedgerTable, StarLedgerRow>,
      ),
      StarLedgerRow,
      PrefetchHooks Function()
    >;
typedef $$DayProgressRowsTableCreateCompanionBuilder =
    DayProgressRowsCompanion Function({
      Value<int> dayKey,
      Value<int> earnedUnits,
      Value<int> grantedUnits,
      Value<int> usedPlaySeconds,
      Value<int> freePlaySeconds,
      Value<int> tasksTotal,
      Value<int> tasksAnswered,
      Value<bool> sessionBonusAwarded,
      Value<bool> streakBonusAwarded,
      Value<int?> expiredAtMs,
    });
typedef $$DayProgressRowsTableUpdateCompanionBuilder =
    DayProgressRowsCompanion Function({
      Value<int> dayKey,
      Value<int> earnedUnits,
      Value<int> grantedUnits,
      Value<int> usedPlaySeconds,
      Value<int> freePlaySeconds,
      Value<int> tasksTotal,
      Value<int> tasksAnswered,
      Value<bool> sessionBonusAwarded,
      Value<bool> streakBonusAwarded,
      Value<int?> expiredAtMs,
    });

class $$DayProgressRowsTableFilterComposer
    extends Composer<_$LunioDatabase, $DayProgressRowsTable> {
  $$DayProgressRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get earnedUnits => $composableBuilder(
    column: $table.earnedUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get grantedUnits => $composableBuilder(
    column: $table.grantedUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usedPlaySeconds => $composableBuilder(
    column: $table.usedPlaySeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get freePlaySeconds => $composableBuilder(
    column: $table.freePlaySeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tasksTotal => $composableBuilder(
    column: $table.tasksTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tasksAnswered => $composableBuilder(
    column: $table.tasksAnswered,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sessionBonusAwarded => $composableBuilder(
    column: $table.sessionBonusAwarded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get streakBonusAwarded => $composableBuilder(
    column: $table.streakBonusAwarded,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expiredAtMs => $composableBuilder(
    column: $table.expiredAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayProgressRowsTableOrderingComposer
    extends Composer<_$LunioDatabase, $DayProgressRowsTable> {
  $$DayProgressRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get earnedUnits => $composableBuilder(
    column: $table.earnedUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get grantedUnits => $composableBuilder(
    column: $table.grantedUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usedPlaySeconds => $composableBuilder(
    column: $table.usedPlaySeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get freePlaySeconds => $composableBuilder(
    column: $table.freePlaySeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tasksTotal => $composableBuilder(
    column: $table.tasksTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tasksAnswered => $composableBuilder(
    column: $table.tasksAnswered,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sessionBonusAwarded => $composableBuilder(
    column: $table.sessionBonusAwarded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get streakBonusAwarded => $composableBuilder(
    column: $table.streakBonusAwarded,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expiredAtMs => $composableBuilder(
    column: $table.expiredAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayProgressRowsTableAnnotationComposer
    extends Composer<_$LunioDatabase, $DayProgressRowsTable> {
  $$DayProgressRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get earnedUnits => $composableBuilder(
    column: $table.earnedUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get grantedUnits => $composableBuilder(
    column: $table.grantedUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usedPlaySeconds => $composableBuilder(
    column: $table.usedPlaySeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get freePlaySeconds => $composableBuilder(
    column: $table.freePlaySeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tasksTotal => $composableBuilder(
    column: $table.tasksTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tasksAnswered => $composableBuilder(
    column: $table.tasksAnswered,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sessionBonusAwarded => $composableBuilder(
    column: $table.sessionBonusAwarded,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get streakBonusAwarded => $composableBuilder(
    column: $table.streakBonusAwarded,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expiredAtMs => $composableBuilder(
    column: $table.expiredAtMs,
    builder: (column) => column,
  );
}

class $$DayProgressRowsTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $DayProgressRowsTable,
          DayProgressRow,
          $$DayProgressRowsTableFilterComposer,
          $$DayProgressRowsTableOrderingComposer,
          $$DayProgressRowsTableAnnotationComposer,
          $$DayProgressRowsTableCreateCompanionBuilder,
          $$DayProgressRowsTableUpdateCompanionBuilder,
          (
            DayProgressRow,
            BaseReferences<
              _$LunioDatabase,
              $DayProgressRowsTable,
              DayProgressRow
            >,
          ),
          DayProgressRow,
          PrefetchHooks Function()
        > {
  $$DayProgressRowsTableTableManager(
    _$LunioDatabase db,
    $DayProgressRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayProgressRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayProgressRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayProgressRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> dayKey = const Value.absent(),
                Value<int> earnedUnits = const Value.absent(),
                Value<int> grantedUnits = const Value.absent(),
                Value<int> usedPlaySeconds = const Value.absent(),
                Value<int> freePlaySeconds = const Value.absent(),
                Value<int> tasksTotal = const Value.absent(),
                Value<int> tasksAnswered = const Value.absent(),
                Value<bool> sessionBonusAwarded = const Value.absent(),
                Value<bool> streakBonusAwarded = const Value.absent(),
                Value<int?> expiredAtMs = const Value.absent(),
              }) => DayProgressRowsCompanion(
                dayKey: dayKey,
                earnedUnits: earnedUnits,
                grantedUnits: grantedUnits,
                usedPlaySeconds: usedPlaySeconds,
                freePlaySeconds: freePlaySeconds,
                tasksTotal: tasksTotal,
                tasksAnswered: tasksAnswered,
                sessionBonusAwarded: sessionBonusAwarded,
                streakBonusAwarded: streakBonusAwarded,
                expiredAtMs: expiredAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> dayKey = const Value.absent(),
                Value<int> earnedUnits = const Value.absent(),
                Value<int> grantedUnits = const Value.absent(),
                Value<int> usedPlaySeconds = const Value.absent(),
                Value<int> freePlaySeconds = const Value.absent(),
                Value<int> tasksTotal = const Value.absent(),
                Value<int> tasksAnswered = const Value.absent(),
                Value<bool> sessionBonusAwarded = const Value.absent(),
                Value<bool> streakBonusAwarded = const Value.absent(),
                Value<int?> expiredAtMs = const Value.absent(),
              }) => DayProgressRowsCompanion.insert(
                dayKey: dayKey,
                earnedUnits: earnedUnits,
                grantedUnits: grantedUnits,
                usedPlaySeconds: usedPlaySeconds,
                freePlaySeconds: freePlaySeconds,
                tasksTotal: tasksTotal,
                tasksAnswered: tasksAnswered,
                sessionBonusAwarded: sessionBonusAwarded,
                streakBonusAwarded: streakBonusAwarded,
                expiredAtMs: expiredAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayProgressRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $DayProgressRowsTable,
      DayProgressRow,
      $$DayProgressRowsTableFilterComposer,
      $$DayProgressRowsTableOrderingComposer,
      $$DayProgressRowsTableAnnotationComposer,
      $$DayProgressRowsTableCreateCompanionBuilder,
      $$DayProgressRowsTableUpdateCompanionBuilder,
      (
        DayProgressRow,
        BaseReferences<_$LunioDatabase, $DayProgressRowsTable, DayProgressRow>,
      ),
      DayProgressRow,
      PrefetchHooks Function()
    >;
typedef $$CountedTargetsTableCreateCompanionBuilder =
    CountedTargetsCompanion Function({
      required int dayKey,
      required TaskKind kind,
      required int targetId,
      required int atMs,
      Value<int> rowid,
    });
typedef $$CountedTargetsTableUpdateCompanionBuilder =
    CountedTargetsCompanion Function({
      Value<int> dayKey,
      Value<TaskKind> kind,
      Value<int> targetId,
      Value<int> atMs,
      Value<int> rowid,
    });

class $$CountedTargetsTableFilterComposer
    extends Composer<_$LunioDatabase, $CountedTargetsTable> {
  $$CountedTargetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TaskKind, TaskKind, int> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CountedTargetsTableOrderingComposer
    extends Composer<_$LunioDatabase, $CountedTargetsTable> {
  $$CountedTargetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetId => $composableBuilder(
    column: $table.targetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CountedTargetsTableAnnotationComposer
    extends Composer<_$LunioDatabase, $CountedTargetsTable> {
  $$CountedTargetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TaskKind, int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get targetId =>
      $composableBuilder(column: $table.targetId, builder: (column) => column);

  GeneratedColumn<int> get atMs =>
      $composableBuilder(column: $table.atMs, builder: (column) => column);
}

class $$CountedTargetsTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $CountedTargetsTable,
          CountedTargetRow,
          $$CountedTargetsTableFilterComposer,
          $$CountedTargetsTableOrderingComposer,
          $$CountedTargetsTableAnnotationComposer,
          $$CountedTargetsTableCreateCompanionBuilder,
          $$CountedTargetsTableUpdateCompanionBuilder,
          (
            CountedTargetRow,
            BaseReferences<
              _$LunioDatabase,
              $CountedTargetsTable,
              CountedTargetRow
            >,
          ),
          CountedTargetRow,
          PrefetchHooks Function()
        > {
  $$CountedTargetsTableTableManager(
    _$LunioDatabase db,
    $CountedTargetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CountedTargetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CountedTargetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CountedTargetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> dayKey = const Value.absent(),
                Value<TaskKind> kind = const Value.absent(),
                Value<int> targetId = const Value.absent(),
                Value<int> atMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CountedTargetsCompanion(
                dayKey: dayKey,
                kind: kind,
                targetId: targetId,
                atMs: atMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int dayKey,
                required TaskKind kind,
                required int targetId,
                required int atMs,
                Value<int> rowid = const Value.absent(),
              }) => CountedTargetsCompanion.insert(
                dayKey: dayKey,
                kind: kind,
                targetId: targetId,
                atMs: atMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CountedTargetsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $CountedTargetsTable,
      CountedTargetRow,
      $$CountedTargetsTableFilterComposer,
      $$CountedTargetsTableOrderingComposer,
      $$CountedTargetsTableAnnotationComposer,
      $$CountedTargetsTableCreateCompanionBuilder,
      $$CountedTargetsTableUpdateCompanionBuilder,
      (
        CountedTargetRow,
        BaseReferences<_$LunioDatabase, $CountedTargetsTable, CountedTargetRow>,
      ),
      CountedTargetRow,
      PrefetchHooks Function()
    >;
typedef $$StreakStatesTableCreateCompanionBuilder =
    StreakStatesCompanion Function({
      Value<int> id,
      Value<int?> lastActiveDay,
      Value<int> consecutiveDays,
      Value<int> best,
    });
typedef $$StreakStatesTableUpdateCompanionBuilder =
    StreakStatesCompanion Function({
      Value<int> id,
      Value<int?> lastActiveDay,
      Value<int> consecutiveDays,
      Value<int> best,
    });

class $$StreakStatesTableFilterComposer
    extends Composer<_$LunioDatabase, $StreakStatesTable> {
  $$StreakStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastActiveDay => $composableBuilder(
    column: $table.lastActiveDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consecutiveDays => $composableBuilder(
    column: $table.consecutiveDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get best => $composableBuilder(
    column: $table.best,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StreakStatesTableOrderingComposer
    extends Composer<_$LunioDatabase, $StreakStatesTable> {
  $$StreakStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastActiveDay => $composableBuilder(
    column: $table.lastActiveDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consecutiveDays => $composableBuilder(
    column: $table.consecutiveDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get best => $composableBuilder(
    column: $table.best,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StreakStatesTableAnnotationComposer
    extends Composer<_$LunioDatabase, $StreakStatesTable> {
  $$StreakStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lastActiveDay => $composableBuilder(
    column: $table.lastActiveDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get consecutiveDays => $composableBuilder(
    column: $table.consecutiveDays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get best =>
      $composableBuilder(column: $table.best, builder: (column) => column);
}

class $$StreakStatesTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $StreakStatesTable,
          StreakRow,
          $$StreakStatesTableFilterComposer,
          $$StreakStatesTableOrderingComposer,
          $$StreakStatesTableAnnotationComposer,
          $$StreakStatesTableCreateCompanionBuilder,
          $$StreakStatesTableUpdateCompanionBuilder,
          (
            StreakRow,
            BaseReferences<_$LunioDatabase, $StreakStatesTable, StreakRow>,
          ),
          StreakRow,
          PrefetchHooks Function()
        > {
  $$StreakStatesTableTableManager(_$LunioDatabase db, $StreakStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StreakStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StreakStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StreakStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> lastActiveDay = const Value.absent(),
                Value<int> consecutiveDays = const Value.absent(),
                Value<int> best = const Value.absent(),
              }) => StreakStatesCompanion(
                id: id,
                lastActiveDay: lastActiveDay,
                consecutiveDays: consecutiveDays,
                best: best,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> lastActiveDay = const Value.absent(),
                Value<int> consecutiveDays = const Value.absent(),
                Value<int> best = const Value.absent(),
              }) => StreakStatesCompanion.insert(
                id: id,
                lastActiveDay: lastActiveDay,
                consecutiveDays: consecutiveDays,
                best: best,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StreakStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $StreakStatesTable,
      StreakRow,
      $$StreakStatesTableFilterComposer,
      $$StreakStatesTableOrderingComposer,
      $$StreakStatesTableAnnotationComposer,
      $$StreakStatesTableCreateCompanionBuilder,
      $$StreakStatesTableUpdateCompanionBuilder,
      (
        StreakRow,
        BaseReferences<_$LunioDatabase, $StreakStatesTable, StreakRow>,
      ),
      StreakRow,
      PrefetchHooks Function()
    >;
typedef $$WeeklyTestsTableCreateCompanionBuilder =
    WeeklyTestsCompanion Function({
      Value<int> id,
      required int weekKey,
      required int startedAtMs,
      Value<int?> finishedAtMs,
      Value<int> totalQuestions,
      Value<int> correctAnswers,
      Value<int> percentBasisPoints,
      Value<int> awardedUnits,
      Value<int?> purgeDoneAtMs,
    });
typedef $$WeeklyTestsTableUpdateCompanionBuilder =
    WeeklyTestsCompanion Function({
      Value<int> id,
      Value<int> weekKey,
      Value<int> startedAtMs,
      Value<int?> finishedAtMs,
      Value<int> totalQuestions,
      Value<int> correctAnswers,
      Value<int> percentBasisPoints,
      Value<int> awardedUnits,
      Value<int?> purgeDoneAtMs,
    });

final class $$WeeklyTestsTableReferences
    extends BaseReferences<_$LunioDatabase, $WeeklyTestsTable, WeeklyTestRow> {
  $$WeeklyTestsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WeeklyTestItemsTable, List<WeeklyTestItemRow>>
  _weeklyTestItemsRefsTable(_$LunioDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.weeklyTestItems,
        aliasName: $_aliasNameGenerator(
          db.weeklyTests.id,
          db.weeklyTestItems.testId,
        ),
      );

  $$WeeklyTestItemsTableProcessedTableManager get weeklyTestItemsRefs {
    final manager = $$WeeklyTestItemsTableTableManager(
      $_db,
      $_db.weeklyTestItems,
    ).filter((f) => f.testId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _weeklyTestItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WeeklyTestsTableFilterComposer
    extends Composer<_$LunioDatabase, $WeeklyTestsTable> {
  $$WeeklyTestsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekKey => $composableBuilder(
    column: $table.weekKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finishedAtMs => $composableBuilder(
    column: $table.finishedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get percentBasisPoints => $composableBuilder(
    column: $table.percentBasisPoints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get awardedUnits => $composableBuilder(
    column: $table.awardedUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get purgeDoneAtMs => $composableBuilder(
    column: $table.purgeDoneAtMs,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> weeklyTestItemsRefs(
    Expression<bool> Function($$WeeklyTestItemsTableFilterComposer f) f,
  ) {
    final $$WeeklyTestItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weeklyTestItems,
      getReferencedColumn: (t) => t.testId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeklyTestItemsTableFilterComposer(
            $db: $db,
            $table: $db.weeklyTestItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WeeklyTestsTableOrderingComposer
    extends Composer<_$LunioDatabase, $WeeklyTestsTable> {
  $$WeeklyTestsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekKey => $composableBuilder(
    column: $table.weekKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finishedAtMs => $composableBuilder(
    column: $table.finishedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get percentBasisPoints => $composableBuilder(
    column: $table.percentBasisPoints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get awardedUnits => $composableBuilder(
    column: $table.awardedUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get purgeDoneAtMs => $composableBuilder(
    column: $table.purgeDoneAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeeklyTestsTableAnnotationComposer
    extends Composer<_$LunioDatabase, $WeeklyTestsTable> {
  $$WeeklyTestsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get weekKey =>
      $composableBuilder(column: $table.weekKey, builder: (column) => column);

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get finishedAtMs => $composableBuilder(
    column: $table.finishedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalQuestions => $composableBuilder(
    column: $table.totalQuestions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get correctAnswers => $composableBuilder(
    column: $table.correctAnswers,
    builder: (column) => column,
  );

  GeneratedColumn<int> get percentBasisPoints => $composableBuilder(
    column: $table.percentBasisPoints,
    builder: (column) => column,
  );

  GeneratedColumn<int> get awardedUnits => $composableBuilder(
    column: $table.awardedUnits,
    builder: (column) => column,
  );

  GeneratedColumn<int> get purgeDoneAtMs => $composableBuilder(
    column: $table.purgeDoneAtMs,
    builder: (column) => column,
  );

  Expression<T> weeklyTestItemsRefs<T extends Object>(
    Expression<T> Function($$WeeklyTestItemsTableAnnotationComposer a) f,
  ) {
    final $$WeeklyTestItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.weeklyTestItems,
      getReferencedColumn: (t) => t.testId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeklyTestItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.weeklyTestItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WeeklyTestsTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $WeeklyTestsTable,
          WeeklyTestRow,
          $$WeeklyTestsTableFilterComposer,
          $$WeeklyTestsTableOrderingComposer,
          $$WeeklyTestsTableAnnotationComposer,
          $$WeeklyTestsTableCreateCompanionBuilder,
          $$WeeklyTestsTableUpdateCompanionBuilder,
          (WeeklyTestRow, $$WeeklyTestsTableReferences),
          WeeklyTestRow,
          PrefetchHooks Function({bool weeklyTestItemsRefs})
        > {
  $$WeeklyTestsTableTableManager(_$LunioDatabase db, $WeeklyTestsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyTestsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyTestsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyTestsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> weekKey = const Value.absent(),
                Value<int> startedAtMs = const Value.absent(),
                Value<int?> finishedAtMs = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int> correctAnswers = const Value.absent(),
                Value<int> percentBasisPoints = const Value.absent(),
                Value<int> awardedUnits = const Value.absent(),
                Value<int?> purgeDoneAtMs = const Value.absent(),
              }) => WeeklyTestsCompanion(
                id: id,
                weekKey: weekKey,
                startedAtMs: startedAtMs,
                finishedAtMs: finishedAtMs,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                percentBasisPoints: percentBasisPoints,
                awardedUnits: awardedUnits,
                purgeDoneAtMs: purgeDoneAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int weekKey,
                required int startedAtMs,
                Value<int?> finishedAtMs = const Value.absent(),
                Value<int> totalQuestions = const Value.absent(),
                Value<int> correctAnswers = const Value.absent(),
                Value<int> percentBasisPoints = const Value.absent(),
                Value<int> awardedUnits = const Value.absent(),
                Value<int?> purgeDoneAtMs = const Value.absent(),
              }) => WeeklyTestsCompanion.insert(
                id: id,
                weekKey: weekKey,
                startedAtMs: startedAtMs,
                finishedAtMs: finishedAtMs,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                percentBasisPoints: percentBasisPoints,
                awardedUnits: awardedUnits,
                purgeDoneAtMs: purgeDoneAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WeeklyTestsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({weeklyTestItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (weeklyTestItemsRefs) db.weeklyTestItems,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (weeklyTestItemsRefs)
                    await $_getPrefetchedData<
                      WeeklyTestRow,
                      $WeeklyTestsTable,
                      WeeklyTestItemRow
                    >(
                      currentTable: table,
                      referencedTable: $$WeeklyTestsTableReferences
                          ._weeklyTestItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WeeklyTestsTableReferences(
                            db,
                            table,
                            p0,
                          ).weeklyTestItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.testId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WeeklyTestsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $WeeklyTestsTable,
      WeeklyTestRow,
      $$WeeklyTestsTableFilterComposer,
      $$WeeklyTestsTableOrderingComposer,
      $$WeeklyTestsTableAnnotationComposer,
      $$WeeklyTestsTableCreateCompanionBuilder,
      $$WeeklyTestsTableUpdateCompanionBuilder,
      (WeeklyTestRow, $$WeeklyTestsTableReferences),
      WeeklyTestRow,
      PrefetchHooks Function({bool weeklyTestItemsRefs})
    >;
typedef $$WeeklyTestItemsTableCreateCompanionBuilder =
    WeeklyTestItemsCompanion Function({
      Value<int> id,
      required int testId,
      required String promptSnapshot,
      required bool correct,
      required int answeredAtMs,
    });
typedef $$WeeklyTestItemsTableUpdateCompanionBuilder =
    WeeklyTestItemsCompanion Function({
      Value<int> id,
      Value<int> testId,
      Value<String> promptSnapshot,
      Value<bool> correct,
      Value<int> answeredAtMs,
    });

final class $$WeeklyTestItemsTableReferences
    extends
        BaseReferences<
          _$LunioDatabase,
          $WeeklyTestItemsTable,
          WeeklyTestItemRow
        > {
  $$WeeklyTestItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WeeklyTestsTable _testIdTable(_$LunioDatabase db) =>
      db.weeklyTests.createAlias(
        $_aliasNameGenerator(db.weeklyTestItems.testId, db.weeklyTests.id),
      );

  $$WeeklyTestsTableProcessedTableManager get testId {
    final $_column = $_itemColumn<int>('test_id')!;

    final manager = $$WeeklyTestsTableTableManager(
      $_db,
      $_db.weeklyTests,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_testIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WeeklyTestItemsTableFilterComposer
    extends Composer<_$LunioDatabase, $WeeklyTestItemsTable> {
  $$WeeklyTestItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get promptSnapshot => $composableBuilder(
    column: $table.promptSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get answeredAtMs => $composableBuilder(
    column: $table.answeredAtMs,
    builder: (column) => ColumnFilters(column),
  );

  $$WeeklyTestsTableFilterComposer get testId {
    final $$WeeklyTestsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.testId,
      referencedTable: $db.weeklyTests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeklyTestsTableFilterComposer(
            $db: $db,
            $table: $db.weeklyTests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeeklyTestItemsTableOrderingComposer
    extends Composer<_$LunioDatabase, $WeeklyTestItemsTable> {
  $$WeeklyTestItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get promptSnapshot => $composableBuilder(
    column: $table.promptSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get answeredAtMs => $composableBuilder(
    column: $table.answeredAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  $$WeeklyTestsTableOrderingComposer get testId {
    final $$WeeklyTestsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.testId,
      referencedTable: $db.weeklyTests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeklyTestsTableOrderingComposer(
            $db: $db,
            $table: $db.weeklyTests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeeklyTestItemsTableAnnotationComposer
    extends Composer<_$LunioDatabase, $WeeklyTestItemsTable> {
  $$WeeklyTestItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get promptSnapshot => $composableBuilder(
    column: $table.promptSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<int> get answeredAtMs => $composableBuilder(
    column: $table.answeredAtMs,
    builder: (column) => column,
  );

  $$WeeklyTestsTableAnnotationComposer get testId {
    final $$WeeklyTestsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.testId,
      referencedTable: $db.weeklyTests,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WeeklyTestsTableAnnotationComposer(
            $db: $db,
            $table: $db.weeklyTests,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WeeklyTestItemsTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $WeeklyTestItemsTable,
          WeeklyTestItemRow,
          $$WeeklyTestItemsTableFilterComposer,
          $$WeeklyTestItemsTableOrderingComposer,
          $$WeeklyTestItemsTableAnnotationComposer,
          $$WeeklyTestItemsTableCreateCompanionBuilder,
          $$WeeklyTestItemsTableUpdateCompanionBuilder,
          (WeeklyTestItemRow, $$WeeklyTestItemsTableReferences),
          WeeklyTestItemRow,
          PrefetchHooks Function({bool testId})
        > {
  $$WeeklyTestItemsTableTableManager(
    _$LunioDatabase db,
    $WeeklyTestItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeeklyTestItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeeklyTestItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeeklyTestItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> testId = const Value.absent(),
                Value<String> promptSnapshot = const Value.absent(),
                Value<bool> correct = const Value.absent(),
                Value<int> answeredAtMs = const Value.absent(),
              }) => WeeklyTestItemsCompanion(
                id: id,
                testId: testId,
                promptSnapshot: promptSnapshot,
                correct: correct,
                answeredAtMs: answeredAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int testId,
                required String promptSnapshot,
                required bool correct,
                required int answeredAtMs,
              }) => WeeklyTestItemsCompanion.insert(
                id: id,
                testId: testId,
                promptSnapshot: promptSnapshot,
                correct: correct,
                answeredAtMs: answeredAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WeeklyTestItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({testId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (testId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.testId,
                                referencedTable:
                                    $$WeeklyTestItemsTableReferences
                                        ._testIdTable(db),
                                referencedColumn:
                                    $$WeeklyTestItemsTableReferences
                                        ._testIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WeeklyTestItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $WeeklyTestItemsTable,
      WeeklyTestItemRow,
      $$WeeklyTestItemsTableFilterComposer,
      $$WeeklyTestItemsTableOrderingComposer,
      $$WeeklyTestItemsTableAnnotationComposer,
      $$WeeklyTestItemsTableCreateCompanionBuilder,
      $$WeeklyTestItemsTableUpdateCompanionBuilder,
      (WeeklyTestItemRow, $$WeeklyTestItemsTableReferences),
      WeeklyTestItemRow,
      PrefetchHooks Function({bool testId})
    >;
typedef $$PlaySessionsTableCreateCompanionBuilder =
    PlaySessionsCompanion Function({
      Value<int> id,
      required String packageName,
      required int dayKey,
      required int startedAtMs,
      Value<int?> endedAtMs,
      Value<int> secondsConsumed,
      Value<PlayEndReason?> endReason,
    });
typedef $$PlaySessionsTableUpdateCompanionBuilder =
    PlaySessionsCompanion Function({
      Value<int> id,
      Value<String> packageName,
      Value<int> dayKey,
      Value<int> startedAtMs,
      Value<int?> endedAtMs,
      Value<int> secondsConsumed,
      Value<PlayEndReason?> endReason,
    });

class $$PlaySessionsTableFilterComposer
    extends Composer<_$LunioDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get secondsConsumed => $composableBuilder(
    column: $table.secondsConsumed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PlayEndReason?, PlayEndReason, int>
  get endReason => $composableBuilder(
    column: $table.endReason,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$PlaySessionsTableOrderingComposer
    extends Composer<_$LunioDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAtMs => $composableBuilder(
    column: $table.endedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get secondsConsumed => $composableBuilder(
    column: $table.secondsConsumed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endReason => $composableBuilder(
    column: $table.endReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlaySessionsTableAnnotationComposer
    extends Composer<_$LunioDatabase, $PlaySessionsTable> {
  $$PlaySessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
    column: $table.startedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endedAtMs =>
      $composableBuilder(column: $table.endedAtMs, builder: (column) => column);

  GeneratedColumn<int> get secondsConsumed => $composableBuilder(
    column: $table.secondsConsumed,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PlayEndReason?, int> get endReason =>
      $composableBuilder(column: $table.endReason, builder: (column) => column);
}

class $$PlaySessionsTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $PlaySessionsTable,
          PlaySessionRow,
          $$PlaySessionsTableFilterComposer,
          $$PlaySessionsTableOrderingComposer,
          $$PlaySessionsTableAnnotationComposer,
          $$PlaySessionsTableCreateCompanionBuilder,
          $$PlaySessionsTableUpdateCompanionBuilder,
          (
            PlaySessionRow,
            BaseReferences<_$LunioDatabase, $PlaySessionsTable, PlaySessionRow>,
          ),
          PlaySessionRow,
          PrefetchHooks Function()
        > {
  $$PlaySessionsTableTableManager(_$LunioDatabase db, $PlaySessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaySessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaySessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaySessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<int> dayKey = const Value.absent(),
                Value<int> startedAtMs = const Value.absent(),
                Value<int?> endedAtMs = const Value.absent(),
                Value<int> secondsConsumed = const Value.absent(),
                Value<PlayEndReason?> endReason = const Value.absent(),
              }) => PlaySessionsCompanion(
                id: id,
                packageName: packageName,
                dayKey: dayKey,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                secondsConsumed: secondsConsumed,
                endReason: endReason,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String packageName,
                required int dayKey,
                required int startedAtMs,
                Value<int?> endedAtMs = const Value.absent(),
                Value<int> secondsConsumed = const Value.absent(),
                Value<PlayEndReason?> endReason = const Value.absent(),
              }) => PlaySessionsCompanion.insert(
                id: id,
                packageName: packageName,
                dayKey: dayKey,
                startedAtMs: startedAtMs,
                endedAtMs: endedAtMs,
                secondsConsumed: secondsConsumed,
                endReason: endReason,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlaySessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $PlaySessionsTable,
      PlaySessionRow,
      $$PlaySessionsTableFilterComposer,
      $$PlaySessionsTableOrderingComposer,
      $$PlaySessionsTableAnnotationComposer,
      $$PlaySessionsTableCreateCompanionBuilder,
      $$PlaySessionsTableUpdateCompanionBuilder,
      (
        PlaySessionRow,
        BaseReferences<_$LunioDatabase, $PlaySessionsTable, PlaySessionRow>,
      ),
      PlaySessionRow,
      PrefetchHooks Function()
    >;
typedef $$SubscriptionCachesTableCreateCompanionBuilder =
    SubscriptionCachesCompanion Function({
      Value<int> id,
      Value<String> payloadJson,
      Value<String> signatureHex,
      Value<int?> fetchedAtMs,
      Value<SubscriptionStateRow> state,
      Value<String> plan,
      Value<int?> endsAtMs,
      Value<int?> graceEndsAtMs,
    });
typedef $$SubscriptionCachesTableUpdateCompanionBuilder =
    SubscriptionCachesCompanion Function({
      Value<int> id,
      Value<String> payloadJson,
      Value<String> signatureHex,
      Value<int?> fetchedAtMs,
      Value<SubscriptionStateRow> state,
      Value<String> plan,
      Value<int?> endsAtMs,
      Value<int?> graceEndsAtMs,
    });

class $$SubscriptionCachesTableFilterComposer
    extends Composer<_$LunioDatabase, $SubscriptionCachesTable> {
  $$SubscriptionCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get signatureHex => $composableBuilder(
    column: $table.signatureHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fetchedAtMs => $composableBuilder(
    column: $table.fetchedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    SubscriptionStateRow,
    SubscriptionStateRow,
    int
  >
  get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endsAtMs => $composableBuilder(
    column: $table.endsAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get graceEndsAtMs => $composableBuilder(
    column: $table.graceEndsAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubscriptionCachesTableOrderingComposer
    extends Composer<_$LunioDatabase, $SubscriptionCachesTable> {
  $$SubscriptionCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get signatureHex => $composableBuilder(
    column: $table.signatureHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAtMs => $composableBuilder(
    column: $table.fetchedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endsAtMs => $composableBuilder(
    column: $table.endsAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get graceEndsAtMs => $composableBuilder(
    column: $table.graceEndsAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionCachesTableAnnotationComposer
    extends Composer<_$LunioDatabase, $SubscriptionCachesTable> {
  $$SubscriptionCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get signatureHex => $composableBuilder(
    column: $table.signatureHex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fetchedAtMs => $composableBuilder(
    column: $table.fetchedAtMs,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SubscriptionStateRow, int> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);

  GeneratedColumn<int> get endsAtMs =>
      $composableBuilder(column: $table.endsAtMs, builder: (column) => column);

  GeneratedColumn<int> get graceEndsAtMs => $composableBuilder(
    column: $table.graceEndsAtMs,
    builder: (column) => column,
  );
}

class $$SubscriptionCachesTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $SubscriptionCachesTable,
          SubscriptionCacheRow,
          $$SubscriptionCachesTableFilterComposer,
          $$SubscriptionCachesTableOrderingComposer,
          $$SubscriptionCachesTableAnnotationComposer,
          $$SubscriptionCachesTableCreateCompanionBuilder,
          $$SubscriptionCachesTableUpdateCompanionBuilder,
          (
            SubscriptionCacheRow,
            BaseReferences<
              _$LunioDatabase,
              $SubscriptionCachesTable,
              SubscriptionCacheRow
            >,
          ),
          SubscriptionCacheRow,
          PrefetchHooks Function()
        > {
  $$SubscriptionCachesTableTableManager(
    _$LunioDatabase db,
    $SubscriptionCachesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionCachesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> signatureHex = const Value.absent(),
                Value<int?> fetchedAtMs = const Value.absent(),
                Value<SubscriptionStateRow> state = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<int?> endsAtMs = const Value.absent(),
                Value<int?> graceEndsAtMs = const Value.absent(),
              }) => SubscriptionCachesCompanion(
                id: id,
                payloadJson: payloadJson,
                signatureHex: signatureHex,
                fetchedAtMs: fetchedAtMs,
                state: state,
                plan: plan,
                endsAtMs: endsAtMs,
                graceEndsAtMs: graceEndsAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<String> signatureHex = const Value.absent(),
                Value<int?> fetchedAtMs = const Value.absent(),
                Value<SubscriptionStateRow> state = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<int?> endsAtMs = const Value.absent(),
                Value<int?> graceEndsAtMs = const Value.absent(),
              }) => SubscriptionCachesCompanion.insert(
                id: id,
                payloadJson: payloadJson,
                signatureHex: signatureHex,
                fetchedAtMs: fetchedAtMs,
                state: state,
                plan: plan,
                endsAtMs: endsAtMs,
                graceEndsAtMs: graceEndsAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $SubscriptionCachesTable,
      SubscriptionCacheRow,
      $$SubscriptionCachesTableFilterComposer,
      $$SubscriptionCachesTableOrderingComposer,
      $$SubscriptionCachesTableAnnotationComposer,
      $$SubscriptionCachesTableCreateCompanionBuilder,
      $$SubscriptionCachesTableUpdateCompanionBuilder,
      (
        SubscriptionCacheRow,
        BaseReferences<
          _$LunioDatabase,
          $SubscriptionCachesTable,
          SubscriptionCacheRow
        >,
      ),
      SubscriptionCacheRow,
      PrefetchHooks Function()
    >;
typedef $$ClockStatesTableCreateCompanionBuilder =
    ClockStatesCompanion Function({
      Value<int> id,
      Value<int?> anchorServerEpochMs,
      Value<int?> anchorElapsedRealtimeMs,
      Value<String?> anchorBootId,
      Value<int> highWaterEpochMs,
      Value<String?> lastBootId,
      Value<int> lastElapsedRealtimeMs,
      Value<int> tamperCount,
      Value<String?> lastTamperSignal,
    });
typedef $$ClockStatesTableUpdateCompanionBuilder =
    ClockStatesCompanion Function({
      Value<int> id,
      Value<int?> anchorServerEpochMs,
      Value<int?> anchorElapsedRealtimeMs,
      Value<String?> anchorBootId,
      Value<int> highWaterEpochMs,
      Value<String?> lastBootId,
      Value<int> lastElapsedRealtimeMs,
      Value<int> tamperCount,
      Value<String?> lastTamperSignal,
    });

class $$ClockStatesTableFilterComposer
    extends Composer<_$LunioDatabase, $ClockStatesTable> {
  $$ClockStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anchorServerEpochMs => $composableBuilder(
    column: $table.anchorServerEpochMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anchorElapsedRealtimeMs => $composableBuilder(
    column: $table.anchorElapsedRealtimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorBootId => $composableBuilder(
    column: $table.anchorBootId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get highWaterEpochMs => $composableBuilder(
    column: $table.highWaterEpochMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastBootId => $composableBuilder(
    column: $table.lastBootId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastElapsedRealtimeMs => $composableBuilder(
    column: $table.lastElapsedRealtimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tamperCount => $composableBuilder(
    column: $table.tamperCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastTamperSignal => $composableBuilder(
    column: $table.lastTamperSignal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClockStatesTableOrderingComposer
    extends Composer<_$LunioDatabase, $ClockStatesTable> {
  $$ClockStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anchorServerEpochMs => $composableBuilder(
    column: $table.anchorServerEpochMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anchorElapsedRealtimeMs => $composableBuilder(
    column: $table.anchorElapsedRealtimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorBootId => $composableBuilder(
    column: $table.anchorBootId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get highWaterEpochMs => $composableBuilder(
    column: $table.highWaterEpochMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastBootId => $composableBuilder(
    column: $table.lastBootId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastElapsedRealtimeMs => $composableBuilder(
    column: $table.lastElapsedRealtimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tamperCount => $composableBuilder(
    column: $table.tamperCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastTamperSignal => $composableBuilder(
    column: $table.lastTamperSignal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClockStatesTableAnnotationComposer
    extends Composer<_$LunioDatabase, $ClockStatesTable> {
  $$ClockStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get anchorServerEpochMs => $composableBuilder(
    column: $table.anchorServerEpochMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get anchorElapsedRealtimeMs => $composableBuilder(
    column: $table.anchorElapsedRealtimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get anchorBootId => $composableBuilder(
    column: $table.anchorBootId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get highWaterEpochMs => $composableBuilder(
    column: $table.highWaterEpochMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastBootId => $composableBuilder(
    column: $table.lastBootId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastElapsedRealtimeMs => $composableBuilder(
    column: $table.lastElapsedRealtimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tamperCount => $composableBuilder(
    column: $table.tamperCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastTamperSignal => $composableBuilder(
    column: $table.lastTamperSignal,
    builder: (column) => column,
  );
}

class $$ClockStatesTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $ClockStatesTable,
          ClockStateRow,
          $$ClockStatesTableFilterComposer,
          $$ClockStatesTableOrderingComposer,
          $$ClockStatesTableAnnotationComposer,
          $$ClockStatesTableCreateCompanionBuilder,
          $$ClockStatesTableUpdateCompanionBuilder,
          (
            ClockStateRow,
            BaseReferences<_$LunioDatabase, $ClockStatesTable, ClockStateRow>,
          ),
          ClockStateRow,
          PrefetchHooks Function()
        > {
  $$ClockStatesTableTableManager(_$LunioDatabase db, $ClockStatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClockStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClockStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClockStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> anchorServerEpochMs = const Value.absent(),
                Value<int?> anchorElapsedRealtimeMs = const Value.absent(),
                Value<String?> anchorBootId = const Value.absent(),
                Value<int> highWaterEpochMs = const Value.absent(),
                Value<String?> lastBootId = const Value.absent(),
                Value<int> lastElapsedRealtimeMs = const Value.absent(),
                Value<int> tamperCount = const Value.absent(),
                Value<String?> lastTamperSignal = const Value.absent(),
              }) => ClockStatesCompanion(
                id: id,
                anchorServerEpochMs: anchorServerEpochMs,
                anchorElapsedRealtimeMs: anchorElapsedRealtimeMs,
                anchorBootId: anchorBootId,
                highWaterEpochMs: highWaterEpochMs,
                lastBootId: lastBootId,
                lastElapsedRealtimeMs: lastElapsedRealtimeMs,
                tamperCount: tamperCount,
                lastTamperSignal: lastTamperSignal,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> anchorServerEpochMs = const Value.absent(),
                Value<int?> anchorElapsedRealtimeMs = const Value.absent(),
                Value<String?> anchorBootId = const Value.absent(),
                Value<int> highWaterEpochMs = const Value.absent(),
                Value<String?> lastBootId = const Value.absent(),
                Value<int> lastElapsedRealtimeMs = const Value.absent(),
                Value<int> tamperCount = const Value.absent(),
                Value<String?> lastTamperSignal = const Value.absent(),
              }) => ClockStatesCompanion.insert(
                id: id,
                anchorServerEpochMs: anchorServerEpochMs,
                anchorElapsedRealtimeMs: anchorElapsedRealtimeMs,
                anchorBootId: anchorBootId,
                highWaterEpochMs: highWaterEpochMs,
                lastBootId: lastBootId,
                lastElapsedRealtimeMs: lastElapsedRealtimeMs,
                tamperCount: tamperCount,
                lastTamperSignal: lastTamperSignal,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClockStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $ClockStatesTable,
      ClockStateRow,
      $$ClockStatesTableFilterComposer,
      $$ClockStatesTableOrderingComposer,
      $$ClockStatesTableAnnotationComposer,
      $$ClockStatesTableCreateCompanionBuilder,
      $$ClockStatesTableUpdateCompanionBuilder,
      (
        ClockStateRow,
        BaseReferences<_$LunioDatabase, $ClockStatesTable, ClockStateRow>,
      ),
      ClockStateRow,
      PrefetchHooks Function()
    >;
typedef $$AuthTokensTableCreateCompanionBuilder =
    AuthTokensCompanion Function({
      Value<int> id,
      Value<String> accessToken,
      Value<String> refreshToken,
      Value<String> email,
      Value<int?> signedInAtMs,
    });
typedef $$AuthTokensTableUpdateCompanionBuilder =
    AuthTokensCompanion Function({
      Value<int> id,
      Value<String> accessToken,
      Value<String> refreshToken,
      Value<String> email,
      Value<int?> signedInAtMs,
    });

class $$AuthTokensTableFilterComposer
    extends Composer<_$LunioDatabase, $AuthTokensTable> {
  $$AuthTokensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get signedInAtMs => $composableBuilder(
    column: $table.signedInAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuthTokensTableOrderingComposer
    extends Composer<_$LunioDatabase, $AuthTokensTable> {
  $$AuthTokensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get signedInAtMs => $composableBuilder(
    column: $table.signedInAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuthTokensTableAnnotationComposer
    extends Composer<_$LunioDatabase, $AuthTokensTable> {
  $$AuthTokensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accessToken => $composableBuilder(
    column: $table.accessToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refreshToken => $composableBuilder(
    column: $table.refreshToken,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<int> get signedInAtMs => $composableBuilder(
    column: $table.signedInAtMs,
    builder: (column) => column,
  );
}

class $$AuthTokensTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $AuthTokensTable,
          AuthTokenRow,
          $$AuthTokensTableFilterComposer,
          $$AuthTokensTableOrderingComposer,
          $$AuthTokensTableAnnotationComposer,
          $$AuthTokensTableCreateCompanionBuilder,
          $$AuthTokensTableUpdateCompanionBuilder,
          (
            AuthTokenRow,
            BaseReferences<_$LunioDatabase, $AuthTokensTable, AuthTokenRow>,
          ),
          AuthTokenRow,
          PrefetchHooks Function()
        > {
  $$AuthTokensTableTableManager(_$LunioDatabase db, $AuthTokensTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuthTokensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuthTokensTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuthTokensTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> accessToken = const Value.absent(),
                Value<String> refreshToken = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<int?> signedInAtMs = const Value.absent(),
              }) => AuthTokensCompanion(
                id: id,
                accessToken: accessToken,
                refreshToken: refreshToken,
                email: email,
                signedInAtMs: signedInAtMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> accessToken = const Value.absent(),
                Value<String> refreshToken = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<int?> signedInAtMs = const Value.absent(),
              }) => AuthTokensCompanion.insert(
                id: id,
                accessToken: accessToken,
                refreshToken: refreshToken,
                email: email,
                signedInAtMs: signedInAtMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuthTokensTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $AuthTokensTable,
      AuthTokenRow,
      $$AuthTokensTableFilterComposer,
      $$AuthTokensTableOrderingComposer,
      $$AuthTokensTableAnnotationComposer,
      $$AuthTokensTableCreateCompanionBuilder,
      $$AuthTokensTableUpdateCompanionBuilder,
      (
        AuthTokenRow,
        BaseReferences<_$LunioDatabase, $AuthTokensTable, AuthTokenRow>,
      ),
      AuthTokenRow,
      PrefetchHooks Function()
    >;
typedef $$EventLogTableCreateCompanionBuilder =
    EventLogCompanion Function({
      Value<int> id,
      required String type,
      Value<String> detail,
      required int atMs,
    });
typedef $$EventLogTableUpdateCompanionBuilder =
    EventLogCompanion Function({
      Value<int> id,
      Value<String> type,
      Value<String> detail,
      Value<int> atMs,
    });

class $$EventLogTableFilterComposer
    extends Composer<_$LunioDatabase, $EventLogTable> {
  $$EventLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventLogTableOrderingComposer
    extends Composer<_$LunioDatabase, $EventLogTable> {
  $$EventLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get detail => $composableBuilder(
    column: $table.detail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get atMs => $composableBuilder(
    column: $table.atMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventLogTableAnnotationComposer
    extends Composer<_$LunioDatabase, $EventLogTable> {
  $$EventLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get detail =>
      $composableBuilder(column: $table.detail, builder: (column) => column);

  GeneratedColumn<int> get atMs =>
      $composableBuilder(column: $table.atMs, builder: (column) => column);
}

class $$EventLogTableTableManager
    extends
        RootTableManager<
          _$LunioDatabase,
          $EventLogTable,
          EventLogRow,
          $$EventLogTableFilterComposer,
          $$EventLogTableOrderingComposer,
          $$EventLogTableAnnotationComposer,
          $$EventLogTableCreateCompanionBuilder,
          $$EventLogTableUpdateCompanionBuilder,
          (
            EventLogRow,
            BaseReferences<_$LunioDatabase, $EventLogTable, EventLogRow>,
          ),
          EventLogRow,
          PrefetchHooks Function()
        > {
  $$EventLogTableTableManager(_$LunioDatabase db, $EventLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> detail = const Value.absent(),
                Value<int> atMs = const Value.absent(),
              }) => EventLogCompanion(
                id: id,
                type: type,
                detail: detail,
                atMs: atMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String type,
                Value<String> detail = const Value.absent(),
                required int atMs,
              }) => EventLogCompanion.insert(
                id: id,
                type: type,
                detail: detail,
                atMs: atMs,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventLogTableProcessedTableManager =
    ProcessedTableManager<
      _$LunioDatabase,
      $EventLogTable,
      EventLogRow,
      $$EventLogTableFilterComposer,
      $$EventLogTableOrderingComposer,
      $$EventLogTableAnnotationComposer,
      $$EventLogTableCreateCompanionBuilder,
      $$EventLogTableUpdateCompanionBuilder,
      (
        EventLogRow,
        BaseReferences<_$LunioDatabase, $EventLogTable, EventLogRow>,
      ),
      EventLogRow,
      PrefetchHooks Function()
    >;

class $LunioDatabaseManager {
  final _$LunioDatabase _db;
  $LunioDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$ManagedAppsTableTableManager get managedApps =>
      $$ManagedAppsTableTableManager(_db, _db.managedApps);
  $$LessonsTableTableManager get lessons =>
      $$LessonsTableTableManager(_db, _db.lessons);
  $$LessonImagesTableTableManager get lessonImages =>
      $$LessonImagesTableTableManager(_db, _db.lessonImages);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$TaskInstancesTableTableManager get taskInstances =>
      $$TaskInstancesTableTableManager(_db, _db.taskInstances);
  $$AttemptsTableTableManager get attempts =>
      $$AttemptsTableTableManager(_db, _db.attempts);
  $$StarLedgerTableTableManager get starLedger =>
      $$StarLedgerTableTableManager(_db, _db.starLedger);
  $$DayProgressRowsTableTableManager get dayProgressRows =>
      $$DayProgressRowsTableTableManager(_db, _db.dayProgressRows);
  $$CountedTargetsTableTableManager get countedTargets =>
      $$CountedTargetsTableTableManager(_db, _db.countedTargets);
  $$StreakStatesTableTableManager get streakStates =>
      $$StreakStatesTableTableManager(_db, _db.streakStates);
  $$WeeklyTestsTableTableManager get weeklyTests =>
      $$WeeklyTestsTableTableManager(_db, _db.weeklyTests);
  $$WeeklyTestItemsTableTableManager get weeklyTestItems =>
      $$WeeklyTestItemsTableTableManager(_db, _db.weeklyTestItems);
  $$PlaySessionsTableTableManager get playSessions =>
      $$PlaySessionsTableTableManager(_db, _db.playSessions);
  $$SubscriptionCachesTableTableManager get subscriptionCaches =>
      $$SubscriptionCachesTableTableManager(_db, _db.subscriptionCaches);
  $$ClockStatesTableTableManager get clockStates =>
      $$ClockStatesTableTableManager(_db, _db.clockStates);
  $$AuthTokensTableTableManager get authTokens =>
      $$AuthTokensTableTableManager(_db, _db.authTokens);
  $$EventLogTableTableManager get eventLog =>
      $$EventLogTableTableManager(_db, _db.eventLog);
}
