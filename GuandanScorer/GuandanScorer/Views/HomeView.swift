import SwiftUI

struct HomeView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @State private var showingNewGame = false
    @State private var selectedTeamA: Team?
    @State private var selectedTeamB: Team?
    
    var body: some View {
        VStack {
            // 搜索框
            SearchBar(text: $gameViewModel.searchText)
                .padding(.horizontal)
            
            // 对局列表
            List {
                ForEach(gameViewModel.filteredGameRecords.reversed()) { record in
                    GameRecordRow(record: record) {
                        // 再来一局
                        selectedTeamA = record.teamA
                        selectedTeamB = record.teamB
                        showingNewGame = true
                    }
                }
            }
            .listStyle(PlainListStyle())
            
            // 来一局按钮
            Button(action: {
                selectedTeamA = nil
                selectedTeamB = nil
                showingNewGame = true
            }) {
                Text("来一局")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("惯蛋记分器")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingNewGame) {
            NewGameView(
                prefilledTeamA: selectedTeamA,
                prefilledTeamB: selectedTeamB,
                isPresented: $showingNewGame
            )
        }
    }
}

// 搜索框组件
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索玩家姓名", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

// 对局记录行
struct GameRecordRow: View {
    let record: GameRecord
    let onPlayAgain: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 队伍信息
            HStack {
                VStack(alignment: .leading) {
                    Text("A组：\(record.teamA.displayName)")
                        .font(.subheadline)
                    Text("B组：\(record.teamB.displayName)")
                        .font(.subheadline)
                }
                
                Spacer()
                
                // 成绩
                Text(record.displayResult)
                    .font(.headline)
                    .foregroundColor(record.winner != nil ? .green : .primary)
            }
            
            HStack {
                // 时间
                Text(formatDate(record.createdAt))
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                // 再来一局按钮
                Button("再来一局") {
                    onPlayAgain()
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        return formatter.string(from: date)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            HomeView()
                .environmentObject(GameViewModel())
        }
    }
} 