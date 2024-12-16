//
//  KeychainManager.swift
//  MobileProject
//
//  Created by Никита Косянков on 16.12.2024.
//

import Foundation
import Security

enum KeychainError: Error {
    case duplicateItem
    case unknown(status: OSStatus)
}

struct KeychainHelper {
    static let shared = KeychainHelper()

    private init() {}

    func save(_ value: String, forKey key: String) {
        guard let data = value.data(using: .utf8) else { return }

        // Удаляем существующее значение, если оно есть
        delete(forKey: key)

        // Создаем запрос для добавления нового значения
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        if status != errSecSuccess {
            print("Ошибка сохранения в Keychain: \(status)")
        }
    }

    func get(forKey key: String) -> String? {
        // Создаем запрос для извлечения значения
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        } else {
            print("Ошибка извлечения из Keychain: \(status)")
            return nil
        }
    }

    func delete(forKey key: String) {
        // Создаем запрос для удаления значения
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        SecItemDelete(query as CFDictionary)
    }
}
