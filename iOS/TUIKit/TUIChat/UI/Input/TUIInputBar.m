//
//  TUIInputBar.m
//  UIKit
//
//  Created by kennethmiao on 2018/9/18.
//  Copyright © 2018年 Tencent. All rights reserved.
//

#import "TUIInputBar.h"
#import "TUIRecordView.h"
#import "TUIDefine.h"
#import "TUITool.h"
#import "TUIDefine.h"
#import <AVFoundation/AVFoundation.h>
#import "ReactiveObjC/ReactiveObjC.h"
#import "UIView+TUILayout.h"
#import "TUIDarkModel.h"
#import "TUIGlobalization.h"
#import "TUIThemeManager.h"
#import "NSTimer+Safe.h"

@interface TUIInputBar() <UITextViewDelegate, AVAudioRecorderDelegate>
@property (nonatomic, strong) TUIRecordView *record;
@property (nonatomic, strong) NSDate *recordStartTime;
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) NSTimer *recordTimer;

@property (nonatomic, assign) BOOL isFocusOn;
@property (nonatomic, strong) NSTimer *sendTypingStatusTimer;
@property (nonatomic, assign) BOOL allowSendTypingStatusByChangeWord;
@end

@implementation TUIInputBar

- (void)dealloc {
    
    if(_sendTypingStatusTimer){
        [_sendTypingStatusTimer invalidate];
        _sendTypingStatusTimer = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        [self setupViews];
        [self defaultLayout];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onThemeChanged) name:TUIDidApplyingThemeChangedNotfication object:nil];
    }
    return self;
}

