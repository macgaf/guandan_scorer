import SwiftUI

struct NewGameView: View {
    @EnvironmentObject var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
                // 根据屏幕大小调整布局
                if horizontalSizeClass == .regular {
                    // iPad横屏：使用水平布局
                    HStack(spacing: 40) {
                        // A队信息
                        VStack {
                            Text("A组")
                                .font(.headline)
                                .padding(.bottom)
                            
                            VStack(spacing: 12) {
                                TextField("队员1姓名", text: $teamAPlayer1)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(minHeight: 44)
                                    .onChange(of: teamAPlayer1) { _, newValue in
                                        OSLogger.logTextInput("文本输入: 字段'A组队员1' - 内容: '\(newValue)'")
                                    }
                                
                                TextField("队员2姓名", text: $teamAPlayer2)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(minHeight: 44)
                                    .onChange(of: teamAPlayer2) { _, newValue in
                                        OSLogger.logTextInput("文本输入: 字段'A组队员2' - 内容: '\(newValue)'")
                                    }
                                
                                Toggle("A队为庄家", isOn: Binding(
                                    get: { teamAIsDealer },
                                    set: { 
                                        let newADealerState = $0
                                        teamAIsDealer = newADealerState
                                        OSLogger.logInputEvent("点击 - 目标: A队庄家开关 - 详情: A队庄家状态: \(newADealerState), B队庄家状态: \(!newADealerState)")
                                    }
                                ))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                        
                        // B队信息
                        VStack {
                            Text("B组")
                                .font(.headline)
                                .padding(.bottom)
                            
                            VStack(spacing: 12) {
                                TextField("队员1姓名", text: $teamBPlayer1)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(minHeight: 44)
                                    .onChange(of: teamBPlayer1) { _, newValue in
                                        OSLogger.logTextInput("文本输入: 字段'B组队员1' - 内容: '\(newValue)'")
                                    }
                                
                                TextField("队员2姓名", text: $teamBPlayer2)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .frame(minHeight: 44)
                                    .onChange(of: teamBPlayer2) { _, newValue in
                                        OSLogger.logTextInput("文本输入: 字段'B组队员2' - 内容: '\(newValue)'")
                                    }
                                
                                Toggle("B队为庄家", isOn: Binding(
                                    get: { !teamAIsDealer },
                                    set: { 
                                        let newBDealerState = $0
                                        teamAIsDealer = !newBDealerState
                                        OSLogger.logInputEvent("点击 - 目标: B队庄家开关 - 详情: B队庄家状态: \(newBDealerState), A队庄家状态: \(!newBDealerState)")
                                    }
                                ))
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    
                } else {
                    // iPhone：使用垂直布局
                    // A队信息
                    Section(header: Text("A组")) {
                    TextField("队员1姓名", text: $teamAPlayer1)
                        .onChange(of: teamAPlayer1) { _, newValue in
                            OSLogger.logTextInput("文本输入: 字段'A组队员1' - 内容: '\(newValue)'")
                        }
                    TextField("队员2姓名", text: $teamAPlayer2)
                        .onChange(of: teamAPlayer2) { _, newValue in
                            OSLogger.logTextInput("文本输入: 字段'A组队员2' - 内容: '\(newValue)'")
                        }
                    
                    Toggle("A队为庄家", isOn: Binding(
                        get: { teamAIsDealer },
                        set: { 
                            let newADealerState = $0
                            teamAIsDealer = newADealerState
                            OSLogger.logInputEvent("点击 - 目标: A队庄家开关 - 详情: A队庄家状态: \(newADealerState), B队庄家状态: \(!newADealerState)")
                        }
                    ))
                    }
                    
                    // B队信息
                    Section(header: Text("B组")) {
                        TextField("队员1姓名", text: $teamBPlayer1)
                            .onChange(of: teamBPlayer1) { _, newValue in
                                OSLogger.logTextInput("文本输入: 字段'B组队员1' - 内容: '\(newValue)'")
                            }
                        TextField("队员2姓名", text: $teamBPlayer2)
                            .onChange(of: teamBPlayer2) { _, newValue in
                                OSLogger.logTextInput("文本输入: 字段'B组队员2' - 内容: '\(newValue)'")
                            }
                        
                        Toggle("B队为庄家", isOn: Binding(
                            get: { !teamAIsDealer },
                            set: { 
                                let newBDealerState = $0
                                teamAIsDealer = !newBDealerState
                                OSLogger.logInputEvent("点击 - 目标: B队庄家开关 - 详情: B队庄家状态: \(newBDealerState), A队庄家状态: \(!newBDealerState)")
                            }
                        ))
                    }
                }
                
                // 操作按钮
                Section {
                    Button("开始对局") {
                        // 记录开始游戏按钮点击
                        OSLogger.logInputEvent("点击 - 目标: 开始对局按钮 - 详情: 创建新游戏: A队(\(teamAPlayer1) & \(teamAPlayer2)) vs B队(\(teamBPlayer1) & \(teamBPlayer2))")
                        
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
                    OSLogger.logInputEvent("点击 - 目标: 取消按钮 - 详情: 取消创建新游戏")
                    
                    dismiss()
                }
            )
            .onAppear {
                // 记录新建游戏界面初始化
                OSLogger.logInputEvent("点击 - 目标: NewGameView界面 - 详情: 界面初始化 - 新建游戏")
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
