import SwiftUI
import AppKit
import myPasteCore

public struct CardView: View {
    public let item: ClipboardItem
    public let onSelect: () -> Void

    public init(item: ClipboardItem, onSelect: @escaping () -> Void) {
        self.item = item; self.onSelect = onSelect
    }

    private var accent: Color {
        switch item.kind {
        case .text:  return Color(red: 0.30, green: 0.55, blue: 1.00)
        case .image: return Color(red: 0.78, green: 0.36, blue: 0.98)
        }
    }

    private var tagLabel: String {
        switch item.kind {
        case .text:  return "TEXT"
        case .image: return "IMAGE"
        }
    }

    public var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(tagLabel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(accent, in: Capsule())
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)

                Group {
                    switch item.payload {
                    case .text(let s):
                        Text(s)
                            .font(.system(size: 13))
                            .lineLimit(8)
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.primary)
                    case .imageRef(let url):
                        if let nsImage = NSImage(contentsOf: url) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Text("⚠ image missing")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.horizontal, 12)
                .padding(.top, 8)

                Text(item.sourceApp ?? "—")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }
            .frame(width: 200, height: 220, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(accent.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
