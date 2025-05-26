//
//  GPXFIleManager.swift
//  MobileProject
//
//  Created by Никита Косянков on 06.04.2025.
//


// Вероятно сюда и парсер с генератором gpx закинуть надо

import Foundation

class GPXFileManager {
    
    static let shared = GPXFileManager()
    
    func getTracksDirectory() -> URL? {
        let fileManager = FileManager.default
        
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        var tracksDirectory = appSupportURL.appendingPathComponent("MyTracks", isDirectory: true)
        
        if !fileManager.fileExists(atPath: tracksDirectory.path) {
            do {
                try fileManager.createDirectory(at: tracksDirectory, withIntermediateDirectories: true, attributes: nil)
                
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try tracksDirectory.setResourceValues(resourceValues)
            } catch {
                print("Ошибка при создании или настройке директории: \(error)")
                return nil
            }
        }
        
        return tracksDirectory
    }

    func saveTrackFile(fileName: String, data: Data) {
        guard let directory = getTracksDirectory() else {
            print("Не удалось получить директорию для треков.")
            return
        }
        
        let fileURL = directory.appendingPathComponent(fileName+".gpx")
        
        do {
            try data.write(to: fileURL)
            print("Файл успешно сохранён по пути: \(fileURL.path)")
        } catch {
            print("Ошибка сохранения файла: \(error)")
        }
    }
    
    func readTrackFile(fileName: String) -> Data? {
        guard let directory = getTracksDirectory() else {
            print("Не удалось получить директорию для треков.")
            return nil
        }
        
        let fileURL = directory.appendingPathComponent(fileName+".gpx")
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            print("Файл успешно прочитан по пути: \(fileURL.path)")
            return fileData
        } catch {
            print("Ошибка чтения файла: \(error)")
            return nil
        }
    }
}
