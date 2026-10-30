//
//  Filters.swift
//  week8
//
//  List of Core Image filters and how strong each one is.
//

import SwiftUI
import CoreImage

enum VideoEffect: String, CaseIterable {
  case normal = "Normal"
  case noir = "Noir"
  case comic = "Comic"
  case pixellate = "Pixel"
  case crystallize = "Crystal"
  case thermal = "Thermal"
  case sepia = "Sepia"
  case twirl = "Twirl"
  case bloom = "Bloom"

  var filterName: String? {
    switch self {
    case .normal: return nil
    case .noir: return "CIPhotoEffectNoir"
    case .comic: return "CIComicEffect"
    case .pixellate: return "CIPixellate"
    case .crystallize: return "CICrystallize"
    case .thermal: return "CIFalseColor"
    case .sepia: return "CISepiaTone"
    case .twirl: return "CITwirlDistortion"
    case .bloom: return "CIBloom"
    }
  }

  // true if the slider changes this filter
  var usesStrength: Bool {
    switch self {
    case .pixellate, .crystallize, .sepia, .twirl, .bloom: return true
    default: return false
    }
  }
}

extension CameraModel {
  // Applies the current filter. strength goes from 0 to 1.
  // Returns the image and whether a filter was applied.
  func filterImage(_ pixelBuffer: CVPixelBuffer) -> (CIImage, Bool) {
    let input = CIImage(cvPixelBuffer: pixelBuffer)
    var output = input
    var changed = false

    if let name = currentEffect.filterName, let filter = CIFilter(name: name) {
      filter.setValue(input, forKey: kCIInputImageKey)
      let s = currentStrength

      switch currentEffect {
      case .pixellate:
        filter.setValue(5 + s * 60, forKey: kCIInputScaleKey)
      case .crystallize:
        filter.setValue(5 + s * 70, forKey: kCIInputRadiusKey)
      case .sepia:
        filter.setValue(s, forKey: kCIInputIntensityKey)
      case .bloom:
        filter.setValue(s * 3, forKey: kCIInputIntensityKey)
        filter.setValue(30.0, forKey: kCIInputRadiusKey)
      case .thermal:
        filter.setValue(CIColor.blue, forKey: "inputColor0")
        filter.setValue(CIColor.yellow, forKey: "inputColor1")
      case .twirl:
        let center = CIVector(x: input.extent.midX, y: input.extent.midY)
        filter.setValue(center, forKey: kCIInputCenterKey)
        filter.setValue(input.extent.width / 2, forKey: kCIInputRadiusKey)
        filter.setValue(s * 6, forKey: kCIInputAngleKey)
      default:
        break
      }

      if let result = filter.outputImage {
        // crop so filters that grow the image keep the same size
        output = result.cropped(to: input.extent)
        changed = true
      }
    }

    // send the frame to the screen
    if let cgImage = context.createCGImage(output, from: input.extent) {
      DispatchQueue.main.async {
        self.previewImage = cgImage
      }
    }
    return (output, changed)
  }
}
