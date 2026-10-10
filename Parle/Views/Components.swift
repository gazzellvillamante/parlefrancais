import SwiftUI

extension Color {
    static func score(_ value: Double) -> Color {
        switch value {
        case 0.85...: .green
        case 0.6..<0.85: .orange
        default: .red
        }
    }

    static func score(_ value: Int) -> Color { score(Double(value) / 100) }
}

/// Lays out children left to right, wrapping onto new lines.
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(width: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                                      proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width && !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

/// Circular score indicator.
struct ScoreRing: View {
    let score: Int
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            Circle().stroke(Color.secondary.opacity(0.2), lineWidth: size * 0.1)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(Color.score(score), style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(score)")
                .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: size, height: size)
        .animation(.spring(duration: 0.6), value: score)
    }
}

/// Big record button that pulses with the microphone level.
struct MicButton: View {
    let isRecording: Bool
    let level: Float
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill((isRecording ? Color.red : Color.accentColor).opacity(0.18))
                    .frame(width: 104, height: 104)
                    .scaleEffect(isRecording ? 1 + CGFloat(level) * 0.45 : 1)
                    .animation(.easeOut(duration: 0.12), value: level)
                Circle()
                    .fill(isRecording ? Color.red : Color.accentColor)
                    .frame(width: 80, height: 80)
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isRecording ? "Stop recording" : "Start speaking")
        .sensoryFeedback(.impact, trigger: isRecording)
    }
}

struct SpeakButton: View {
    let text: String
    var slow = false
    var label: String? = nil

    var body: some View {
        Button {
            Speaker.shared.speak(text, slow: slow)
        } label: {
            if let label {
                Label(label, systemImage: slow ? "tortoise.fill" : "speaker.wave.2.fill")
            } else {
                Image(systemName: slow ? "tortoise.fill" : "speaker.wave.2.fill")
            }
        }
        .accessibilityLabel(slow ? "Listen slowly" : "Listen")
    }
}
