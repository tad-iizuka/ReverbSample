//
//  ViewController.swift
//  ReverbSample
//
//  Created by Tadashi on 2016/11/03.
//  Copyright © 2016 T@d. All rights reserved.
//

import UIKit
import MediaPlayer

class ViewController: UIViewController {

	var engine: AVAudioEngine!
	var playerNode : AVAudioPlayerNode!
	var audioFile : AVAudioFile!
	var reverb : AVAudioUnitReverb!
	var timer : Timer!
	var completionFlag = false
	var offsetFrame = Int()

	@IBOutlet var slider: UISlider!

	@IBOutlet var playButton: UIButton!
	@IBAction func playButton(_ sender: Any) {

		if playerNode.isPlaying {

			completionFlag = true

		} else {

			self.play(onoff: true)
		}
	}

	@IBOutlet var reverbSwitch: UISwitch!
	@IBAction func reverbSwitch(_ sender: Any) {
	
		self.reverbControl(onoff: (sender as! UISwitch).isOn)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.audioSetup()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	func audioSetup() {
	
		engine = AVAudioEngine()

		playerNode = AVAudioPlayerNode()

		reverb = AVAudioUnitReverb()
		reverb.loadFactoryPreset(.largeHall2)
		reverb.wetDryMix = 50

		engine.attach(playerNode)
		engine.attach(reverb)

		do {
			audioFile = try AVAudioFile(forReading: NSURL(fileURLWithPath: Bundle.main.path(forResource: "Valkyries", ofType: "m4a")!) as URL)
		} catch {
			print(error)
		}

		engine.connect(playerNode, to: engine.mainMixerNode, format: audioFile.processingFormat)
		
		offsetFrame = 0
	}
	
	func reverbControl(onoff: Bool) {

		let status = playerNode.isPlaying

		offsetFrame = Int(self.slider.value)
		
		if status {
		
			playerNode.pause()

			playerNode.stop()

			engine.stop()

		}

		if onoff {

			engine.connect(playerNode, to: reverb, format: audioFile.processingFormat)
			engine.connect(reverb, to: engine.mainMixerNode, format: audioFile.processingFormat)

			playerNode.scheduleSegment(audioFile,
				startingFrame: AVAudioFramePosition(self.slider.value),
				frameCount: AVAudioFrameCount(audioFile.length) - UInt32(self.slider.value),
				at: nil,
				completionHandler: self.completion)

		} else {

			engine.connect(playerNode, to: engine.mainMixerNode, format: audioFile.processingFormat)

			playerNode.scheduleSegment(audioFile,
				startingFrame: AVAudioFramePosition(self.slider.value),
				frameCount: AVAudioFrameCount(audioFile.length) - UInt32(self.slider.value),
				at: nil,
				completionHandler: self.completion)
		}

		if status {

			do {
				try engine.start()
			} catch {
				print(error)
			}

			playerNode.play()
		}
	}
	
	func play(onoff: Bool) {
	
		if onoff {

			playerNode.scheduleSegment(audioFile,
				startingFrame: AVAudioFramePosition(self.slider.value),
				frameCount: AVAudioFrameCount(audioFile.length) - UInt32(self.slider.value),
				at: nil,
				completionHandler: self.completion)

			do {

				try engine.start()

				playerNode.play()

				self.playButton.setImage(UIImage(named: "Stop.png"), for: .normal)

				timer = Timer.scheduledTimer(timeInterval: 0.05,
				target: self, selector: #selector(self.intervalTimer), userInfo: nil, repeats: true)

				self.slider.maximumValue = Float(audioFile.length)

			} catch {
				print(error)
			}

		} else {

			if playerNode.isPlaying {

				playerNode.pause()

				playerNode.stop()

				engine.stop()
				
				offsetFrame = Int(self.slider.value)
			}

			timer.invalidate()

			self.playButton.setImage(UIImage(named: "Play.png"), for: .normal)
		}
	}
	
	func completion() {

		if playerNode.isPlaying {

			completionFlag = true

		}

	}
	
	func intervalTimer() {
	
		if completionFlag {

			self.play(onoff: false)
			
			completionFlag = false
			
			self.slider.value = 0
			
			offsetFrame = 0
			
			return

		}

		if playerNode.isPlaying {

			if let nodeTime = playerNode.lastRenderTime {
				self.slider.value = Float((playerNode.playerTime(forNodeTime: nodeTime)?.sampleTime)!) + Float(offsetFrame)
			}
		}
	}
}
