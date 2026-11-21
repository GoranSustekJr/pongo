import Foundation
import SQLite3

/// A value in an SQLite column.
public enum SQLValue: Sendable, Hashable {
    case null
    case int(Int)
    case double(Double)
    case text(String)
    case blob(Data)

    public var int: Int? {
        switch self {
        case .int(let value): value
        case .double(let value): Int(value)
        case .text(let value): Int(value)
        default: nil
        }
    }

    public var double: Double? {
        switch self {
        case .int(let value): Double(value)
        case .double(let value): value
        default: nil
        }
    }

    public var text: String? {
        if case .text(let value) = self { return value }
        return nil
    }

    public var blob: Data? {
        if case .blob(let value) = self { return value }
        return nil
    }

    /// Whether the value is a true boolean, stored as 1.
    public var isTrue: Bool { int == 1 }

    /// The column value as JSON, for syncing.
    var json: JSONValue {
        switch self {
        case .null: .null
        case .int(let value): .int(value)
        case .double(let value): .double(value)
        case .text(let value): .string(value)
        case .blob(let value): .string(value.base64EncodedString())
        }
    }

    /// A column value for synced JSON.
    init(json: JSONValue?) {
        switch json {
        case .int(let value): self = .int(value)
        case .double(let value): self = .double(value)
        case .string(let value): self = .text(value)
        case .bool(let value): self = .int(value ? 1 : 0)
        default: self = .null
        }
    }
}

extension SQLValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByNilLiteral {
    public init(stringLiteral value: String) { self = .text(value) }
    public init(integerLiteral value: Int) { self = .int(value) }
    public init(nilLiteral: ()) { self = .null }
}

extension SQLValue {
    init(_ value: String?) { self = value.map(SQLValue.text) ?? .null }
    init(_ value: Data?) { self = value.map(SQLValue.blob) ?? .null }
    init(_ value: Bool) { self = .int(value ? 1 : 0) }
}

/// A row of a query result, by column name.
public typealias SQLRow = [String: SQLValue]

/// Why an SQLite call failed.
public struct SQLiteError: Error, CustomStringConvertible {
    public var description: String
}

/// A connection to an SQLite database file. Not thread safe; the database
/// actor owns it.
final class SQLiteConnection {
    private var handle: OpaquePointer?

    init(path: String) throws {
        guard sqlite3_open(path, &handle) == SQLITE_OK else {
            throw SQLiteError(description: "Can't open \(path)")
        }
    }

    deinit { sqlite3_close(handle) }

    var userVersion: Int {
        get { (try? query("PRAGMA user_version").first?["user_version"]?.int) ?? 0 }
        set { try? execute("PRAGMA user_version = \(newValue)") }
    }

    /// The ID of the latest inserted row.
    var lastInsertID: Int { Int(sqlite3_last_insert_rowid(handle)) }

    /// The number of rows the latest statement changed.
    var changes: Int { Int(sqlite3_changes(handle)) }

    func execute(_ sql: String, _ arguments: [SQLValue] = []) throws {
        let statement = try prepare(sql, arguments)
        defer { sqlite3_finalize(statement) }
        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE || result == SQLITE_ROW else { throw error(sql) }
    }

    func query(_ sql: String, _ arguments: [SQLValue] = []) throws -> [SQLRow] {
        let statement = try prepare(sql, arguments)
        defer { sqlite3_finalize(statement) }
        var rows: [SQLRow] = []
        while true {
            let result = sqlite3_step(statement)
            if result == SQLITE_DONE { break }
            guard result == SQLITE_ROW else { throw error(sql) }
            var row: SQLRow = [:]
            for column in 0..<sqlite3_column_count(statement) {
                let name = String(cString: sqlite3_column_name(statement, column))
                row[name] = value(statement, column)
            }
            rows.append(row)
        }
        return rows
    }

    /// Runs [body] in a transaction, rolling it back if [body] throws.
    func transaction<T>(_ body: () throws -> T) throws -> T {
        try execute("BEGIN")
        do {
            let result = try body()
            try execute("COMMIT")
            return result
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func prepare(_ sql: String, _ arguments: [SQLValue]) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else {
            throw error(sql)
        }
        let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
        for (offset, argument) in arguments.enumerated() {
            let index = Int32(offset + 1)
            switch argument {
            case .null: sqlite3_bind_null(statement, index)
            case .int(let value): sqlite3_bind_int64(statement, index, Int64(value))
            case .double(let value): sqlite3_bind_double(statement, index, value)
            case .text(let value): sqlite3_bind_text(statement, index, value, -1, transient)
            case .blob(let value):
                _ = value.withUnsafeBytes { bytes in
                    sqlite3_bind_blob(statement, index, bytes.baseAddress, Int32(value.count), transient)
                }
            }
        }
        return statement
    }

    private func value(_ statement: OpaquePointer?, _ column: Int32) -> SQLValue {
        switch sqlite3_column_type(statement, column) {
        case SQLITE_INTEGER: return .int(Int(sqlite3_column_int64(statement, column)))
        case SQLITE_FLOAT: return .double(sqlite3_column_double(statement, column))
        case SQLITE_TEXT: return .text(String(cString: sqlite3_column_text(statement, column)))
        case SQLITE_BLOB:
            let count = Int(sqlite3_column_bytes(statement, column))
            guard count > 0, let bytes = sqlite3_column_blob(statement, column) else { return .blob(Data()) }
            return .blob(Data(bytes: bytes, count: count))
        default: return .null
        }
    }

    private func error(_ sql: String) -> SQLiteError {
        SQLiteError(description: "\(String(cString: sqlite3_errmsg(handle))) in \(sql)")
    }
}

/// SQL placeholders for an `IN` clause with [count] values.
func placeholders(_ count: Int) -> String {
    Array(repeating: "?", count: count).joined(separator: ", ")
}
