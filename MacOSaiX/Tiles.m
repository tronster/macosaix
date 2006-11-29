#import "Tiles.h"

#import "MacOSaiXDocument.h"
#import "NSBezierPath+MacOSaiX.h"


@interface MacOSaiXMosaic (TilePrivate)
- (void)tileDidExtractBitmap:(MacOSaiXTile *)tile;
@end


@implementation MacOSaiXTile


- (id)initWithOutline:(NSBezierPath *)inOutline fromMosaic:(MacOSaiXMosaic *)inMosaic
{
	if (self = [super init])
	{
		outline = [inOutline retain];
		mosaic = inMosaic;	// non-retained, it retains us
		[self setOrientation:M_PI_2];
	}
	return self;
}


- (MacOSaiXMosaic *)mosaic
{
	return mosaic;
}

- (void)setOutline:(NSBezierPath *)inOutline
{
    [outline autorelease];
    outline = [inOutline retain];
}


- (NSBezierPath *)outline
{
    return outline;
}


- (void)setOrientation:(float)angle
{
	orientation = angle;
}


- (float)orientation
{
	return orientation;
}


- (float)worstCaseMatchValue
{
	return 255.0 * 255.0 * 9.0;
}


- (void)resetBitmapRepAndMask
{
		// TODO: this should not be called from outside.  we should listen for notifications 
		// that the original image or tile shapes changed for our mosaic and reset at that
		// point.
    [bitmapRep autorelease];
    bitmapRep = nil;
    [maskRep autorelease];
    maskRep = nil;
}


- (void)createBitmapRep
{
		// Determine the bounds of the tile in the original image and in the workingImage.
	NSBezierPath	*tileOutline = [self outline];
	NSImage			*originalImage = [mosaic originalImage];
	NSRect			origRect = NSMakeRect([tileOutline bounds].origin.x * [originalImage size].width,
										  [tileOutline bounds].origin.y * [originalImage size].height,
										  [tileOutline bounds].size.width * [originalImage size].width,
										  [tileOutline bounds].size.height * [originalImage size].height),
					destRect = (origRect.size.width > origRect.size.height) ?
								NSMakeRect(0, 0, TILE_BITMAP_SIZE, TILE_BITMAP_SIZE * origRect.size.height / origRect.size.width) : 
								NSMakeRect(0, 0, TILE_BITMAP_SIZE * origRect.size.width / origRect.size.height, TILE_BITMAP_SIZE);
	
	destRect.size.width = ceilf(destRect.size.width);
	destRect.size.height = ceilf(destRect.size.height);
	
	NSImage			*workingImage = [[NSImage alloc] initWithSize:destRect.size];
	BOOL			focusLocked = NO;
	
	NS_DURING
		[workingImage lockFocus];
		focusLocked = YES;
		
			// Start with a clear image.
		[[NSColor clearColor] set];
		[[NSBezierPath bezierPathWithRect:destRect] fill];
		
			// Copy out the portion of the original image contained by the tile's outline.
		#if 0
			[originalImage drawInRect:destRect fromRect:origRect operation:NSCompositeCopy fraction:1.0];
		#else
			float				originalWidth = [originalImage size].width, 
								originalHeight = [originalImage size].height;
			NSAffineTransform	*transform = [NSAffineTransform transform];
			[transform scaleXBy:originalWidth yBy:originalHeight];
			NSBezierPath		*scaledOutline = [transform transformBezierPath:[self outline]];
			NSRect				outlineBounds = [scaledOutline bounds];
			
			transform = [NSAffineTransform transform];
			[transform rotateByDegrees:-[self imageOrientation]];
			[transform translateXBy:-NSMidX(outlineBounds) yBy:-NSMidY(outlineBounds)];
			NSRect				rotatedBounds = [[transform transformBezierPath:scaledOutline] bounds];
			
			transform = [NSAffineTransform transform];
			[transform translateXBy:NSWidth([contentOutline bounds]) / 2.0 yBy:NSHeight([contentOutline bounds]) / 2.0];
			[transform rotateByDegrees:[self imageOrientation]];
			if ((NSWidth(rotatedBounds) / NSWidth(outlineBounds)) > (NSHeight(rotatedBounds) / originalImageHeight))
				[transform scaleBy:NSWidth(rotatedBounds) / originalImageWidth];
			else
				[transform scaleBy:NSHeight(rotatedBounds) / originalImageHeight];
			
			[transform concat];
			[tileImage drawInRect:NSMakeRect(-NSMinX(outlineBounds) - NSWidth(outlineBounds) / 2.0, 
											 -NSMinY(outlineBounds) - NSHeight(outlineBounds) / 2.0, 
											 NSWidth(outlineBounds), 
											 NSHeight(outlineBounds)) 
						 fromRect:NSZeroRect 
						operation:NSCompositeCopy 
						 fraction:1.0];
		#endif
		
		bitmapRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:destRect];
		#ifdef DEBUG
			if (bitmapRep == nil)
				NSLog(@"Could not extract tile image from original.");
		#endif
	NS_HANDLER
		#ifdef DEBUG
			NSLog(@"Exception raised while extracting tile images: %@", [localException name]);
		#endif
	NS_ENDHANDLER
	
	if (focusLocked)
		[workingImage unlockFocus];
	
	[workingImage release];

		// Calculate a mask image using the tile's outline that is the same size as the image
		// extracted from the original.  The mask will be white for pixels that are inside the 
		// tile and black outside.
		// (This would work better if we could just replace the previous rep's alpha channel
		//  but I haven't figured out an easy way to do that yet.)
	maskRep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil 
													   pixelsWide:NSWidth(destRect) 
													   pixelsHigh:NSHeight(destRect) 
													bitsPerSample:8 
												  samplesPerPixel:1 
														 hasAlpha:NO 
														 isPlanar:NO 
												   colorSpaceName:NSCalibratedWhiteColorSpace 
													  bytesPerRow:0 
													 bitsPerPixel:0];
	CGColorSpaceRef	grayscaleColorSpace = CGColorSpaceCreateDeviceGray();
	CGContextRef	bitmapContext = CGBitmapContextCreate([maskRep bitmapData], 
														  [maskRep pixelsWide], 
														  [maskRep pixelsHigh], 
														  [maskRep bitsPerSample], 
														  [maskRep bytesPerRow], 
														  grayscaleColorSpace,
														  kCGBitmapByteOrderDefault);
		// Start with a black background.
	CGContextSetGrayFillColor(bitmapContext, 0.0, 1.0);
	CGRect			cgDestRect = CGRectMake(destRect.origin.x, destRect.origin.y, 
											destRect.size.width, destRect.size.height);
	CGContextFillRect(bitmapContext, cgDestRect);
	
		// Fill the tile's outline with white.
	NSAffineTransform  *transform = [NSAffineTransform transform];
	[transform scaleXBy:destRect.size.width / [tileOutline bounds].size.width
					yBy:destRect.size.height / [tileOutline bounds].size.height];
	[transform translateXBy:[tileOutline bounds].origin.x * -1
						yBy:[tileOutline bounds].origin.y * -1];
	CGPathRef		cgTileOutline = [[transform transformBezierPath:tileOutline] quartzPath];
	CGContextSetGrayFillColor(bitmapContext, 1.0, 1.0);
	CGContextBeginPath(bitmapContext);
	CGContextAddPath(bitmapContext, cgTileOutline);
	CGContextClosePath(bitmapContext);
	CGContextFillPath(bitmapContext);
	CGPathRelease(cgTileOutline);
	
	CGContextRelease(bitmapContext);
	CGColorSpaceRelease(grayscaleColorSpace);
}


