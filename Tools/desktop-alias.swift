import Foundation
import Darwin
// Usage: desktop-alias APP_PATH ALIAS_PATH [EXPECTED_OLD_TARGET]
let args = CommandLine.arguments
 guard args.count == 3 || args.count == 4 else { fatalError("Usage: desktop-alias APP_PATH ALIAS_PATH [EXPECTED_OLD_TARGET]") }
let target = URL(fileURLWithPath: args[1]).standardizedFileURL
let alias = URL(fileURLWithPath: args[2]).standardizedFileURL
let manager = FileManager.default
precondition(manager.fileExists(atPath: target.appendingPathComponent("Contents/MacOS/Nuomi").path), "Target application missing")
func verifyExisting() throws {
    let properties = try alias.resourceValues(forKeys: [.isAliasFileKey])
    guard properties.isAliasFile == true, args.count == 4 else { fatalError("Existing item is not an authorized alias replacement") }
    let old = try URL(resolvingAliasFileAt: alias, options: [.withoutUI, .withoutMounting]).standardizedFileURL
    guard old == URL(fileURLWithPath: args[3]).standardizedFileURL else { fatalError("Existing alias points elsewhere; refusing replacement") }
    print("Verified previous alias target: \(old.path)")
}
let exists = manager.fileExists(atPath: alias.path)
if exists { try verifyExisting() }
let bookmark = try target.bookmarkData(options: .suitableForBookmarkFile, includingResourceValuesForKeys: nil, relativeTo: nil)
let temporary = alias.deletingLastPathComponent().appendingPathComponent(".nuomi-alias-\(UUID().uuidString)")
try URL.writeBookmarkData(bookmark, to: temporary)
defer { try? manager.removeItem(at: temporary) }
if exists {
    try verifyExisting()
    guard rename(temporary.path, alias.path) == 0 else { throw NSError(domain:NSPOSIXErrorDomain, code:Int(errno)) }
} else {
    // Hard link refuses a destination created by another process in the meantime.
    try manager.linkItem(at: temporary, to: alias)
}
let resolved = try URL(resolvingAliasFileAt: alias, options: [.withoutUI, .withoutMounting]).standardizedFileURL
precondition(resolved == target)
let aliasValues = try alias.resourceValues(forKeys: [.isAliasFileKey])
precondition(aliasValues.isAliasFile == true)
print("Verified Finder alias: \(alias.path) -> \(resolved.path)")
