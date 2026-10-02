import SwiftUI

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

#Preview {
    ContentView()
}
