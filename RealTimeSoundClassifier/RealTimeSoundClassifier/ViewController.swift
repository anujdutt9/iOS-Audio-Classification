//
//  ViewController.swift
//  SoundClassifier
//
//  Created by Anuj Dutt on 6/4/19.
//  Copyright © 2019 Anuj Dutt. All rights reserved.
//

// Steps to Make Changes:
// Just Delete the Existing CoreML Model [Remove Reference].
// Drag and Drop the New Model under Sound Classifier

import UIKit
import CoreML
import SoundAnalysis
import AVFoundation

@available(iOS 13.0, *)
class ViewController: UIViewController {
    
    @IBOutlet weak var predictedLabel: UITextField!
    @IBOutlet weak var predictionConfidence: UITextField!
    
    // Audio Engine
    var audioEngine = AVAudioEngine()
    
    // Streaming Audio Analyzer
    var streamAnalyzer: SNAudioStreamAnalyzer!
    
    // Serial dispatch queue used to analyze incoming audio buffers.
    let analysisQueue = DispatchQueue(label: "com.apple.AnalysisQueue")

    var resultsObserver: ResultsObserver!
    
    // Instantiate the ML Model
    lazy var envSceneClassifier = EnvSceneClassification()
    lazy var model: MLModel = envSceneClassifier.model
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.startAudioEngine()
        
        // Get the native audio format of the engine's input bus.
        let inputFormat = self.audioEngine.inputNode.inputFormat(forBus: 0)

        // Create a new stream analyzer.
        streamAnalyzer = SNAudioStreamAnalyzer(format: inputFormat)

        // Create a new observer that will be notified of analysis results.
        // Keep a strong reference to this object.
        resultsObserver = ResultsObserver()
        resultsObserver.vc = self

        do {
            // Prepare a new request for the trained model.
            let request = try SNClassifySoundRequest(mlModel: model)
            try streamAnalyzer.add(request, withObserver: resultsObserver)
        } catch {
            print("Unable to prepare request: \(error.localizedDescription)")
            return
        }

        // Install an audio tap on the audio engine's input node.
        self.audioEngine.inputNode.installTap(onBus: 0,
                                         bufferSize: 8192, // 8k buffer
        format: inputFormat) { buffer, time in
            // Analyze the current audio buffer.
            self.analysisQueue.async {
                self.streamAnalyzer.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }
        self.startAudioEngine()
        print("Result....")
    }
    
    // Function to Start Audio Engine for Recording Audio
    func startAudioEngine() {
        do {
            // Start the stream of audio data.
            try self.audioEngine.start()
        } catch {
            print("Unable to start AVAudioEngine: \(error.localizedDescription)")
        }
    }
}

