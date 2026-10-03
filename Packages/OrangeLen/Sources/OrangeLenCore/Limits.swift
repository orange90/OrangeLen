import Foundation
public struct PreviewLimits: Sendable {
    public var fileBytes = 5 * 1024 * 1024
    public var directoryBatch = 500
    public var directoryInitial = 2000
    public var tableRows = 5000
    public var highlightUTF16 = 250000
    public var directoryScanItems = 20000
    public var directorySeconds: Double = 3
    public var tableColumns = 256
    public var structureDepth = 64
    public var structureNodes = 20000
    public var containerBytes = 64 * 1024 * 1024
    public var archiveEntries = 5000
    public var archiveEntryBytes = 5 * 1024 * 1024
    public var archiveExpandedBytes = 64 * 1024 * 1024
    public var archiveRatio = 100
    public var databaseRows = 500
    public var databaseSeconds: Double = 2
    public var notebookCells = 1000
    public init() {}
}
