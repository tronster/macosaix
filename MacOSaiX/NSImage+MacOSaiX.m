//
//  NSImage+MacOSaiX.m
//  MacOSaiX
//
//  Created by Frank Midgley on 11/13/04.
//  Copyright 2004 Frank M. Midgley. All rights reserved.
//

#import "NSImage+MacOSaiX.h"


@implementation NSImage (MacOSaiX)


- (NSImage *)copyWithLargestDimension:(int)largestDimension
{
	NSSize				copySize, originalSize = [self size];
	
	if (originalSize.width > originalSize.height)
		copySize = NSMakeSize(largestDimension, roundf(originalSize.height * largestDimension / originalSize.width));
	else
		copySize = NSMakeSize(roundf(originalSize.width * largestDimension / originalSize.height), largestDimension);
	
	NSRect				copyRect = NSMakeRect(0.0, 0.0, copySize.width, copySize.height);
	
	NSImage				*copy = [[NSImage alloc] initWithSize:copySize];
	
	NSBitmapImageRep	*bitmapRep = nil;
	BOOL				haveFocus = NO;
	while (!haveFocus)	// && ???
	{
		NS_DURING
			[copy lockFocus];
			haveFocus = YES;
		NS_HANDLER
			#ifdef DEBUG
				NSLog(@"Couldn't lock focus on image copy: %@", localException);
			#endif
		NS_ENDHANDLER
	}
	
	if (haveFocus)
	{
		[[NSGraphicsContext currentContext] saveGraphicsState];
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		[self drawInRect:copyRect 
			    fromRect:NSMakeRect(0.0, 0.0, originalSize.width, originalSize.height) 
			   operation:NSCompositeCopy 
			    fraction:1.0];
		bitmapRep = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:copyRect] autorelease];
		[[NSGraphicsContext currentContext] restoreGraphicsState];
		[copy unlockFocus];
		
		[copy removeRepresentation:[[copy representations] lastObject]];
		[copy addRepresentation:bitmapRep];
	}
	else
	{
		#ifdef DEBUG
			NSLog(@"Couldn't create cached thumbnail image.");
		#endif
	}
	
	return copy;
}


@end
