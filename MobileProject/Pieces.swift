//
//  Tracks.swift
//  MobileProject
//
//  Created by Никита Косянков on 21.05.2025.
//

import SwiftUI
import MapKit

public struct TrackView: View {
    var name: String
    var coordinates: [CLLocationCoordinate2D]
    @Binding var added: Bool
    public var body: some View {
        HStack {
            Text(name)
                .font(.title3)
            Spacer()
            Map() {
                MapPolyline(coordinates: coordinates, contourStyle: .straight)
                    .stroke(Color.red, lineWidth: 5)
            }
            .cornerRadius(12)
            .padding(.horizontal)
            .frame(width: 150, height: 75)
        }
        .padding(.horizontal, 16)
    }
}

struct PieceData {
    var name: String
    var coordinates: [CLLocationCoordinate2D]
    var added: Bool
    var length: Double
}

// Че то явно надо переделать. Тут запросы будут от каждого элемента, как минимум бесшовная пагинация нужна

public struct PiecesList: View {
    var added: Bool
    @State var isLoading: Bool = true
    @State var tracks: [PieceData] = []
    public var body: some View {
        ScrollView {
            if isLoading {
                Text("Загрузка...")
            } else {
                VStack {
                    ForEach($tracks, id: \.name) { $track in
                        NavigationLink(destination: PieceView(name: track.name, coordinates: track.coordinates, length: track.length)) {
                            TrackView(name: track.name, coordinates: track.coordinates, added: $track.added)
                        }
                    }
                }
            }
        }
        .task {
            isLoading = true
            do {
                let pieces: [PiecesData] = try await apiService.getPieces(added: added)
                print(pieces)
                var result: [PieceData] = []
                for piece in pieces {
                    let gpx: Data = try await apiService.getStatic(file: piece.filename)
                    let coors = GPXManager.shared.parseXML(data: gpx)
                    result.append(PieceData(name: piece.name, coordinates: coors, added: true, length: piece.length))
                }
                print("Результат", result)
                tracks = result
            } catch {
                print(error.localizedDescription)
            }
            isLoading = false
        }
    }
}

public struct PieceView: View {
    var name: String
    var coordinates: [CLLocationCoordinate2D]
    var length: Double
    public var body: some View {
        ScrollView {
            VStack {
                Text(name)
                    .font(.headline)
                Map() {
                    MapPolyline(coordinates: coordinates, contourStyle: .straight)
                        .stroke(Color.red, lineWidth: 5)
                }
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.vertical, 8)
                Text("Длина участка - \(length, specifier: "%.2f") км")
                    .font(.headline)
                Text("Таблица лидеров")
                    .font(.headline)
            }
        }
    }
}
