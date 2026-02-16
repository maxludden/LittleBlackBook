import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            ContactsView()
                .tabItem {
                    Label("Contacts", systemImage: "person.2.fill")
                }
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
        }
    }
}

#Preview {
    RootTabView()
}
