//
//  Persistence.swift
//  GuandanScorer
//
//  Created by 徐添 on 3/6/25.
//

// 注意：这个文件暂时保留，已经简化并移除了 CoreData 依赖。
// 项目现在使用 GameManager 进行数据管理。

struct PersistenceController {
    static let shared = PersistenceController()
    static let preview: PersistenceController = PersistenceController()
    
    init() {}
}
