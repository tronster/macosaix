/*
	GoogleImageSourceController.h
	MacOSaiX

	Created by Frank Midgley on Wed Mar 13 2002.
	Copyright (c) 2002-2004 Frank M. Midgley. All rights reserved.
*/

#import <Cocoa/Cocoa.h>
#import "GoogleImageSource.h"

@interface GoogleImageSourceController : NSObject <MacOSaiXImageSourceController>
{
	IBOutlet NSView			*editorView;
	IBOutlet NSTextField	*requiredTermsTextField,
							*optionalTermsTextField,
							*excludedTermsTextField,
							*siteTextField;
	IBOutlet NSPopUpButton	*contentTypePopUpButton, 
							*colorSpacePopUpButton,
							*adultContentFilteringPopUpButton, 
							*collectionPopUpButton;

	GoogleImageSource		*currentImageSource;
}

- (IBAction)setContentType:(id)sender;
- (IBAction)setColorSpace:(id)sender;
- (IBAction)setAdultContentFiltering:(id)sender;
- (IBAction)setCollection:(id)sender;

@end
