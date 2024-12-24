import UIKit
import DGCharts

class GlucoseChartViewController: UIViewController, ChartViewDelegate {
    private let chartView = LineChartView()
    private let circleMarker = CircleMarker()
    let infoBubble = ChartInfoBubbleView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupChartView()
        
        // Load and align data
        let alignedData = alignTimestamps(from: ["20241025", "20241026", "20241027"])
        updateChart(with: alignedData)
    }
    
    private func setupChartView() {
        view.addSubview(chartView)
        chartView.translatesAutoresizingMaskIntoConstraints = false
        
        // Calculate height based on golden ratio
        let goldenRatioHeight = UIScreen.main.bounds.width * 0.618
        
        NSLayoutConstraint.activate([
            chartView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,constant: 60.0),
            chartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            chartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            chartView.heightAnchor.constraint(equalToConstant: goldenRatioHeight)
        ])
        
        chartView.rightAxis.enabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = false
        chartView.leftAxis.axisMinimum = 0 // Minimum glucose level
        chartView.leftAxis.axisMaximum = 30 // Default max glucose level
        chartView.legend.enabled = false
        // disable axis annotations
        chartView.xAxis.drawLabelsEnabled = false
        chartView.leftAxis.drawLabelsEnabled = false
        chartView.rightAxis.drawLabelsEnabled = false
        // disable zoom
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = false
        // remove artifacts around chart area
        chartView.xAxis.enabled = true
        chartView.leftAxis.enabled = true
        chartView.rightAxis.enabled = false
        chartView.drawBordersEnabled = false
        chartView.minOffset = 0
        
        // setting up delegate needed for touches handling
        chartView.delegate = self
    }
    
    private func updateChart(with data: [GlucoseData]) {
        // Convert data to chart entries
        let entries = data.map { ChartDataEntry(x: $0.timestamp.timeIntervalSince1970, y: $0.value) }
        
        // Create a LineChartDataSet with interpolated spline mode
        let dataSet = ChartDatasetFactory().makeChartDataset(colorAsset: .first, entries: entries)
        //        LineChartDataSet(entries: entries, label: "Glucose Levels")
        //        dataSet.mode = .cubicBezier // Enable spline interpolation
        //        dataSet.colors = [.systemBlue]
        //        dataSet.lineWidth = 2.0
        //        dataSet.circleColors = [.systemBlue]
        //        dataSet.circleRadius = 0.0
        //        dataSet.drawValuesEnabled = false
        // selected value display settings
        //        dataSet.drawHorizontalHighlightIndicatorEnabled = false // leave only vertical line
        //        dataSet.highlightLineWidth = 2 // vertical line width
        //        dataSet.highlightColor = .systemBlue // vertical line color
        
        // Set data to chart
        chartView.data = LineChartData(dataSet: dataSet)
        
        // Adjust Y-axis dynamically
        if let maxValue = data.map({ $0.value }).max() {
            chartView.leftAxis.axisMaximum = maxValue * 1.05 // Add 5% margin
        }
    }
    
    private func alignTimestamps(from files: [String]) -> [GlucoseData] {
        var allData: [GlucoseData] = []
        
        for file in files {
            if let filePath = Bundle.main.path(forResource: file, ofType: "tsv"),
               let fileContent = try? String(contentsOfFile: filePath) {
                let lines = fileContent.components(separatedBy: .newlines).dropFirst() // Skip header
                for line in lines {
                    let components = line.split(separator: "\t")
                    if components.count == 2,
                       let minutes = Double(components[0]),
                       let mmol = Double(components[1]) {
                        let timestamp = Date(timeIntervalSince1970: (25 * 24 * 60 + minutes) * 60)
                        allData.append(GlucoseData(timestamp: timestamp, value: mmol))
                    }
                }
            }
        }
        
        // Align timestamps to the latest file
        guard let latestTimestamp = allData.last?.timestamp else { return [] }
        return allData.filter { $0.timestamp <= latestTimestamp }
    }
    
    // MARK: - ChartViewDelegate Methods
    
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        print("Selected entry at x: \(entry.x), y: \(entry.y)")
        
        // Update marker position
        circleMarker.offset = CGPoint(x: highlight.xPx, y: highlight.yPx)
        
        // Optionally display additional UI like a tooltip
        showInfoBubble(at: CGPoint(x: highlight.xPx, y: highlight.yPx), value: entry.y)
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        print("Nothing selected")
        infoBubble.removeFromSuperview()
    }
    
    /// Show an info bubble at a specified location with the given value
    private func showInfoBubble(at point: CGPoint, value: Double) {
//        let infoBubble = ChartInfoBubbleView()
        infoBubble.setText(String(format: "Glucose: %.2f mmol/L", value))
        
        // Convert the point to the parent view's coordinate system
        let globalPoint = chartView.convert(point, to: self.view)
        
        // Adjust position to prevent clipping
        let bubbleWidth: CGFloat = 150
        let bubbleHeight: CGFloat = 50
        let xPosition = max(16, min(globalPoint.x - bubbleWidth / 2, self.view.bounds.width - bubbleWidth - 16))
        let yPosition = max(16, globalPoint.y - bubbleHeight - 16)
        
        infoBubble.frame = CGRect(x: xPosition, y: yPosition, width: bubbleWidth, height: bubbleHeight)
        
        // Add the bubble to the parent view
        self.view.addSubview(infoBubble)
        
        // Auto-remove bubble after 2 seconds
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            self.infoBubble.removeFromSuperview()
//        }
    }
}

