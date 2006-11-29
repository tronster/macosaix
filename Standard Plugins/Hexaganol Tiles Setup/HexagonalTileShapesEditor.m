//
//  HexagonalTileShapesController.m
//  MacOSaiX
//
//  Created by Frank Midgley on Thu Jan 23 2003.
//  Copyright (c) 2003-2004 Frank M. Midgley. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "HexagonalTileShapesEditor.h"
#import "NSString+MacOSaiX.h"


enum { tilesSize1x1 = 1, tilesSize3x4, tilesSize4x3 };


@interface MacOSaiXHexagonalTileShapesEditor (PrivateMethods)
- (void)setFixedSizeControlsBasedOnFreeformControls;
@end


@implementation MacOSaiXHexagonalTileShapesEditor


+ (NSString *)name
{
	return NSLocalizedString(@"Hexagons", @"");
}


- (NSView *)editorView
{
	if (!editorView)
		[NSBundle loadNibNamed:@"HexagonalTileShapes" owner:self];
	
	return editorView;
}


- (NSSize)minimumSize
{
	return NSMakeSize(270.0, 211.0);
}


- (NSSize)maximumSize
{
	return NSZeroSize;
}


- (NSResponder *)firstResponder
{
	return tilesAcrossTextField;
}


- (id)initWithOriginalImage:(NSImage *)originalImage
{
	if (self = [super init])
		originalImageSize = [originalImage size];
	
	return self;
}


- (void)updatePlugInDefaults
{
	[[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithObjectsAndKeys:
														[NSNumber numberWithInt:[currentTileShapes tilesAcross]], @"Tiles Across", 
														[NSNumber numberWithInt:[currentTileShapes tilesDown]], @"Tiles Down", 
														nil]
											  forKey:@"Hexagonal Tile Shapes"];
}


- (void)editTileShapes:(id<MacOSaiXTileShapes>)tilesSetup
{
	[currentTileShapes autorelease];
	currentTileShapes = [tilesSetup retain];
	
	minAspectRatio = (originalImageSize.width / [tilesAcrossSlider maxValue]) / 
					 (originalImageSize.height / [tilesDownSlider minValue]);
	maxAspectRatio = (originalImageSize.width / [tilesAcrossSlider minValue]) / 
					 (originalImageSize.height / [tilesDownSlider maxValue]);
	
	// Constrain the tiles across value to the stepper's range and update the model and view.
	int	tilesAcross = MIN(MAX([currentTileShapes tilesAcross], [tilesAcrossStepper minValue]), [tilesAcrossStepper maxValue]);
	[currentTileShapes setTilesAcross:tilesAcross];
	[tilesAcrossStepper setIntValue:tilesAcross];
	[tilesAcrossTextField setIntValue:tilesAcross];
	[tilesAcrossStepper setIntValue:tilesAcross];
	
		// Constrain the tiles down value to the stepper's range and update the model and view.
	int	tilesDown = MIN(MAX([currentTileShapes tilesDown], [tilesDownStepper minValue]), [tilesDownStepper maxValue]);
	[currentTileShapes setTilesDown:tilesDown];
	[tilesDownStepper setIntValue:tilesDown];
	[tilesDownTextField setIntValue:tilesDown];
	[tilesDownStepper setIntValue:tilesDown];
	
	[self setFixedSizeControlsBasedOnFreeformControls];
}


- (float)aspectRatio
{
	float	aspectRatio = [tilesSizeSlider floatValue];
	
	if (aspectRatio < 1.0)
		aspectRatio = minAspectRatio + (1.0 - minAspectRatio) * aspectRatio;
	else if (aspectRatio > 1.0)
		aspectRatio = 1.0 + (maxAspectRatio - 1.0) * (aspectRatio - 1.0);
	
	return aspectRatio;
}


- (void)setFreeFormControlsBasedOnFixedSizeControls
{
	float	aspectRatio = [self aspectRatio], 
			targetTileCount = [tilesCountSlider floatValue];
	
	int		minX = [tilesAcrossSlider minValue], 
			minY = [tilesDownSlider minValue], 
			maxX = [tilesAcrossSlider maxValue], 
			maxY = [tilesDownSlider maxValue];
	if (originalImageSize.height * minX * aspectRatio / originalImageSize.width < minY)
		minX = originalImageSize.width * minY / aspectRatio / originalImageSize.height;
	if (originalImageSize.width * minY / aspectRatio / originalImageSize.height < minX)
		minY = minX * originalImageSize.height * aspectRatio / originalImageSize.width;
	if (originalImageSize.height * maxX * aspectRatio / originalImageSize.width > maxY)
		maxX = originalImageSize.width * maxY / aspectRatio / originalImageSize.height;
	if (originalImageSize.width * maxY / aspectRatio / originalImageSize.height > maxX)
		maxY = maxX * originalImageSize.height * aspectRatio / originalImageSize.width;
	
	int		tilesAcross = minX + (maxX - minX) * targetTileCount, 
			tilesDown = minY + (maxY - minY) * targetTileCount;
	
	[tilesAcrossSlider setIntValue:tilesAcross];
	[tilesAcrossTextField setIntValue:tilesAcross];
	[tilesAcrossStepper setIntValue:tilesAcross];
	[tilesDownSlider setIntValue:tilesDown];
	[tilesDownTextField setIntValue:tilesDown];
	[tilesDownStepper setIntValue:tilesDown];
}


