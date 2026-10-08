import Foundation
import UniformTypeIdentifiers

public enum ReadableFormat {
    public static let codeExtensions: Set<String> = ["swift","py","js","ts","tsx","jsx","mjs","cjs","mts","cts","vue","svelte","astro","c","h","cpp","hpp","rs","go","sh","zsh","bash","rb","java","kt","css","scss","sass","less","html","sql","cs","php","dart","lua","r","scala","ps1","proto","graphql","gql","tf","tfvars","hcl"]
    public static func isNamedText(_ url: URL) -> Bool {
        let name = url.lastPathComponent.lowercased()
        let names: Set<String> = ["makefile","gnumakefile","dockerfile","containerfile","gemfile","rakefile","justfile","license","readme",".gitignore",".gitattributes",".gitmodules",".env",".dockerignore",".editorconfig",".npmrc",".yarnrc",".prettierrc",".eslintrc",".babelrc",".nvmrc",".python-version",".ruby-version","cargo.lock","yarn.lock","poetry.lock","uv.lock","pipfile","pipfile.lock","gemfile.lock","go.mod","go.sum","cmakelists.txt","procfile","brewfile","jenkinsfile"]
        return names.contains(name) || [".env.","dockerfile.","containerfile.","makefile.",".prettierrc.",".eslintrc.",".babelrc."].contains(where: { name.hasPrefix($0) })
    }
    public static func isCollection(_ url: URL) -> Bool {
        ["openapi.json","swagger.json"].contains(url.lastPathComponent.lowercased()) || ["har","epub","jsonl","ndjson","diff","patch","sqlite","sqlite3","db","zip","tar","tgz","gz","ipynb"].contains(url.pathExtension.lowercased())
    }
    public static func isText(_ url: URL) -> Bool {
        if isNamedText(url) { return true }
        let ext = url.pathExtension.lowercased()
        if codeExtensions.contains(ext) || ["txt","md","markdown","json","jsonc","json5","yaml","yml","toml","xml","csv","tsv","log","ini","conf","config","properties","plist","svg","diff","patch"].contains(ext) { return true }
        return UTType(filenameExtension:ext)?.conforms(to:.text) == true
    }
}
