# SBDB

参考 FMDB，以学习 Swift 为目的写的 SQLite wrapper，支持 ORM。Just for fun

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

### Creating & Droping Table 

```swift
struct Student {
    var name: String
    var age: UInt8
    var address: String?
    var grade: Int?
    var married: Bool
    var isBoy: Bool?
    var gpa: Float
    var extra: Data?
}

extension Student: TableCodable { }

// create table
try db.createTable(Student.self)
// create table if not exists
try db.createTable(Student.self, options: .ifNotExists)

// drop table
try db.dropTable(Student.self)
```

### Inserting

```swift
// 单条插入
try db.insert(generateStudent())

// 批量插入
try db.insert((0..<100).map { generateStudent() })
```

### Deleting

```swift
// 全删
try db.delete(from: Student.self)

// 条件删
try db.delete(from: Student.self, where: Column("age") < 18)
```

如果 `Student` 实现了 `KeyPathToColumnNameConvertiable` 协议，还可以基于 KeyPath 实现更高级的操作：

```swift
extension Student: KeyPathToColumnNameConvertiable {
    static func columnName(of keyPath: PartialKeyPath<Student>) -> String? {
        switch keyPath {
        case \Student.name: return "name"
        case \Student.age: return "age"
        case \Student.address: return "address"
        case \Student.grade: return "grade"
        case \Student.married: return "married"
        case \Student.isBoy: return "isBoy"
        case \Student.gpa: return "gpa"
        case \Student.extra: return "extra"
        default: return nil
        }
    }
}
```

```swift
// 条件删
try db.delete(from: Student.self, where: \Student.name < 18)
```

### Updating

```swift
try db.update(Student.self, where: \Student.name == "the one") { assign in
    assign(\Student.married, false)
    assign(\Student.extra, Base.null)
    assign(\Student.gpa, 4.0)
}
```

### DatabaseQueue

类似于 FMDB 的 `FMDatabaseQueue`，`DatabaseQueue` 对 `Database` 进行封装，确保对数据库操作的串行化。

```swift
let queue = DatabaseQueue(path: path)

try? dbQueue.inTransaction(mode: .immediate, execute: { (db, rollback) in
    (0..<5000).forEach { (_) in
        try? generateStudent().save(in: db)
    }
})
```

### DatabasePool

类似于 FMDB 的 FMDatabasePool，DatabasePool 维护一个连接池，提供更高的并发性；只是 DatabasePool 默认使用 wal 模式，并发读，串行写。