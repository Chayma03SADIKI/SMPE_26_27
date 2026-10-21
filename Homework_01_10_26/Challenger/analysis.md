# Critical Analysis of the Challenger O-ring Risk Notebook

## What is good

- The general framing is correct: logistic regression is an appropriate method to model the probability of O-ring failure as a function of temperature.
- The dataset is correctly loaded and the variables (temperature, pressure, number of malfunctions) are well identified.
- The prediction curve is plotted over a reasonable temperature range, which is a good visualization habit.
- The final probability calculation (combining individual O-ring failure probabilities across the three launcher segments) is mathematically sound **given the model input**.

---

## What is wrong

### Flights without incidents were excluded from the analysis

The notebook explicitly filters out all flights where no O-ring failed:

```python
data = data[data.Malfunction > 0]
```

The justification given is:
> *"Flights without incidents do not provide any information on the influence of temperature or pressure on malfunction."*

**This is statistically incorrect and the root cause of the underestimation.**  
Flights with zero failures are essential data points. They tell us that at higher temperatures, O-rings tend not to fail. Removing them destroys the temperature signal entirely: the remaining data only contains failures, spread across a narrow temperature range, making temperature look irrelevant.

With the full dataset, the negative relationship between temperature and failure probability becomes clearly visible and statistically significant.

### Dangerous extrapolation without warning

The model is fitted on data ranging approximately from 53°F to 81°F.  
The prediction is then made at **31°F**, which is 22°F below the coldest observed data point.

Extrapolating a logistic regression that far outside the observed range — especially after the temperature signal was artificially suppressed by Error 1 — is highly unreliable. This should at minimum have been flagged as a major uncertainty.

### ncertainty of the logistic regression is not taken into account

The model summary shows that the temperature coefficient is essentially zero with a very large standard error (coefficient: 0.0014, std error: 0.122). The notebook acknowledges this but draws no strong conclusion from it.

In fact, this is a **consequence of Error 1**: once all flights are included, the temperature coefficient becomes negative and statistically significant, and the confidence interval around the prediction at 31°F shows a very high probability of failure.

The uncertainty interval should have been plotted around the prediction curve to honestly represent the risk at low temperatures.

---

## Conclusion

When the analysis is redone with the **full dataset** (including flights with no O-ring failures):

- The logistic regression shows a clear **negative relationship** between temperature and failure probability.
- At 31°F, the model predicts a **very high probability of O-ring failure** (close to 1), with a wide confidence interval that remains alarming.
- The takeoff should have been delayed.

The original analysis is a cautionary tale about **confirmation bias in data filtering**: excluding "uneventful" observations because they seem uninformative is a common but dangerous mistake that can have catastrophic consequences.