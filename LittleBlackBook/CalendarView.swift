import SwiftUI

struct CalendarView: View {
    var body: some View {
        ContentUnavailableView("Calendar", systemImage: "calendar", description: Text("This feature is coming soon."))
            .navigationTitle("Calendar")
    }
}

#Preview {
    NavigationStack { CalendarView() }
}
