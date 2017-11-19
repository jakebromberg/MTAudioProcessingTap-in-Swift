import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

    var player: AVPlayer!
    lazy var playerItem: AVPlayerItem = {
        let url = URL(string: "http://audio-mp3.ibiblio.org:8000/wxyc.mp3")!
        return AVPlayerItem(url: url)
    }()
    
    let processor = LogAudioProcessor()
    var observationToken: Any?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.player = AVPlayer(playerItem: self.playerItem)
        self.observationToken = self.playerItem.observe(\.status, changeHandler: { (player, change) in
            do {
                let audioMix = AVMutableAudioMix()
                audioMix.inputParameters = try self.playerItem.tracks
                    .filter { $0.assetTrack.mediaType == .audio }
                    .map { playerItemTrack -> AVAudioMixInputParameters in
                        let audioTrack = playerItemTrack.assetTrack
                        let inputParams = AVMutableAudioMixInputParameters(track: audioTrack)
                        inputParams.audioTapProcessor = try MTAudioProcessingTap.with(processor: self.processor)
                        return inputParams
                    }
                
                self.player.currentItem?.audioMix = audioMix
                self.player.play()
            } catch {
                return
            }
        })
        
		return true
	}
}