- (void)setFixedSizeControlsBasedOnFreeformControls
{
	int		tilesAcross = [tilesAcrossSlider intValue], 
			tilesDown = [tilesDownSlider intValue];
	float	tileAspectRatio = (originalImageSize.width / tilesAcross) / 
							  (originalImageSize.height / tilesDown);
	
		// Update the tile size slider and pop-up.
	if (tileAspectRatio < 1.0)
		tileAspectRatio = (tileAspectRatio - minAspectRatio) / (1.0 - minAspectRatio);
	else if (tileAspectRatio > 1.0)
		tileAspectRatio = (tileAspectRatio - 1.0) / (maxAspectRatio - 1.0) + 1.0;
	[tilesSizeSlider setFloatValue:tileAspectRatio];
	
	[[tilesSizePopUp itemAtIndex:0] setTitle:[NSString stringWithAspectRatio:[self aspectRatio]]];
	
		// Update the tile count slider.
	int		minX = [tilesAcrossSlider minValue], 
			minY = [tilesDownSlider minValue], 
			maxX = [tilesAcrossSlider maxValue], 
			maxY = [tilesDownSlider maxValue], 
			minTileCount = 0,
			maxTileCount = 0;
	if (originalImageSize.height * minX * tileAspectRatio / originalImageSize.width < minY)
		minTileCount = minX * minX / tileAspectRatio;
	else
		minTileCount = minY * minY * tileAspectRatio;
	if (originalImageSize.height * maxX * tileAspectRatio / originalImageSize.width < maxY)
		maxTileCount = maxX * maxX / tileAspectRatio;
	else
		maxTileCount = maxY * maxY * tileAspectRatio;
	[tilesCountSlider setFloatValue:(float)(tilesAcross * tilesDown - minTileCount) / (maxTileCount - minTileCount)];
}


- (IBAction)setTilesAcross:(id)sender
{
    [currentTileShapes setTilesAcross:[sender intValue]];
    [tilesAcrossTextField setIntValue:[sender intValue]];
	if (sender == tilesAcrossSlider)
		[tilesAcrossStepper setIntValue:[sender intValue]];
	else
		[tilesAcrossSlider setIntValue:[sender intValue]];
	
	[self setFixedSizeControlsBasedOnFreeformControls];
	
	[self updatePlugInDefaults];
	
	[[editorView window] sendEvent:nil];
}


- (IBAction)setTilesDown:(id)sender
{
    [currentTileShapes setTilesDown:[sender intValue]];
    [tilesDownTextField setIntValue:[sender intValue]];
	if (sender == tilesDownSlider)
		[tilesDownStepper setIntValue:[sender intValue]];
	else
		[tilesDownSlider setIntValue:[sender intValue]];
	
	[self setFixedSizeControlsBasedOnFreeformControls];
	
	[self updatePlugInDefaults];
	
	[[editorView window] sendEvent:nil];
}


- (IBAction)setTilesSize:(id)sender
{
	if (sender == tilesSizePopUp)
	{
		float	tileAspectRatio = 1.0;
		if ([tilesSizePopUp selectedTag] == tilesSize3x4)
			tileAspectRatio = 3.0 / 4.0;
		else if ([tilesSizePopUp selectedTag] == tilesSize4x3)
			tileAspectRatio = 4.0 / 3.0;
		
			// Map the ratio to the slider position.
		if (tileAspectRatio < 1.0)
			tileAspectRatio = (tileAspectRatio - minAspectRatio) / (1.0 - minAspectRatio);
		else
			tileAspectRatio = (tileAspectRatio - 1.0) / (maxAspectRatio - 1.0) + 1.0;
		[tilesSizeSlider setFloatValue:tileAspectRatio];
	}
	
	[self setFreeFormControlsBasedOnFixedSizeControls];
	[[tilesSizePopUp itemAtIndex:0] setTitle:[NSString stringWithAspectRatio:[self aspectRatio]]];
	
	[currentTileShapes setTilesAcross:[tilesAcrossSlider intValue]];
	[currentTileShapes setTilesDown:[tilesDownSlider intValue]];
	
	[self updatePlugInDefaults];
	
	[[editorView window] sendEvent:nil];
}


- (IBAction)setTilesCount:(id)sender
{
	[self setFreeFormControlsBasedOnFixedSizeControls];
	
	[currentTileShapes setTilesAcross:[tilesAcrossSlider intValue]];
	[currentTileShapes setTilesDown:[tilesDownSlider intValue]];
	
	[self updatePlugInDefaults];
	
	[[editorView window] sendEvent:nil];
}


- (BOOL)settingsAreValid
{
	return YES;
}


- (int)tileCount
{
	return [tilesAcrossTextField intValue] * [tilesDownTextField intValue] + [tilesDownTextField intValue] / 2;
}


- (id<MacOSaiXTileShape>)previewShape
{
	float			unitHeight = (originalImageSize.height / [tilesDownTextField intValue]) / 
								 (originalImageSize.width / [tilesAcrossTextField intValue]);
	NSBezierPath	*previewPath = [NSBezierPath bezierPath];
	
	[previewPath moveToPoint:NSMakePoint(1.0 / 3.0, 0.0)];
	[previewPath lineToPoint:NSMakePoint(1.0, 0.0)];
	[previewPath lineToPoint:NSMakePoint(4.0 / 3.0, unitHeight / 2.0)];
	[previewPath lineToPoint:NSMakePoint(1.0, unitHeight)];
	[previewPath lineToPoint:NSMakePoint(1.0 / 3.0, unitHeight)];
	[previewPath lineToPoint:NSMakePoint(0.0, unitHeight / 2.0)];
	[previewPath lineToPoint:NSMakePoint(1.0 / 3.0, 0.0)];
	
	return [MacOSaiXHexagonalTileShape tileShapeWithOutline:previewPath orientation:0.0];
}


- (void)editingComplete
{
	[currentTileShapes release];
}


- (void)dealloc
{
	[editorView release];	// we are responsible for releasing any top-level objects in the nib
	
	[super dealloc];
}


@end