- (void)setupViews
{
    self.backgroundColor = TUIChatDynamicColor(@"chat_input_controller_bg_color", @"#EBF0F6");

    _lineView = [[UIView alloc] init];
    _lineView.backgroundColor = TUICoreDynamicColor(@"separator_color", @"#FFFFFF");

    _micButton = [[UIButton alloc] init];
    [_micButton addTarget:self action:@selector(clickVoiceBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_micButton setImage:TUIChatBundleThemeImage(@"chat_ToolViewInputVoice_img",@"ToolViewInputVoice")         forState:UIControlStateNormal];
    [_micButton setImage: TUIChatBundleThemeImage(@"chat_ToolViewInputVoiceHL_img", @"ToolViewInputVoiceHL")
                forState:UIControlStateHighlighted];
    [self addSubview:_micButton];

    _faceButton = [[UIButton alloc] init];
    [_faceButton addTarget:self action:@selector(clickFaceBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_faceButton setImage: TUIChatBundleThemeImage(@"chat_ToolViewEmotion_img", @"ToolViewEmotion")
                 forState:UIControlStateNormal];
    [_faceButton setImage: TUIChatBundleThemeImage(@"chat_ToolViewEmotionHL_img",@"ToolViewEmotionHL")
                 forState:UIControlStateHighlighted];
    [self addSubview:_faceButton];

    
    _keyboardButton = [[UIButton alloc] init];
    [_keyboardButton addTarget:self action:@selector(clickKeyboardBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_keyboardButton setImage:TUIChatBundleThemeImage(@"chat_ToolViewKeyboard_img", @"ToolViewKeyboard") forState:UIControlStateNormal];
    [_keyboardButton setImage:TUIChatBundleThemeImage(@"chat_ToolViewKeyboardHL_img", @"ToolViewKeyboardHL")
                     forState:UIControlStateHighlighted];
    _keyboardButton.hidden = YES;
    [self addSubview:_keyboardButton];

    _moreButton = [[UIButton alloc] init];
    [_moreButton addTarget:self action:@selector(clickMoreBtn:) forControlEvents:UIControlEventTouchUpInside];
    [_moreButton setImage:TUIChatBundleThemeImage(@"chat_TypeSelectorBtn_Black_img",@"TypeSelectorBtn_Black")          forState:UIControlStateNormal];
    [_moreButton setImage:TUIChatBundleThemeImage(@"chat_TypeSelectorBtnHL_Black_img",@"TypeSelectorBtnHL_Black")
                 forState:UIControlStateHighlighted];
    [self addSubview:_moreButton];

    _recordButton = [[UIButton alloc] init];
    [_recordButton.titleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [_recordButton addTarget:self action:@selector(recordBtnDown:) forControlEvents:UIControlEventTouchDown];
    [_recordButton addTarget:self action:@selector(recordBtnUp:) forControlEvents:UIControlEventTouchUpInside];
    [_recordButton addTarget:self action:@selector(recordBtnCancel:) forControlEvents:UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    [_recordButton addTarget:self action:@selector(recordBtnExit:) forControlEvents:UIControlEventTouchDragExit];
    [_recordButton addTarget:self action:@selector(recordBtnEnter:) forControlEvents:UIControlEventTouchDragEnter];
    [_recordButton setTitle:TUIKitLocalizableString(TUIKitInputHoldToTalk) forState:UIControlStateNormal];
    [_recordButton setTitleColor:TUIChatDynamicColor(@"chat_input_text_color", @"#000000") forState:UIControlStateNormal];
    _recordButton.hidden = YES;
    [self addSubview:_recordButton];

    _inputTextView = [[TUIResponderTextView alloc] init];
    _inputTextView.delegate = self;
    [_inputTextView setFont:[UIFont systemFontOfSize:16]];
    _inputTextView.backgroundColor = TUIChatDynamicColor(@"chat_input_bg_color", @"#FFFFFF");
    _inputTextView.textColor = TUIChatDynamicColor(@"chat_input_text_color", @"#000000");
    [_inputTextView setReturnKeyType:UIReturnKeySend];
    [self addSubview:_inputTextView];

    [self applyBorderTheme];
}
- (void)applyBorderTheme {
    if (_recordButton) {
        [_recordButton.layer setMasksToBounds:YES];
        [_recordButton.layer setCornerRadius:4.0f];
        [_recordButton.layer setBorderWidth:0.5f];
        [_recordButton.layer setBorderColor:TUICoreDynamicColor(@"separator_color", @"#DBDBDB").CGColor];
    }
    
    if (_inputTextView) {
        [_inputTextView.layer setMasksToBounds:YES];
        [_inputTextView.layer setCornerRadius:4.0f];
        [_inputTextView.layer setBorderWidth:0.5f];
        [_inputTextView.layer setBorderColor:TUICoreDynamicColor(@"separator_color", @"#DBDBDB").CGColor];
    }
    
}
- (void)defaultLayout
{
    _lineView.frame = CGRectMake(0, 0, Screen_Width, TLine_Heigh);
    CGSize buttonSize = TTextView_Button_Size;
    CGFloat buttonOriginY = (TTextView_Height - buttonSize.height) * 0.5;
    _micButton.frame = CGRectMake(TTextView_Margin, buttonOriginY, buttonSize.width, buttonSize.height);
    _keyboardButton.frame = _micButton.frame;
    _moreButton.frame = CGRectMake(Screen_Width - buttonSize.width - TTextView_Margin, buttonOriginY, buttonSize.width, buttonSize.height);
    _faceButton.frame = CGRectMake(_moreButton.frame.origin.x - buttonSize.width - TTextView_Margin, buttonOriginY, buttonSize.width, buttonSize.height);

    CGFloat beginX = _micButton.frame.origin.x + _micButton.frame.size.width + TTextView_Margin;
    CGFloat endX = _faceButton.frame.origin.x - TTextView_Margin;
    _recordButton.frame = CGRectMake(beginX, (TTextView_Height - TTextView_TextView_Height_Min) * 0.5, endX - beginX, TTextView_TextView_Height_Min);
    _inputTextView.frame = _recordButton.frame;
}

- (void)layoutButton:(CGFloat)height
{
    CGRect frame = self.frame;
    CGFloat offset = height - frame.size.height;
    frame.size.height = height;
    self.frame = frame;

    CGSize buttonSize = TTextView_Button_Size;
    CGFloat bottomMargin = (TTextView_Height - buttonSize.height) * 0.5;
    CGFloat originY = frame.size.height - buttonSize.height - bottomMargin;

    CGRect faceFrame = _faceButton.frame;
    faceFrame.origin.y = originY;
    _faceButton.frame = faceFrame;

    CGRect moreFrame = _moreButton.frame;
    moreFrame.origin.y = originY;
    _moreButton.frame = moreFrame;

    CGRect voiceFrame = _micButton.frame;
    voiceFrame.origin.y = originY;
    _micButton.frame = voiceFrame;

    _keyboardButton.frame = _faceButton.frame;

    if(_delegate && [_delegate respondsToSelector:@selector(inputBar:didChangeInputHeight:)]){
        [_delegate inputBar:self didChangeInputHeight:offset];
    }
}

- (void)clickVoiceBtn:(UIButton *)sender
{
    _recordButton.hidden = NO;
    _inputTextView.hidden = YES;
    _micButton.hidden = YES;
    _keyboardButton.hidden = NO;
    _faceButton.hidden = NO;
    [_inputTextView resignFirstResponder];
    [self layoutButton:TTextView_Height];
    if(_delegate && [_delegate respondsToSelector:@selector(inputBarDidTouchMore:)]){
        [_delegate inputBarDidTouchVoice:self];
    }
    _keyboardButton.frame = _micButton.frame;
}

- (void)clickKeyboardBtn:(UIButton *)sender
{
    _micButton.hidden = NO;
    _keyboardButton.hidden = YES;
    _recordButton.hidden = YES;
    _inputTextView.hidden = NO;
    _faceButton.hidden = NO;
    [self layoutButton:_inputTextView.frame.size.height + 2 * TTextView_Margin];
    if(_delegate && [_delegate respondsToSelector:@selector(inputBarDidTouchKeyboard:)]){
        [_delegate inputBarDidTouchKeyboard:self];
    }
}

- (void)clickFaceBtn:(UIButton *)sender
{
    _micButton.hidden = NO;
    _faceButton.hidden = YES;
    _keyboardButton.hidden = NO;
    _recordButton.hidden = YES;
    _inputTextView.hidden = NO;
    if(_delegate && [_delegate respondsToSelector:@selector(inputBarDidTouchFace:)]){
        [_delegate inputBarDidTouchFace:self];
    }
    _keyboardButton.frame = _faceButton.frame;
}

- (void)clickMoreBtn:(UIButton *)sender
{
    if(_delegate && [_delegate respondsToSelector:@selector(inputBarDidTouchMore:)]){
        [_delegate inputBarDidTouchMore:self];
    }
}

- (void)recordBtnDown:(UIButton *)sender
{
    AVAudioSessionRecordPermission permission = AVAudioSession.sharedInstance.recordPermission;
    //在此添加新的判定 undetermined，否则新安装后的第一次询问会出错。新安装后的第一次询问为 undetermined，而非 denied。
    if (permission == AVAudioSessionRecordPermissionDenied || permission == AVAudioSessionRecordPermissionUndetermined) {
        [AVAudioSession.sharedInstance requestRecordPermission:^(BOOL granted) {
            if (!granted) {
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:TUIKitLocalizableString(TUIKitInputNoMicTitle) message:TUIKitLocalizableString(TUIKitInputNoMicTips) preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(TUIKitInputNoMicOperateLater) style:UIAlertActionStyleCancel handler:nil]];
                [ac addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(TUIKitInputNoMicOperateEnable) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    UIApplication *app = [UIApplication sharedApplication];
                    NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                    if ([app canOpenURL:settingsURL]) {
                        [app openURL:settingsURL];
                    }
                }]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.mm_viewController presentViewController:ac animated:YES completion:nil];
                });
            }
        }];
        return;
    }
    //在此包一层判断，添加一层保护措施。
    if(permission == AVAudioSessionRecordPermissionGranted){
        if(!_record){
            _record = [[TUIRecordView alloc] init];
            _record.frame = [UIScreen mainScreen].bounds;
        }
        [self.window addSubview:_record];
        _recordStartTime = [NSDate date];
        [_record setStatus:Record_Status_Recording];
        _recordButton.backgroundColor = [UIColor lightGrayColor];
        [_recordButton setTitle:TUIKitLocalizableString(TUIKitInputReleaseToSend) forState:UIControlStateNormal];  // @"松开 结束"
        [self showHapticFeedback];
        [self startRecord];
    }
}

