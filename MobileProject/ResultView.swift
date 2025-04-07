import SwiftUI
import MapKit

struct ResultView: View {
    var time: String
    var elapsed: Int
    var distance: Double
    var pace: Double
    var locations: [CLLocation]
    var onTapped: ([CLLocation], Double, Int) -> Void
    var locations2d: [CLLocationCoordinate2D] {
        var locs: [CLLocationCoordinate2D] = []
        for location in locations {
            locs.append(CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude))
        }
        return locs
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Результат")
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
            }
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            Button(action: {
                onTapped(locations, distance, elapsed)
            }) {
                Text("Сохранить")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

struct MetricView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(value)
                .font(.title2)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .bold()
                .foregroundColor(.black)
        }
    }
}


//#Preview {
//    ResultView(time: "00:45:28", distance: 10.223, pace: 5.345)
//}
