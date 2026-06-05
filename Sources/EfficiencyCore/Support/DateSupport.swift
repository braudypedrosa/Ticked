import Foundation

public extension Calendar {
    static var efficiencyUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}

public extension Date {
    static func iso8601(_ value: String) -> Date {
        guard let date = efficiencyDateTime(value) else {
            preconditionFailure("Invalid ISO-8601 date: \(value)")
        }
        return date
    }

    static func efficiencyDateOnly(_ value: String) -> Date? {
        var components = DateComponents()
        components.calendar = .efficiencyUTC
        components.timeZone = TimeZone(secondsFromGMT: 0)

        let pieces = value.split(separator: "-").map(String.init)
        guard pieces.count == 3,
              let year = Int(pieces[0]),
              let month = Int(pieces[1]),
              let day = Int(pieces[2])
        else { return nil }

        components.year = year
        components.month = month
        components.day = day
        return components.date
    }

    static func efficiencyDateTime(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }

        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        return fallback.date(from: value)
    }
}

public extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var nilIfBlank: String? {
        let value = trimmed
        return value.isEmpty ? nil : value
    }
}
