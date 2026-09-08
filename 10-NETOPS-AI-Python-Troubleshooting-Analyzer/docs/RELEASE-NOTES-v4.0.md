# NETOPS AI v4.0

Status: Completed  
Platform: Windows 10/11  
Runtime: Python 3.13

## Bilingual release

- Added an Albanian/English language selector to the application header.
- Translated navigation, buttons, table headings, warnings and confirmations.
- Added English technical diagnoses for every supported analyzer rule.
- Added English device-comparison evidence, verification, minimal-change and retest guidance.
- Added bilingual HTML/PDF incident-report output.
- Re-runs the visible analysis immediately after a language change.
- Preserves the existing local SQLite incident history across upgrades.

## Verification

The expanded unit-test suite passes all 11 tests. The bilingual catalog is verified against representative BGP, DNS and interface scenarios.
