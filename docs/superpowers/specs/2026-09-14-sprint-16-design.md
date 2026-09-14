# Sprint 16 Design

## Scope

Implement only the mandatory Sprint 16 requirements for Tracker:

- move the category selection screen to MVVM with closure-based bindings;
- add a two-page onboarding flow built with `UIPageViewController`;
- match the Sprint 16 Figma screens;
- preserve the completed Sprint 14 and Sprint 15 behavior.

The optional starred task—migrating every application screen to MVVM—is explicitly excluded.

## Git and delivery constraints

- Work on `sprint_16`, created from the current `main` after Sprint 15 has been merged.
- Do not commit or push changes unless the user asks separately.
- Minimum deployment target remains iOS 17.0.
- Use UIKit, Core Data, and the existing programmatic Auto Layout style.

## Category architecture

### Model

`TrackerCategoryStore` remains the only object that reads and writes category data in Core Data. It exposes domain values (`TrackerCategory`) rather than managed objects and provides an `add(title:)` method. Its fetched-results-controller delegate continues to notify consumers after database changes.

### ViewModel

`CategoryViewModel` owns presentation state for the category table. It depends on a small store protocol rather than Core Data directly. It:

- exposes an immutable list of category cell models;
- exposes a closure binding that notifies the view when the list changes;
- loads categories from the store;
- creates categories through the store;
- tracks the selected category title;
- marks the selected row and returns the selected category through a callback.

The ViewModel imports Foundation only and knows nothing about UIKit.

### View

`CategoryViewController` owns the `UITableView`, empty-state illustration and “Добавить категорию” button. It binds to the ViewModel with a closure and reloads the table when presentation data changes. Selecting a row updates the ViewModel and returns the category to `NewTrackerViewController`.

`NewCategoryViewController` provides a 38-character name field and a “Готово” button. The button is enabled only for a non-empty trimmed name. Saving calls the ViewModel and returns to the category list; the new category is not automatically selected.

`NewTrackerViewController` displays the chosen category as secondary text, requires it before enabling “Создать”, and passes it back through the tracker-creation delegate. `TrackersViewController` stores the new tracker under that title instead of “По умолчанию”.

## Onboarding architecture

`OnboardingPageViewController` is a `UIPageViewController` configured with `.scroll` and horizontal navigation. It owns two child `OnboardingPageContentViewController` instances, implements `UIPageViewControllerDataSource` and `UIPageViewControllerDelegate`, and updates a custom `UIPageControl` when a swipe completes.

Each child page contains a full-screen Figma background image, a centered two-line title, and the common “Вот это технологии!” button. The page content is described by a small immutable model.

`OnboardingStateStore` wraps one `UserDefaults` boolean. At launch, `SceneDelegate` chooses onboarding only if it has not been completed. Pressing the button stores completion and replaces the window root controller with the existing `TabBarController`. Future launches go directly to the tracker list.

## Figma fidelity

Use Sprint 16 nodes `37878:20676` and `37878:20667` from the user's editable Tracker copy:

- backgrounds exported directly from Figma;
- titles: “Отслеживайте только то, что хотите” and “Даже если это не литры воды и йога”;
- title font: system bold, 32 pt, centered, approximately 38 pt line height;
- button: 335×60 pt, 20 pt horizontal inset, 16 pt corner radius, black background, white 16 pt medium text;
- page indicator centered above the button;
- layout uses safe-area-aware constraints and scales the background with aspect fill across all supported iPhone sizes.

Category screens follow nodes `37878:20394`, `37878:20387`, `37878:20119`, and `37878:20373`: centered 16 pt navigation title, 75 pt rows and text fields, 16 pt corner radii, 20 pt side inset for the bottom button, and project color tokens.

## Error handling

Store operations throw. The ViewModel catches no database errors silently: it exposes an error callback for the controller to present a simple alert. Empty or whitespace-only category names are rejected before a store call. Duplicate names are rejected case-insensitively to avoid visually identical categories.

## Testing and verification

Add unit tests before production code for:

- initial category loading and binding notification;
- selected-row state and callback;
- category creation and duplicate/empty-name validation;
- onboarding state before and after completion;
- page ordering and boundary behavior.

Then run the complete test suite and a Debug simulator build. Manually verify first launch, both swipe directions, page-control updates, exit persistence after relaunch, empty category state, creating a category, selecting it, and creating a tracker in it. Compare screenshots against the Figma reference at 375×812 and one compact supported iPhone size.
