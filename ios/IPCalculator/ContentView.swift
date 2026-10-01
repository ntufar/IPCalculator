import SwiftUI

/// iOS port of Android `MainActivity`: CIDR input via native wheel rollers
/// plus subnet result cards. Tap any result card to copy its value.
struct ContentView: View {
    @AppStorage("dark_mode") private var darkMode = false

    @State private var octet1 = 192
    @State private var octet2 = 168
    @State private var octet3 = 0
    @State private var octet4 = 0
    @State private var prefix = 16
    @State private var showCopiedToast = false

    private var cidrString: String {
        "\(octet1).\(octet2).\(octet3).\(octet4)/\(prefix)"
    }

    private var result: Result<IPv4, Error> {
        Result { try IPv4(cidr: cidrString) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    networkCard
                    pickerCard

                    Text("Results")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 12)

                    switch result {
                    case .success(let ipv4):
                        resultCards(ipv4)
                    case .failure(let error):
                        Text(error.localizedDescription)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("IP Calculator")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(darkMode ? "Light Mode" : "Dark Mode") {
                        darkMode.toggle()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showCopiedToast {
                    Text("Copied to clipboard")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(.bottom, 24)
                        .transition(.opacity)
                }
            }
        }
    }

    // MARK: - Cards

    private var networkCard: some View {
        HStack {
            Text("Network")
                .font(.title3.weight(.semibold))
            Spacer()
            Text(cidrString)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding()
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary, lineWidth: 1))
    }

    private var pickerCard: some View {
        CIDRPicker(fields: [
            .init(label: "Octet 1", range: 0...255, value: $octet1),
            .init(label: "Octet 2", range: 0...255, value: $octet2),
            .init(label: "Octet 3", range: 0...255, value: $octet3),
            .init(label: "Octet 4", range: 0...255, value: $octet4),
            .init(label: "Prefix", range: 0...32, value: $prefix),
        ])
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary, lineWidth: 1))
    }

    private func resultCards(_ ipv4: IPv4) -> some View {
        VStack(spacing: 4) {
            ResultCard(title: "Subnet Mask", value: ipv4.netmask, systemImage: "network",
                       onCopy: copyFeedback)
            ResultCard(title: "Number of Hosts", value: "\(ipv4.numberOfHosts)",
                       systemImage: "desktopcomputer", onCopy: copyFeedback)
            ResultCard(title: "Broadcast Address", value: ipv4.broadcastAddress,
                       systemImage: "antenna.radiowaves.left.and.right", onCopy: copyFeedback)
            ResultCard(title: "Wildcard Mask", value: ipv4.wildcardMask,
                       systemImage: "rectangle.on.rectangle", onCopy: copyFeedback)
            ResultCard(title: "Hosts Address Range", value: ipv4.hostAddressRange,
                       systemImage: "arrow.left.and.right", onCopy: copyFeedback)
            ResultCard(title: "Netmask Binary", value: ipv4.netmaskInBinary,
                       systemImage: "binary", onCopy: copyFeedback)
            ResultCard(title: "IP Classification", value: ipv4.classificationSummary,
                       systemImage: "tag", onCopy: copyFeedback)
        }
    }

    private func copyFeedback(_ value: String) {
        UIPasteboard.general.string = value
        withAnimation { showCopiedToast = true }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation { showCopiedToast = false }
        }
    }
}

/// A single tappable result row; mirrors one Android `MaterialCardView`.
/// The value rolls its digits on change and the card glows softly while
/// values are streaming, so the eye catches live recalculation.
private struct ResultCard: View {
    let title: String
    let value: String
    let systemImage: String
    let onCopy: (String) -> Void

    @State private var changed = false

    private var cardBackground: Color {
        changed ? .accentColor.opacity(0.14) : Color(.quaternarySystemFill).opacity(0.4)
    }

    var body: some View {
        Button { onCopy(value) } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(value)
                        .font(.body.weight(.bold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: value)
                }
                Spacer()
            }
            .padding()
            .background(cardBackground, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(.quaternary, lineWidth: 1))
            .animation(.easeInOut(duration: 0.25), value: changed)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Tap to copy")
        // Stays lit while values keep changing; fades shortly after they stop.
        .task(id: value) {
            changed = true
            try? await Task.sleep(for: .milliseconds(350))
            if !Task.isCancelled { changed = false }
        }
    }
}

#Preview {
    ContentView()
}
