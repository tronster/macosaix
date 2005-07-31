//
//  MacOSaiXiPhotoImageSourceController.h
//  MacOSaiX
//
//  Created by Frank Midgley on Mar 15 2005.
//  Copyright (c) 2005 Frank M. Midgley. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MacOSaiXImageSource.h"
#import "iPhotoImageSource.h"


@interface MacOSaiXiPhotoImageSourceController : NSObject <MacOSaiXImageSourceController>
{
	IBOutlet NSView				*editorView;

	IBOutlet NSImageView		*iconView;
	IBOutlet NSMatrix			*matrix;
	IBOutlet NSPopUpButton		*albumsPopUp,
								*keywordsPopUp;
	
	NSButton					*okButton;
	
		// The image source instance currently being edited.
	MacOSaiXiPhotoImageSource	*currentImageSource;
}

- (IBAction)chooseAllPhotos:(id)sender;
- (IBAction)chooseAlbum:(id)sender;
- (IBAction)chooseKeyword:(id)sender;

@end