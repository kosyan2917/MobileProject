//
//  ViewController.swift
//  MobileProject
//
//  Created by Никита Косянков on 12.12.2024.
//

import SwiftUI
import MapKit

struct TrainingView: View {
    var filename: String
    var colors: [Color] = [Color.blue, Color.green, Color.yellow, Color.orange, Color.pink]
    @State var isLoading = true
    @State var time: String = "00:00:00"
    @State var pace: Double = 0
    @State var distance: Double = 0
    @State var createdAt: Date?
    @State var locations2d: [CLLocationCoordinate2D] = []
    @State var errorText: String?
    @State var piecesStats: [PieceStats] = []
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if isLoading {
                    Text("Загрузка...")
                } else if let error = errorText {
                    Text(error)
                } else {
                    Text("Тренировка от \(createdAt ?? Date(), style: .date)")
                        .font(.title2)
                    HStack(spacing: 16) {
                        MetricView(title: "Время", value: time)
                        MetricView(title: "Средняя скорость", value: String(format: "%.2f km/h", pace))
                        MetricView(title: "Дистанция", value: String(format: "%.2f km", distance))
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    Text("Маршрут:")
                        .font(.title2)
                    Map() {
                        MapPolyline(coordinates: locations2d, contourStyle: .straight)
                            .stroke(Color.red, lineWidth: 5)
                        ForEach(piecesStats.indices, id: \.self) { index in
                            MapPolyline(coordinates: piecesStats[index].coords, contourStyle: .straight)
                                .stroke(colors[index], lineWidth: 5)
                        }
                    }
                    .frame(height: 400)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    Text("Пройденные участки")
                        .font(.title2)
                    VStack {
                        ForEach(piecesStats, id: \.name) { stat in
                            VStack(alignment: .leading) {
                                Text(stat.name)
                                    .font(.title3)
                                Text("Время: \(formatTime(totalSeconds: stat.time))")
                                    .font(.title3)
                                Map() {
                                    MapPolyline(coordinates: stat.coords, contourStyle: .straight)
                                        .stroke(Color.red, lineWidth: 5)
                                }
                                .cornerRadius(12)
                                .padding(.horizontal)
                                .frame(height: 400)
                            }
                        }
                    }
                }
            }
            .task {
                isLoading = true
                guard let stats = await CoreDataManager.shared.getTrainingStats(filename: filename) else {
                    errorText = "Не удалось загрузить данные о тренировке"
                    return
                }
                time = formatTime(totalSeconds: stats.time)
                pace = stats.distance / Double(stats.time) * 3600
                distance = stats.distance
                createdAt = stats.createdAt
                locations2d = stats.coords
                do {
                    let pstats = try await apiService.calculatePieces(filename: filename)
                    print(pstats)
                    for stat in pstats {
                        let pieceGpx = try await apiService.getStatic(file: stat.path)
                        let pieceCoords = GPXManager.shared.parseXML(data: pieceGpx)
                        piecesStats.append(PieceStats(name: stat.name, time: stat.time, coords: pieceCoords))
                    }
                } catch {
                    errorText = "Произошла ошибка при расчете участков"
                    print(error.localizedDescription)
                }
                isLoading = false
            }
        }
    }
}

struct PieceStats {
    var name: String
    var time: Int
    var coords: [CLLocationCoordinate2D]
}

func formatTime(totalSeconds: Int) -> String {
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
}

func formatDateFromUnixTimestamp(
    _ secondsSince1970: TimeInterval,
    format: String = "yyyy-MM-dd HH:mm:ss"
) -> String {
    let date = Date(timeIntervalSince1970: secondsSince1970)
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.timeZone = .current
    return formatter.string(from: date)
}

enum GPXError: Error {
    case fileNameOrTokenEqualsNil
}
enum parsingError: Error {
    case noSuchFile(file: String)
    case readingError(file: String)
}
