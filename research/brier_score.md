#### Brier Score
- The accuracy of a set of probabilistic predictions can be formally measured with the Brier score
- The math is pretty simple:
  - If an event comes to pass, it is assigned a value of 1. If an event doesn't occur, it is assigned a value of 0.
  - Given probabilistic predictions for those events, the Brier score is just the mean of squared differences between those predictions and their corresponding event scores (1s and 0s).
- Larger differences between probabilistic forecasts and event outcomes reflect more error in predictions, so a lower Brier score indicates greater accuracy.
- Brier scores are bound between 0 and 1.
