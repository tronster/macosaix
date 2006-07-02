//
//  MacOSaiXTilesShapes.h
//  MacOSaiX
//
//  Created by Frank Midgley on Nov 28 2004.
//  Copyright (c) 2004 Frank M. Midgley. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kMacOSaiXTileShapesSettingType @"Element Type"


@protocol MacOSaiXTileShapes <NSObject, NSCopying>

	// A generic image for this type of tile shapes.  This image is used for display in the preferences window (32x32), the tiles setup pop-up menu (16x16) and the crash reporter window (16x16).
+ (NSImage *)image;

	// This method should return a class that conforms to the MacOSaiXTileShapesEditor protocol.
+ (Class)editorClass;

	// This method should return a class that conforms to the MacOSaiXTileShapesPreferencesController protocol.  Return nil if there are no preferences for this plug-in.
+ (Class)preferencesControllerClass;

	// An image appropriate for this instance of the tile shapes.  This image is used for the "Tiles Setup" toolbar icon (32x32).
- (NSImage *)image;

	// A human-readable string that briefly describes this instance's settings.
- (NSString *)briefDescription;

	// Methods called to save and load settings.
- (BOOL)saveSettingsToFileAtPath:(NSString *)path;
- (BOOL)loadSettingsFromFileAtPath:(NSString *)path;

	// This method should return an array of NSBezierPaths based on the settings defined by the user.
- (NSArray *)shapes;

@end


@protocol MacOSaiXTileShapesEditor <NSObject>

- (id)initWithOriginalImage:(NSImage *)originalImage;

	// The view containing the editing controls.
- (NSView *)editorView;

	// These methods should return the minimum and maximum sizes of the editor view.  If no limit is desired then return NSZeroSize from either method.
- (NSSize)minimumSize;
- (NSSize)maximumSize;

	// The first responder of the editor view.
- (NSResponder *)firstResponder;

- (void)editTileShapes:(id<MacOSaiXTileShapes>)tilesSetup;

	// This method should indicate whether the current state of the editing controls represents a valid image source.  If NO then the OK button will be disabled.
- (BOOL)settingsAreValid;

- (int)tileCount;
- (NSBezierPath *)previewPath;

- (void)editingComplete;

@end