- (void)recordBtnUp:(UIButton *)sender
{
    if (AVAudioSession.sharedInstance.recordPermission == AVAudioSessionRecordPermissionDenied) {
        return;
    }
    _recordButton.backgroundColor = [UIColor clearColor];
    [_recordButton setTitle:TUIKitLocalizableString(TUIKitInputHoldToTalk) forState:UIControlStateNormal]; // @"按住 说话"
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:_recordStartTime];
    if(interval < 1){
        [_record setStatus:Record_Status_TooShort];
        [self cancelRecord];
        __weak typeof(self) ws = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ws.record removeFromSuperview];
        });
    } else if(interval > 60) {
        [_record setStatus:Record_Status_TooLong];
        if (self.recordTimer == nil) {
            // 此时超时回调已经在处理了，忽略
            return;
        }
        [self cancelRecord];
        __weak typeof(self) ws = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ws.record removeFromSuperview];
        });
    } else{
        [_record removeFromSuperview];
        NSString *path = [self stopRecord];
        _record = nil;
        if (path) {
            if(_delegate && [_delegate respondsToSelector:@selector(inputBar:didSendVoice:)]){
                [_delegate inputBar:self didSendVoice:path];
            }
        }
    }
}

- (void)recordBtnCancel:(UIButton *)sender
{
    [_record removeFromSuperview];
    _recordButton.backgroundColor = [UIColor clearColor];
    [_recordButton setTitle:TUIKitLocalizableString(TUIKitInputHoldToTalk) forState:UIControlStateNormal]; // @"按住 说话"
    [self cancelRecord];
}

