import Foundation
import Security

/// Keeps the refresh token in the device Keychain. It is available after the first unlock, but never synced to
/// iCloud or copied to another device.
final class SecureTokenStore {
  private let service = "app.velomine.velomine"
  private let account = "refresh-token"

  private func baseQuery() -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
    ]
  }

  func read() -> String? {
    var query = baseQuery()
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne

    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
          let data = item as? Data else {
      return nil
    }
    return String(data: data, encoding: .utf8)
  }

  func write(_ token: String) -> Bool {
    guard let data = token.data(using: .utf8) else { return false }
    let query = baseQuery()
    let attributes: [String: Any] = [kSecValueData as String: data]

    let updated = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
    if updated == errSecSuccess { return true }
    guard updated == errSecItemNotFound else { return false }

    var added = query
    added[kSecValueData as String] = data
    added[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    return SecItemAdd(added as CFDictionary, nil) == errSecSuccess
  }

  func clear() -> Bool {
    let status = SecItemDelete(baseQuery() as CFDictionary)
    return status == errSecSuccess || status == errSecItemNotFound
  }
}
