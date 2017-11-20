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
        self.observationToken = self.playerItem.observe(\.status, changeHandler: { (playerItem, change) in
            
            let audioMix = AVMutableAudioMix()
            audioMix.inputParameters = self.playerItem.tracks
                .filter { $0.assetTrack.mediaType == .audio }
                .map { playerItemTrack -> AVAudioMixInputParameters in
                    let inputParams = AVMutableAudioMixInputParameters(track: playerItemTrack.assetTrack)
                    inputParams.audioTapProcessor = self.tap
                    return inputParams
                }
            
            self.playerItem.audioMix = audioMix
            self.player.play()
        })
        
		return true
	}
    
    lazy var tap: MTAudioProcessingTap? = {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            init: self.initialize,
            finalize: self.finalize,
            prepare: self.prepare,
            unprepare: self.unprepare,
            process: self.process)
        
        var tap: Unmanaged<MTAudioProcessingTap>?
        
        let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        
        return tap?.takeRetainedValue()
    }()
    
    let initialize: MTAudioProcessingTapInitCallback = {
        (tap, clientInfo, tapStorageOut) in
        
        tapStorageOut.pointee = clientInfo
        
        
        print("init \(tap, clientInfo, tapStorageOut)\n")
    }
    
    let finalize: MTAudioProcessingTapFinalizeCallback = {
        (tap) in
        print("finalize \(tap)\n")
    }
    
    let prepare: MTAudioProcessingTapPrepareCallback = {
        (tap, b, c) in
        print("prepare: \(tap, b, c)\n")
    }
    
    let unprepare: MTAudioProcessingTapUnprepareCallback = {
        (tap) in
        print("unprepare \(tap)\n")
    }
    
    let process: MTAudioProcessingTapProcessCallback = {
        (tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut) in
        print("callback \(tap, numberFrames, flags, bufferListInOut, numberFramesOut, flagsOut)\n")
        
        let status = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, nil, numberFramesOut)
        print("get audio: \(status)\n")
    }
}
