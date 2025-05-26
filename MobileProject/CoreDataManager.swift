//
//  CoreDataManager.swift
//  MobileProject
//
//  Created by Никита Косянков on 02.04.2025.
//

import CoreData
import CoreLocation

class CoreDataManager {
    static let shared = CoreDataManager()
    
    lazy var persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "TracksModel")
        
        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load persistent stores: \(error.localizedDescription)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    
    func clearDatabase() {
        let context = persistentContainer.viewContext
        let entities = persistentContainer.managedObjectModel.entities
        
        for entity in entities {
            guard let name = entity.name else { continue }
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
                print("Сущность \(name) успешно очищена.")
            } catch {
                print("Ошибка удаления данных сущности \(name): \(error)")
            }
        }
        context.reset()
    }
        
    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Ошибка сохранения контекста: \(error)")
            }
        }
    }
    
    func getTrainingStats(filename: String) async -> TrainingStats? {
        let fetchRequest: NSFetchRequest<Tracks> = Tracks.fetchRequest()
        let tracksArray = try? CoreDataManager.shared.context.fetch(fetchRequest)
        for track in tracksArray ?? [] {
            if track.name == filename {
                let file = try? await apiService.getGPX(file: filename)
                let coords: [CLLocationCoordinate2D]
                if let file = file {
                    coords = GPXManager.shared.parseXML(data: file)
                } else {
                    coords = []
                }
                let stats = TrainingStats(name: track.name!, createdAt: track.createdAt! , distance: track.distance, time: Int(track.time), coords: coords)
                return stats
            }
        }
        return nil
    }
    
    func getNotPublishedTracks() async -> [String] {
        let fetchRequest: NSFetchRequest<Tracks> = Tracks.fetchRequest()
        let tracksArray = try? CoreDataManager.shared.context.fetch(fetchRequest)
        var tracks: [String] = []
        for track in tracksArray ?? [] {
            if track.isPublished == false {
                tracks.append(track.name!)
            }
        }
        return tracks
    }
        
    private init() { }
}

struct TrainingStats {
    var name: String
    var createdAt: Date
    var distance: Double
    var time: Int
    var coords: [CLLocationCoordinate2D]
}
