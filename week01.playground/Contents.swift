// my little emoji art stored as a list of "rows"
let emojis = ["🌸", "🌿", "🍀", "🌺", "⭐️"]

// how wide the shapes are
let size = 5
// which emoji to use for the frame
let frameEmoji = "✨"

// building a string by repeating one emoji
func makeLine(of symbol: String, count: Int) -> String {
    var result = ""
    if count <= 0 {
        return result
    }
    for _ in 1...count {
        result += symbol
    }
    return result
}

// printing a heading with empty lines around it
func title(_ text: String) {
    print("")
    print(text)
    print("")
}

// triangle that grows one emoji at a time
func triangle(list: [String], size: Int) {
    // stop early if there is nothing to draw
    if list.isEmpty || size <= 0 {
        return
    }
    // which emoji comes next
    var position = 0

    for row in 1...size {
        var text = ""
        for _ in 1...row {
            // wrap back to the first emoji if we run out
            text += list[position % list.count]
            position += 1
        }
        print(text)
    }
}

// rhombus, two triangles stacked together
func rhombus(list: [String], size: Int) {
    if list.isEmpty || size <= 0 {
        return
    }
    var position = 0

    for row in 0..<(size * 2 - 1) {
        // how far this row is from the middle row
        let distance = abs(row - (size - 1))

        // odd widths: 1, 3, 5, 7, 9 ... so there is always a true centre
        let width = (size - distance) * 2 - 1

        // two spaces per step, because an emoji is about two characters wide
        var text = makeLine(of: "  ", count: distance)

        for _ in 0..<width {
            text += list[position % list.count]
            position += 1
        }
        print(text)
    }
}

// hollow box with a frame
func box(size: Int, frame: String) {
    if size <= 0 {
        return
    }
    for row in 0..<size {
        var text = ""
        for column in 0..<size {
            // am i on any edge?
            let isEdge = row == 0 || row == size - 1 || column == 0 || column == size - 1
            if isEdge {
                text += frame
            } else {
                text += "  " // empty inside, two spaces again
            }
        }
        print(text)
    }
}

title("triangle")
triangle(list: emojis, size: size)

title("rhombus")
rhombus(list: emojis, size: size)

title("box")
box(size: size, frame: frameEmoji)