- (NSBitmapImageRep *)bitmapRep
{
	if (!bitmapRep)
	{
		[self performSelectorOnMainThread:@selector(createBitmapRep) withObject:nil waitUntilDone:YES];
		
		[mosaic tileDidExtractBitmap:self];
	}
	
    return bitmapRep;
}


- (NSBitmapImageRep *)maskRep
{
	return maskRep;
}


- (void)sendNotificationThatImageMatch:(NSString *)matchType changedFrom:(MacOSaiXImageMatch *)previousMatch
{
	[[NSNotificationCenter defaultCenter] postNotificationName:MacOSaiXTileImageDidChangeNotification
														object:mosaic 
													  userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																	self, @"Tile", 
																	matchType, @"Match Type", 
																	previousMatch, @"Previous Match",
																	nil]];
}


- (void)setUniqueImageMatch:(MacOSaiXImageMatch *)match
{
	if (match != uniqueImageMatch)
	{
		MacOSaiXImageMatch	*previousMatch = uniqueImageMatch;
		
		[uniqueImageMatch autorelease];
		uniqueImageMatch = [match retain];
		
		[self sendNotificationThatImageMatch:@"Unique" changedFrom:previousMatch];
	}
}


- (MacOSaiXImageMatch *)uniqueImageMatch
{
	return [[uniqueImageMatch retain] autorelease];
}


- (void)setBestImageMatch:(MacOSaiXImageMatch *)match
{
	if (match != bestImageMatch)
	{
		MacOSaiXImageMatch	*previousMatch = bestImageMatch;
		
		[bestImageMatch autorelease];
		bestImageMatch = [match retain];
		
		[self sendNotificationThatImageMatch:@"Best" changedFrom:previousMatch];
	}
}


- (MacOSaiXImageMatch *)bestImageMatch
{
	return [[bestImageMatch retain] autorelease];
}


- (void)setUserChosenImageMatch:(MacOSaiXImageMatch *)match
{
	if (match != userChosenImageMatch)
	{
		MacOSaiXImageMatch	*previousMatch = userChosenImageMatch;
		
		[userChosenImageMatch autorelease];
		userChosenImageMatch = [match retain];
		
		[self sendNotificationThatImageMatch:@"User Chosen" changedFrom:previousMatch];
	}
}


- (MacOSaiXImageMatch *)userChosenImageMatch;
{
	return [[userChosenImageMatch retain] autorelease];
}


- (MacOSaiXImageMatch *)displayedImageMatch
{
	if (userChosenImageMatch)
		return userChosenImageMatch;
	else if (uniqueImageMatch)
		return uniqueImageMatch;
	else if (bestImageMatch)
		return bestImageMatch;
	else
		return nil;
}


- (void)dealloc
{
    [outline release];
    [bitmapRep release];
	[maskRep release];
	[uniqueImageMatch release];
    [userChosenImageMatch release];
	[bestImageMatch release];
	
    [super dealloc];
}


@end
