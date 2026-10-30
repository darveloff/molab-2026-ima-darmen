//
//  FrameView.swift
//  week8
//
//  Shows the latest filtered camera frame.
//

import SwiftUI

struct FrameView: View {
  var image: CGImage?
  private let label = Text("Video feed")

  var body: some View {
    if let image = image {
      GeometryReader { geometry in
        Image(image, scale: 1.0, orientation: .upMirrored, label: label)
          .resizable()
          .scaledToFill()
          .frame(width: geometry.size.width, height: geometry.size.height)
          .clipped()
      }
    } else {
      Color.black
    }
  }
}
