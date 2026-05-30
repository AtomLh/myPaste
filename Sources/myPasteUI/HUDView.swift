import SwiftUI
import myPasteCore

public struct HUDView: View {
    @State private var query: String = ""
    public let viewModel: HUDViewModel
    public let onPaste: (ClipboardItem) -> Void
    public let onDismiss: () -> Void

    public init(viewModel: HUDViewModel,
                onPaste: @escaping (ClipboardItem) -> Void,
                onDismiss: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onPaste = onPaste
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 13))
                    TextField("Search", text: $query)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .onChange(of: query) { _, new in
                            viewModel.setQuery(new)
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(width: 320)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                Spacer()
            }
            .padding(.top, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if viewModel.visibleItems.isEmpty {
                        Text("No clipboard history yet")
                            .foregroundStyle(.secondary)
                            .frame(width: 240, height: 220)
                    } else {
                        ForEach(viewModel.visibleItems) { item in
                            CardView(item: item, onSelect: { onPaste(item) })
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)

                VStack(spacing: 0) {
                    Spacer()
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [Color.white.opacity(0.0),
                                     Color.white.opacity(0.35)],
                            startPoint: .top,
                            endPoint: .bottom))
                        .frame(height: 80)
                        .blur(radius: 16)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .allowsHitTesting(false)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 6)
        .padding(8)
    }
}
