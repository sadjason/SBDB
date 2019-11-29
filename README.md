# SBDB

参考 FMDB，以学习 Swift 为目的写的 SQLite wrapper，支持 ORM。

## 使用

### Database

Database 封装 sqlite 句柄，代表一次连接

```swift
let userDir = NSSearchPathForDirectoriesInDomains(
    .documentDirectory,
    .userDomainMask,
    true
).first!
let path = "\(userDir)/tests.sqlite3"

let db = try Database(path: path) // or Database(path: path, options: [.readwrite, .create, .noMutex])
```

### 支持 ORM

```swift
// 会话
struct Conversation {
    var id: String      // 会话 ID
    var name: String    // 会话名
}

extension Conversation: TableCodable { }

/// 成员
struct Participant: TableCodable {
    var userId: String  // 用户 ID
    var convId: String  // 会话 ID
    var name: String    // 姓名
    var age: Int        // 年龄
}

```

如果实现了 `TableCodingKeyConvertiable` 协议，还可以支持更多基于 KeyPath 的操作：

```swift
struct Conversation: TableCodingKeyConvertiable {
    static func codingKey(forKeyPath keyPath: PartialKeyPath<Self>) -> CodingKey {
        switch keyPath {
        case \Self.id: return CodingKeys.id
        case \Self.name: return CodingKeys.name
        default: fatalError()
        }
    }
}

struct Participant: TableCodingKeyConvertiable { ... }
```

### Creating & Droping Table 

```swift
// create table
try db.createTable(Conversation.self)
try db.createTable(Conversation.self, options: .ifNotExists) { tb in
    // set primaryKey: single comumn
    // set unique
    tb.column(forKeyPath: \Conversation.id)?.primaryKey().unique()
    // set notNull
    tb.column(forKeyPath: \Conversation.name)?.notNull()
}
try db.createTable(Participant.self, options: .ifNotExists) { tb in
    // set primaryKey: multiple columns
    tb.setPrimaryKey(withKeyPath: \Participant.userId, \Participant.convId)
}

// drop table
try db.dropTable(Conversation.self)
try db.dropTable(Participant.self, ifExists: true)
```

### Inserting

```swift
// 单条插入
let conv = buildConversation(name: "conv_0")
try db.insert(conv)

// 批量插入
let participants = (1...100).map { index in buildParticipant(name: "name_\(index)", age: index, convId: conv.id) }
try db.insert(participants)
```

### Deleting

```swift
// 全删
try db.delete(from: Conversation.self)

// 条件删
try db.delete(from: Participant.self, where: Column("age") < 18)

// 基于 keyPath 条件删
let age = \Participant.age
// >=
try db.delete(from: Participant.self, where: age >= 80)
// in
try db.delete(from: Participant.self, where: age.in([32, 19]))
// between and
try db.delete(from: Participant.self, where: age.between(65, and: 70))
// isNull
try db.delete(from: Participant.self, where: age.isNull())
// cond1 && cond2
try db.delete(from: Participant.self, where: age <= 60 && age >= 18)
```

### Updating

```swift
try db.update(Participant.self, where: \Participant.name == "name_42"){ assign in
    assign(\Participant.age, "24")
}
```

### Selecting

```swift
let (age, name, convId) = (\Participant.age, \Participant.name, \Participant.convId)

// select all
_ = try db.select(from: Participant.self)
_ = try db.select(from: Participant.self, where: age >= 30)
_ = try db.select(from: Participant.self, where: age >= 60, orderBy: age)
_ = try db.select(from: Participant.self, where: age >= 60, orderBy: age.desc())
_ = try db.select(from: Participant.self, where: age >= 50 && age <= 60, orderBy: age)

// select one
_ = try db.selectOne(from: Participant.self)
_ = try db.selectOne(from: Participant.self, where: age >= 30)
_ = try db.selectOne(from: Participant.self, where: age >= 60, orderBy: age)
_ = try db.selectOne(from: Participant.self, where: age >= 60, orderBy: age.desc())

// select specify columns
_ = try db.selectColumns(from: Participant.self, on: [name, age], where: convId == conv.id)

// select with aggregate
_ = try db.selectOneColumn(from: Participant.self, on: age.sum())
_ = try db.selectOneColumn(from: Participant.self, on: name.count(), where: convId == conv.id && age >= 18)
_ = try db.selectOneColumn(from: Participant.self, on: age.max())
_ = try db.selectOneColumn(from: Participant.self, on: age.min())
```

### DatabaseQueue

类似于 FMDB 的 `FMDatabaseQueue`，`DatabaseQueue` 对 `Database` 进行封装，确保对数据库操作的串行化。

```swift
let queue = DatabaseQueue(path: path)

try? dbQueue.inTransaction(mode: .immediate, execute: { (db, rollback) in
    (0..<5000).forEach { index in
        try? db.insert(buildParticipant(name: "name_\(index)", age: index, convId: conv.id) )
    }
})
```

### DatabasePool

类似于 FMDB 的 FMDatabasePool，DatabasePool 维护一个连接池，提供更高的并发性；只是 DatabasePool 默认使用 wal 模式，并发读，串行写。

```swift
try pool.write { (db, _) in
    if let p = try db.selectOne(from: Participant.self) {
        try db.update(Participant.self, where: userId == p.userId) { assign in
            assign(name, "the one")
        }
    }
}
```
