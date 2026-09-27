import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The Dart side of `dz.lunio/blocking`.
///
/// **Nothing here enforces anything.** AD-7 puts the blocking engine in a Kotlin
/// library that must keep working while the Flutter engine is dead, so this class
/// only ever *writes* the engine's inputs and *reads* the permission state. If the
/// whole Dart isolate died mid-sentence, blocking would carry on unchanged — that
/// is the property the design exists to have, and it is why no method below returns
/// a decision.
///
/// **UNVERIFIED-ON-HARDWARE.** No part of this has run on a phone.
abstract class BlockingChannel {
  /// What the parent still has to grant, and what device we are on.
  Future<BlockingStatus> status();

  /// Mirrors the current world into the engine's store.
  Future<void> push({
    required bool enabled,
    required List<String> blockedPackages,
    required int remainingPlaySeconds,
    required bool playPaused,
    required String priceInStars,
  });

  /// The apps the parent can classify. Icons are optional because the payload is
  /// a few hundred kilobytes on a phone with sixty apps.
  Future<List<InstalledApp>> launchableApps({bool includeIcons = true});

  /// Schedule the background heartbeat that tells the server Lunio is still
  /// installed. Safe to call on every start: an existing schedule is kept.
  Future<void> configureHeartbeat({
    required String apiBase,
    required String installId,
  });

  /// Seconds of play the engine measured while Dart was not running, cleared as
  /// they are read.
  ///
  /// The engine counts a copy of the balance down so it can enforce with the
  /// Flutter engine dead; the ledger stays here (AD-4). This is how the two are
  /// reconciled, and it must be called before anything trusts the local balance
  /// after a resume.
  Future<int> drainConsumedSeconds();

  /// The play-time countdown, one value a second while a blocked game is in
  /// front of the child.
  ///
  /// **An event stream from the engine, not a socket to the server.** Nothing
  /// about play time involves the server — the balance is Article 5 arithmetic
  /// over data that never leaves the phone (Art. 14) — and while the child is
  /// inside a game there is no Flutter engine alive to hold a connection open,
  /// which is the whole reason the clock lives in Kotlin.
  ///
  /// So this is only ever read when Lunio itself is on screen: launcher mode, or
  /// the moment the child comes back. `drainConsumedSeconds` is what reconciles
  /// the ledger; this is what makes the number move while somebody is watching.
  Stream<int> playTicks();

  /// Hand a URL to the parent's browser.
  ///
  /// Used for the payment page (client direction, 2026-08-29). The browser, not
  /// a WebView: see `LunioBlockingBridge.openUrl`.
  Future<bool> openUrl(String url);

  Future<bool> openAccessibilitySettings();
  Future<bool> openOverlaySettings();
  Future<bool> openBatterySettings();

  /// Ask the system to stop restricting Lunio in the background.
  Future<bool> requestBatteryExemption();

  /// The OEM autostart screen. Best-effort — see the Kotlin side for why.
  Future<bool> openAutostartSettings();

  /// Android gets the real channel. Everything else — the developer's Windows
  /// machine, a `flutter test` run — gets [UnavailableBlockingChannel], which
  /// reports every permission as missing rather than pretending.
  factory BlockingChannel.forPlatform() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return const PlatformBlockingChannel();
    }
    return const UnavailableBlockingChannel();
  }
}

/// What the engine needs from the parent before it can do anything.
///
/// Every field is a Settings screen the parent must visit by hand. None can be
/// granted by a runtime dialog, and none can be granted by us — which is why the
/// parent dashboard shows them individually rather than as one "blocking is on"
/// switch that might be lying.
@immutable
class BlockingStatus {
  const BlockingStatus({
    this.accessibilityEnabled = false,
    this.overlayGranted = false,
    this.notificationsGranted = false,
    this.autostartScreenAvailable = false,
    this.batteryUnrestricted = false,
    this.manufacturer = '',
    this.sdkInt = 0,
    this.available = true,
  });

  const BlockingStatus.unavailable() : this(available: false);

  /// Tier 1 of AD-8. Without this, nothing is blocked at all.
  final bool accessibilityEnabled;

  /// Tier 3. Without this the phone still goes home, but the child is not told
  /// why — see `BlockCardOverlay`, which logs exactly that.
  final bool overlayGranted;

  /// Android 13+. The watchdog runs regardless; only its notification is hidden,
  /// and a foreground service the user cannot see is a support problem.
  final bool notificationsGranted;

  final bool autostartScreenAvailable;

  /// Whether the system will let Lunio run while a game is in front.
  ///
  /// **The play clock depends on this more than on anything else.** While the
  /// child plays, Lunio is a background process, and ColorOS, One UI and MIUI
  /// all freeze background processes — a frozen process runs no timer, so the
  /// countdown stops and the game is not closed when the balance ends.
  final bool batteryUnrestricted;
  final String manufacturer;
  final int sdkInt;

  /// False off Android. Not an error — Article 15.2 makes blocking opt-in, and a
  /// desktop run of the app is a legitimate way to use it.
  final bool available;

