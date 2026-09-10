import Foundation
import SwiftData

enum RecurringEngine {
    static func materialize(context: ModelContext) {
        let descriptor = FetchDescriptor<RecurringRule>()
        guard let rules = try? context.fetch(descriptor) else { return }

        let now = Date.now
        var changed = false

        for rule in rules where rule.isActive {
            guard rule.amount > 0, let category = rule.category else { continue }
            var last: Date
            if let generated = rule.lastGeneratedDate {
                last = generated
            } else {
                last = rule.startDate.startOfDay
                if rule.startDate <= now, !hasTransaction(rule: rule, on: last, context: context) {
                    context.insert(Transaction(
                        title: rule.title,
                        desc: nil,
                        amount: rule.amount,
                        date: last,
                        category: category,
                        createdAt: now,
                        recurringRuleID: rule.id
                    ))
                    changed = true
                }
                rule.lastGeneratedDate = last
                changed = true
            }

            var safety = 0
            while safety < 120 {
                safety += 1
                guard let next = rule.frequency.nextDate(after: last, dayNumber: rule.dayNumber) else { break }
                guard next > last else { break }
                guard next <= now else { break }
                if let end = rule.endDate, next > end {
                    break
                }

                if !hasTransaction(rule: rule, on: next, context: context) {
                    context.insert(Transaction(
                        title: rule.title,
                        desc: nil,
                        amount: rule.amount,
                        date: next,
                        category: category,
                        createdAt: now,
                        recurringRuleID: rule.id
                    ))
                    changed = true
                }

                last = next
                rule.lastGeneratedDate = next
                changed = true
            }
        }

        if changed {
            try? context.save()
        }
    }

    static func nextDueDate(for rule: RecurringRule) -> Date? {
        guard rule.isActive else { return nil }
        let since = rule.lastGeneratedDate ?? rule.startDate.addingTimeInterval(-1)
        guard let next = rule.frequency.nextDate(after: since, dayNumber: rule.dayNumber) else { return nil }
        if let end = rule.endDate, next > end {
            return nil
        }
        return next
    }

    private static func hasTransaction(rule: RecurringRule, on date: Date, context: ModelContext) -> Bool {
        let ruleID = rule.id
        var descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { tx in
                tx.recurringRuleID == ruleID
            }
        )
        descriptor.fetchLimit = 500
        guard let transactions = try? context.fetch(descriptor) else { return false }
        return transactions.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }
}
