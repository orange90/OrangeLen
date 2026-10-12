import AppKit
import OrangeLenCore

@MainActor final class DiagramPreview: NSView {
    var document: DiagramDocument
    let canvas = ZoomCanvasView(frame:.zero), pages = NSPopUpButton(), info = NSTextField(labelWithString: "")
    init(_ document: DiagramDocument) {
        self.document = document; super.init(frame:.zero)
        pages.addItems(withTitles:document.pages.map(\.title)); pages.target = self; pages.action = #selector(changePage)
        info.lineBreakMode = .byWordWrapping; info.preferredMaxLayoutWidth = 300; info.setContentCompressionResistancePriority(.defaultLow,for:.horizontal)
        pages.widthAnchor.constraint(lessThanOrEqualToConstant:180).isActive = true
        info.stringValue = document.kind + " · " + document.notice; info.maximumNumberOfLines = 2; info.font = .systemFont(ofSize:11); info.textColor = .secondaryLabelColor
        let bar = NSStackView(views:[pages,info]); bar.spacing = 10
        for child in [bar,canvas] { addSubview(child); child.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([bar.leadingAnchor.constraint(equalTo:leadingAnchor,constant:10),bar.trailingAnchor.constraint(equalTo:trailingAnchor,constant:-10),bar.topAnchor.constraint(equalTo:topAnchor,constant:8),canvas.leadingAnchor.constraint(equalTo:leadingAnchor),canvas.trailingAnchor.constraint(equalTo:trailingAnchor),canvas.topAnchor.constraint(equalTo:bar.bottomAnchor,constant:8),canvas.bottomAnchor.constraint(equalTo:bottomAnchor)])
        changePage()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:)") }
    override func viewDidChangeEffectiveAppearance() { super.viewDidChangeEffectiveAppearance(); changePage() }
    @objc func changePage() {
        guard document.pages.indices.contains(pages.indexOfSelectedItem) else { return }
        let page = document.pages[pages.indexOfSelectedItem]
        let minX = page.boxes.map(\.x).min() ?? 0, minY = page.boxes.map(\.y).min() ?? 0
        let maxX = page.boxes.map {$0.x + $0.width}.max() ?? 600, maxY = page.boxes.map {$0.y + $0.height}.max() ?? 400
        let width = max(300,maxX - minX + 60), height = max(200,maxY - minY + 60)
        let scale = min(2,min(3000 / width,3000 / height)), size = NSSize(width:width * scale,height:height * scale)
        let image = NSImage(size:size); image.lockFocusFlipped(true)
        NSColor.controlBackgroundColor.setFill(); NSRect(origin:.zero,size:size).fill()
        let transform = NSAffineTransform(); transform.scale(by:scale); transform.concat()
        func rect(_ box: DiagramDocument.Box) -> NSRect { NSRect(x:box.x - minX + 30,y:box.y - minY + 30,width:box.width,height:box.height) }
        let index = Dictionary(uniqueKeysWithValues:page.boxes.map {($0.id,$0)})
        for edge in page.edges {
            guard let from = index[edge.from], let to = index[edge.to] else { continue }
            let a = rect(from), b = rect(to), p = NSPoint(x:a.midX,y:a.midY), q = NSPoint(x:b.midX,y:b.midY)
            let dx = q.x - p.x, dy = q.y - p.y
            guard abs(dx) + abs(dy) > 0.001 else { continue }
            let startScale = min(a.width / (2 * max(0.001,abs(dx))),a.height / (2 * max(0.001,abs(dy))))
            let endScale = min(b.width / (2 * max(0.001,abs(dx))),b.height / (2 * max(0.001,abs(dy))))
            let start = NSPoint(x:p.x + dx * startScale,y:p.y + dy * startScale), tip = NSPoint(x:q.x - dx * endScale,y:q.y - dy * endScale)
            let line = NSBezierPath(); line.move(to:start); line.line(to:tip); line.lineWidth = 2; NSColor.secondaryLabelColor.setStroke(); line.stroke()
            let angle = atan2(dy,dx)
            let arrow = NSBezierPath(); arrow.move(to:tip); arrow.line(to:NSPoint(x:tip.x - 12 * cos(angle - 0.4),y:tip.y - 12 * sin(angle - 0.4))); arrow.move(to:tip); arrow.line(to:NSPoint(x:tip.x - 12 * cos(angle + 0.4),y:tip.y - 12 * sin(angle + 0.4))); arrow.stroke()
            (String(edge.label.prefix(160)) as NSString).draw(at:NSPoint(x:(p.x + q.x) / 2,y:(p.y + q.y) / 2),withAttributes:[.font:NSFont.systemFont(ofSize:12),.foregroundColor:NSColor.labelColor,.backgroundColor:NSColor.controlBackgroundColor])
        }
        for box in page.boxes {
            let r = rect(box), shape: NSBezierPath
            if box.shape == "ellipse" { shape = NSBezierPath(ovalIn:r) }
            else if box.shape == "diamond" { shape = NSBezierPath(); shape.move(to:.init(x:r.midX,y:r.minY)); shape.line(to:.init(x:r.maxX,y:r.midY)); shape.line(to:.init(x:r.midX,y:r.maxY)); shape.line(to:.init(x:r.minX,y:r.midY)); shape.close() }
            else { shape = NSBezierPath(roundedRect:r,xRadius:8,yRadius:8) }
            let colors: [String:NSColor] = ["1":.systemRed,"2":.systemOrange,"3":.systemYellow,"4":.systemGreen,"5":.systemBlue,"6":.systemPurple]
            var color = colors[box.color] ?? .systemBlue
            if box.color.hasPrefix("#"), box.color.count == 7, let rgb = UInt32(box.color.dropFirst(),radix:16) { color = NSColor(srgbRed:CGFloat((rgb >> 16) & 255) / 255,green:CGFloat((rgb >> 8) & 255) / 255,blue:CGFloat(rgb & 255) / 255,alpha:1) }
            color.withAlphaComponent(box.shape == "group" ? 0.05 : 0.13).setFill(); shape.fill(); color.setStroke(); shape.lineWidth = 1.5; shape.stroke()
            NSGraphicsContext.saveGraphicsState(); NSBezierPath(rect:r.insetBy(dx:8,dy:8)).addClip()
            var text = NSAttributedString(string:String(box.text.prefix(4096)),attributes:[.font:NSFont.systemFont(ofSize:14),.foregroundColor:NSColor.labelColor])
            if ["text","file"].contains(box.shape), let model = try? MarkdownModel.parse(String(box.text.prefix(4096))) { var settings = ReaderSettings(); settings.documentSize = 14; text = TextStyler.attributed(model,markdown:true,settings:settings,width:r.width - 24,highlight:false) }
            text.draw(with:r.insetBy(dx:12,dy:12),options:[.usesLineFragmentOrigin,.usesFontLeading]); NSGraphicsContext.restoreGraphicsState()
        }
        image.unlockFocus(); canvas.image = image
        canvas.setAccessibilityLabel(document.kind + " · " + page.title + " · " + page.boxes.map(\.text).joined(separator:" · "))
    }
}

@MainActor final class ScientificPreview: NSView {
    let table = TableController(), summary = NSTextView()
    init(_ document: ScientificDocument) {
        super.init(frame:.zero)
        summary.isEditable = false; summary.isSelectable = true; summary.font = .monospacedSystemFont(ofSize:12,weight:.regular); summary.string = document.summary; summary.textContainerInset = NSSize(width:12,height:12)
        let scroll = NSScrollView(); scroll.hasVerticalScroller = true; scroll.documentView = summary
        summary.autoresizingMask = [.width]; summary.textContainer?.widthTracksTextView = true
        let source = ([document.columns] + document.rows).map {$0.map {DatabaseDocument.tsvField($0)}.joined(separator:"\t")}.joined(separator:"\n")
        if let data = try? CSVParser.parse(source,separator:9) { table.show(data) }
        for child in [scroll,table.view] { addSubview(child); child.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([scroll.leadingAnchor.constraint(equalTo:leadingAnchor),scroll.trailingAnchor.constraint(equalTo:trailingAnchor),scroll.topAnchor.constraint(equalTo:topAnchor),scroll.heightAnchor.constraint(equalToConstant:180),table.view.leadingAnchor.constraint(equalTo:leadingAnchor),table.view.trailingAnchor.constraint(equalTo:trailingAnchor),table.view.topAnchor.constraint(equalTo:scroll.bottomAnchor),table.view.bottomAnchor.constraint(equalTo:bottomAnchor)])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:)") }
}
