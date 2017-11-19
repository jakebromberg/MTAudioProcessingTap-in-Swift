import MediaToolbox

protocol AudioProcessor: class {
    var initialize: MTAudioProcessingTapInitCallback { get }
    var finalize: MTAudioProcessingTapFinalizeCallback { get }
    var prepare: MTAudioProcessingTapPrepareCallback { get }
    var unprepare: MTAudioProcessingTapUnprepareCallback { get }
    var process: MTAudioProcessingTapProcessCallback { get }
}

internal extension MTAudioProcessingTap {
    static func with<P: AudioProcessor>(processor: P) throws -> MTAudioProcessingTap? {
        var callbacks = MTAudioProcessingTapCallbacks(
            version: kMTAudioProcessingTapCallbacksVersion_0,
            clientInfo: UnsafeMutableRawPointer(Unmanaged.passUnretained(processor).toOpaque()),
            init: processor.initialize,
            finalize: processor.finalize,
            prepare: processor.prepare,
            unprepare: processor.unprepare,
            process: processor.process)
        
        var tap: Unmanaged<MTAudioProcessingTap>?
        
        let err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks, kMTAudioProcessingTapCreationFlag_PostEffects, &tap)
        
        if err != noErr {
            throw NSError(domain: "com.flatcap.audioProcessor", code: Int(err), userInfo: nil)
        }
        
        return tap?.takeRetainedValue()
    }
}

final class LogAudioProcessor: AudioProcessor {
    init() {
        print("LogAudioProcessor")
    }
    
    func tapStorageOutPointee() -> UnsafeMutableRawPointer {
        let result = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        return result
    }
    
    let initialize: MTAudioProcessingTapInitCallback = {
        (tap, clientInfo, tapStorageOut) in
        
        if let clientInfo = clientInfo {
            let typedClientInfo = Unmanaged<LogAudioProcessor>.fromOpaque(clientInfo).takeUnretainedValue()
            print(typedClientInfo)
        }
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
    
    deinit {
        print("dead")
    }
}

