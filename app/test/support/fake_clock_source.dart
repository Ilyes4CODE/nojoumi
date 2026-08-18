import 'package:nojoumi/platform/clock_source.dart';
import 'package:nojoumi_time/nojoumi_time.dart';

/// A [ClockSource] the test drives by hand.
///
/// The point of `nojoumi_time` is that tampering is a property of the *readings*,
/// not of the device — so a test can stage a clock change exactly, with no phone
/// and no waiting. Article 12 scenario 12 is expensive to run on hardware and
/// free to run here; hardware then only has to confirm that the platform reports
/// what this class fakes.
class FakeClockSource implements ClockSource {
  FakeClockSource({
    required int wallClockMs,
    int elapsedRealtimeMs = 0,
    String bootId = 'boot-1',
  })  : _wall = wallClockMs,
        _elapsed = elapsedRealtimeMs,
        _bootId = bootId;

  int _wall;
  int _elapsed;
  String _bootId;
  bool failing = false;

  /// Ordinary passage of time: both clocks advance together.
  void advance(Duration d) {
    _wall += d.inMilliseconds;
    _elapsed += d.inMilliseconds;
  }

  /// Somebody changed the date in Settings. The monotonic clock is untouched,
  /// which is exactly what makes the change detectable.
  void setWallClock(int epochMs) => _wall = epochMs;

  void jumpWallClock(Duration d) => _wall += d.inMilliseconds;

  /// A reboot: `elapsedRealtime` restarts and the boot token changes.
  void reboot({Duration upSince = Duration.zero}) {
    _elapsed = upSince.inMilliseconds;
    _bootId = 'boot-${DateTime.now().microsecondsSinceEpoch}';
  }

  @override
  Future<ClockReading> read() async {
    if (failing) {
      throw const ClockSourceUnavailable('staged failure');
    }
    return ClockReading(
      wallClockMs: _wall,
      elapsedRealtimeMs: _elapsed,
      bootId: _bootId,
    );
  }
}
