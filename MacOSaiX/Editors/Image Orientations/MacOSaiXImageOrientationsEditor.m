//
//  MacOSaiXImageOrientationsEditor.m
//  MacOSaiX
//
//  Created by Frank Midgley on 12/22/06.
//  Copyright 2006 Frank M. Midgley. All rights reserved.
//

#import "MacOSaiXImageOrientationsEditor.h"

#import "MacOSaiX.h"
#import "MacOSaiXMosaic.h"
#import "MacOSaiXImageOrientations.h"
#import "Tiles.h"
#import "MacOSaiXWarningController.h"


@implementation MacOSaiXImageOrientationsEditor


+ (void)load
{
	[super load];
}


+ (NSImage *)image
{
	// TODO: create an image for this editor
	return [super image];
}


+ (NSString *)title
{
	return NSLocalizedString(@"Image Orientations", @"");
}


+ (NSString *)description
{
	return NSLocalizedString(@"This setting lets you define the angle at which images are placed into the tiles.", @"");
}


+ (BOOL)isAdditional
{
	return YES;
}


- (NSString *)editorNibName
{
	return @"Image Orientations Editor";
}


- (void)nibDidLoad
{
	// Make sure the pop-up is drawn over the box.
	NSPopUpButton	*popUp = [[plugInPopUpButton retain] autorelease];
	[popUp removeFromSuperview];
	[[self view] addSubview:popUp positioned:NSWindowAbove relativeTo:plugInEditorBox];
	
	[plugInEditorBox setContentViewMargins:NSMakeSize(0.0, 10.0)];
}


- (NSArray *)plugInClasses
{
	return [(MacOSaiX *)[NSApp delegate] imageOrientationsPlugIns];
}


- (NSString *)plugInTitleFormat
{
	return NSLocalizedString(@"%@", @"");
}


- (BOOL)shouldChangePlugInClass:(id)sender
{
	return (sender == self || 
			[[[self delegate] mosaic] numberOfImagesFound] == 0 || 
			![MacOSaiXWarningController warningIsEnabled:@"Changing Image Orientations"] || 
			[MacOSaiXWarningController runAlertForWarning:@"Changing Image Orientations" 
													title:NSLocalizedString(@"Do you wish to change the image orientations?", @"") 
												  message:NSLocalizedString(@"All work in the current mosaic will be lost.", @"") 
											 buttonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"Change", @""), NSLocalizedString(@"Cancel", @""), nil]] == 0);
}


- (NSSize)minimumViewSize
{
	NSSize	minSize = [editorView frame].size;
	
		// Subtract out the current size of the plug-in's editor view.
	minSize.width -= NSWidth([[plugInEditorBox contentView] frame]);
	minSize.height -= NSHeight([[plugInEditorBox contentView] frame]);
	
		// Add the minimum size of the plug-in's editor view.
	minSize.width += [plugInEditor minimumSize].width;
	minSize.height += [plugInEditor minimumSize].height;
	
	minSize.width = MAX(minSize.width, 233.0);
	minSize.height = MAX(minSize.height, 202.0);
	
	return minSize;
}


- (void)setMosaicDataSource:(id<MacOSaiXDataSource>)dataSource
{
	[[[self delegate] mosaic] setImageOrientations:(id<MacOSaiXImageOrientations>)dataSource];
	
	[[self delegate] embellishmentNeedsDisplay];
}


- (id<MacOSaiXDataSource>)mosaicDataSource
{
	return [[[self delegate] mosaic] imageOrientations];
}


