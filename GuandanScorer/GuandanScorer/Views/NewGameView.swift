import SwiftUI

struct NewGameView: View {
    @EnvironmentObject var gameViewModel: GameViewModel
    @Binding var isPresented: Bool
    
    // 预填充的团队信息（用于"再来一局"）
    let prefilledTeamA: Team?
    let prefilledTeamB: Team?
    
    @State private var teamAPlayer1: String = ""
    @State private var teamAPlayer2: String = ""
    @State private var teamBPlayer1: String = ""
    @State private var teamBPlayer2: String = ""
    @State private var dealerTeam: GameRecord.TeamType = .teamA
    
    var canStartGame: Bool {
        !teamAPlayer1.isEmpty && !teamAPlayer2.isEmpty &&
        !teamBPlayer1.isEmpty && !teamBPlayer2.isEmpty
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // A组
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("A组")
                            .font(.headline)
                        
                        Spacer()
                        
                        // 庄家标示
                        Button(action: {
                            dealerTeam = .teamA
                        }) {
                            HStack {
                                Image(systemName: dealerTeam == .teamA ? "checkmark.circle.fill" : "circle")
                                Text("庄家")
                            }
                            .foregroundColor(dealerTeam == .teamA ? .blue : .gray)
                        }
                    }
                    
                    TextField("玩家1姓名", text: $teamAPlayer1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("玩家2姓名", text: $teamAPlayer2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // B组
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("B组")
                            .font(.headline)
                        
                        Spacer()
                        
                        // 庄家标示
                        Button(action: {
                            dealerTeam = .teamB
                        }) {
                            HStack {
                                Image(systemName: dealerTeam == .teamB ? "checkmark.circle.fill" : "circle")
                                Text("庄家")
                            }
                            .foregroundColor(dealerTeam == .teamB ? .blue : .gray)
                        }
                    }
                    
                    TextField("玩家1姓名", text: $teamBPlayer1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("玩家2姓名", text: $teamBPlayer2)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Spacer()
                
                // 开局按钮
                Button(action: startGame) {
                    Text("开局")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canStartGame ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!canStartGame)
            }
            .padding()
            .navigationTitle("新建一局")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("取消") {
                    isPresented = false
                }
            )
        }
        .onAppear {
            // 如果有预填充信息，填充表单
            if let teamA = prefilledTeamA {
                teamAPlayer1 = teamA.player1
                teamAPlayer2 = teamA.player2
            }
            if let teamB = prefilledTeamB {
                teamBPlayer1 = teamB.player1
                teamBPlayer2 = teamB.player2
            }
        }
    }
    
    private func startGame() {
        let teamA = Team(
            player1: teamAPlayer1,
            player2: teamAPlayer2,
            isDealer: dealerTeam == .teamA
        )
        
        let teamB = Team(
            player1: teamBPlayer1,
            player2: teamBPlayer2,
            isDealer: dealerTeam == .teamB
        )
        
        gameViewModel.createNewGame(teamA: teamA, teamB: teamB)
        isPresented = false
    }
}

struct NewGameView_Previews: PreviewProvider {
    static var previews: some View {
        NewGameView(
            prefilledTeamA: nil,
            prefilledTeamB: nil,
            isPresented: .constant(true)
        )
        .environmentObject(GameViewModel())
    }
} 