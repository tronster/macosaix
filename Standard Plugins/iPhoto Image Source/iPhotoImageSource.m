/*
	iPhotoImageSource.m
	MacOSaiX

	Created by Frank Midgley on Wed Mar 15 2005.
	Copyright (c) 2005 Frank M. Midgley. All rights reserved.
*/

#import "iPhotoImageSource.h"
#import "iPhotoImageSourceController.h"
#import "NSString+MacOSaiX.h"


static NSImage	*iPhotoImage = nil,
				*albumImage = nil;


@implementation MacOSaiXiPhotoImageSource


+ (void)initialize
{
	NSURL		*iPhotoAppURL = nil;
	LSFindApplicationForInfo(kLSUnknownCreator, CFSTR("com.apple.iPhoto"), NULL, NULL, (CFURLRef *)&iPhotoAppURL);
	NSBundle	*iPhotoBundle = [NSBundle bundleWithPath:[iPhotoAppURL path]];
	
	iPhotoImage = [[NSImage alloc] initWithContentsOfFile:[iPhotoBundle pathForImageResource:@"NSApplicationIcon"]];
	albumImage = [[NSImage alloc] initWithContentsOfFile:[iPhotoBundle pathForImageResource:@"album_local"]];
	[albumImage setScalesWhenResized:YES];
	[albumImage setSize:NSMakeSize(16.0, 16.0)];
}


+ (NSString *)name
{
	return @"iPhoto";
}


+ (Class)editorClass
{
	return [MacOSaiXiPhotoImageSourceController class];
}


+ (BOOL)allowMultipleImageSources
{
	return YES;
}


+ (NSImage *)albumImage
{
	return albumImage;
}


+ (NSImage *)keywordImage
{
	return nil;
}


- (id)initWithAlbumName:(NSString *)name
{
	if (self = [super init])
	{
		[self setAlbumName:name];
	}

    return self;
}


- (NSString *)settingsAsXMLElement
{
	NSMutableString	*settings = [NSMutableString string];
	
	if ([self albumName])
		[settings appendString:[NSString stringWithFormat:@"<ALBUM NAME=\"%@\"/>\n", 
										  [NSString stringByEscapingXMLEntites:[self albumName]]]];
	if ([self keywordName])
		[settings appendString:[NSString stringWithFormat:@"<KEYWORD NAME=\"%@\"/>\n", 
										  [NSString stringByEscapingXMLEntites:[self keywordName]]]];
	
	[settings appendString:[NSString stringWithFormat:@"<PHOTO_IDS REMAINING=\"%@\"/>", 
													  [remainingPhotoIDs componentsJoinedByString:@","]]];

	return settings;
}


- (void)useSavedSetting:(NSDictionary *)settingDict
{
	NSString	*settingType = [settingDict objectForKey:kMacOSaiXImageSourceSettingType];
	
	if ([settingType isEqualToString:@"ALBUM"])
		[self setAlbumName:[NSString stringByUnescapingXMLEntites:[[settingDict objectForKey:@"NAME"] description]]];
	else if ([settingType isEqualToString:@"KEYWORD"])
		[self setAlbumName:[NSString stringByUnescapingXMLEntites:[[settingDict objectForKey:@"NAME"] description]]];
	else if ([settingType isEqualToString:@"PHOTO_IDS"])
		remainingPhotoIDs = [[[[settingDict objectForKey:@"REMAINING"] description] componentsSeparatedByString:@","] mutableCopy];
}


- (void)addSavedChildSetting:(NSDictionary *)childSettingDict toParent:(NSDictionary *)parentSettingDict
{
	// not needed
}


- (void)savedSettingIsCompletelyLoaded:(NSDictionary *)settingDict
{
	// not needed
}


- (NSString *)albumName
{
	return [[albumName retain] autorelease];
}


- (void)setAlbumName:(NSString *)name
{
	[albumName autorelease];
	albumName = [name copy];
	
	if (name)
	{
		[self setKeywordName:nil];
		
		[sourceDescription autorelease];
		sourceDescription = [[NSString stringWithFormat:@"photos from \"%@\"", albumName] retain];
		
			// Indicate that the photo ID's need to be retrieved.
		[remainingPhotoIDs autorelease];
		remainingPhotoIDs = nil;
	}
}


- (NSString *)keywordName
{
	return [[keywordName retain] autorelease];
}


- (void)setKeywordName:(NSString *)name
{
	[keywordName autorelease];
	keywordName = [name copy];
	
	if (name)
	{
		[self setAlbumName:nil];
		
		[sourceDescription autorelease];
		sourceDescription = [[NSString stringWithFormat:@"\"%@\" photos", keywordName] retain];
		
			// Indicate that the photo ID's need to be retrieved.
		[remainingPhotoIDs autorelease];
		remainingPhotoIDs = nil;
	}
}