- (void)beginEditing
{
	NSEnumerator	*tileEnumerator = [[[[self delegate] mosaic] tiles] objectEnumerator];
	MacOSaiXTile	*tile = nil;
	
	allTilesHaveOrientations = YES;
	noTilesHaveOrientations = YES;
	
	while (tile = [tileEnumerator nextObject])
	{
		if ([tile imageOrientation])
			noTilesHaveOrientations = NO;
		else
			allTilesHaveOrientations = NO;
	}
	
	if (allTilesHaveOrientations)
		[tabView selectTabViewItemAtIndex:1];
	else
	{
		BOOL	warningBoxVisible = !NSIsEmptyRect([warningBox visibleRect]);
		float	topEdge = NSMaxY([[self view] bounds]), 
				offset = 0.0;
		
		if (noTilesHaveOrientations && warningBoxVisible)
			offset = topEdge - NSMinY([warningBox frame]);	// Hide the warning.
		else if (!noTilesHaveOrientations && !warningBoxVisible)
			offset = topEdge - 10.0 - NSMaxY([warningBox frame]);	// Show the warning.
		
		if (offset != 0.0)
		{
				// Move the warning box.
			NSPoint	warningBoxOrigin = [warningBox frame].origin;
			warningBoxOrigin.y += offset;
			[warningBox setFrameOrigin:warningBoxOrigin];
			
				// Move the pop-up.
			NSPoint	popUpOrigin = [plugInPopUpButton frame].origin;
			popUpOrigin.y += offset;
			[plugInPopUpButton setFrameOrigin:popUpOrigin];
			
				// Resize the editor box.
			NSRect	boxFrame = [plugInEditorBox frame];
			boxFrame.size.height += offset;
			[plugInEditorBox setFrame:boxFrame];
		}
		
		[tabView selectTabViewItemAtIndex:0];
		
		[super beginEditing];
	}
}


- (NSString *)lastChosenPlugInClassDefaultsKey
{
	return @"Last Chosen Image Orientations Class";
}


- (NSNumber *)targetImageOpacity
{
	return [NSNumber numberWithFloat:1.0];
}


- (void)embellishMosaicView:(MosaicView *)mosaicView inRect:(NSRect)rect;
{
	[super embellishMosaicView:mosaicView inRect:rect];
	
	if (!allTilesHaveOrientations)
	{
		static	NSBezierPath	*vectorPath = nil;
		if (!vectorPath)
		{
			vectorPath = [[NSBezierPath bezierPath] retain];
			
				// Start with the head.
			//NSMakeRect(-4.0, -5.0, 8.0, 12.0)
			[vectorPath moveToPoint:NSMakePoint(0.0, -4.0)];
			[vectorPath curveToPoint:NSMakePoint(0.0, 7.0) controlPoint1:NSMakePoint(-5.0, -4.0) controlPoint2:NSMakePoint(-5.0, 7.0)];
			[vectorPath curveToPoint:NSMakePoint(0.0, -4.0) controlPoint1:NSMakePoint(5.0, 7.0) controlPoint2:NSMakePoint(5.0, -4.0)];
			
				// Then the shoulders.
			[vectorPath moveToPoint:NSMakePoint(-8.0, -7.0)];
			[vectorPath curveToPoint:NSMakePoint(8.0, -7.0) controlPoint1:NSMakePoint(-8.0, -2.0) controlPoint2:NSMakePoint(8.0, -2.0)];
			[vectorPath lineToPoint:NSMakePoint(-8.0, -7.0)];
			
				// Finish with the box outline.
			[vectorPath moveToPoint:NSMakePoint(-12.0, -8.0)];
			[vectorPath lineToPoint:NSMakePoint(12.0, -8.0)];
			[vectorPath lineToPoint:NSMakePoint(12.0, 8.0)];
			[vectorPath lineToPoint:NSMakePoint(-12.0, 8.0)];
			[vectorPath lineToPoint:NSMakePoint(-12.0, -8.0)];
		}
		
			// Get the bounds of the mosaic within the mosaic view.
		NSRect							imageBounds = [mosaicView imageBounds];
		
			// Start by lightening the whole mosaic.
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.2] set];
		NSRectFillUsingOperation(NSIntersectionRect(rect, imageBounds), NSCompositeSourceOver);
				   
			// Draw a darkened vector field over the mosaic.
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.6] set];
		id<MacOSaiXImageOrientations>	imageOrientations = [[[self delegate] mosaic] imageOrientations];
		int								xCount = NSWidth(imageBounds) / 30, 
										yCount = NSHeight(imageBounds) / 30;
		float							xSize = NSWidth(imageBounds) / xCount, 
										ySize = NSHeight(imageBounds) / yCount;
		float							x, y;
		for (y = ySize / 2.0; y < NSHeight(imageBounds); y += ySize)
			for (x = xSize / 2.0; x < NSWidth(imageBounds); x += xSize)
			{
				float	angle = [imageOrientations imageOrientationAtPoint:NSMakePoint(x, y) inRectOfSize:imageBounds.size];
				
				NSAffineTransform	*transform = [NSAffineTransform transform];
				[transform translateXBy:x + NSMinX(imageBounds) yBy:y + NSMinY(imageBounds)];
				[transform rotateByDegrees:-angle];
				[[transform transformBezierPath:vectorPath] fill];
			}
				
		
		// TBD: What API would be required for the radial plug-in to draw its focus point?
	}
}


