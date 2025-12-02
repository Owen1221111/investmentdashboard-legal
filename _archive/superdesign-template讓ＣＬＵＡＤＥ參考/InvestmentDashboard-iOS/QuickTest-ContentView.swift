import SwiftUI

// 快速測試版本 - 把所有代碼都放在一個檔案
struct ContentView: View {
    @State private var selectedClientName = "張先生"
    @State private var showingClientList = false
    
    let sampleClients = ["張先生", "王女士", "李先生", "陳女士"]
    
    var body: some View {
        VStack {
            // 頂部導航欄
            HStack {
                Button(action: { showingClientList = true }) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                Spacer()
                Text(selectedClientName)
                    .font(.headline)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Spacer()
            
            // 主要內容
            VStack {
                Text("目前選擇的客戶:")
                    .font(.title2)
                    .padding()
                Text(selectedClientName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding()
                Text("(這裡之後會顯示儀表板內容)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .sheet(isPresented: $showingClientList) {
            NavigationView {
                List {
                    ForEach(sampleClients, id: \.self) { client in
                        HStack {
                            Text(client)
                                .font(.body)
                            Spacer()
                            if client == selectedClientName {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                                    .fontWeight(.semibold)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedClientName = client
                            showingClientList = false
                        }
                    }
                }
                .navigationTitle("選擇客戶")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("完成") {
                            showingClientList = false
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}