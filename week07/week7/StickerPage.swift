import CoreImage
import CoreImage.CIFilterBuiltins
import Photos
import PhotosUI
import SwiftUI

// PAGE 6: pick a photo, add a filter, drag emoji stickers on top, save to Photos
// Based on Instafilter (Paul Hudson) + the layers idea from week 6.

// one emoji sticker on top of the photo
struct Sticker: Identifiable {
    let id = UUID()
    var emoji: String
    var position = CGPoint(x: 175, y: 175)   // starts in the middle of the 350x350 canvas
}

struct StickerPage: View {
    @State private var processedImage: UIImage?
    @State private var filterIntensity = 0.5
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingFilters = false
    @State private var stickers: [Sticker] = []
    @State private var saveMessage = ""
    @State private var permissionDenied = false

    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()

    let emojis = ["😎", "🔥", "⭐️", "❤️", "🌸", "👑"]

    // the photo with all stickers on top: this is what gets saved
    var canvas: some View {
        ZStack {
            Color(.systemGray6)
            if let processedImage {
                Image(uiImage: processedImage)
                    .resizable()
                    .scaledToFit()
            }
            ForEach($stickers) { $sticker in
                Text(sticker.emoji)
                    .font(.system(size: 60))
                    .position(sticker.position)
                    .gesture(
                        DragGesture(coordinateSpace: .named("canvas"))
                            .onChanged { value in
                                sticker.position = value.location   // follow the finger
                            }
                    )
            }
        }
        .frame(width: 350, height: 350)
        .coordinateSpace(name: "canvas")
        .clipped()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if processedImage == nil {
                    // tapping the empty box also opens the photo picker
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        ContentUnavailableView("No picture", systemImage: "photo.badge.plus",
                                               description: Text("Tap to choose a photo"))
                            .frame(height: 350)
                    }
                    .buttonStyle(.plain)
                } else {
                    canvas
                }

                // choose a photo
                PhotosPicker("Choose Photo", selection: $selectedItem, matching: .images)
                    .onChange(of: selectedItem) { loadImage() }

                // filter strength
                HStack {
                    Text("Intensity")
                    Slider(value: $filterIntensity)
                        .onChange(of: filterIntensity) { applyProcessing() }
                }

                // tap an emoji to add it as a sticker layer
                HStack {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(emoji) {
                            stickers.append(Sticker(emoji: emoji))
                        }
                        .font(.largeTitle)
                    }
                }

                HStack {
                    Button("Change Filter") { showingFilters = true }
                    Spacer()
                    Button("Undo Sticker") {
                        if !stickers.isEmpty { stickers.removeLast() }
                    }
                    Spacer()
                    Button("Save") { saveToPhotos() }
                        .buttonStyle(.borderedProminent)
                        .disabled(processedImage == nil)
                }

                Text(saveMessage)
                    .foregroundColor(.secondary)

                // shown only if the user said "Don't Allow"
                if permissionDenied {
                    Button("Open Settings to allow saving") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            
                Spacer()
            }
            .padding([.horizontal, .bottom])
            .navigationTitle("Sticker Filter")
            .navigationBarTitleDisplayMode(.inline)   // small title takes less room
            .confirmationDialog("Select a filter", isPresented: $showingFilters) {
                Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                Button("Edges") { setFilter(CIFilter.edges()) }
                Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                Button("Vignette") { setFilter(CIFilter.vignette()) }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    // read the picked photo and give it to the filter
    func loadImage() {
        Task {
            guard let data = try? await selectedItem?.loadTransferable(type: Data.self),
                  let inputImage = UIImage(data: data) else { return }
            // redraw the photo upright first, so it does not turn 90 degrees
            // (also shrink it to at most 1200 points wide, big photos can crash the app)
            let scale = min(1, 1200 / max(inputImage.size.width, inputImage.size.height))
            let newSize = CGSize(width: inputImage.size.width * scale, height: inputImage.size.height * scale)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let upright = UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
                inputImage.draw(in: CGRect(origin: .zero, size: newSize))
            }
            currentFilter.setValue(CIImage(image: upright), forKey: kCIInputImageKey)
            applyProcessing()
        }
    }

    // run the filter and keep the result as a UIImage
    func applyProcessing() {
        let keys = currentFilter.inputKeys
        let amount = max(filterIntensity, 0.02)
        if keys.contains(kCIInputIntensityKey) { currentFilter.setValue(amount, forKey: kCIInputIntensityKey) }
        if keys.contains(kCIInputRadiusKey) { currentFilter.setValue(amount * 200, forKey: kCIInputRadiusKey) }
        if keys.contains(kCIInputScaleKey) { currentFilter.setValue(amount * 200, forKey: kCIInputScaleKey) }

        guard let output = currentFilter.outputImage,
              let cgImage = context.createCGImage(output, from: output.extent) else { return }
        processedImage = UIImage(cgImage: cgImage)
    }

    // switch filter, keeping the same photo
    func setFilter(_ filter: CIFilter) {
        let oldInput = currentFilter.value(forKey: kCIInputImageKey)
        currentFilter = filter
        currentFilter.setValue(oldInput, forKey: kCIInputImageKey)
        applyProcessing()
    }

    // draw photo + stickers into one picture and save it to the Photos app
    @MainActor func saveToPhotos() {
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = 2
        guard let image = renderer.uiImage else { return }

        Task {
            // asks the user the first time, then remembers the answer
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                permissionDenied = true
                saveMessage = "Saving is not allowed ❌"
                return
            }
            permissionDenied = false
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }
                saveMessage = "Saved to Photos ✅"
            } catch {
                saveMessage = "Could not save"
            }
        }
    }
}

#Preview {
    StickerPage()
}