- (void)recordBtnExit:(UIButton *)sender
{
    [_record setStatus:Record_Status_Cancel];
    [_recordButton setTitle:TUIKitLocalizableString(TUIKitInputReleaseToCancel) forState:UIControlStateNormal]; //  @"松开 取消"
}

- (void)recordBtnEnter:(UIButton *)sender
{
    [_record setStatus:Record_Status_Recording];
    [_recordButton setTitle:TUIKitLocalizableString(TUIKitInputReleaseToSend) forState:UIControlStateNormal]; //  @"松开 结束"
}

- (void)showHapticFeedback{
    if (@available(iOS 10.0, *)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle: UIImpactFeedbackStyleMedium];
            [generator prepare];
            [generator impactOccurred];
        });
        
    } else {
        // Fallback on earlier versions
    }
}
#pragma mark - talk

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.keyboardButton.hidden = YES;
    self.micButton.hidden = NO;
    self.faceButton.hidden = NO;
    
    self.isFocusOn = YES;
    self.allowSendTypingStatusByChangeWord  = YES;

    
    __weak typeof(self) weakSelf = self;
    self.sendTypingStatusTimer = [NSTimer tui_scheduledTimerWithTimeInterval:4 repeats:YES block:^(NSTimer * _Nonnull timer) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.allowSendTypingStatusByChangeWord = YES;
    }];
    
    if (self.isFocusOn &&textView.text.length > 0) {
        if (_delegate && [_delegate respondsToSelector:@selector(inputTextViewShouldBeginTyping:)]) {
            [_delegate inputTextViewShouldBeginTyping:textView];
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    
    self.isFocusOn = NO;
    if (_delegate && [_delegate respondsToSelector:@selector(inputTextViewShouldEndTyping:)]) {
        [_delegate inputTextViewShouldEndTyping:textView];
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (self.allowSendTypingStatusByChangeWord && self.isFocusOn &&textView.text.length > 0) {
        if (_delegate && [_delegate respondsToSelector:@selector(inputTextViewShouldBeginTyping:)]) {
            self.allowSendTypingStatusByChangeWord = NO;
            [_delegate inputTextViewShouldBeginTyping:textView];
        }
    }
    
    if (self.isFocusOn && textView.text.length == 0) {
        if (_delegate && [_delegate respondsToSelector:@selector(inputTextViewShouldEndTyping:)]) {
            [_delegate inputTextViewShouldEndTyping:textView];
        }
    }
    CGSize size = [_inputTextView sizeThatFits:CGSizeMake(_inputTextView.frame.size.width, TTextView_TextView_Height_Max)];
    CGFloat oldHeight = _inputTextView.frame.size.height;
    CGFloat newHeight = size.height;

    if(newHeight > TTextView_TextView_Height_Max){
        newHeight = TTextView_TextView_Height_Max;
    }
    if(newHeight < TTextView_TextView_Height_Min){
        newHeight = TTextView_TextView_Height_Min;
    }
    if(oldHeight == newHeight){
        return;
    }

    __weak typeof(self) ws = self;
    [UIView animateWithDuration:0.3 animations:^{
        CGRect textFrame = ws.inputTextView.frame;
        textFrame.size.height += newHeight - oldHeight;
        ws.inputTextView.frame = textFrame;
        [ws layoutButton:newHeight + 2 * TTextView_Margin];
    }];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if([text isEqualToString:@"\n"]){
        if(_delegate && [_delegate respondsToSelector:@selector(inputBar:didSendText:)]) {
            NSString *sp = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (sp.length == 0) {
                UIAlertController *ac = [UIAlertController alertControllerWithTitle:TUIKitLocalizableString(TUIKitInputBlankMessageTitle) message:nil preferredStyle:UIAlertControllerStyleAlert];
                [ac addAction:[UIAlertAction actionWithTitle:TUIKitLocalizableString(Confirm) style:UIAlertActionStyleDefault handler:nil]];
                [self.mm_viewController presentViewController:ac animated:YES completion:nil];
            } else {
                [_delegate inputBar:self didSendText:textView.text];
                [self clearInput];
            }
        }
        return NO;
    }
    else if ([text isEqualToString:@""]) {
        if (textView.text.length > range.location) {
            // 一次性删除 [微笑] 这种表情消息
            if ([textView.text characterAtIndex:range.location] == ']') {
                NSUInteger location = range.location;
                NSUInteger length = range.length;
                int left = 91;     // '[' 对应的ascii码
                int right = 93;    // ']' 对应的ascii码
                while (location != 0) {
                    location --;
                    length ++ ;
                    int c = (int)[textView.text characterAtIndex:location];     // 将字符转换成ascii码，复制给int  避免越界
                    if (c == left) {
                        textView.text = [textView.text stringByReplacingCharactersInRange:NSMakeRange(location, length) withString:@""];
                        return NO;
                    }
                    else if (c == right) {
                        return YES;
                    }
                }
            }
            // 一次性删除 @xxx 这种 @ 消息
            else if ([textView.text characterAtIndex:range.location] == ' ') {
                NSUInteger location = range.location;
                NSUInteger length = range.length;
                int at = 64;    // '@' 对应的ascii码
                while (location != 0) {
                    location --;
                    length ++ ;
                    int c = (int)[textView.text characterAtIndex:location]; // 将字符转成ascii码，复制给int,避免越界
                    if (c == at) {
                        NSString *atText = [textView.text substringWithRange:NSMakeRange(location, length)];
                        textView.text = [textView.text stringByReplacingCharactersInRange:NSMakeRange(location, length) withString:@""];
                        if (self.delegate && [self.delegate respondsToSelector:@selector(inputBar:didDeleteAt:)]) {
                            [self.delegate inputBar:self didDeleteAt:atText];
                        }
                        return NO;
                    }
                }
            }
        }
    }
    // 监听 @ 字符的输入，包含全角/半角
    else if ([text isEqualToString:@"@"] || [text isEqualToString:@"＠"]) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(inputBarDidInputAt:)]) {
            [self.delegate inputBarDidInputAt:self];
        }
    }
    return YES;
}

