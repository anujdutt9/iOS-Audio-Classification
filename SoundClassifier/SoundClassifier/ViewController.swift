//
//  ViewController.swift
//  SoundClassifier
//
//  Created by Anuj Dutt on 6/4/19.
//  Copyright © 2019 Anuj Dutt. All rights reserved.
//

import UIKit
import CoreML
import AVFoundation

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var selectedAudioFileName: UITextField!
    @IBOutlet weak var mlModelPrediction: UITextView!
    @IBOutlet weak var predictionImage: UIImageView!
    @IBOutlet weak var audioPicker: UIPickerView!
    
    var pickerData: [String] = [String]()
    var selectedAudioFile = ""
    var selectedAudioFileURL: URL!
    var audioPlayer: AVAudioPlayer?
    
    // Instantiate the ML Model
    let model:EnvSceneClassification = EnvSceneClassification()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mlModelPrediction.text = ""
        self.audioPicker.delegate = self
        self.audioPicker.dataSource = self
        self.pickerData = ["clock_tick", "crackling_fire", "chainsaw", "sneezing", "sea_waves", "rooster", "helicopter", "rain", "baby_crying", "cry", "dog_barking"]
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Selected an Audio File to Play
        self.selectedAudioFileName.text = self.pickerData[row]
        self.selectedAudioFile = self.pickerData[row]
        // Get Audio File Paths as URL
        if let audioFileURL = Bundle.main.url(forResource: self.selectedAudioFile, withExtension: "wav"){
            print("Audio File URL: \(audioFileURL)")
            self.selectedAudioFileURL = audioFileURL
        }
    }
    
    // Function to Play selected Audio File
    @IBAction func playSelectedFile(_ sender: Any) {
        //print("\n\nSlected File: \(self.selectedAudioFileURL)\n\n")
        // To Do: Play Audio File
        let audioSession = AVAudioSession.sharedInstance()
        do {
            //try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: kAudioSessionProperty_OverrideCategoryDefaultToSpeaker)
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            audioPlayer = try AVAudioPlayer(contentsOf: self.selectedAudioFileURL)
            audioPlayer!.prepareToPlay()
            audioPlayer!.volume = 1.0
            audioPlayer?.play()
            //audioPlayer?.numberOfLoops = 1
        }
        catch{
            fatalError("No audio file selected.")
        }
    }
    
    // Function to Process Audio and Make Predictions
    @IBAction func makePredictions(_ sender: Any) {
        self.classifyAudio(audioFileName: self.selectedAudioFileURL)
    }
    
    // Function to Classify Audio File in one of 10 classes
    func classifyAudio(audioFileName: URL){
        // Read Audio File
        var audioFile: AVAudioFile!
        
        do{
            print("Log: Opening wav file.\n")
            audioFile = try AVAudioFile(forReading: audioFileName)
        }
        catch{
            fatalError("Unable to Open Wav File.")
        }
        
        print("Log: Audio File Length: \(audioFile.length)\n")
        assert(audioFile.fileFormat.sampleRate == 16000.0, "Sample rate incorrect, must be 16 KHz.")
        
        // Define Audio Buffer
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: UInt32(audioFile.length))
        
        // Read Audio File into Audio Buffer
        do{
            print("Log: Reading wav file.\n")
            try audioFile.read(into: buffer!)
        }
        catch{
            fatalError("Error reading Buffer.")
        }
        
        guard let bufferData = try buffer?.floatChannelData else {
            fatalError("Cannot get a float handle to buffer.")
        }
        
        // Chunk audio data and send to CoreML Model for Processing
        let windowSize = 15600
        print("Log: Creating audio window.\n")
        guard let audioData = try? MLMultiArray(shape: [windowSize as NSNumber], dataType: MLMultiArrayDataType.float32) else {
            fatalError("Cannot create MLMUltiArray.")
        }
        
        // Ignore any Partial Window at end of audio
        var results = [Dictionary<String, Double>]()
        let windowNumber = audioFile.length / Int64(windowSize)
        for windowIndex in 0..<Int(windowNumber) {
            let offset = windowIndex * windowSize
            for i in 0...windowSize {
                audioData[i] = NSNumber.init(value: bufferData[0][offset + i])
            }
            
            // Define ML Model Input Data
            let modelInput = EnvSceneClassificationInput(audio: audioData)
            print("Log: Making Predictions for Audio.\n")
            guard let modelOutput = try? model.prediction(input: modelInput) else {
                fatalError("Error calling predict")
            }
            results.append(modelOutput.categoryProbability)
        }
        
        // Average model results from each chunk
        var prob_sums = Dictionary<String, Double>()
        for r in results {
            for (label, prob) in r {
                prob_sums[label] = (prob_sums[label] ?? 0) + prob
            }
        }
        
        var max_sum:Float = 0.0
        var max_sum_label = ""
        for (label, sum) in prob_sums {
            if Float(sum) > max_sum {
                max_sum = Float(sum)
                max_sum_label = label
            }
        }
        
        let most_probable_label = max_sum_label
        let probability = max_sum / Float(results.count)
        print("Output: The Model thinks it's a: \(most_probable_label), with a probability of: \(probability)\n")
        self.mlModelPrediction.text = "The Model thinks it's a: \(most_probable_label), with a probability of: \(probability)"
    }
    
}
