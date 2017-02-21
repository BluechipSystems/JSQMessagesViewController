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

#import <UIKit/UIKit.h>

/**
 *  `JSQMessagesCellTextView` is a subclass of `UITextView` that is used to display text
 *  in a `JSQMessagesCollectionViewCell`.
 */

//  the problem with textviews is
//  textviews are selectable to allow data detectors
//  however, this allows the 'copy, define, select' UIMenuController to show
//  which conflicts with the collection view's UIMenuController
//  that is why data detection when textview selectable is OFF implemented here
//  but now implemented only Link detection 
@interface JSQMessagesCellTextView : UITextView

@end
