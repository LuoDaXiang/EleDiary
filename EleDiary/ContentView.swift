import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var store = DiaryStore()   // 持有数据，全程不丢
    @State private var selectedID: DiaryEntry.ID?   // 当前选中哪篇
    @State private var draft: String = ""           // 编辑区里正在打的字

    var body: some View {
        NavigationSplitView {
            // 左侧：日记列表
            List(store.entries, selection: $selectedID) { entry in
                Text(entry.title)
            }
            .navigationTitle("日记")
            .toolbar {
                ToolbarItem {
                    Button {
                        selectedID = store.createTodayEntry().id   // 新建今天并选中
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .help("写今天的日记")
                }
                ToolbarItem {
                    Button {
                        NSWorkspace.shared.open(store.folderURL)    // 在访达里打开文件夹
                    } label: {
                        Image(systemName: "folder")
                    }
                    .help("在访达中打开日记文件夹")
                }
            }
        } detail: {
            // 右侧：编辑器
            if let entry = store.entries.first(where: { $0.id == selectedID }) {
                TextEditor(text: $draft)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .navigationTitle(entry.title)
                    .onChange(of: draft) { newValue in
                        store.save(newValue, to: entry)             // 边打边存
                    }
            } else {
                Text("选择左边的一篇日记，或点右上角 ✎ 写今天的")
                    .foregroundStyle(.secondary)
            }
        }
        // 切换选中的日记时，把那篇的内容读进编辑区
        .onChange(of: selectedID) { newID in
            if let entry = store.entries.first(where: { $0.id == newID }) {
                draft = store.content(of: entry)
            } else {
                draft = ""
            }
        }
    }
}
