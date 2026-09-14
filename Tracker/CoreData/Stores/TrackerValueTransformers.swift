import UIKit

enum TrackerValueTransformers {
    static func register() {
        ValueTransformer.setValueTransformer(
            TrackerColorTransformer(),
            forName: NSValueTransformerName("TrackerColorTransformer")
        )
        ValueTransformer.setValueTransformer(
            TrackerScheduleTransformer(),
            forName: NSValueTransformerName("TrackerScheduleTransformer")
        )
    }
}

@objc(TrackerColorTransformer)
final class TrackerColorTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass { NSData.self }
    override class func allowsReverseTransformation() -> Bool { true }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let color = value as? UIColor else { return nil }
        return try? NSKeyedArchiver.archivedData(
            withRootObject: color,
            requiringSecureCoding: true
        )
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data)
    }
}

@objc(TrackerScheduleTransformer)
final class TrackerScheduleTransformer: ValueTransformer {
    override class func transformedValueClass() -> AnyClass { NSData.self }
    override class func allowsReverseTransformation() -> Bool { true }

    override func transformedValue(_ value: Any?) -> Any? {
        guard let rawDays = value as? [Int] else { return nil }
        return try? JSONEncoder().encode(rawDays)
    }

    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let data = value as? Data else { return nil }
        return try? JSONDecoder().decode([Int].self, from: data)
    }
}
