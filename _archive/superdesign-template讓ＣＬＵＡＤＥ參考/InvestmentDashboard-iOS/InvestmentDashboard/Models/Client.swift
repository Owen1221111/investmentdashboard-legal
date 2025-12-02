import Foundation
import CloudKit

// MARK: - Client Model (CloudKit整合版本)
struct Client: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var createdDate: Date

    init(id: UUID = UUID(), name: String, email: String = "", createdDate: Date = Date()) {
        self.id = id
        self.name = name
        self.email = email
        self.createdDate = createdDate
    }

    // MARK: - CloudKit Support
    static let recordType = "Client"

    var recordID: CKRecord.ID {
        CKRecord.ID(recordName: id.uuidString)
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: Client.recordType, recordID: recordID)
        record["name"] = name
        record["email"] = email
        record["createdDate"] = createdDate
        return record
    }

    init?(from record: CKRecord) {
        guard
            let name = record["name"] as? String,
            let email = record["email"] as? String,
            let createdDate = record["createdDate"] as? Date,
            let id = UUID(uuidString: record.recordID.recordName)
        else {
            return nil
        }

        self.id = id
        self.name = name
        self.email = email
        self.createdDate = createdDate
    }
}

// MARK: - Extensions
extension Client: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Client, rhs: Client) -> Bool {
        lhs.id == rhs.id
    }
}

extension Client {
    static var sampleClients: [Client] {
        [
            Client(name: "張先生", email: "chang@example.com"),
            Client(name: "王女士", email: "wang@example.com"),
            Client(name: "李先生", email: "li@example.com"),
            Client(name: "陳女士", email: "chen@example.com")
        ]
    }
}