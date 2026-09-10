import SwiftUI
import WidgetKit

@main
struct IdiotWidgetBundle: WidgetBundle {
    var body: some Widget {
        TransactionWidget()
        AnalyticsWidget()
        NewTransactionWidget()
    }
}
