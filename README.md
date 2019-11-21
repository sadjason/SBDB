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
struct Student: TableCodable {
    var name: String
    var age: UInt8
    var address: String?
    var grade: Int?
    var married: Bool
    var isBoy: Bool?
    var gpa: Float
    var extra: Data?
}

// create table (ifNotExists)
try Student.create(in: db)

// drop table
try Student.drop(from: db)
```

### Inserting

```swift
let singleStudent: Student = generateStudent()

// 单条插入
try singleStudent.save(in: db)

// 批量插入
let students = (0..<100).map { generateStudent() }
try Student.save(students, in: db)
```

### Deleting

```swift
// 全删
try Student.delete(in: db)

// 条件删
try Student.delete(in: db, where: Column("age") < 18)
```

### Updating

```swift
Student.update(in: db, where: Column("name") == "the one") { (assignment) in
    assignment["married"] = false
    assignment["extra"] = Base.null
    assignment["gpa"] = 4.0
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