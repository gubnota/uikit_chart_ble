import UIKit
import DGCharts

// Glucose data model
struct GlucoseData {
    let timestamp: Date
    let value: Double
}

func alignTimestamps(from files: [String]) -> [GlucoseData] {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // Adjust based on TSV format

    var allData: [GlucoseData] = []

    for file in files {
        guard let filePath = Bundle.main.path(forResource: file, ofType: "tsv"),
              let content = try? String(contentsOfFile: filePath) else {
            print("Could not load file: \(file)")
            continue
        }

        let lines = content.split(separator: "\n")
        for line in lines {
            let components = line.split(separator: "\t")
            guard components.count >= 2,
                  let timestamp = dateFormatter.date(from: String(components[0])),
                  let value = Double(components[1]) else {
                continue
            }
            allData.append(GlucoseData(timestamp: timestamp, value: value))
        }
    }

    // Align to the latest timestamp
    guard let latestTimestamp = allData.map({ $0.timestamp }).max() else {
        return []
    }

    return allData.map {
        let timeOffset = latestTimestamp.timeIntervalSince($0.timestamp)
        return GlucoseData(
            timestamp: $0.timestamp.addingTimeInterval(timeOffset),
            value: $0.value
        )
    }
}


/// Custom marker for highlighting selected values on the graph
final class CircleMarker: MarkerView {
    override func draw(context: CGContext, point: CGPoint) {
        super.draw(context: context, point: point)
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.blue.cgColor)
        context.setLineWidth(2)

        let radius: CGFloat = 8
        let rectangle = CGRect(
            x: point.x - radius,
            y: point.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        context.addEllipse(in: rectangle)
        context.drawPath(using: .fillStroke)
    }
}

/// Custom bubble view for displaying additional information
final class ChartInfoBubbleView: UIView {
    private let label = UILabel()

    init() {
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = UIColor.white.withAlphaComponent(1)
        layer.cornerRadius = 8
        label.textColor = .black
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        layer.borderWidth = 2
        layer.borderColor = UIColor.blue.cgColor
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
        ])
    }

    func setText(_ text: String) {
        label.text = text
    }
}
