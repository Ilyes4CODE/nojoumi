/// Article 7 — subscription, activation and payment state for Lunio.
///
/// Contract basis:
///  * 7.1 — three plans, and the free mode that follows: blocking, stars and
///    already-saved lessons keep working; only new AI generation stops.
///  * 7.4 — no auto-debit, manual renewal, reminders at 7 and 2 days, a 3-day
///    grace period, and renewal that *adds* to the remainder.
///  * 7.5 — a refund marked by the client stops the subscription immediately.
///  * 7.6 — the server is the source of truth, the local copy is signed, good
///    for 7 days offline, revalidated every 24 h; and changing the device date
///    or time never extends a subscription.
///
/// Pure Dart: no Flutter, no network, no `DateTime.now()`. Nothing here knows
/// what Chargily is — payment lives on the server, and Article 7.2 forbids the
/// app from showing a price, a buy button, or a payment link at all.
library;

export 'src/subscription.dart';
export 'src/subscription_machine.dart';
