import 'package:flutter_test/flutter_test.dart';
import 'package:lunio/features/setup/setup_wizard.dart';

/// The game list is chosen during setup, not found later in the dashboard.
///
/// Client request, 2026-09-25. The literal wording was "right after signing
/// up"; it sits after the protection step instead, because choosing what to
/// block before agreeing that anything will be blocked is a question with no
/// context — and the accessibility disclosure on that step is the one screen in
/// this flow that is not ours to reorder.
///
/// These are deliberately thin. The step's own behaviour is a route push and a
/// count read from `managedAppsProvider`, both of which belong to screens that
/// already have tests; what is worth pinning is that the step **exists in the
/// flow at all**, because the way this regresses is somebody renumbering the
/// switch and the last case silently swallowing it.
void main() {
  test('the wizard has a step for the game list', () {
    // Five steps before 2026-09-25. A six that drifts back to five means the
    // games step has been absorbed into the default case and will never show.
    expect(SetupWizard.totalSteps, 6);
  });

  test('the completed marker moves with the step count', () {
    // One fact written in two files, and forgetting is silent: the gate still
    // opens, so nothing breaks — a household that set up before the games step
    // existed is simply never shown it, and ends with blocking switched on and
    // nothing blocked.
    //
    // This assertion failed the moment the sixth step was added, which is the
    // only reason the sentinel was raised with it.
    expect(SetupWizard.completedStep, SetupWizard.totalSteps);
  });
}
