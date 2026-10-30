//
//  ContentView.swift
//  week8
//
//  Filter camera: pick a filter, change its strength,
//  take a photo or record a video.
//

import SwiftUI
import Combine

struct ContentView: View {
  @State var model = CameraModel()
  @State var seconds = 0

  let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  var body: some View {
    ZStack {
      FrameView(image: model.previewImage)
        .ignoresSafeArea()

      VStack {
        if model.isRecording {
          RecordingTimeView()
        }
        Spacer()
        if model.selectedEffect.usesStrength {
          StrengthSliderView()
        }
        FilterSelectionView()
        ButtonsView()
      }
    }
    .onAppear {
      model.start()
    }
    .onReceive(clock) { _ in
      if model.isRecording { seconds += 1 }
    }
    .alert(model.message ?? "", isPresented: Binding(
      get: { model.message != nil },
      set: { if !$0 { model.message = nil } }
    )) {}
  }

  // red dot and time while recording
  func RecordingTimeView() -> some View {
    HStack {
      Circle().fill(.red).frame(width: 10, height: 10)
      Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
        .monospacedDigit()
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(.black.opacity(0.5), in: Capsule())
    .padding(.top)
  }

  func StrengthSliderView() -> some View {
    HStack {
      Image(systemName: "dial.low")
      Slider(value: $model.strength, in: 0...1)
        .onChange(of: model.strength) { _, value in
          model.changeStrength(to: value)
        }
      Image(systemName: "dial.high")
    }
    .foregroundStyle(.white)
    .padding(.horizontal)
  }

  func FilterSelectionView() -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 6) {
        ForEach(VideoEffect.allCases, id: \.self) { effect in
          Button(effect.rawValue) {
            model.changeEffect(to: effect)
          }
          .padding(8)
          .background(model.selectedEffect == effect ? Color.orange : Color.gray.opacity(0.7))
          .foregroundColor(.white)
          .cornerRadius(8)
        }
      }
      .padding()
    }
    .background(Color.black.opacity(0.5))
  }

  // photo button on the left, record button in the middle
  func ButtonsView() -> some View {
    HStack {
      Button {
        model.takePhoto()
      } label: {
        Image(systemName: "camera.fill")
          .font(.title2)
          .foregroundStyle(.white)
          .frame(width: 56, height: 56)
          .background(.black.opacity(0.5), in: Circle())
      }
      .disabled(model.isRecording)
      .frame(maxWidth: .infinity)

      Button {
        if !model.isRecording { seconds = 0 }
        model.toggleRecording()
      } label: {
        RoundedRectangle(cornerRadius: model.isRecording ? 8 : 35)
          .fill(Color.red)
          .frame(width: model.isRecording ? 34 : 64, height: model.isRecording ? 34 : 64)
          .frame(width: 80, height: 80)
          .overlay(Circle().stroke(Color.white, lineWidth: 4))
          .animation(.easeInOut(duration: 0.2), value: model.isRecording)
      }
      .frame(maxWidth: .infinity)

      Color.clear.frame(maxWidth: .infinity, maxHeight: 1)
    }
    .padding(.bottom, 10)
  }
}

#Preview {
  ContentView()
}