  /// The two that decide whether blocking works at all. Notifications are a
  /// quality issue; these two are the feature.
  bool get ready => available && accessibilityEnabled && overlayGranted;

  factory BlockingStatus.fromMap(Map<String, Object?> map) => BlockingStatus(
    accessibilityEnabled: map['accessibilityEnabled'] as bool? ?? false,
    overlayGranted: map['overlayGranted'] as bool? ?? false,
    notificationsGranted: map['notificationsGranted'] as bool? ?? false,
    autostartScreenAvailable: map['autostartScreenAvailable'] as bool? ?? false,
    batteryUnrestricted: map['batteryUnrestricted'] as bool? ?? false,
    manufacturer: map['manufacturer'] as String? ?? '',
    sdkInt: map['sdkInt'] as int? ?? 0,
  );
}

@immutable
class InstalledApp {
  const InstalledApp({
    required this.packageName,
    required this.label,
    this.icon,
  });

  final String packageName;
  final String label;
  final Uint8List? icon;

  factory InstalledApp.fromMap(Map<Object?, Object?> map) => InstalledApp(
    packageName: map['packageName'] as String? ?? '',
    label: map['label'] as String? ?? '',
    icon: map['icon'] as Uint8List?,
  );
}

class PlatformBlockingChannel implements BlockingChannel {
  const PlatformBlockingChannel();

  static const MethodChannel channel = MethodChannel('dz.lunio/blocking');

  @override
  Future<BlockingStatus> status() async {
    final map = await channel.invokeMapMethod<String, Object?>('status');
    if (map == null) return const BlockingStatus.unavailable();
    return BlockingStatus.fromMap(map);
  }

  @override
  Future<void> push({
    required bool enabled,
    required List<String> blockedPackages,
    required int remainingPlaySeconds,
    required bool playPaused,
    required String priceInStars,
  }) {
    return channel.invokeMethod<void>('setState', <String, Object?>{
      'enabled': enabled,
      'blockedPackages': blockedPackages,
      'remainingPlaySeconds': remainingPlaySeconds,
      'playPaused': playPaused,
      'priceInStars': priceInStars,
    });
  }

  @override
  Future<void> configureHeartbeat({
    required String apiBase,
    required String installId,
  }) => channel.invokeMethod<void>('configureHeartbeat', <String, Object?>{
    'apiBase': apiBase,
    'installId': installId,
  });

  @override
  Future<List<InstalledApp>> launchableApps({bool includeIcons = true}) async {
    final list = await channel.invokeListMethod<Object?>(
      'launchableApps',
      <String, Object?>{'includeIcons': includeIcons},
    );
    if (list == null) return const [];
    return list
        .whereType<Map<Object?, Object?>>()
        .map(InstalledApp.fromMap)
        .where((app) => app.packageName.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<int> drainConsumedSeconds() async =>
      await channel.invokeMethod<int>('drainConsumedSeconds') ?? 0;

  static const EventChannel ticks = EventChannel('dz.lunio/play_ticks');

  @override
  Stream<int> playTicks() =>
      ticks.receiveBroadcastStream().map((event) => event is int ? event : 0);

  @override
  Future<bool> openUrl(String url) async =>
      await channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;

  @override
  Future<bool> openAccessibilitySettings() =>
      _open('openAccessibilitySettings');

  @override
  Future<bool> openOverlaySettings() => _open('openOverlaySettings');

  @override
  Future<bool> openBatterySettings() => _open('openBatterySettings');

  @override
  Future<bool> requestBatteryExemption() => _open('requestBatteryExemption');

  @override
  Future<bool> openAutostartSettings() => _open('openAutostartSettings');

  Future<bool> _open(String method) async =>
      await channel.invokeMethod<bool>(method) ?? false;
}

/// The stand-in for platforms with no blocking engine.
///
/// It reports everything as ungranted and every action as failed, which is the
/// honest answer: on a desktop there is no engine, and a class that quietly
/// returned `true` would let a screen claim blocking was armed when nothing at all
/// was running.
class UnavailableBlockingChannel implements BlockingChannel {
  const UnavailableBlockingChannel();

  @override
  Future<BlockingStatus> status() async => const BlockingStatus.unavailable();

  /// Nothing to schedule off a device.
  @override
  Future<void> configureHeartbeat({
    required String apiBase,
    required String installId,
  }) async {}

  @override
  Future<void> push({
    required bool enabled,
    required List<String> blockedPackages,
    required int remainingPlaySeconds,
    required bool playPaused,
    required String priceInStars,
  }) async {}

  @override
  Future<List<InstalledApp>> launchableApps({bool includeIcons = true}) async =>
      const [];

  @override
  Future<int> drainConsumedSeconds() async => 0;

  @override
  Stream<int> playTicks() => const Stream<int>.empty();

  @override
  Future<bool> openUrl(String url) async => false;

  @override
  Future<bool> openAccessibilitySettings() async => false;

  @override
  Future<bool> openOverlaySettings() async => false;

  @override
  Future<bool> openBatterySettings() async => false;

  @override
  Future<bool> requestBatteryExemption() async => false;

  @override
  Future<bool> openAutostartSettings() async => false;
}
