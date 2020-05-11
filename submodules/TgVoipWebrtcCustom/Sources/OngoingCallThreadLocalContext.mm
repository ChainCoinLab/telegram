#import <TgVoip/OngoingCallThreadLocalContext.h>

#import <Foundation/Foundation.h>

#import "api/peerconnection/RTCPeerConnectionFactory.h"
#import "api/peerconnection/RTCSSLAdapter.h"
#import "api/peerconnection/RTCConfiguration.h"
#import "api/peerconnection/RTCIceServer.h"
#import "api/peerconnection/RTCPeerConnection.h"
#import "api/peerconnection/RTCMediaConstraints.h"
#import "api/peerconnection/RTCMediaStreamTrack.h"
#import "api/peerconnection/RTCAudioTrack.h"
#import "api/peerconnection/RTCVideoTrack.h"
#import "api/peerconnection/RTCRtpTransceiver.h"
#import "api/peerconnection/RTCSessionDescription.h"
#import "api/peerconnection/RTCIceCandidate.h"
#import "api/peerconnection/RTCMediaStream.h"
#import "components/video_codec/RTCDefaultVideoDecoderFactory.h"
#import "components/video_codec/RTCDefaultVideoEncoderFactory.h"
#import "components/audio/RTCAudioSession.h"
#import "base/RTCVideoCapturer.h"
#import "api/peerconnection/RTCVideoSource.h"
#import "components/capturer/RTCFileVideoCapturer.h"
#import "components/capturer/RTCCameraVideoCapturer.h"
#import "components/renderer/metal/RTCMTLVideoView.h"
#import "components/renderer/opengl/RTCEAGLVideoView.h"

static void (*InternalVoipLoggingFunction)(NSString *) = NULL;

static void voipLog(NSString* format, ...) {
    va_list args;
    va_start(args, format);
    NSString *string = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    if (InternalVoipLoggingFunction) {
        InternalVoipLoggingFunction(string);
    }
}

@interface NativePeerConnectionDelegate : NSObject <RTCPeerConnectionDelegate> {
    id<OngoingCallThreadLocalContextQueueWebrtcCustom> _queue;
    void (^_didGenerateIceCandidate)(RTCIceCandidate *);
    void (^_didChangeIceState)(OngoingCallStateWebrtcCustom);
}

@end

@implementation NativePeerConnectionDelegate

