//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "JSQMessagesCellTextView.h"

@implementation JSQMessagesCellTextView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.textColor = [UIColor whiteColor];
    self.editable = NO;
    self.selectable = YES;
    self.userInteractionEnabled = YES;
    self.dataDetectorTypes = UIDataDetectorTypeNone;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.scrollEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
    self.contentInset = UIEdgeInsetsZero;
    self.scrollIndicatorInsets = UIEdgeInsetsZero;
    self.contentOffset = CGPointZero;
    self.textContainerInset = UIEdgeInsetsZero;
    self.textContainer.lineFragmentPadding = 0;
    self.linkTextAttributes = @{ NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) };
    
    UITapGestureRecognizer *tapLinkRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapLInk:)];
    [self addGestureRecognizer:tapLinkRecognizer];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    if ((attributedText != nil) && (attributedText.length > 0) && [self isLinkNeedsDetected]) {
        NSMutableAttributedString *mutableString = [attributedText mutableCopy];
        NSString *str = [attributedText string];
        NSError *error = nil;
        
        NSDataDetector *dataDetector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
        if (dataDetector != nil) {
            NSArray *matches = [dataDetector matchesInString:str options:NSMatchingReportCompletion range:NSMakeRange(0, str.length)];
            
            if ((matches != nil) && (matches.count > 0)) {
                for (NSTextCheckingResult *matchResult in matches) {
                    [mutableString addAttribute:NSLinkAttributeName value:@"0" range:[matchResult range]];
                 }
            }
        }
        [super setAttributedText:[[NSAttributedString alloc] initWithAttributedString:mutableString]];
    } else {
        [super setAttributedText:attributedText];
    }
    
}

- (void)setSelectable:(BOOL)selectable
{
    [super setSelectable:selectable];
    
    if ([self isLinkNeedsDetected]) {
        NSAttributedString *str = self.attributedText;
        self.attributedText = str;
    }
}

- (void)setDataDetectorTypes:(UIDataDetectorTypes)dataDetectorTypes
{
    [super setDataDetectorTypes:dataDetectorTypes];
    
    if ([self isLinkNeedsDetected]) {
        NSAttributedString *str = self.attributedText;
        self.attributedText = str;
    }
}

- (void)setSelectedRange:(NSRange)selectedRange
{
    //  attempt to prevent selecting text
    [super setSelectedRange:NSMakeRange(NSNotFound, 0)];
}

- (NSRange)selectedRange
{
    //  attempt to prevent selecting text
    return NSMakeRange(NSNotFound, NSNotFound);
}

#pragma mark - Gesture handling
- (void)enumerateViewRectsForRanges:(NSArray *)ranges usingBlock:(void (^)(CGRect rect, NSRange range, BOOL *stop))block
{
    if (!block) {
        return;
    }
    
    for (NSValue *rangeAsValue in ranges) {
        NSRange range = rangeAsValue.rangeValue;
        NSRange glyphRange = [self.layoutManager glyphRangeForCharacterRange:range actualCharacterRange:NULL];
        [self.layoutManager enumerateEnclosingRectsForGlyphRange:glyphRange withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0) inTextContainer:self.textContainer usingBlock:^(CGRect rect, BOOL *stop) {
            rect.origin.x += self.textContainerInset.left;
            rect.origin.y += self.textContainerInset.top;
            rect = UIEdgeInsetsInsetRect(rect, self.textContainerInset);
            
            block(rect, range, stop);
        }];
    }
}

- (BOOL)enumerateLinkRangesContainingLocation:(CGPoint)location usingBlock:(void (^)(NSRange range))block
{
    __block BOOL found = NO;
    
    NSAttributedString *attributedString = self.attributedText;
    [attributedString enumerateAttribute:NSLinkAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (found) {
            *stop = YES;
            return;
        }
        if (value) {
            [self enumerateViewRectsForRanges:@[[NSValue valueWithRange:range]] usingBlock:^(CGRect rect, NSRange range, BOOL *stop) {
                if (found) {
                    *stop = YES;
                    return;
                }
                if (CGRectContainsPoint(rect, location)) {
                    found = YES;
                    *stop = YES;
                    if (block) {
                        block(range);
                    }
                }
            }];
        }
    }];
    
    return found;
}

- (NSArray *)didTouchDownAtLocation:(CGPoint)location
{
    NSMutableArray *rangeValuesForTouchDown = [NSMutableArray array];
    [self enumerateLinkRangesContainingLocation:location usingBlock:^(NSRange range) {
        [rangeValuesForTouchDown addObject:[NSValue valueWithRange:range]];
    }];
    
    return rangeValuesForTouchDown;
}

- (void)didTapAtRangeValues:(NSArray *)rangeValues
{
    NSValue *rangeValue = rangeValues[0];
    
    NSRange range = rangeValue.rangeValue;
    NSString *linkString = [self.text substringWithRange:range];
    if ((linkString != nil) && (linkString.length > 0))
    {
        NSURL *url = [NSURL URLWithString:linkString];
        BOOL canOpen = [[UIApplication sharedApplication] canOpenURL:url];
        if (!canOpen)
        {
            NSMutableString *tempString = [linkString mutableCopy];
            [tempString insertString:@"http://" atIndex:0];
            url = [NSURL URLWithString:tempString];
        }
        
        // iOS 10 depricated openURL: method
        UIApplication *app = UIApplication.sharedApplication;
        if ([app respondsToSelector:@selector(openURL:options:completionHandler:)]) {
            [app openURL:url options:@{} completionHandler:nil];
        } else {
            [app openURL:url];
        }
    }
}

#pragma mark - Guesture recognizers
- (void)handleTapLInk:(UITapGestureRecognizer *)gestureRecognizer
{
    if ([self isLinkNeedsDetected]) {
        if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
            CGPoint location = [gestureRecognizer locationInView:self];
            NSArray *rangeValuesForTouchDown = [self didTouchDownAtLocation:location];
            if ((rangeValuesForTouchDown != nil) && (rangeValuesForTouchDown.count > 0)) {
                [self didTapAtRangeValues:rangeValuesForTouchDown];
            }
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    //  ignore double-tap to prevent copy/define/etc. menu from showing
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gestureRecognizer;
        if (tap.numberOfTapsRequired == 2) {
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    //  ignore double-tap to prevent copy/define/etc. menu from showing
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tap = (UITapGestureRecognizer *)gestureRecognizer;
        if (tap.numberOfTapsRequired == 2) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Helpers
- (BOOL)isLinkNeedsDetected
{
    BOOL result = (!self.selectable && ((self.dataDetectorTypes & UIDataDetectorTypeLink) == UIDataDetectorTypeLink));
    
    return result;
}

@end
