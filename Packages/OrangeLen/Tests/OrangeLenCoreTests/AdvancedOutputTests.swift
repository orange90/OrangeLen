import XCTest
@testable import OrangeLenCore

final class AdvancedOutputTests: XCTestCase {
    func fixture(_ name: String) throws -> Data { try Data(contentsOf:URL(fileURLWithPath:#filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("Tests/Fixtures/advanced-outputs/" + name)) }
    func text(_ name: String) throws -> String { String(decoding:try fixture(name),as:UTF8.self) }
    func testDrawioCompressedPagesAndInvalidIdentities() throws {
        let doc = try XCTUnwrap(DiagramDocument.parseIfKnown(text("diagram.drawio"),name:"diagram.drawio"))
        XCTAssertEqual(doc.pages.count,2); XCTAssertEqual(doc.pages[0].boxes.count,2); XCTAssertEqual(doc.pages[1].boxes[0].text,"输入文件")
        XCTAssertThrowsError(try DiagramDocument.parseIfKnown(text("diagram.drawio").replacingOccurrences(of:"id=\"3\"",with:"id=\"2\""),name:"diagram.drawio"))
        XCTAssertThrowsError(try DiagramDocument.parseIfKnown("<!DOCTYPE foo><mxfile/>",name:"a.drawio"))
    }
    func testCanvasAndAllWorkflowSchemas() throws {
        for name in ["board.canvas","comfy.json","comfy-api.json","n8n.json","dify.yml"] {
            let doc = try XCTUnwrap(DiagramDocument.parseIfKnown(text(name),name:name)); XCTAssertEqual(doc.pages[0].boxes.count,2,name); XCTAssertEqual(doc.pages[0].edges.count,1,name)
        }
        XCTAssertNil(try DiagramDocument.parseIfKnown("{\"hello\":1}",name:"ordinary.json"))
        XCTAssertThrowsError(try DiagramDocument.parseIfKnown("workflow: &a\n  graph: *a",name:"dify.yml"))
        let token = Cancellation(); token.cancel(); XCTAssertThrowsError(try DiagramDocument.parseIfKnown(text("board.canvas"),name:"board.canvas",cancellation:token))
    }
    func testNumPyValuesFortranAndObjectHeaderOnly() throws {
        let array = try ScientificDocument.parse(fixture("array.npy"),name:"array.npy")
        XCTAssertEqual(array.rows.map {$0[1]},["1","2","3","4","5","6"])
        let fortran = try ScientificDocument.parse(fixture("fortran.npy"),name:"fortran.npy"); XCTAssertTrue(fortran.summary.contains("Fortran")); XCTAssertEqual(fortran.rows.map {$0[1]},["1.0","3.0","2.0","4.0"])
        let header = "{'descr': '|O', 'fortran_order': False, 'shape': (1,), }\n"; var data = Data([147,78,85,77,80,89,1,0,UInt8(header.utf8.count),0]); data.append(Data(header.utf8)); data.append(Data("malicious pickle is never evaluated".utf8))
        XCTAssertTrue(try ScientificDocument.parse(data,name:"object.npy").rows.isEmpty)
        XCTAssertThrowsError(try ScientificDocument.parse(Data(try fixture("array.npy").dropLast()),name:"array.npy"))
        let archive = try ArchiveDocument.parse(fixture("arrays.npz"),name:"arrays.npz"); XCTAssertEqual(archive.entries.count,2)
    }
    func testTensorCatalogAndGGUFWithoutWeights() throws {
        for name in ["weights.safetensors","sample.latent","model.gguf"] {
            let value = try ScientificDocument.parse(fixture(name),name:name); XCTAssertEqual(value.rows.count,1); XCTAssertEqual(value.rows[0][0],"sample")
        }
        var bad = try fixture("weights.safetensors"); bad[0] = 255; XCTAssertThrowsError(try ScientificDocument.parse(bad,name:"bad.safetensors"))
        let token = Cancellation(); token.cancel(); XCTAssertThrowsError(try ScientificDocument.parse(fixture("model.gguf"),name:"model.gguf",cancellation:token))
    }
    func testAllMeshFormatsAndMalformedBounds() throws {
        for name in ["mesh.obj","mesh.stl","mesh.gltf","mesh.glb"] { let doc = try MeshDocument.parse(fixture(name),name:name); XCTAssertGreaterThan(doc.triangles,0) }
        XCTAssertThrowsError(try MeshDocument.parse(Data("v 0 0 0\nf 1 2 3".utf8),name:"bad.obj"))
        let changed = try text("mesh.gltf").replacingOccurrences(of:"\"count\": 3",with:"\"count\": 300")
        XCTAssertThrowsError(try MeshDocument.parse(Data(changed.utf8),name:"bad.gltf"))
    }
    func testLargeIndexedMeshSamplesWholeTrianglesWithoutRaisingGeometryBudget() throws {
        let positions: [Float] = [-1,0,0,1,0,0,0,1,0]
        var bytes = positions.withUnsafeBytes { Data($0) }
        let indexCount = 600003
        for i in 0..<indexCount {
            var index = UInt32(i % 3).littleEndian
            withUnsafeBytes(of: &index) { bytes.append(contentsOf: $0) }
        }
        var object: [String:Any] = ["asset":["version":"2.0"],
            "buffers":[["byteLength":bytes.count,"uri":"data:application/octet-stream;base64," + bytes.base64EncodedString()]],
            "bufferViews":[["buffer":0,"byteLength":36],["buffer":0,"byteOffset":36,"byteLength":indexCount * 4]],
            "accessors":[["bufferView":0,"componentType":5126,"count":3,"type":"VEC3"],["bufferView":1,"componentType":5125,"count":indexCount,"type":"SCALAR"]],
            "meshes":[["primitives":[["attributes":["POSITION":0],"indices":1]]]]]
        let mesh = try MeshDocument.parse(JSONSerialization.data(withJSONObject:object),name:"large.gltf")
        XCTAssertEqual(mesh.triangles,100001)
        XCTAssertTrue(mesh.notice.contains("sampled"))
        XCTAssertLessThanOrEqual(mesh.parts.reduce(0) { $0 + $1.indices.count },600000)
        XCTAssertEqual(Array(mesh.parts[0].indices.prefix(6)),[0,1,2,0,1,2])
        var accessors = object["accessors"] as! [[String:Any]]
        accessors[1]["count"] = indexCount + 3; object["accessors"] = accessors
        XCTAssertThrowsError(try MeshDocument.parse(JSONSerialization.data(withJSONObject:object),name:"out-of-bounds.gltf"))
        accessors[1]["count"] = indexCount - 1; object["accessors"] = accessors
        XCTAssertThrowsError(try MeshDocument.parse(JSONSerialization.data(withJSONObject:object),name:"incomplete-triangle.gltf"))
        let token = Cancellation(); token.cancel()
        XCTAssertThrowsError(try MeshDocument.parse(JSONSerialization.data(withJSONObject:object),name:"cancelled.gltf",cancellation:token))
    }
    func testParquetFooterAndInvalidLength() throws {
        let data = try fixture("table.parquet"), metadata = try ParquetHeader.parse(data)
        XCTAssertEqual(metadata.rows,3); XCTAssertEqual(metadata.columns,3)
        var broken = data; broken[data.count - 5] = 255
        XCTAssertThrowsError(try ParquetHeader.parse(broken))
    }
    func testImageExifXMPRecipesAndC2PABounds() throws {
        XCTAssertTrue(try AIImageMetadata.parse(fixture("generation.jpg")).text.contains("orange cat"))
        XCTAssertTrue(try AIImageMetadata.parse(fixture("generation.xmp")).text.contains("Seed: 42"))
        let doc = try ProvenanceDocument.parse(fixture("credentials.c2pa")); XCTAssertTrue(doc.summary.contains("NOT verified")); XCTAssertTrue(doc.summary.contains("claim_generator"))
        var invalid = try fixture("credentials.c2pa"); invalid[0] = 255
        XCTAssertThrowsError(try ProvenanceDocument.parse(invalid))
    }
    func testMultiGigabyteModelReadsOnlyBoundedHeader() throws {
        let directory = FileManager.default.temporaryDirectory.resolvingSymlinksInPath().appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true); defer { try? FileManager.default.removeItem(at:directory) }
        let payload = 4 * 1024 * 1024 * 1024
        let header = Data("{\"huge\":{\"dtype\":\"F32\",\"shape\":[1073741824],\"data_offsets\":[0,4294967296]}}".utf8)
        var count = UInt64(header.count).littleEndian; var data = withUnsafeBytes(of:&count) { Data($0) }; data.append(header)
        let file = directory.appendingPathComponent("large.safetensors"); try data.write(to:file)
        let handle = try FileHandle(forWritingTo:file); try handle.truncate(atOffset:UInt64(data.count + payload)); try handle.close()
        let value = try ScientificDocument.load(file,root:directory,cancellation:.init()).0
        XCTAssertEqual(value.rows[0][3],String(payload))
    }
    func testN8NPackageIsTarGzipWithManifest() throws {
        let archive = try ArchiveDocument.parse(fixture("workflows.n8np"),name:"workflows.n8np")
        XCTAssertTrue(try MCPBundle.summary(archive,name:"workflows.n8np").contains("workflows: 1"))
        XCTAssertNotNil(archive.entry("workflows/preview/workflow.json"))
    }
}
