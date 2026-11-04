import SwiftUI
import WidgetKit

private let appGroup = "group.com.example.paisaclone"
struct MoneyEntry: TimelineEntry {
    let date: Date
    let balance: String
    let profile: String
    let budget: String
    let budgetName: String
    let progress: Double
}
struct MoneyProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoneyEntry {
        MoneyEntry(date: Date(), balance: "••••", profile: "Tink", budget: "Budget check-in", budgetName: "Your next good habit", progress: 0.4)
    }
    private func read() -> MoneyEntry {
        let prefs = UserDefaults(suiteName: appGroup)
        return MoneyEntry(date: Date(), balance: prefs?.string(forKey: "balance") ?? "Open Tink", profile: prefs?.string(forKey: "profile") ?? "Tink", budget: prefs?.string(forKey: "budget") ?? "Create a budget", budgetName: prefs?.string(forKey: "budgetName") ?? "Your next good habit", progress: Double(prefs?.integer(forKey: "budgetPercent") ?? 0) / 100)
    }
    func getSnapshot(in context: Context, completion: @escaping (MoneyEntry) -> Void) { completion(read()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<MoneyEntry>) -> Void) {
        completion(Timeline(entries: [read()], policy: .after(Date().addingTimeInterval(3600))))
    }
}
private extension View {
    @ViewBuilder func paisaBackground() -> some View {
        if #available(iOS 17.0, *) { self.containerBackground(Color(red: 0.97, green: 0.97, blue: 0.985), for: .widget) }
        else { self.padding(16).background(Color(red: 0.97, green: 0.97, blue: 0.985)) }
    }
}
struct BalanceView: View {
    let entry: MoneyEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(entry.profile, systemImage: "sparkle").font(.caption)
            Spacer()
            Text("NET WORTH").font(.caption2).tracking(2)
            Text(entry.balance).font(.title2.bold()).monospacedDigit().minimumScaleFactor(0.5).lineLimit(1)
            Text("Your money. Your device.").font(.caption2)
        }.foregroundColor(Color(red: 0.043, green: 0.043, blue: 0.059)).paisaBackground().widgetURL(URL(string: "paisa://home"))
    }
}
struct BudgetView: View {
    let entry: MoneyEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Budget check-in", systemImage: "chart.pie").font(.caption)
            Text(entry.budgetName).font(.subheadline.bold()).lineLimit(2)
            Text(entry.budget).font(.title3.bold())
            ProgressView(value: min(1, max(0, entry.progress))).tint(Color(red: 0.569, green: 0.424, blue: 1.0))
        }.foregroundColor(Color(red: 0.043, green: 0.043, blue: 0.059)).paisaBackground().widgetURL(URL(string: "paisa://home"))
    }
}
struct QuickView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "plus.circle.fill").font(.largeTitle)
            Text("A little entry.").font(.title3.bold())
            Text("One less thing to remember.").font(.caption)
        }.foregroundColor(Color(red: 0.043, green: 0.043, blue: 0.059)).paisaBackground().widgetURL(URL(string: "paisa://quick_add"))
    }
}
struct BalanceWidget: Widget {
    let kind = "BalanceWidget"
    var body: some WidgetConfiguration { StaticConfiguration(kind: kind, provider: MoneyProvider()) { BalanceView(entry: $0) }.configurationDisplayName("Net worth").description("Your bigger balance, at a glance.").supportedFamilies([.systemSmall, .systemMedium]) }
}
struct BudgetWidget: Widget {
    let kind = "BudgetWidget"
    var body: some WidgetConfiguration { StaticConfiguration(kind: kind, provider: MoneyProvider()) { BudgetView(entry: $0) }.configurationDisplayName("Budget progress").description("A gentle spending check-in.").supportedFamilies([.systemSmall, .systemMedium]) }
}
struct QuickAddWidget: Widget {
    let kind = "QuickAddWidget"
    var body: some WidgetConfiguration { StaticConfiguration(kind: kind, provider: MoneyProvider()) { _ in QuickView() }.configurationDisplayName("Quick add").description("Your next entry, one tap away.").supportedFamilies([.systemSmall]) }
}
@main struct PaisaWidgetBundle: WidgetBundle {
    var body: some Widget { BalanceWidget(); BudgetWidget(); QuickAddWidget() }
}
