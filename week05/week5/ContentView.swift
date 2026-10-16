import SwiftUI
import Combine
import CoreText

// MAIN VIEW: holds the two pages as tabs at the bottom
struct ContentView: View {
    var body: some View {
        TabView {
            ClockPage()
                .tabItem {
                    Label("Clock", systemImage: "clock")
                }

            TimerPage()
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            FontPage()
                .tabItem {
                    Label("Fonts", systemImage: "textformat")
                }

            ScorePage()
                .tabItem {
                    Label("Score", systemImage: "star")
                }
        }
    }
}

// PAGE 1: shows the current time, updates every second
struct ClockPage: View {
    @State private var now = Date()

    // fires every 1 second
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text("Current Time")
                .font(.title)

            Text(now, style: .time)
                .font(.system(size: 60))
                .bold()
        }
        .onReceive(timer) { _ in
            now = Date()   // update the time each second
        }
    }
}

// PAGE 2: countdown timer from 10 seconds
struct TimerPage: View {
    @State private var secondsLeft = 10
    @State private var isRunning = false

    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 20) {
            Text("Countdown")
                .font(.title)

            Text("\(secondsLeft)")
                .font(.system(size: 80))
                .bold()

            if secondsLeft == 0 {
                Text("Time is up!")
                    .foregroundColor(.red)
            }

            HStack(spacing: 20) {
                Button("Start") {
                    isRunning = true
                }

                Button("Stop") {
                    isRunning = false
                }

                Button("Reset") {
                    isRunning = false
                    secondsLeft = 10
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onReceive(timer) { _ in
            // only count down if running and not at 0
            if isRunning && secondsLeft > 0 {
                secondsLeft -= 1
            }
        }
    }
}

// PAGE 3: shows custom fonts
// Pacifico-Regular.ttf was downloaded from Google Fonts and added to the project.
struct FontPage: View {
    init() {
        if let url = Bundle.main.url(forResource: "Pacifico-Regular", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    var body: some View {
        VStack(spacing: 20) {

            // downloaded font
            Text("Hello, Pacifico!")
                .font(Font.custom("Pacifico-Regular", size: 44))

            Text("Custom fonts make apps fun")
                .font(Font.custom("Pacifico-Regular", size: 24))
                .foregroundColor(.purple)

            // default system font
            Text("Hello, system!")
                .font(.system(size: 54))
        }
        .padding()
    }
}

// PAGE 4: username + score saved with @AppStorage
// @AppStorage keeps values even after the app is closed and opened again
struct ScorePage: View {
    @AppStorage("username") var username: String = "Anonymous"
    @AppStorage("score") var score: Int = 0
    @AppStorage("bestScore") var bestScore: Int = 0

    @State private var nameInput = ""

    var isLoggedIn: Bool {
        username != "Anonymous"
    }

    // pick an emoji based on the score
    var mood: String {
        if score >= 20 { return "🏆" }
        if score >= 10 { return "🔥" }
        if score > 0 { return "😀" }
        if score == 0 { return "😐" }
        return "😢"
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("Welcome, \(username)")
                .font(.title)
                .bold()

            if isLoggedIn {
                Button("Log out") {
                    username = "Anonymous"
                    score = 0
                }
                .buttonStyle(.bordered)
            } else {
                HStack {
                    TextField("Enter your name", text: $nameInput)
                        .textFieldStyle(.roundedBorder)
                    Button("Log in") {
                        if !nameInput.isEmpty {
                            username = nameInput
                            nameInput = ""
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal)
            }

            Text(mood)
                .font(.system(size: 80))

            Text("Score: \(score)")
                .font(.system(size: 40))
                .bold()
                .foregroundColor(score < 0 ? .red : .primary)

            Text("Best: \(bestScore)")
                .foregroundColor(.secondary)

            HStack(spacing: 20) {
                Button("- 1") {
                    score -= 1
                }
                Button("+ 1") {
                    score += 1
                    if score > bestScore { bestScore = score }
                }
                Button("Reset") {
                    score = 0
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isLoggedIn)

            if !isLoggedIn {
                Text("Log in to start playing")
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .animation(.spring, value: score)
    }
}

#Preview {
    ContentView()
}