- (instancetype)initWithQueue:(id<OngoingCallThreadLocalContextQueueWebrtcCustom>)queue didGenerateIceCandidate:(void (^)(RTCIceCandidate *))didGenerateIceCandidate didChangeIceState:(void (^)(OngoingCallStateWebrtcCustom))didChangeIceState {
    self = [super init];
    if (self != nil) {
        _queue = queue;
        _didGenerateIceCandidate = [didGenerateIceCandidate copy];
        _didChangeIceState = [didChangeIceState copy];
    }
    return self;
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {
    switch (stateChanged) {
        case RTCSignalingStateStable:
            _didChangeIceState(OngoingCallStateConnected);
            break;
        case RTCSignalingStateHaveLocalOffer:
            _didChangeIceState(OngoingCallStateInitializing);
            break;
        case RTCSignalingStateHaveLocalPrAnswer:
            _didChangeIceState(OngoingCallStateInitializing);
            break;
        case RTCSignalingStateHaveRemoteOffer:
            _didChangeIceState(OngoingCallStateInitializing);
            break;
        case RTCSignalingStateHaveRemotePrAnswer:
            _didChangeIceState(OngoingCallStateInitializing);
            break;
        default:
            break;
    }
    voipLog(@"didChangeSignalingState: %d", stateChanged);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream {
    voipLog(@"Added stream: %@", stream.streamId);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream {
}

- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection {
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    voipLog(@"IceConnectionState: %d", newState);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {
    voipLog(@"didChangeIceGatheringState: %d", newState);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate {
    [_queue dispatch:^{
        _didGenerateIceCandidate(candidate);
    }];
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates {
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel {
}

@end

@implementation OngoingCallConnectionDescriptionWebrtcCustom

- (instancetype _Nonnull)initWithConnectionId:(int64_t)connectionId ip:(NSString * _Nonnull)ip ipv6:(NSString * _Nonnull)ipv6 port:(int32_t)port peerTag:(NSData * _Nonnull)peerTag {
    self = [super init];
    if (self != nil) {
        _connectionId = connectionId;
        _ip = ip;
        _ipv6 = ipv6;
        _port = port;
        _peerTag = peerTag;
    }
    return self;
}

@end

@interface OngoingCallThreadLocalContextWebrtcCustom () {
    id<OngoingCallThreadLocalContextQueueWebrtcCustom> _queue;
    int32_t _contextId;
    
    bool _isOutgoing;
    void (^_sendSignalingData)(NSData * _Nonnull);
    
    NativePeerConnectionDelegate *_peerConnectionDelegate;

    OngoingCallNetworkTypeWebrtcCustom _networkType;
    NSTimeInterval _callReceiveTimeout;
    NSTimeInterval _callRingTimeout;
    NSTimeInterval _callConnectTimeout;
    NSTimeInterval _callPacketTimeout;
    
    OngoingCallStateWebrtcCustom _state;
    int32_t _signalBars;
    
    RTCPeerConnectionFactory *_peerConnectionFactory;
    
    RTCPeerConnection *_peerConnection;
    
    RTCVideoCapturer *_videoCapturer;
    RTCVideoTrack *_localVideoTrack;
    RTCVideoTrack *_remoteVideoTrack;
    
    bool _receivedRemoteDescription;
    
    
}

@end

@implementation VoipProxyServerWebrtcCustom

- (instancetype _Nonnull)initWithHost:(NSString * _Nonnull)host port:(int32_t)port username:(NSString * _Nullable)username password:(NSString * _Nullable)password {
    self = [super init];
    if (self != nil) {
        _host = host;
        _port = port;
        _username = username;
        _password = password;
    }
    return self;
}

@end

@implementation OngoingCallThreadLocalContextWebrtcCustom

+ (NSString *)version {
    return @"2.8.8";
}

+ (void)setupLoggingFunction:(void (*)(NSString *))loggingFunction {
    InternalVoipLoggingFunction = loggingFunction;
}

+ (void)applyServerConfig:(NSString * _Nullable)__unused data {
    
}

+ (int32_t)maxLayer {
    return 80;
}

- (instancetype _Nonnull)initWithQueue:(id<OngoingCallThreadLocalContextQueueWebrtcCustom> _Nonnull)queue proxy:(VoipProxyServerWebrtcCustom * _Nullable)proxy networkType:(OngoingCallNetworkTypeWebrtcCustom)networkType dataSaving:(OngoingCallDataSavingWebrtcCustom)dataSaving derivedState:(NSData * _Nonnull)derivedState key:(NSData * _Nonnull)key isOutgoing:(bool)isOutgoing primaryConnection:(OngoingCallConnectionDescriptionWebrtcCustom * _Nonnull)primaryConnection alternativeConnections:(NSArray<OngoingCallConnectionDescriptionWebrtcCustom *> * _Nonnull)alternativeConnections maxLayer:(int32_t)maxLayer allowP2P:(BOOL)allowP2P logPath:(NSString * _Nonnull)logPath sendSignalingData:(void (^)(NSData * _Nonnull))sendSignalingData {
    self = [super init];
    if (self != nil) {
        _queue = queue;
        assert([queue isCurrent]);
        
        _isOutgoing = isOutgoing;
        _sendSignalingData = [sendSignalingData copy];
        
        _callReceiveTimeout = 20.0;
        _callRingTimeout = 90.0;
        _callConnectTimeout = 30.0;
        _callPacketTimeout = 10.0;
        _networkType = networkType;
        
        _state = OngoingCallStateInitializing;
        _signalBars = -1;
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            RTCInitializeSSL();
        });
        
        [RTCAudioSession sharedInstance].useManualAudio = true;
        [RTCAudioSession sharedInstance].isAudioEnabled = true;
        
        RTCDefaultVideoDecoderFactory *decoderFactory = [[RTCDefaultVideoDecoderFactory alloc] init];
        RTCDefaultVideoEncoderFactory *encoderFactory = [[RTCDefaultVideoEncoderFactory alloc] init];
        
        _peerConnectionFactory = [[RTCPeerConnectionFactory alloc] initWithEncoderFactory:encoderFactory decoderFactory:decoderFactory];
        
        NSArray<NSString *> *iceServers = @[
            @"stun:stun.l.google.com:19302"
        ];
        
        RTCConfiguration *config = [[RTCConfiguration alloc] init];
        config.iceServers = @[
            [[RTCIceServer alloc] initWithURLStrings:iceServers]
        ];
        config.sdpSemantics = RTCSdpSemanticsUnifiedPlan;
        config.continualGatheringPolicy = RTCContinualGatheringPolicyGatherContinually;
        
        RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:@{ @"DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue }];
        
        __weak OngoingCallThreadLocalContextWebrtcCustom *weakSelf = self;
        
        _peerConnectionDelegate = [[NativePeerConnectionDelegate alloc] initWithQueue:_queue didGenerateIceCandidate:^(RTCIceCandidate *iceCandidate) {
            __strong OngoingCallThreadLocalContextWebrtcCustom *strongSelf = weakSelf;
            if (strongSelf == nil) {
                return;
            }
            [strongSelf sendCandidate:iceCandidate];
        } didChangeIceState: ^(OngoingCallStateWebrtcCustom state) {
            __strong OngoingCallThreadLocalContextWebrtcCustom *strongSelf = weakSelf;
            if (strongSelf == nil) {
                return;
            }
            if (strongSelf.stateChanged) {
                strongSelf.stateChanged(state);
            }
        }];
        
        _peerConnection = [_peerConnectionFactory peerConnectionWithConfiguration:config  constraints:constraints delegate:_peerConnectionDelegate];
        
        NSString *streamId = @"stream";
        
        RTCMediaConstraints *audioConstrains = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:nil optionalConstraints:nil];
        
        RTCAudioSource *audioSource = [_peerConnectionFactory audioSourceWithConstraints:audioConstrains];
        RTCAudioTrack * _Nonnull audioTrack = [_peerConnectionFactory audioTrackWithSource:audioSource trackId:@"audio0"];
        
        [_peerConnection addTrack:audioTrack streamIds:@[streamId]];
        
        RTCVideoSource *videoSource = [_peerConnectionFactory videoSource];
        
        #if TARGET_OS_SIMULATOR
        _videoCapturer = [[RTCFileVideoCapturer alloc] initWithDelegate:videoSource];
        #else
        _videoCapturer = [[RTCCameraVideoCapturer alloc] initWithDelegate:videoSource];
        #endif
        
        _localVideoTrack = [_peerConnectionFactory videoTrackWithSource:videoSource trackId:@"video0"];
        [_peerConnection addTrack:_localVideoTrack streamIds:@[streamId]];
        
        if (isOutgoing) {
            id<OngoingCallThreadLocalContextQueueWebrtcCustom> queue = _queue;
            NSDictionary *mediaConstraints = @{
                kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
                kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue
            };
            
            RTCMediaConstraints *connectionConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mediaConstraints optionalConstraints:nil];
            __weak OngoingCallThreadLocalContextWebrtcCustom *weakSelf = self;
            [_peerConnection offerForConstraints:connectionConstraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
                [queue dispatch:^{
                    __strong OngoingCallThreadLocalContextWebrtcCustom *strongSelf = weakSelf;
                    if (strongSelf == nil) {
                        return;
                    }
                    
                    [strongSelf->_peerConnection setLocalDescription:sdp completionHandler:^(__unused NSError * _Nullable error) {
                        [queue dispatch:^{
                            __strong OngoingCallThreadLocalContextWebrtcCustom *strongSelf = weakSelf;
                            if (strongSelf == nil) {
                                return;
                            }
                            [strongSelf tryAdvertising:sdp];
                        }];
                    }];
                }];
            }];
        }
        
        [self startLocalVideo];
    }
    return self;
}

- (void)dealloc {
    assert([_queue isCurrent]);
}

- (void)tryAdvertising:(RTCSessionDescription *)sessionDescription {
    if (_receivedRemoteDescription) {
        return;
    }
    
    [self sendSdp:sessionDescription];
    __weak OngoingCallThreadLocalContextWebrtcCustom *weakSelf = self;
    [_queue dispatchAfter:1.0 block:^{
        __strong OngoingCallThreadLocalContextWebrtcCustom *strongSelf = weakSelf;
        if (strongSelf == nil) {
            return;
        }
        [strongSelf tryAdvertising:sessionDescription];
    }];
}

- (void)startLocalVideo {
    if (_videoCapturer == nil || ![_videoCapturer isKindOfClass:[RTCCameraVideoCapturer class]]) {
        return;
    }
    RTCCameraVideoCapturer *cameraCapturer = (RTCCameraVideoCapturer *)_videoCapturer;
    AVCaptureDevice *frontCamera = nil;
    for (AVCaptureDevice *device in [RTCCameraVideoCapturer captureDevices]) {
        if (device.position == AVCaptureDevicePositionFront) {
            frontCamera = device;
            break;
        }
    }
    
    if (cameraCapturer == nil) {
        return;
    }
    
    NSArray<AVCaptureDeviceFormat *> *sortedFormats = [[RTCCameraVideoCapturer supportedFormatsForDevice:frontCamera] sortedArrayUsingComparator:^NSComparisonResult(AVCaptureDeviceFormat* lhs, AVCaptureDeviceFormat *rhs) {
        int32_t width1 = CMVideoFormatDescriptionGetDimensions(lhs.formatDescription).width;
        int32_t width2 = CMVideoFormatDescriptionGetDimensions(rhs.formatDescription).width;
        return width1 < width2 ? NSOrderedAscending : NSOrderedDescending;
    }];
    
    AVCaptureDeviceFormat *bestFormat = nil;
    for (AVCaptureDeviceFormat *format in sortedFormats) {
        CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription);
        if (dimensions.width >= 600 || dimensions.height >= 600) {
            bestFormat = format;
            break;
        }
    }
    
    if (bestFormat == nil) {
        return;
    }
    
    AVFrameRateRange *frameRateRange = [[bestFormat.videoSupportedFrameRateRanges sortedArrayUsingComparator:^NSComparisonResult(AVFrameRateRange *lhs, AVFrameRateRange *rhs) {
        if (lhs.maxFrameRate < rhs.maxFrameRate) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }] lastObject];
    
    if (frameRateRange == nil) {
        return;
    }
    
    [cameraCapturer startCaptureWithDevice:frontCamera format:bestFormat fps:27 completionHandler:^(NSError * _Nonnull error) {
    }];
}

- (bool)needRate {
    return false;
}

- (void)stop:(void (^)(NSString *, int64_t, int64_t, int64_t, int64_t))completion {
    if ([_videoCapturer isKindOfClass:[RTCCameraVideoCapturer class]]) {
        RTCCameraVideoCapturer *cameraCapturer = (RTCCameraVideoCapturer *)_videoCapturer;
        [cameraCapturer stopCapture];
    }
    [_peerConnection close];
    if (completion) {
        completion(@"", 0, 0, 0, 0);
    }
}

- (NSString *)debugInfo {
    NSString *version = [self version];
    return [NSString stringWithFormat:@"WebRTC, Version: %@", version];
}

- (NSString *)version {
    return [OngoingCallThreadLocalContextWebrtcCustom version];
}

- (NSData * _Nonnull)getDerivedState {
    return [NSData data];
}

- (void)sendSdp:(RTCSessionDescription *)rtcSdp {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    json[@"messageType"] = @"sessionDescription";
    json[@"sdp"] = rtcSdp.sdp;
    if (rtcSdp.type == RTCSdpTypeOffer) {
        json[@"type"] = @"offer";
    } else if (rtcSdp.type == RTCSdpTypePrAnswer) {
        json[@"type"] = @"prAnswer";
    } else if (rtcSdp.type == RTCSdpTypeAnswer) {
        json[@"type"] = @"answer";
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    if (data != nil) {
        _sendSignalingData(data);
    }
}

- (void)sendCandidate:(RTCIceCandidate *)rtcIceCandidate {
    NSMutableDictionary *json = [[NSMutableDictionary alloc] init];
    json[@"messageType"] = @"iceCandidate";
    json[@"sdp"] = rtcIceCandidate.sdp;
    json[@"mLineIndex"] = @(rtcIceCandidate.sdpMLineIndex);
    if (rtcIceCandidate.sdpMid != nil) {
        json[@"sdpMid"] = rtcIceCandidate.sdpMid;
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:nil];
    if (data != nil) {
        _sendSignalingData(data);
    }
}

- (void)receiveSignalingData:(NSData *)data {
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![json isKindOfClass:[NSDictionary class]]) {
        return;
    }
    NSString *messageType = json[@"messageType"];
    if (![messageType isKindOfClass:[NSString class]]) {
        return;
    }
    
    if ([messageType isEqualToString:@"sessionDescription"]) {
        NSString *sdp = json[@"sdp"];
        if (![sdp isKindOfClass:[NSString class]]) {
            return;
        }
        
        NSString *typeString = json[@"type"];
        if (![typeString isKindOfClass:[NSString class]]) {
            return;
        }
        
        RTCSdpType type;
        if ([typeString isEqualToString:@"offer"]) {
            type = RTCSdpTypeOffer;
        } else if ([typeString isEqualToString:@"prAnswer"]) {
            type = RTCSdpTypePrAnswer;
        } else if ([typeString isEqualToString:@"answer"]) {
            type = RTCSdpTypeAnswer;
        } else {
            return;
        }
        
        if (_receivedRemoteDescription) {
            return;
        }
        _receivedRemoteDescription = true;
        
        RTCSessionDescription *sessionDescription = [[RTCSessionDescription alloc] initWithType:type sdp:sdp];
        
        NSDictionary *mediaConstraints = @{
            kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue,
            kRTCMediaConstraintsOfferToReceiveVideo: kRTCMediaConstraintsValueTrue
        };
        
        RTCMediaConstraints *connectionConstraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mediaConstraints optionalConstraints:nil];
        
        [_peerConnection setRemoteDescription:sessionDescription completionHandler:^(__unused NSError * _Nullable error) {
        }];
        
        if (!_isOutgoing) {
            __weak OngoingCallThreadLocalContextWebrtcCustom *weakSelf = self;
            [_peerConnection answerForConstraints:connectionConstraints completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
                __strong OngoingCallThreadLocalContextWebrtcCustom *strongSelf = weakSelf;
                if (strongSelf == nil) {
                    return;
                }
                
                id<OngoingCallThreadLocalContextQueueWebrtcCustom> queue = strongSelf->_queue;
                [strongSelf->_peerConnection setLocalDescription:sdp completionHandler:^(__unused NSError * _Nullable error) {
                    [queue dispatch:^{
                        __strong OngoingCallThreadLocalContextWebrtcCustom *strongSelf = weakSelf;
                        if (strongSelf == nil) {
                            return;
                        }
                        [strongSelf sendSdp:sdp];
                    }];
                }];
            }];
        }
    } else if ([messageType isEqualToString:@"iceCandidate"]) {
        NSString *sdp = json[@"sdp"];
        if (![sdp isKindOfClass:[NSString class]]) {
            return;
        }
        
        NSNumber *mLineIndex = json[@"mLineIndex"];
        if (![mLineIndex isKindOfClass:[NSNumber class]]) {
            return;
        }
        
        NSString *sdpMidString = json[@"sdpMid"];
        NSString *sdpMid = nil;
        if ([sdpMidString isKindOfClass:[NSString class]]) {
            sdpMid = sdpMidString;
        }
        
        RTCIceCandidate *iceCandidate = [[RTCIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:[mLineIndex intValue] sdpMid:sdpMid];
        voipLog(@"didReceiveIceCandidate: %@", iceCandidate);
        [_peerConnection addIceCandidate:iceCandidate];
    }
}

- (void)setIsMuted:(bool)isMuted {
    for (RTCRtpTransceiver *transceiver in _peerConnection.transceivers) {
        if ([transceiver isKindOfClass:[RTCAudioTrack class]]) {
            RTCAudioTrack *audioTrack = (RTCAudioTrack *)transceiver;
            [audioTrack setIsEnabled:!isMuted];
        }
    }
}

- (void)setNetworkType:(OngoingCallNetworkTypeWebrtcCustom)networkType {
}

- (void)getRemoteCameraView:(void (^_Nonnull)(UIView * _Nullable))completion {
    if (_remoteVideoTrack == nil) {
        for (RTCRtpTransceiver *transceiver in _peerConnection.transceivers) {
            if (transceiver.mediaType == RTCRtpMediaTypeVideo && [transceiver.receiver.track isKindOfClass:[RTCVideoTrack class]]) {
                _remoteVideoTrack = (RTCVideoTrack *)transceiver.receiver.track;
                break;
            }
        }
    }
    
    RTCVideoTrack *remoteVideoTrack = _remoteVideoTrack;
    dispatch_async(dispatch_get_main_queue(), ^{
        #if false && TARGET_OS_SIMULATOR
        RTCEAGLVideoView *remoteRenderer = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
        [remoteVideoTrack addRenderer:remoteRenderer];
        completion(remoteRenderer);
        #else
        RTCMTLVideoView *remoteRenderer = [[RTCMTLVideoView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 240.0f)];
        remoteRenderer.videoContentMode = UIViewContentModeScaleAspectFill;
        [remoteVideoTrack addRenderer:remoteRenderer];
        completion(remoteRenderer);
        #endif
    });
}

@end
