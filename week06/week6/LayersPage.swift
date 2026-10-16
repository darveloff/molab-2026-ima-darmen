import SwiftUI

// page 5: stack layers on top of each other, saved as JSON
// same idea as 06-ImageEditDemoJSON: a Codable model, saved to a JSON file,
// and a ZStack that draws every item on top of the one before.

// one layer: one symbol with a color and a size
struct LayerModel: Identifiable, Codable {
    var id = UUID()
    var systemName: String = "star.fill"
    var colorName: String = "red"
    var size: Double = 150
}

// the list of layers. @Observable redraws the screen when it changes
@Observable
class LayerDocument {
    var layers: [LayerModel] = []

    // file name to store the JSON in the documents directory
    let saveFileName = "layers.json"

    init() {
        load()
        // start with a few sample layers the first time
        if layers.isEmpty {
            layers = [
                LayerModel(systemName: "circle.fill", colorName: "yellow", size: 260),
                LayerModel(systemName: "star.fill", colorName: "orange", size: 160),
                LayerModel(systemName: "heart.fill", colorName: "red", size: 70)
            ]
            save()
        }
    }

    func add(_ layer: LayerModel) {
        layers.append(layer)   // last item is drawn on top
        save()
    }

    func delete(id: UUID) {
        layers.removeAll { $0.id == id }
        save()
    }

    func save() {
        do {
            let url = try documentURL()
            let data = try JSONEncoder().encode(layers)
            try data.write(to: url)
        } catch {
            print("LayerDocument save error \(error)")
        }
    }

    func load() {
        do {
            let url = try documentURL()
            let data = try Data(contentsOf: url)
            layers = try JSONDecoder().decode([LayerModel].self, from: data)
        } catch {
            print("LayerDocument load error \(error)")
        }
    }

    func documentURL() throws -> URL {
        let dir = try FileManager.default.url(for: .documentDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: false)
        return dir.appendingPathComponent(saveFileName)
    }
}

// turn the saved color name into a real Color
func layerColor(_ name: String) -> Color {
    switch name {
    case "red": return .red
    case "orange": return .orange
    case "yellow": return .yellow
    case "green": return .green
    case "blue": return .blue
    case "purple": return .purple
    default: return .gray
    }
}

struct LayersPage: View {
    @State private var document = LayerDocument()

    // choices for the new layer
    let symbols = ["star.fill", "heart.fill", "circle.fill", "moon.fill", "bolt.fill", "leaf.fill"]
    let colors = ["red", "orange", "yellow", "green", "blue", "purple"]

    @State private var symbol = "star.fill"
    @State private var colorName = "blue"
    @State private var size = 120.0

    var body: some View {
        VStack(spacing: 12) {
            Text("Layers")
                .font(.title)

            // all layers drawn on top of each other
            ZStack {
                Color(.systemGray6)
                ForEach(document.layers) { layer in
                    Image(systemName: layer.systemName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(layerColor(layer.colorName))
                        .frame(width: layer.size, height: layer.size)
                }
            }
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)

            // pick a new layer
            Picker("Symbol", selection: $symbol) {
                ForEach(symbols, id: \.self) { Image(systemName: $0).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            Picker("Color", selection: $colorName) {
                ForEach(colors, id: \.self) { Text($0).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            HStack {
                Text("Size")
                Slider(value: $size, in: 40...280)
            }
            .padding(.horizontal)

            Button("Add Layer") {
                document.add(LayerModel(systemName: symbol, colorName: colorName, size: size))
            }
            .buttonStyle(.borderedProminent)

            // list of layers: swipe to delete
            List {
                // newest on top, like the original demo
                ForEach(document.layers.reversed()) { layer in
                    HStack {
                        Image(systemName: layer.systemName)
                            .foregroundColor(layerColor(layer.colorName))
                        Text("\(layer.systemName) – \(Int(layer.size))")
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            document.delete(id: layer.id)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
    }
}

#Preview {
    LayersPage()
}