- (id)copyWithZone:(NSZone *)zone
{
	return [[MacOSaiXiPhotoImageSource allocWithZone:zone] initWithAlbumName:albumName];
}


- (NSImage *)image;
{
	return iPhotoImage;
}


- (id)descriptor
{
	if (!sourceDescription)
		sourceDescription = [[NSString stringWithString:@"All photos"] retain];
	
	return [[sourceDescription retain] autorelease];
}


- (BOOL)hasMoreImages
{
	return (!remainingPhotoIDs || [remainingPhotoIDs count] > 0);
}


- (void)getPhotoIDs
{
	NSString				*scriptText = nil;
	if (albumName)
		scriptText = [NSString stringWithFormat:@"tell application \"iPhoto\" to get id of photos of album \"%@\"", 
												albumName];
	else if (keywordName)
		scriptText = [NSString stringWithFormat:@"tell application \"iPhoto\"\r" \
													"set ids to {}\r" \
													 "repeat with thePhoto in (photos whose keywords is not {})\r" \
														 "set kws to name of keywords of thePhoto\r" \
														 "if kws contains \"%@\" then set ids to ids & (id of thePhoto)\r" \
													 "end repeat\r" \
													"ids\r" \
												 "end tell", keywordName];
	else
		scriptText = @"tell application \"iPhoto\" to get id of photos";
		
	NSAppleScript			*getPhotoIDsScript = [[[NSAppleScript alloc] initWithSource:scriptText] autorelease];
	NSDictionary			*getPhotoIDsError = nil;
	NSAppleEventDescriptor	*getPhotoIDsResult = [getPhotoIDsScript executeAndReturnError:&getPhotoIDsError];
	
	remainingPhotoIDs = [[NSMutableArray array] retain];
	
	if (!getPhotoIDsError)
	{
		int	photoIDCount = [getPhotoIDsResult numberOfItems],
			photoIDIndex;
		for (photoIDIndex = 1; photoIDIndex <= photoIDCount; photoIDIndex++)
			[remainingPhotoIDs addObject:[[getPhotoIDsResult descriptorAtIndex:photoIDIndex] stringValue]];
	}
}


- (NSImage *)nextImageAndIdentifier:(NSString **)identifier
{
	NSImage			*image = nil;
	
	if (!remainingPhotoIDs)
		[self getPhotoIDs];
	
	if ([remainingPhotoIDs count] > 0)
	{
		NSString		*photoID = [remainingPhotoIDs objectAtIndex:0];
		
		image = [self imageForIdentifier:photoID];
		
		if (image)
			*identifier = [[photoID retain] autorelease];
		
		[remainingPhotoIDs removeObjectAtIndex:0];
	}

    return image;
}


- (NSString *)pathOfPhotoWithID:(NSString *)photoID
{
	NSString				*imagePath = nil;
	NSString				*getImagePathText = [NSString stringWithFormat:
													@"tell application \"iPhoto\" to get image path of first photo whose id is %@", 
													photoID];
	NSAppleScript			*getImagePathScript = [[[NSAppleScript alloc] initWithSource:getImagePathText] autorelease];
	NSDictionary			*getImagePathError = nil;
	NSAppleEventDescriptor	*getImagePathResult = [getImagePathScript executeAndReturnError:&getImagePathError];
	
	if (!getImagePathError)
		imagePath = [getImagePathResult stringValue];
	
	return imagePath;
}


- (NSImage *)imageForIdentifier:(NSString *)identifier
{
	NSImage		*image = nil;
	NSString	*imagePath = [self pathOfPhotoWithID:identifier];
	
	if (imagePath)
	{
		NS_DURING
			image = [[[NSImage alloc] initWithContentsOfFile:imagePath] autorelease];
			if (!image)
			{
					// The image might have the wrong or a missing file extension so 
					// try init'ing it based on its contents instead.  This requires 
					// more memory so only do this if initWithContentsOfFile fails.
				NSData	*data = [[NSData alloc] initWithContentsOfFile:imagePath];
				image = [[[NSImage alloc] initWithData:data] autorelease];
				[data release];
			}
		NS_HANDLER
			NSLog(@"%@ is not a valid image file.", imagePath);
		NS_ENDHANDLER
	}
	
    return image;
}


- (void)reset
{
	[self setAlbumName:albumName];
}


- (void)dealloc
{
	[albumName release];
	[sourceDescription release];
	[remainingPhotoIDs release];
	
	[super dealloc];
}


@end