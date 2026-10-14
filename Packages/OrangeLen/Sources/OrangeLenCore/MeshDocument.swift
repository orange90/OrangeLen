import Foundation
import simd

public struct MeshDocument: Sendable {
    public struct Part: Sendable { public var vertices: [SIMD3<Float>], indices: [UInt32], color: SIMD4<Float>, transform: simd_float4x4 }
    public var parts: [Part], notice: String
    public var triangles: Int { parts.reduce(0) {$0 + $1.indices.count / 3} }
    public static func supports(_ url: URL) -> Bool { ["obj","stl","gltf","glb"].contains(url.pathExtension.lowercased()) }
    public static func load(_ url: URL, root: URL?, cancellation: Cancellation) throws -> Self {
        var limits = PreviewLimits(); limits.fileBytes = 25 * 1024 * 1024
        let raw = try AccessBroker.readBytes(url,root:root,limits:limits,cancellation:cancellation)
        return try parse(raw.data,name:url.lastPathComponent,cancellation:cancellation) { name in
            guard let root, ArchiveDocument.safePath(name), let decoded = name.removingPercentEncoding, ArchiveDocument.safePath(decoded) else { throw PreviewError.unsafePath }
            return try AccessBroker.readBytes(url.deletingLastPathComponent().appendingPathComponent(decoded),root:root,limits:limits,cancellation:cancellation).data
        }
    }
    public static func parse(_ data: Data, name: String, cancellation: Cancellation = .init(), resource: (String) throws -> Data = { _ in throw PreviewError.unsafePath }) throws -> Self {
        guard data.count <= 25 * 1024 * 1024 else { throw PreviewError.limit("3D input 25 MiB") }
        let ext = (name as NSString).pathExtension.lowercased()
        if ext == "obj" { return try obj(String(decoding:data,as:UTF8.self),token:cancellation) }
        if ext == "stl" { return try stl(data,token:cancellation) }
        return try gltf(data,binary:ext == "glb",token:cancellation,resource:resource)
    }
    static func validate(_ parts: [Part]) throws {
        for part in parts {
            let m = part.transform
            let columns = [m.columns.0,m.columns.1,m.columns.2,m.columns.3]
            guard columns.allSatisfy({ $0.x.isFinite && $0.y.isFinite && $0.z.isFinite && $0.w.isFinite && abs($0.x) <= 1e9 && abs($0.y) <= 1e9 && abs($0.z) <= 1e9 && abs($0.w) <= 1e9 }), m.columns.0.w == 0, m.columns.1.w == 0, m.columns.2.w == 0, m.columns.3.w == 1 else { throw PreviewError.malformed("3D affine transform") }
            for v in part.vertices { let p = m * SIMD4<Float>(v.x,v.y,v.z,1); guard p.x.isFinite && p.y.isFinite && p.z.isFinite && abs(p.x) <= 1e9 && abs(p.y) <= 1e9 && abs(p.z) <= 1e9 else { throw PreviewError.limit("3D world coordinates") } }
        }
        guard !parts.isEmpty, parts.count <= 2000, parts.reduce(0,{$0 + $1.vertices.count}) <= 200000, parts.reduce(0,{$0 + $1.indices.count}) <= 600000,
              parts.allSatisfy({ p in p.transform.columns.0.x.isFinite && p.transform.columns.1.y.isFinite && p.transform.columns.2.z.isFinite && p.transform.columns.3.w.isFinite && !p.indices.isEmpty && !p.vertices.isEmpty && p.vertices.allSatisfy { v in v.x.isFinite && v.y.isFinite && v.z.isFinite && abs(v.x) < 1e9 && abs(v.y) < 1e9 && abs(v.z) < 1e9 } && p.indices.allSatisfy { Int($0) < p.vertices.count } && p.indices.count % 3 == 0 }) else { throw PreviewError.limit("3D geometry: 200k vertices/triangles") }
    }
    static func obj(_ source: String, token: Cancellation) throws -> Self {
        var vertices: [SIMD3<Float>] = [], indices: [UInt32] = []
        for line in source.split(whereSeparator: { $0.isNewline }) {
            try token.check(); let fields = line.split(whereSeparator: { $0.isWhitespace }); guard let kind = fields.first else { continue }
            if kind == "v" {
                guard fields.count >= 4, let x = Float(fields[1]), let y = Float(fields[2]), let z = Float(fields[3]), vertices.count < 200000 else { throw PreviewError.malformed("OBJ vertex") }
                vertices.append(.init(x,y,z))
            } else if kind == "f" {
                guard fields.count <= 256 else { throw PreviewError.limit("OBJ face") }
                var face: [UInt32] = []
                for field in fields.dropFirst() {
                    guard let first = field.split(separator:"/",omittingEmptySubsequences:false).first, let n = Int(first), n != 0 else { throw PreviewError.malformed("OBJ index") }
                    let index = n < 0 ? vertices.count + n : n - 1
                    guard index >= 0, index < vertices.count else { throw PreviewError.malformed("OBJ index range") }; face.append(UInt32(index))
                }
                if face.count >= 3 { for i in 1..<(face.count - 1) { indices += [face[0],face[i],face[i + 1]] } }
                guard indices.count <= 600000 else { throw PreviewError.limit("OBJ triangles") }
            }
        }
        let parts = [Part(vertices:vertices,indices:indices,color:.init(0.7,0.75,0.9,1),transform:matrix_identity_float4x4)]
        try validate(parts); guard !indices.isEmpty else { throw PreviewError.malformed("OBJ has no faces") }
        return .init(parts:parts,notice:"OBJ polygon mesh · MTL/textures and animation are not loaded")
    }
    static func stl(_ data: Data, token: Cancellation) throws -> Self {
        var vertices: [SIMD3<Float>] = []
        if data.count >= 84 {
            var c = BinaryCursor(data:data,offset:80,token:token); let count = try c.uint(4)
            if count <= 200000 && 84 + Int(count) * 50 == data.count {
                for _ in 0..<count {
                    _ = try c.bytes(12)
                    for _ in 0..<3 { vertices.append(.init(Float(bitPattern:UInt32(try c.uint(4))),Float(bitPattern:UInt32(try c.uint(4))),Float(bitPattern:UInt32(try c.uint(4))))) }
                    _ = try c.bytes(2)
                }
            }
        }
        if vertices.isEmpty {
            for line in String(decoding:data,as:UTF8.self).split(whereSeparator:{$0.isNewline}) {
                try token.check(); let f = line.split(whereSeparator:{$0.isWhitespace})
                if f.first == "vertex" { guard f.count == 4, let x = Float(f[1]), let y = Float(f[2]), let z = Float(f[3]), vertices.count < 200000 else { throw PreviewError.malformed("STL vertex") }; vertices.append(.init(x,y,z)) }
            }
        }
        let parts = [Part(vertices:vertices,indices:vertices.indices.map {UInt32($0)},color:.init(0.7,0.75,0.9,1),transform:matrix_identity_float4x4)]
        try validate(parts); return .init(parts:parts,notice:"STL triangle mesh · solid color")
    }
    static func gltf(_ data: Data, binary: Bool, token: Cancellation, resource: (String) throws -> Data) throws -> Self {
        var json = data, binaryBuffer = Data()
        if binary {
            var c = BinaryCursor(data:data,token:token)
            guard try c.bytes(4) == Data("glTF".utf8), try c.uint(4) == 2, try c.uint(4) == UInt64(data.count) else { throw PreviewError.malformed("GLB v2 header") }
            var chunks = 0
            while c.offset < data.count {
                chunks += 1; guard chunks <= 32 else { throw PreviewError.limit("GLB chunks") }
                let size = try c.length(4,maximum:25 * 1024 * 1024), type = try c.uint(4), value = try c.bytes(size)
                if type == 0x4e4f534a { json = value }; if type == 0x004e4942 { binaryBuffer = value }
            }
        }
        guard json.count <= 5 * 1024 * 1024 else { throw PreviewError.limit("glTF JSON") }
        _ = try JSONParser.parse(String(decoding:json,as:UTF8.self),cancellation:token)
        guard let object = try JSONSerialization.jsonObject(with:json) as? [String:Any], (object["asset"] as? [String:Any])?["version"] as? String == "2.0" else { throw PreviewError.malformed("glTF v2 asset") }
        if let required = object["extensionsRequired"] as? [String], !required.isEmpty { throw PreviewError.malformed("glTF required extensions: " + required.joined(separator:", ")) }
        let specs = object["buffers"] as? [[String:Any]] ?? [], views = object["bufferViews"] as? [[String:Any]] ?? [], accessors = object["accessors"] as? [[String:Any]] ?? []
        guard specs.count <= 64 else { throw PreviewError.limit("glTF buffers") }
        var buffers: [Data] = [], total = 0
        for spec in specs {
            try token.check(); let buffer: Data
            if let uri = spec["uri"] as? String {
                if uri.hasPrefix("data:"), let comma = uri.firstIndex(of:","), uri[..<comma].hasSuffix(";base64"), let value = Data(base64Encoded:String(uri[uri.index(after:comma)...])) { buffer = value }
                else { buffer = try resource(uri) }
            } else { buffer = binaryBuffer }
            guard let length = spec["byteLength"] as? Int, length >= 0, buffer.count >= length, buffer.count <= 25 * 1024 * 1024 - total else { throw PreviewError.limit("glTF buffer length") }
            total += buffer.count; buffers.append(buffer)
        }
        var sampledTriangles = false
        func accessor(_ id: Int, samplingTriangles: Bool = false) throws -> ([Double],Int) {
            guard accessors.indices.contains(id) else { throw PreviewError.malformed("glTF accessor") }
            let a = accessors[id]; guard a["sparse"] == nil, let vID = a["bufferView"] as? Int, views.indices.contains(vID), let count = a["count"] as? Int, count >= 0, count <= (samplingTriangles ? 25 * 1024 * 1024 : 600000) else { throw PreviewError.malformed("glTF sparse/count") }
            let view = views[vID]; guard let bufferID = view["buffer"] as? Int, buffers.indices.contains(bufferID), let length = view["byteLength"] as? Int, let component = a["componentType"] as? Int, let width = [5120:1,5121:1,5122:2,5123:2,5125:4,5126:4][component], let components = ["SCALAR":1,"VEC2":2,"VEC3":3,"VEC4":4][a["type"] as? String ?? ""] else { throw PreviewError.malformed("glTF buffer view") }
            let base = view["byteOffset"] as? Int ?? 0, extra = a["byteOffset"] as? Int ?? 0, stride = view["byteStride"] as? Int ?? width * components, buffer = buffers[bufferID]
            guard base >= 0, length >= 0, length <= buffer.count, base <= buffer.count - length, extra >= 0, stride >= width * components, stride <= 256, extra <= length, count == 0 || (count - 1) <= (length - extra - min(length - extra,width * components)) / stride else { throw PreviewError.malformed("glTF accessor bounds") }
            guard count == 0 || width * components <= length - extra - (count - 1) * stride else { throw PreviewError.malformed("glTF accessor length") }
            guard !samplingTriangles || (components == 1 && count % 3 == 0) else { throw PreviewError.malformed("glTF triangle indices") }
            // Bound decoded indices by the existing 200k triangle budget. The
            // full buffer range was checked above; skipped faces are never
            // allocated. Keep complete triangles, not individual vertex indices.
            let triangleStep = samplingTriangles ? max(1, (count / 3 + 199999) / 200000) : 1
            if triangleStep > 1 { sampledTriangles = true }
            var values: [Double] = []; values.reserveCapacity(min(count,600000) * components)
            for start in Swift.stride(from:0,to:count,by:samplingTriangles ? 3 * triangleStep : 1) {
                try token.check()
                for i in start..<min(count,start + (samplingTriangles ? 3 : 1)) {
                    var c = BinaryCursor(data:buffer,offset:base + extra + i * stride,token:token)
                    for _ in 0..<components { let bits = try c.uint(width); values.append(component == 5126 ? Double(Float(bitPattern:UInt32(bits))) : Double(bits)) }
                }
            }
            return (values,components)
        }
        let meshes = object["meshes"] as? [[String:Any]] ?? [], materials = object["materials"] as? [[String:Any]] ?? []
        var meshParts: [[Part]] = []
        for mesh in meshes {
            var parts: [Part] = []
            for primitive in mesh["primitives"] as? [[String:Any]] ?? [] {
                guard (primitive["mode"] as? Int ?? 4) == 4, let attributes = primitive["attributes"] as? [String:Int], let pos = attributes["POSITION"] else { throw PreviewError.malformed("glTF triangle POSITION") }
                guard accessors.indices.contains(pos), accessors[pos]["componentType"] as? Int == 5126 else { throw PreviewError.malformed("glTF FLOAT positions") }; let (values,components) = try accessor(pos); guard components == 3, values.count <= 600000 else { throw PreviewError.limit("glTF vertices") }
                var vertices: [SIMD3<Float>] = []; for i in stride(from:0,to:values.count,by:3) { vertices.append(.init(Float(values[i]),Float(values[i + 1]),Float(values[i + 2]))) }
                var indices = vertices.indices.map {UInt32($0)}
                if let id = primitive["indices"] as? Int { guard accessors.indices.contains(id), [5121,5123,5125].contains(accessors[id]["componentType"] as? Int ?? 0) else { throw PreviewError.malformed("glTF unsigned indices") }; let (values,components) = try accessor(id,samplingTriangles:true); guard components == 1, values.allSatisfy({$0 >= 0 && $0 < Double(vertices.count) && $0.rounded() == $0}) else { throw PreviewError.malformed("glTF indices") }; indices = values.map {UInt32($0)} }
                var color = SIMD4<Float>(0.7,0.75,0.9,1)
                if let id = primitive["material"] as? Int, materials.indices.contains(id), let rgba = (materials[id]["pbrMetallicRoughness"] as? [String:Any])?["baseColorFactor"] as? [Float], rgba.count == 4, rgba.allSatisfy({$0.isFinite && $0 >= 0 && $0 <= 1}) { color = .init(rgba[0],rgba[1],rgba[2],rgba[3]) }
                parts.append(.init(vertices:vertices,indices:indices,color:color,transform:matrix_identity_float4x4))
            }
            meshParts.append(parts)
        }
        let nodes = object["nodes"] as? [[String:Any]] ?? []
        guard nodes.count <= 2000 else { throw PreviewError.limit("glTF nodes") }
        var parts: [Part] = [], visited = Set<Int>()
        func visit(_ id: Int, _ parent: simd_float4x4, _ depth: Int) throws {
            try token.check(); guard depth < 64, nodes.indices.contains(id), visited.insert(id).inserted else { throw PreviewError.malformed("glTF node cycle/alias") }
            let node = nodes[id]; var transform = matrix_identity_float4x4
            if let values = node["matrix"] as? [Float], values.count == 16, values.allSatisfy(\.isFinite) { transform = .init(columns:(.init(values[0],values[1],values[2],values[3]),.init(values[4],values[5],values[6],values[7]),.init(values[8],values[9],values[10],values[11]),.init(values[12],values[13],values[14],values[15]))) }
            else {
                let t = node["translation"] as? [Float] ?? [0,0,0], r = node["rotation"] as? [Float] ?? [0,0,0,1], s = node["scale"] as? [Float] ?? [1,1,1]
                guard t.count == 3, r.count == 4, s.count == 3, (t + r + s).allSatisfy(\.isFinite) else { throw PreviewError.malformed("glTF transform") }
                transform = simd_float4x4(simd_quatf(ix:r[0],iy:r[1],iz:r[2],r:r[3])); transform.columns.0 *= s[0]; transform.columns.1 *= s[1]; transform.columns.2 *= s[2]; transform.columns.3 = .init(t[0],t[1],t[2],1)
            }
            transform = parent * transform
            if let mesh = node["mesh"] as? Int { guard meshParts.indices.contains(mesh) else { throw PreviewError.malformed("glTF mesh") }; for var part in meshParts[mesh] { part.transform = transform; parts.append(part); guard parts.count <= 2000 else { throw PreviewError.limit("glTF instances") } } }
            for child in node["children"] as? [Int] ?? [] { try visit(child,transform,depth + 1) }
        }
        let scenes = object["scenes"] as? [[String:Any]] ?? [], scene = object["scene"] as? Int ?? 0
        if scenes.indices.contains(scene) { for root in scenes[scene]["nodes"] as? [Int] ?? [] { try visit(root,matrix_identity_float4x4,0) } }
        else if !nodes.isEmpty { let children = Set(nodes.flatMap {$0["children"] as? [Int] ?? []}); for i in nodes.indices where !children.contains(i) { try visit(i,matrix_identity_float4x4,0) } }
        else { parts = meshParts.flatMap {$0} }
        try validate(parts)
        return .init(parts:parts,notice:(sampledTriangles ? "Large mesh: sampled whole triangles within the 200k budget; geometry is simplified · " : "") + "glTF 2.0 static triangle scene · base colors and node transforms · textures, skins, morphs and animation are omitted")
    }
}
