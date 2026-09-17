import Foundation

// Run the compiled executable with the built Tracker.app path and language code.
// Uses an explicit locale because this command-line executable has no app localizations.
let appPath = CommandLine.arguments[1]
let language = CommandLine.arguments[2]
let bundle = Bundle(path: appPath + "/" + language + ".lproj")!
let locale = Locale(identifier: language)
let expectedTitles = ["ru": "Трекеры", "en": "Trackers", "de": "Tracker", "ar": "المتتبعات"]
let title = NSLocalizedString("tab.trackers", bundle: bundle, comment: "")
precondition(title == expectedTitles[language], "Wrong app language: \(title)")

let languages = ["ru", "en", "de", "ar"]
var referenceKeys: Set<String>?
for code in languages {
    let path = appPath + "/" + code + ".lproj/Localizable.strings"
    let data = try Data(contentsOf: URL(fileURLWithPath: path))
    let strings = try PropertyListSerialization.propertyList(from: data, format: nil) as! [String: String]
    let keys = Set(strings.keys)
    if let referenceKeys {
        precondition(keys == referenceKeys, "Missing translations in \(code)")
    } else {
        referenceKeys = keys
    }
    precondition(strings.values.allSatisfy { !$0.isEmpty }, "Empty translation in \(code)")
}

let cases: [String: [(Int, String)]] = [
    "ru": [(0, "дней"), (1, "день"), (2, "дня"), (5, "дней"),
           (11, "дней"), (12, "дней"), (14, "дней"), (21, "день"),
           (22, "дня"), (25, "дней"), (101, "день"), (111, "дней")],
    "en": [(0, "days"), (1, "day"), (2, "days"), (11, "days"), (21, "days")],
    "de": [(0, "Tage"), (1, "Tag"), (2, "Tage"), (11, "Tage"), (21, "Tage")],
    "ar": [(0, "يوم"), (1, "يوم"), (2, "يومان"), (3, "أيام"),
           (10, "أيام"), (11, "يومًا"), (99, "يومًا"), (100, "يوم")]
]
let format = NSLocalizedString("tracker.days_count", bundle: bundle, comment: "")
for (count, noun) in cases[language]! {
    let actual = String(format: format, locale: locale, arguments: [count])
    precondition(actual.hasSuffix(" " + noun), "Wrong plural for \(language), \(count): \(actual)")
    precondition(actual.unicodeScalars.contains { CharacterSet.decimalDigits.contains($0) },
                 "Missing count: \(actual)")
    print("\(language): \(count) → \(actual)")
}
let limit = String(
    format: NSLocalizedString("creation.name.limit", bundle: bundle, comment: ""),
    locale: locale, arguments: [38]
)
precondition(!limit.contains("%"), "Unresolved format: \(limit)")
print("PASS: \(language), all resource keys and plural cases")