- (void)onDeleteBackward:(TUIResponderTextView *)textView
{
    // 点击键盘上的删除按钮
    if (self.delegate && [self.delegate respondsToSelector:@selector(inputBarDidDeleteBackward:)]) {
        [self.delegate inputBarDidDeleteBackward:self];
    }
}

- (void)clearInput
{
    _inputTextView.text = @"";
    [self textViewDidChange:_inputTextView];
}

- (NSString *)getInput
{
    return _inputTextView.text;
}

- (void)addEmoji:(NSString *)emoji
{
    [_inputTextView setText:[_inputTextView.text stringByAppendingString:emoji]];
    if(_inputTextView.contentSize.height > TTextView_TextView_Height_Max){
        float offset = _inputTextView.contentSize.height - _inputTextView.frame.size.height;
        [_inputTextView scrollRectToVisible:CGRectMake(0, offset, _inputTextView.frame.size.width, _inputTextView.frame.size.height) animated:YES];
    }
    [self textViewDidChange:_inputTextView];
}

- (void)backDelete
{
    [self textView:_inputTextView shouldChangeTextInRange:NSMakeRange(_inputTextView.text.length - 1, 1) replacementText:@""];
    [self textViewDidChange:_inputTextView];
}

- (void)updateTextViewFrame
{
    [self textViewDidChange:[UITextView new]];
}

