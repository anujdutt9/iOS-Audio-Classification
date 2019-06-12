//
//  ResultsObserver.swift
//  SoundClassifier
//
//  Created by Anuj Dutt on 6/12/19.
//  Copyright © 2019 Anuj Dutt. All rights reserved.
//
import UIKit
import Foundation
import SoundAnalysis

// Observer object that is called as analysis results are found.
@available(iOS 13.0, *)
class ResultsObserver : NSObject, SNResultsObserving {
    
    weak var vc: ViewController?
    
    func request(_ request: SNRequest, didProduce result: SNResult) {
        
        // Get the top classification.
        guard let result = result as? SNClassificationResult,
            let classification = result.classifications.first else { return }
        
        // Determine the time of this result.
        let formattedTime = String(format: "%.2f", result.timeRange.start.seconds)
        print("Analysis result for audio at time: \(formattedTime)")
        
        let confidence = classification.confidence * 100.0
        let percent = String(format: "%.2f%%", confidence)
        
        // Print the result as Instrument: percentage confidence.
        print("\(classification.identifier): \(percent) confidence.\n")
        
        DispatchQueue.main.async {
            self.vc?.predictedLabel.text = classification.identifier
            self.vc?.predictionConfidence.text = percent
        }
    }
    
    func request(_ request: SNRequest, didFailWithError error: Error) {
        print("The the analysis failed: \(error.localizedDescription)")
    }
    
    func requestDidComplete(_ request: SNRequest) {
        print("The request completed successfully!")
    }
}
