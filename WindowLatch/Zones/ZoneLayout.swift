struct ZoneLayout: Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let zones: [Zone]
}
