# Sprint 17 Localization Design

## Goal

Prepare Tracker for international use according to the Sprint 17 localization assignment: move every user-facing string into localization resources, localize the interface, and format the completed-day counter with language-aware plural rules.

## Scope

The implementation covers the complete mandatory assignment and the first optional assignment:

- add and populate `Localizable.strings`;
- replace user-facing string literals with localized lookups;
- add `Localizable.stringsdict` for the “N days” counter;
- support Russian, English, German, and Arabic;
- verify the interface with long translated text and right-to-left Arabic layout.

The optional SwiftGen integration is intentionally excluded. The official SwiftGen build plugin currently has unresolved Xcode 26 compatibility reports, while code generation is not required for review acceptance. Avoiding it keeps this learning project deterministic and dependency-free.

## Existing Work to Preserve

The current `sprint_17` working tree already contains user-created localization groups for Russian, English, German, and Arabic, localized `LaunchScreen.strings` files, project-region settings, and the nonlocalized-string analyzer flag. These changes are the starting point and must not be reverted.

## Localization Architecture

`Localizable.strings` remains the single source of translations for static user-facing text. Keys use semantic dotted names grouped by feature, for example `tab.trackers`, `tracker.empty.title`, and `creation.button.create`. Swift code accesses them through `NSLocalizedString(_:comment:)`, as requested in the lesson.

Only text visible or announced to the user is localized. Technical identifiers remain unchanged: SF Symbol names, asset names, reuse identifiers, Core Data keys and model names, predicates, persistence filenames, and `UserDefaults` keys.

The app uses the current system locale. The hard-coded Russian locale is removed from `UIDatePicker`, allowing UIKit to display dates according to the selected app language and region.

## Pluralization

Each supported localization receives a `Localizable.stringsdict` entry for `tracker.days_count`. `String.localizedStringWithFormat` supplies the count and Foundation selects the proper grammatical form.

- Russian includes `one`, `few`, `many`, and `other`.
- English and German include `one` and `other`.
- Arabic includes the CLDR-relevant `zero`, `one`, `two`, `few`, `many`, and `other` forms.

The existing manual Russian suffix calculation in `TrackerCell` is removed.

## Interface Coverage

Localization covers:

- tab bar and main Tracker/Statistics titles;
- tracker search, empty states, category headers, and accessibility labels;
- tracker type, creation, category, and schedule screens;
- weekday full and short names;
- validation and persistence error messages shown to users;
- onboarding titles and completion button;
- dynamic schedule summaries such as “Every day”;
- completed-day count through pluralization.

Development-only assertion messages are not part of the UI and do not need localization.

## Layout and RTL Behavior

Existing Auto Layout constraints should use `leading` and `trailing`; the changed screens will be audited for fixed left/right positioning. Text controls must tolerate longer German translations without truncating essential actions. Arabic is used to verify automatic mirroring and correct alignment. Images are not localized unless they communicate direction or contain text; the current Tracker assets do neither.

## Verification

Verification consists of:

1. Validate every `.strings` and `.stringsdict` file with `plutil`.
2. Search Swift sources for remaining Russian user-facing literals and classify any intentional technical/debug strings.
3. Build the app for an available iOS Simulator using `xcodebuild`.
4. Launch and inspect at least Russian, English, German, and Arabic configurations, including the main screen, creation flow, schedule, categories, onboarding, and plural counter.
5. Confirm Arabic right-to-left layout and that the date picker no longer stays Russian under other locales.

## Out of Scope

- SwiftGen or another code-generation dependency;
- localization of SF Symbol names, asset names, database fields, or persistence identifiers;
- changes belonging to later Sprint 17 topics such as dark theme, analytics, or screenshot tests.
