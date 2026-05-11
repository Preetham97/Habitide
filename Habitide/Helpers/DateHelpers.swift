import Foundation

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    func formatted(_ format: String) -> String {
        let f = DateFormatter()
        f.dateFormat = format
        return f.string(from: self)
    }

    var prettyDate: String {
        formatted("MMM d, yyyy")
    }

    var shortDay: String {
        formatted("d")
    }
}

extension Calendar {
    func daysInMonth(for date: Date) -> [Date] {
        guard let range = self.range(of: .day, in: .month, for: date),
              let firstOfMonth = self.date(from: self.dateComponents([.year, .month], from: date))
        else { return [] }
        return range.compactMap { day in
            self.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
    }

    func firstWeekdayOffset(for date: Date) -> Int {
        guard let firstOfMonth = self.date(from: self.dateComponents([.year, .month], from: date))
        else { return 0 }
        let weekday = self.component(.weekday, from: firstOfMonth)
        return weekday - self.firstWeekday
    }
}
