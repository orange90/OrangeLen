import AppKit
import OrangeLenCore

private final class OverviewSurface: NSView {
    var card = false
    var outlined = false
    override var isFlipped: Bool { true }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); needsDisplay = true }
    override func draw(_ dirtyRect: NSRect) {
        (card && !outlined ? NSColor(calibratedWhite: effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? 0.16 : 0.96, alpha: 1) : NSColor.textBackgroundColor).setFill()
        if card {
            let shape = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 10, yRadius: 10)
            shape.fill()
            if outlined { NSColor.separatorColor.setStroke(); shape.lineWidth = 0.5; shape.stroke() }
        }
        else { bounds.fill() }
    }
}

private final class FolderCategoryBar: NSView {
    var values: [(FolderFileKind, Int)] = [] { didSet { needsDisplay = true } }
    static func color(_ kind: FolderFileKind) -> NSColor {
        switch kind {
        case .documents: return .systemBlue
        case .code: return .systemPurple
        case .data: return .systemTeal
        case .images: return .systemOrange
        case .media: return .systemPink
        case .other: return .systemGray
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6).addClip()
        NSColor.quaternaryLabelColor.setFill(); bounds.fill()
        let total = values.reduce(0) { $0 + $1.1 }
        guard total > 0 else { return }
        var x: CGFloat = 0
        for (kind, count) in values {
            let width = bounds.width * CGFloat(count) / CGFloat(total)
            Self.color(kind).withAlphaComponent(0.75).setFill()
            NSRect(x: x, y: 0, width: width, height: bounds.height).fill(); x += width
        }
    }
}

