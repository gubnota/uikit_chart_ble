//
//  ChartDataset.swift
//
/// Factory preparing dataset for a single chart
import DGCharts
import UIKit

/// Abstraction above UIColor
enum DataColor {
    case first
    case second
    case third

    var color: UIColor {
        switch self {
        case .first: return UIColor.blue //UIColor(red: 56/255, green: 58/255, blue: 209/255, alpha: 1)
        case .second: return UIColor(red: 235/255, green: 113/255, blue: 52/255, alpha: 1)
        case .third: return UIColor(red: 52/255, green: 235/255, blue: 143/255, alpha: 1)
        }
    }
}

struct ChartDatasetFactory {
    func makeChartDataset(
        colorAsset: DataColor,
        entries: [ChartDataEntry]
    ) -> LineChartDataSet {
        var dataSet = LineChartDataSet(entries: entries, label: "")

        // chart main settings
        dataSet.setColor(colorAsset.color)
        dataSet.lineWidth = 2
        dataSet.mode = .cubicBezier // curve smoothing
        dataSet.drawValuesEnabled = false // disble values
        dataSet.drawCirclesEnabled = false // disable circles
        dataSet.drawFilledEnabled = true // gradient setting

        // settings for picking values on graph
        dataSet.drawHorizontalHighlightIndicatorEnabled = false // leave only vertical line
        dataSet.highlightLineWidth = 2 // vertical line width
        dataSet.highlightColor = colorAsset.color // vertical line color

        addGradient(to: &dataSet, colorAsset: colorAsset)

        return dataSet
    }
}

private extension ChartDatasetFactory {
    func addGradient(
        to dataSet: inout LineChartDataSet,
        colorAsset: DataColor
    ) {
        let mainColor = colorAsset.color.withAlphaComponent(0.5)
        let secondaryColor = colorAsset.color.withAlphaComponent(0)
        let colors = [
            mainColor.cgColor,
            secondaryColor.cgColor,
            secondaryColor.cgColor
        ] as CFArray
        let locations: [CGFloat] = [0, 0.79, 1]
        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors,
            locations: locations
        ) {
            dataSet.fill = LinearGradientFill(gradient: gradient, angle: 270)
        }
    }
}