- (void)changeToKeyboard
{
    [self clickKeyboardBtn:self.keyboardButton];
}

- (void)startRecord
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    [session setActive:YES error:&error];

    //设置参数
    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
                                   //采样率  8000/11025/22050/44100/96000（影响音频的质量）
                                   [NSNumber numberWithFloat: 8000.0],AVSampleRateKey,
                                   // 音频格式
                                   [NSNumber numberWithInt: kAudioFormatMPEG4AAC],AVFormatIDKey,
                                   //采样位数  8、16、24、32 默认为16
                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
                                   // 音频通道数 1 或 2
                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
                                   //录音质量
                                   [NSNumber numberWithInt:AVAudioQualityHigh],AVEncoderAudioQualityKey,
                                   nil];

    NSString *path = [TUIKit_Voice_Path stringByAppendingString:[TUITool genVoiceName:nil withExtension:@"m4a"]];
    NSURL *url = [NSURL fileURLWithPath:path];
    _recorder = [[AVAudioRecorder alloc] initWithURL:url settings:recordSetting error:nil];
    _recorder.meteringEnabled = YES;
    [_recorder prepareToRecord];
    [_recorder record];
    [_recorder updateMeters];

    _recordTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(recordTick:) userInfo:nil repeats:YES];
}

- (void)recordTick:(NSTimer *)timer{
    [_recorder updateMeters];
    float power = [_recorder averagePowerForChannel:0];
    [_record setPower:power];
    
    //在此处添加一个时长判定，如果时长超过60s，则取消录制，提示时间过长,同时不再显示 recordView。
    //此处使用 recorder 的属性，使得录音结果尽量精准。注意：由于语音的时长为整形，所以 60.X 秒的情况会被向下取整。但因为 ticker 0.5秒执行一次，所以因该都会在超时时显示为60s
    NSTimeInterval interval = _recorder.currentTime;
    if(interval >= 55 && interval < 60){
        NSInteger seconds = 60 - interval;
        NSString *secondsString = [NSString stringWithFormat:TUIKitLocalizableString(TUIKitInputWillFinishRecordInSeconds),(long)seconds + 1];//此处加long，是为了消除编译器警告。此处 +1 是为了向上取整，优化时间逻辑。
        _record.title.text = secondsString;
    }
    if(interval >= 60){
        NSString *path = [self stopRecord];
        [_record setStatus:Record_Status_TooLong];
        __weak typeof(self) ws = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ws.record removeFromSuperview];
        });
        if (path) {
            if(_delegate && [_delegate respondsToSelector:@selector(inputBar:didSendVoice:)]){
                [_delegate inputBar:self didSendVoice:path];
            }
        }
    }
    
}


- (NSString *)stopRecord
{
    if(_recordTimer){
        [_recordTimer invalidate];
        _recordTimer = nil;
    }
    if([_recorder isRecording]){
        [_recorder stop];
    }
    return _recorder.url.path;
}

- (void)cancelRecord
{
    if(_recordTimer){
        [_recordTimer invalidate];
        _recordTimer = nil;
    }
    if([_recorder isRecording]){
        [_recorder stop];
    }
    NSString *path = _recorder.url.path;
    if([[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
}

- (void)onThemeChanged {
    [self applyBorderTheme];
}


@end