- (void)handleEvent:(NSEvent *)event inMosaicView:(MosaicView *)mosaicView;
{
		// Convert the event location to the target image's space.
	NSRect	mosaicBounds = [mosaicView imageBounds];
	NSPoint	targetLocation = [mosaicView convertPoint:[event locationInWindow] fromView:nil];
	targetLocation.x -= NSMinX(mosaicBounds);
	targetLocation.y -= NSMinY(mosaicBounds);
	targetLocation.x *= [[self targetImage] size].width / NSWidth(mosaicBounds);
	targetLocation.y *= [[self targetImage] size].height / NSHeight(mosaicBounds);
	
	NSEvent	*newEvent = [NSEvent mouseEventWithType:[event type] 
										   location:targetLocation 
									  modifierFlags:[event modifierFlags] 
										  timestamp:[event timestamp] 
									   windowNumber:[event windowNumber] 
											context:[event context] 
										eventNumber:[event eventNumber] 
										 clickCount:[event clickCount] 
										   pressure:[event pressure]];
	
	BOOL	plugInHandledEvent = NO;
	
		// Pass along mouse events to the plug in's editor.
	switch ([event type])
	{
		case NSLeftMouseDown:
		case NSRightMouseDown:
		case NSOtherMouseDown:
			plugInHandledEvent = [[self plugInEditor] mouseDownInMosaic:newEvent];
			break;
		case NSLeftMouseDragged:
		case NSRightMouseDragged:
		case NSOtherMouseDragged:
			plugInHandledEvent = [[self plugInEditor] mouseDraggedInMosaic:newEvent];
			break;
		case NSLeftMouseUp:
		case NSRightMouseUp:
		case NSOtherMouseUp:
			plugInHandledEvent = [[self plugInEditor] mouseUpInMosaic:newEvent];
			break;
		default:
			break;
	}
	
	if (!plugInHandledEvent)
		[super handleEvent:event inMosaicView:mosaicView];
}


- (void)setDataSource:(id<MacOSaiXDataSource>)dataSource value:(id)value forKey:(NSString *)key
{
	[super setDataSource:dataSource value:value forKey:key];
	
	[[self delegate] embellishmentNeedsDisplay];
}


- (void)dataSource:(id<MacOSaiXDataSource>)dataSource 
	  didChangeKey:(NSString *)key
		 fromValue:(id)previousValue 
		actionName:(NSString *)actionName;
{
	// TODO: don't display the warning continuously
	if ([[[self delegate] mosaic] numberOfImagesFound] == 0 || 
		![MacOSaiXWarningController warningIsEnabled:@"Changing Image Orientations"] || 
		[MacOSaiXWarningController runAlertForWarning:@"Changing Image Orientations" 
												title:NSLocalizedString(@"Do you wish to change the image orientations?", @"") 
											  message:NSLocalizedString(@"All work in the current mosaic will be lost.", @"") 
										 buttonTitles:[NSArray arrayWithObjects:NSLocalizedString(@"Change", @""), NSLocalizedString(@"Cancel", @""), nil]] == 0)
	{
		[super dataSource:dataSource didChangeKey:key fromValue:previousValue actionName:actionName];
		
		[[self delegate] embellishmentNeedsDisplay];
	}
	else
		[self setDataSource:dataSource value:previousValue forKey:key];
}


@end