/// Native, scrollable folder landing page; summary updates never rebuild document content.
final class FolderOverviewView: NSView {
    let scroll = NSScrollView()
    let title = NSTextField(labelWithString: "")
    let path = NSTextField(labelWithString: "")
    let sizeLabel = NSTextField(labelWithString: L10n.text("已统计大小"))
    let countLabel = NSTextField(labelWithString: L10n.text("已发现项目"))
    let size = NSTextField(labelWithString: "—")
    let count = NSTextField(labelWithString: "—")
    let breakdown = NSTextField(labelWithString: "—")
    let progress = NSTextField(wrappingLabelWithString: L10n.text("正在统计…"))
    let scanButton = NSButton(title: L10n.text("停止统计"), target: nil, action: nil)
    let readmeTitle = NSTextField(labelWithString: L10n.text("README 预览"))
    let readmeHeadingText = NSTextField(labelWithString: "")
    let readmeText = NSTextField(wrappingLabelWithString: "")
    let readmeName = NSTextField(labelWithString: "")
    let openReadme = NSButton(title: L10n.text("打开完整文件 ↗"), target: nil, action: nil)
    let location = NSTextField(wrappingLabelWithString: "")
    let scope = NSTextField(wrappingLabelWithString: L10n.text("当前文件夹及全部子文件夹"))
    let readmeSection = NSStackView()
    private let content = NSStackView()
    private let metrics = NSStackView()
    private let legend = NSStackView()
    private let categoryBar = FolderCategoryBar()
    private var readmeURL: URL?
    var onReadme: ((URL) -> Void)?
    var onScan: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        let surface = OverviewSurface()
        scroll.documentView = surface; scroll.hasVerticalScroller = true; scroll.autohidesScrollers = true
        scroll.drawsBackground = false; scroll.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)
        NSLayoutConstraint.activate([scroll.leadingAnchor.constraint(equalTo: leadingAnchor), scroll.trailingAnchor.constraint(equalTo: trailingAnchor), scroll.topAnchor.constraint(equalTo: topAnchor), scroll.bottomAnchor.constraint(equalTo: bottomAnchor)])
        surface.translatesAutoresizingMaskIntoConstraints = false
        content.orientation = .vertical; content.alignment = .leading; content.spacing = 20
        content.translatesAutoresizingMaskIntoConstraints = false; surface.addSubview(content)
        NSLayoutConstraint.activate([surface.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor), content.leadingAnchor.constraint(equalTo: surface.leadingAnchor, constant: 30), content.trailingAnchor.constraint(equalTo: surface.trailingAnchor, constant: -30), content.topAnchor.constraint(equalTo: surface.topAnchor, constant: 20), content.bottomAnchor.constraint(equalTo: surface.bottomAnchor, constant: -24)])

        title.font = .systemFont(ofSize: 26, weight: .semibold); title.lineBreakMode = .byTruncatingMiddle; title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        path.font = .systemFont(ofSize: 12); path.textColor = .secondaryLabelColor; path.lineBreakMode = .byTruncatingMiddle; path.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let icon = NSImageView(image: NSImage(systemSymbolName: "folder.fill", accessibilityDescription: L10n.text("文件夹"))!)
        icon.contentTintColor = .systemBlue; icon.symbolConfiguration = .init(pointSize: 42, weight: .regular)
        icon.widthAnchor.constraint(equalToConstant: 52).isActive = true
        let heading = NSStackView(views: [title, path]); heading.orientation = .vertical; heading.alignment = .leading; heading.spacing = 5
        heading.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let header = NSStackView(views: [icon, heading]); header.spacing = 16; header.alignment = .centerY
        add(header)

        metrics.orientation = .horizontal; metrics.distribution = .fillEqually; metrics.spacing = 14
        for (label, value) in [(sizeLabel, size), (countLabel, count), (NSTextField(labelWithString: L10n.text("文件 / 文件夹")), breakdown)] {
            label.font = .systemFont(ofSize: 12); label.textColor = .secondaryLabelColor
            value.font = .monospacedDigitSystemFont(ofSize: 27, weight: .semibold)
            value.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let pair = NSStackView(views: [label, value]); pair.orientation = .vertical; pair.spacing = 8
            metrics.addArrangedSubview(pair)
        }
        let metricCard = card(metrics, padding: 20); add(metricCard)
        let stateRow = NSStackView(views: [progress, scanButton]); stateRow.spacing = 12; stateRow.alignment = .centerY
        progress.font = .systemFont(ofSize: 12); progress.textColor = .secondaryLabelColor
        progress.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        scanButton.isBordered = false; scanButton.font = .systemFont(ofSize: 12); scanButton.contentTintColor = .linkColor
        scanButton.target = self; scanButton.action = #selector(scan)
        add(stateRow); content.setCustomSpacing(10, after: metricCard)

        let categories = NSStackView(); categories.orientation = .vertical; categories.alignment = .leading; categories.spacing = 14
        let categoryHeading = NSTextField(labelWithString: L10n.text("内容分类")); categoryHeading.font = .systemFont(ofSize: 15, weight: .semibold)
        let hint = NSTextField(labelWithString: L10n.text("按文件数量")); hint.font = .systemFont(ofSize: 12); hint.textColor = .secondaryLabelColor
        let headingRow = NSStackView(views: [categoryHeading, NSView(), hint]); headingRow.distribution = .fill
        for v in [headingRow, categoryBar, legend] { categories.addArrangedSubview(v); v.widthAnchor.constraint(equalTo: categories.widthAnchor).isActive = true }
        categoryBar.heightAnchor.constraint(equalToConstant: 12).isActive = true
        legend.orientation = .horizontal; legend.distribution = .fillEqually; legend.spacing = 12
        add(categories)

        readmeSection.orientation = .vertical; readmeSection.alignment = .leading; readmeSection.spacing = 12
        readmeTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        openReadme.isBordered = false; openReadme.contentTintColor = .linkColor; openReadme.font = .systemFont(ofSize: 12)
        openReadme.target = self; openReadme.action = #selector(openDocument)
        let readmeHeading = NSStackView(views: [readmeTitle, NSView(), openReadme])
        readmeText.font = .systemFont(ofSize: 14); readmeText.isSelectable = true; readmeText.maximumNumberOfLines = 4; readmeText.lineBreakMode = .byTruncatingTail
        readmeName.font = .systemFont(ofSize: 12); readmeName.textColor = .secondaryLabelColor
        readmeHeadingText.font = .systemFont(ofSize: 16, weight: .semibold); readmeHeadingText.lineBreakMode = .byTruncatingTail
        let readmeBody = NSStackView(views: [readmeHeadingText, readmeText, readmeName]); readmeBody.orientation = .vertical; readmeBody.alignment = .leading; readmeBody.spacing = 12
        let readmeCard = card(readmeBody, padding: 16)
        (readmeCard as? OverviewSurface)?.outlined = true
        readmeText.widthAnchor.constraint(equalTo: readmeBody.widthAnchor).isActive = true
        for v in [readmeHeading, readmeCard] { readmeSection.addArrangedSubview(v); v.widthAnchor.constraint(equalTo: readmeSection.widthAnchor).isActive = true }
        add(readmeSection); readmeSection.isHidden = true

        let info = NSStackView(); info.orientation = .vertical; info.alignment = .leading; info.spacing = 12
        let infoTitle = NSTextField(labelWithString: L10n.text("文件夹信息")); infoTitle.font = .systemFont(ofSize: 15, weight: .semibold)
        info.addArrangedSubview(infoTitle)
        for (name, value) in [(L10n.text("位置"), location), (L10n.text("统计范围"), scope)] {
            let separator = NSBox(); separator.boxType = .separator; info.addArrangedSubview(separator); separator.widthAnchor.constraint(equalTo: info.widthAnchor).isActive = true
            let key = NSTextField(labelWithString: name); key.font = .systemFont(ofSize: 12); key.textColor = .secondaryLabelColor; key.widthAnchor.constraint(equalToConstant: 72).isActive = true
            value.font = .systemFont(ofSize: 12); value.isSelectable = true; value.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let row = NSStackView(views: [key, value]); row.alignment = .firstBaseline; row.spacing = 16
            info.addArrangedSubview(row); row.widthAnchor.constraint(equalTo: info.widthAnchor).isActive = true
        }
        add(info)
        let footnote = NSTextField(wrappingLabelWithString: L10n.text("ⓘ  大小为逻辑文件大小，不跟随符号链接"))
        footnote.font = .systemFont(ofSize: 11); footnote.textColor = .secondaryLabelColor; add(footnote)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    private func add(_ view: NSView) { content.addArrangedSubview(view); view.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true }
    private func card(_ child: NSView, padding: CGFloat) -> NSView {
        let view = OverviewSurface(); view.card = true; child.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(child)
        NSLayoutConstraint.activate([child.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding), child.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding), child.topAnchor.constraint(equalTo: view.topAnchor, constant: padding), child.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -padding)])
        return view
    }
    override func layout() {
        super.layout()
        let narrow = bounds.width < 510
        let orientation: NSUserInterfaceLayoutOrientation = narrow ? .vertical : .horizontal
        if metrics.orientation != orientation { metrics.orientation = orientation }
        let legendOrientation: NSUserInterfaceLayoutOrientation = bounds.width < 640 ? .vertical : .horizontal
        if legend.orientation != legendOrientation { legend.orientation = legendOrientation }
    }
    func configure(_ root: URL) {
        title.stringValue = root.lastPathComponent; path.stringValue = root.deletingLastPathComponent().path; path.toolTip = root.path
        location.stringValue = root.deletingLastPathComponent().path
        scope.stringValue = L10n.text("当前文件夹及全部子文件夹")
        size.stringValue = "—"; count.stringValue = "—"; breakdown.stringValue = "—"
        readmeURL = nil; readmeSection.isHidden = true; openReadme.isHidden = false
        update(nil, scanning: true, message: L10n.text("正在统计…"))
        scroll.contentView.scroll(to: .zero)
    }
    func showReadme(_ readme: FolderReadme?) {
        openReadme.isHidden = false
        readmeURL = readme?.url; readmeSection.isHidden = readme == nil
        let lines = (readme?.excerpt ?? "").components(separatedBy: "\n")
        readmeHeadingText.stringValue = lines.first ?? ""; readmeHeadingText.isHidden = readme == nil
        let bodyLines = lines.dropFirst().filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let body = bodyLines.prefix(3).joined(separator: "\n")
        readmeText.stringValue = String(body.prefix(240)) + (bodyLines.count > 3 || body.count > 240 ? "…" : ""); readmeName.stringValue = readme?.url.lastPathComponent ?? ""
    }
    func readmeFailed() {
        readmeSection.isHidden = false; openReadme.isHidden = true; readmeHeadingText.isHidden = true
        readmeText.stringValue = L10n.text("暂时无法读取 README，可从左侧文件列表重试。"); readmeName.stringValue = ""
    }
    func update(_ summary: FolderSummary?, scanning: Bool, message: String) {
        scanButton.title = scanning ? L10n.text("停止统计") : L10n.text("重新统计")
        sizeLabel.stringValue = summary?.complete == true && !scanning ? L10n.text("总大小") : L10n.text("已统计大小")
        countLabel.stringValue = summary?.complete == true && !scanning ? L10n.text("包含项目") : L10n.text("已发现项目")
        progress.stringValue = message
        progress.textColor = summary?.complete == false && !scanning ? .systemOrange : .secondaryLabelColor
        if let summary {
            size.stringValue = ByteCountFormatter.string(fromByteCount: summary.bytes, countStyle: .file)
            count.stringValue = (summary.files + summary.folders + summary.links).formatted()
            breakdown.stringValue = "\(summary.files.formatted()) / \(summary.folders.formatted())"
            scope.stringValue = L10n.text("当前文件夹及全部子文件夹") + (summary.links > 0 ? L10n.text(" · \(summary.links) 个符号链接（不跟随）") : "")
        }
        let values = FolderFileKind.allCases.compactMap { kind -> (FolderFileKind, Int)? in
            let n = summary?.categories[kind] ?? 0; return n > 0 ? (kind, n) : nil
        }
        categoryBar.values = values
        for child in legend.arrangedSubviews { legend.removeArrangedSubview(child); child.removeFromSuperview() }
        if values.isEmpty {
            let empty = NSTextField(labelWithString: scanning ? L10n.text("正在识别文件类型…") : L10n.text("没有可统计的文件"))
            empty.font = .systemFont(ofSize: 12); empty.textColor = .secondaryLabelColor; legend.addArrangedSubview(empty)
        }
        for (kind, number) in values {
            let label = NSTextField(labelWithString: "●  " + kind.localizedName)
            label.font = .systemFont(ofSize: 12)
            let legendText = NSMutableAttributedString(string: "●  " + kind.localizedName, attributes: [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.secondaryLabelColor])
            legendText.addAttribute(.foregroundColor, value: FolderCategoryBar.color(kind), range: NSRange(location: 0, length: 1))
            label.attributedStringValue = legendText
            let value = NSTextField(labelWithString: number.formatted()); value.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
            let pair = NSStackView(views: [label, value]); pair.orientation = .vertical; pair.alignment = .leading; pair.spacing = 5
            legend.addArrangedSubview(pair)
        }
    }
    @objc private func scan() { onScan?() }
    @objc private func openDocument() { if let readmeURL { onReadme?(readmeURL) } }
}
