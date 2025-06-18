import SwiftUI

struct NewGameView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var teamAPlayer1: String
    @State private var teamAPlayer2: String
    @State private var teamBPlayer1: String
    @State private var teamBPlayer2: String
    @State private var teamAIsDealer: Bool = true
    
    // 支持预填写人名信息的初始化器
    init(teamAPlayer1: String = "", teamAPlayer2: String = "", teamBPlayer1: String = "", teamBPlayer2: String = "") {
        _teamAPlayer1 = State(initialValue: teamAPlayer1)
        _teamAPlayer2 = State(initialValue: teamAPlayer2)
        _teamBPlayer1 = State(initialValue: teamBPlayer1)
        _teamBPlayer2 = State(initialValue: teamBPlayer2)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // A队信息
                Section(header: Text("A组")) {
                    TextField("队员1姓名", text: $teamAPlayer1)
                        .onChange(of: teamAPlayer1) { _, newValue in
                            GameLogger.shared.logTextInput(field: "A组队员1", text: newValue)
                        }
                    TextField("队员2姓名", text: $teamAPlayer2)
                        .onChange(of: teamAPlayer2) { _, newValue in
                            GameLogger.shared.logTextInput(field: "A组队员2", text: newValue)
                        }
                    
                    Toggle("A队为庄家", isOn: $teamAIsDealer)
                }
                
                // B队信息
                Section(header: Text("B组")) {
                    TextField("队员1姓名", text: $teamBPlayer1)
                        .onChange(of: teamBPlayer1) { _, newValue in
                            GameLogger.shared.logTextInput(field: "B组队员1", text: newValue)
                        }
                    TextField("队员2姓名", text: $teamBPlayer2)
                        .onChange(of: teamBPlayer2) { _, newValue in
                            GameLogger.shared.logTextInput(field: "B组队员2", text: newValue)
                        }
                    
                    Toggle("B队为庄家", isOn: Binding(
                        get: { !teamAIsDealer },
                        set: { teamAIsDealer = !$0 }
                    ))
                }
                
                // 操作按钮
                Section {
                    Button("开始对局") {
                        // 记录开始游戏按钮点击
                        GameLogger.shared.logInputEvent(
                            type: .tap,
                            target: "开始对局按钮",
                            details: "创建新游戏: A队(\(teamAPlayer1) & \(teamAPlayer2)) vs B队(\(teamBPlayer1) & \(teamBPlayer2))"
                        )
                        
                        createNewGame()
                    }
                    .disabled(!isFormValid)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(isFormValid ? .blue : .gray)
                }
            }
            .navigationTitle("新建对局")
            .navigationBarItems(
                leading: Button("取消") {
                    // 记录取消按钮点击
                    GameLogger.shared.logInputEvent(
                        type: .tap,
                        target: "取消按钮",
                        details: "取消创建新游戏"
                    )
                    
                    dismiss()
                }
            )
            .onAppear {
                // 记录新建游戏界面初始化
                GameLogger.shared.logInputEvent(
                    type: .tap,
                    target: "NewGameView界面",
                    details: "界面初始化 - 新建游戏"
                )
            }
        }
    }
    
    // 表单验证
    private var isFormValid: Bool {
        !teamAPlayer1.isEmpty && !teamAPlayer2.isEmpty &&
        !teamBPlayer1.isEmpty && !teamBPlayer2.isEmpty
    }
    
    // 创建新对局
    private func createNewGame() {
        let teamA = TeamStatus(
            player1: teamAPlayer1,
            player2: teamAPlayer2,
            currentLevel: .two, // 从2开始
            isDealer: teamAIsDealer
        )
        
        let teamB = TeamStatus(
            player1: teamBPlayer1,
            player2: teamBPlayer2,
            currentLevel: .two, // 从2开始
            isDealer: !teamAIsDealer
        )
        
        let newGame = gameManager.createNewGame(teamA: teamA, teamB: teamB)
        gameManager.currentGame = newGame
        dismiss()
    }
}

#Preview {
    NewGameView()
        .environmentObject(GameManager())
}
