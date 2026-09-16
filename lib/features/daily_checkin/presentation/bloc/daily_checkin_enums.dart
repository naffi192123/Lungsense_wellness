/// Step positions in the guided daily check-in flow.
enum CheckinStep {
  start,
  cough,
  breathing,
  symptoms,
  diagnosis,
  review,
  completing,
  completed,
}

/// State machine for the submission phase of the check-in.
enum CheckinSessionStatus {
  ready,
  submitting,        // Triggered, starting compute
  computingScore,    // POST /score/compute in progress
  completingSession, // POST /score/session-complete in progress
  refreshingScore,   // GET /score/latest+history+baseline in progress
  completed,
  error,
}
