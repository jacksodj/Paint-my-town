import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "paintbrush.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                Text("Paint My Town")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Let's get started!")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Home")
        }
    }
}

#Preview {
    ContentView()
}
