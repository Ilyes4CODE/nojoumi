import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lunio_stars/lunio_stars.dart';

import '../../core/format.dart';
import '../../core/illustrations.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';

/// The balance, and what it buys.
///
/// The ring comes from the client's reference design, and it earns its place:
/// it shows the star count **and** how much of the daily ceiling is used, in one
/// shape, without a second row of text. Article 6.4 caps what the child *earns*,
/// so the ring measures `earnedUnits` against the ceiling — a parent grant sits
/// above the system (appendix §4) and must never look like it consumed the
/// child's day.
///
/// Play time is `mm:ss`, never rounded to minutes: the star value may be half a
/// minute (appendix §5), so half a star is thirty seconds, and "1 minute" would
/// be a lie the child can measure against the clock on the wall.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.progress,
    required this.rules,
    required this.paused,
  });

  final DayProgress? progress;
  final StarRules? rules;
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context)!;
    final theme = Theme.of(context);

    final units = progress?.balanceUnits ?? 0;
    final earned = progress?.earnedUnits ?? 0;
    final ceiling = rules?.dailyCeilingUnits ?? 0;
    final seconds = (rules == null || progress == null)
        ? 0
        : progress!.remainingPlaySeconds(rules!);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LunioSpacing.l),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.starsBalance,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: LunioTheme.ink.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: LunioSpacing.xs),
                      Row(
                        children: [
                          Text(
                            Fmt.stars(units),
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: LunioTheme.ink,
                            ),
                          ),
                          const SizedBox(width: LunioSpacing.s),
                          const Icon(
                            Icons.star_rounded,
                            color: LunioTheme.star,
                            size: 34,
                          ),
                        ],
                      ),
                      if (ceiling > 0)
                        Text(
                          '${Fmt.stars(earned)} / ${Fmt.stars(ceiling)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: LunioTheme.ink.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ),
                _CeilingRing(
                  value: ceiling == 0 ? 0 : (earned / ceiling).clamp(0.0, 1.0),
                ),
              ],
            ),
            const Divider(height: LunioSpacing.xl),
            Row(
              children: [
                const TintedIcon(Icons.sports_esports_rounded),
                const SizedBox(width: LunioSpacing.m),
                Expanded(
                  child: Text(
                    l10n.playTimeRemaining,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: LunioTheme.ink.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                Text(
                  Fmt.duration(seconds),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: seconds > 0 ? LunioTheme.play : LunioTheme.blocked,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            if (paused) ...[
              const SizedBox(height: LunioSpacing.s),
              Text(
                l10n.playPausedByParent,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The daily-ceiling ring.
///
/// Drawn rather than composed from a `CircularProgressIndicator` for one reason:
/// the track and the fill need different widths and rounded caps, and the ring
/// must not animate. Article 13's floor is a 2 GB device, and a ring that
/// repaints on a ticker for decoration is exactly the kind of cost that shows up
/// as jank in the 30-minute session of criterion 11.10.
class _CeilingRing extends StatelessWidget {
  const _CeilingRing({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: CustomPaint(
        painter: _RingPainter(
          value: value,
          track: LunioTheme.tintLavender,
          fill: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.value,
    required this.track,
    required this.fill,
  });

  final double value;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final inner = rect.deflate(stroke / 2);

    canvas.drawArc(
      inner,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (value <= 0) return;

    // Starts at twelve o'clock and sweeps anticlockwise, so it fills in the same
    // direction the eye reads on a right-to-left screen.
    canvas.drawArc(
      inner,
      -math.pi / 2,
      -math.pi * 2 * value,
      false,
      Paint()
        ..color = fill
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.fill != fill || old.track != track;
}
