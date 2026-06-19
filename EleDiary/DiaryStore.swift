import Foundation
import Combine

// 一篇日记 = 磁盘上的一个 .md 文件
struct DiaryEntry: Identifiable, Hashable {
    let url: URL
    var id: URL { url }                         // 用文件路径做唯一标识
    var title: String {                          // 去掉 .md 的文件名，如 "2026-06-19"
        url.deletingPathExtension().lastPathComponent
    }
}

// 负责：找文件夹、列出日记、读、写、新建
final class DiaryStore: ObservableObject {
    @Published var entries: [DiaryEntry] = []   // @Published：这个一变，界面自动刷新

    let folderURL: URL                           // 所有日记存放的文件夹

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        folderURL = documents.appendingPathComponent("EleDiary", isDirectory: true)
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        loadEntries()
    }

    // 扫描文件夹，把所有 .md 读成列表（按日期从新到旧排）
    func loadEntries() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: folderURL, includingPropertiesForKeys: nil)) ?? []
        entries = files
            .filter { $0.pathExtension == "md" }
            .map { DiaryEntry(url: $0) }
            .sorted { $0.title > $1.title }
    }

    // 读取某篇日记的正文
    func content(of entry: DiaryEntry) -> String {
        (try? String(contentsOf: entry.url, encoding: .utf8)) ?? ""
    }

    // 保存正文到某篇日记
    func save(_ text: String, to entry: DiaryEntry) {
        try? text.write(to: entry.url, atomically: true, encoding: .utf8)
    }

    // 新建（或打开已存在的）今天的日记
    func createTodayEntry() -> DiaryEntry {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let name = formatter.string(from: Date())
        let url = folderURL.appendingPathComponent("\(name).md")

        if !FileManager.default.fileExists(atPath: url.path) {
            try? "# \(name)\n\n".write(to: url, atomically: true, encoding: .utf8)
        }
        loadEntries()
        return DiaryEntry(url: url)
    }
}
