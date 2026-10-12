import AppKit
import SceneKit
import Metal
import OrangeLenCore

private final class MeshCanvas: NSImageView { override var intrinsicContentSize: NSSize { NSSize(width:NSView.noIntrinsicMetric,height:NSView.noIntrinsicMetric) } }

@MainActor final class MeshPreview: NSView {
    let scene = SCNScene(), camera = SCNNode(), renderer: SCNRenderer
    let canvas: NSImageView = MeshCanvas(), label = NSTextField(labelWithString: "")
    var yaw: Float = 0.5, pitch: Float = 0.3, distance: Float = 3
    init(_ document: MeshDocument) {
        renderer = SCNRenderer(device:MTLCreateSystemDefaultDevice(),options:nil)
        super.init(frame:.zero)
        let model = SCNNode(); scene.rootNode.addChildNode(model)
        var minPoint = SIMD3<Float>(repeating:.greatestFiniteMagnitude), maxPoint = SIMD3<Float>(repeating:-Float.greatestFiniteMagnitude)
        for part in document.parts {
            let vertices = part.vertices.map {SCNVector3($0.x,$0.y,$0.z)}
            let source = SCNGeometrySource(vertices:vertices)
            let indices = part.indices.withUnsafeBytes {Data($0)}
            let element = SCNGeometryElement(data:indices,primitiveType:.triangles,primitiveCount:part.indices.count / 3,bytesPerIndex:4)
            let geometry = SCNGeometry(sources:[source],elements:[element])
            let material = SCNMaterial(); material.diffuse.contents = NSColor(red:CGFloat(part.color.x),green:CGFloat(part.color.y),blue:CGFloat(part.color.z),alpha:CGFloat(part.color.w)); material.isDoubleSided = true; material.lightingModel = .lambert; geometry.materials = [material]
            let node = SCNNode(geometry:geometry); node.simdTransform = part.transform; model.addChildNode(node)
            for v in part.vertices { let p = part.transform * SIMD4<Float>(v.x,v.y,v.z,1); guard p.w.isFinite, p.w != 0 else { continue }; let value = SIMD3<Float>(p.x,p.y,p.z) / p.w; minPoint = simd_min(minPoint,value); maxPoint = simd_max(maxPoint,value) }
        }
        let center = (minPoint + maxPoint) * 0.5, span = simd_length(maxPoint - minPoint)
        let scale: Float = span.isFinite && span > 0 ? 2 / span : 1
        model.simdScale = .init(repeating:scale); model.simdPosition = -center * scale
        camera.camera = SCNCamera(); camera.camera?.zNear = 0.01; camera.camera?.zFar = 100; scene.rootNode.addChildNode(camera)
        let ambient = SCNNode(); ambient.light = SCNLight(); ambient.light?.type = .ambient; ambient.light?.intensity = 500; scene.rootNode.addChildNode(ambient)
        let light = SCNNode(); light.light = SCNLight(); light.light?.type = .omni; light.light?.intensity = 1000; light.position = .init(3,4,5); scene.rootNode.addChildNode(light)
        scene.background.contents = NSColor.controlBackgroundColor; renderer.scene = scene; renderer.pointOfView = camera
        let bar = NSStackView(); bar.spacing = 6
        for (title,tag) in [("←",0),("→",1),("↑",2),("↓",3),("−",4),("+",5),(L10n.text("适合窗口"),6)] { let b = NSButton(title:title,target:self,action:#selector(rotate(_:))); b.tag = tag; bar.addArrangedSubview(b) }
        label.lineBreakMode = .byWordWrapping; label.preferredMaxLayoutWidth = 240; label.setContentCompressionResistancePriority(.defaultLow,for:.horizontal)
        label.stringValue = "\(document.triangles) triangles · " + document.notice; label.maximumNumberOfLines = 2; label.font = .systemFont(ofSize:11); label.textColor = .secondaryLabelColor
        bar.addArrangedSubview(label); canvas.imageScaling = .scaleProportionallyUpOrDown; canvas.setAccessibilityLabel("3D mesh · " + label.stringValue)
        for child in [bar,canvas] { addSubview(child); child.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([bar.leadingAnchor.constraint(equalTo:leadingAnchor,constant:8),bar.trailingAnchor.constraint(equalTo:trailingAnchor,constant:-8),bar.topAnchor.constraint(equalTo:topAnchor,constant:8),canvas.topAnchor.constraint(equalTo:bar.bottomAnchor,constant:8),canvas.leadingAnchor.constraint(equalTo:leadingAnchor),canvas.trailingAnchor.constraint(equalTo:trailingAnchor),canvas.bottomAnchor.constraint(equalTo:bottomAnchor)])
        redraw()
    }
    required init?(coder:NSCoder) { fatalError("init(coder:)") }
    @objc func rotate(_ sender: NSButton) {
        switch sender.tag { case 0: yaw -= 0.3; case 1: yaw += 0.3; case 2: pitch = min(1.4,pitch + 0.2); case 3: pitch = max(-1.4,pitch - 0.2); case 4: distance = min(20,distance * 1.25); case 5: distance = max(1,distance / 1.25); default: yaw = 0.5; pitch = 0.3; distance = 3 }
        redraw()
    }
    func cancel() { renderer.scene = nil; renderer.pointOfView = nil; canvas.image = nil; scene.rootNode.childNodes.forEach { $0.removeFromParentNode() } }
    func redraw() { camera.simdPosition = SIMD3<Float>(sin(yaw) * cos(pitch),sin(pitch),cos(yaw) * cos(pitch)) * distance; camera.look(at:SCNVector3Zero); canvas.image = renderer.snapshot(atTime:0,with:NSSize(width:1200,height:900),antialiasingMode:.multisampling4X) }
}
