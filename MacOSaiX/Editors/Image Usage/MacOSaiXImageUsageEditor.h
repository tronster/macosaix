//
//  MacOSaiXImageUsageEditor.h
//  MacOSaiX
//
//  Created by Frank Midgley on 12/22/06.
//  Copyright 2006 Frank M. Midgley. All rights reserved.
//

#import "MacOSaiXEditor.h"


@interface MacOSaiXImageUsageEditor : MacOSaiXEditor
{
	IBOutlet NSPopUpButton	*imageUseCountPopUp;
	IBOutlet NSSlider		*imageReuseSlider, 
							*imageCropLimitSlider;
	
	NSPoint					samplePoint;
}

- (IBAction)setImageUseCount:(id)sender;

- (IBAction)setImageReuseDistance:(id)sender;

- (IBAction)setImageCropLimit:(id)sender;

@end