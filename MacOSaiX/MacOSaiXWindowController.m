/*
	MacOSaiXWindowController.h
	MacOSaiX

	Created by Frank Midgley on Sun Oct 24 2004.
	Copyright (c) 2004 Frank M. Midgley. All rights reserved.
*/

//#import <HIToolbox/MacWindows.h>
#import "MacOSaiX.h"
#import "MacOSaiXWindowController.h"
#import "MacOSaiXDocument.h"
#import "Tiles.h"
#import "MosaicView.h"
#import "OriginalView.h"
#import <unistd.h>


@interface MacOSaiXWindowController (PrivateMethods)
- (void)chooseOriginalImage;
- (void)spawnImageSourceThreads;
- (void)synchronizeMenus;
- (void)updateMosaicImage:(NSMutableArray *)updatedTiles;
- (void)calculateImageMatches:(id)path;
- (void)updateEditor;
- (BOOL)showTileMatchInEditor:(ImageMatch *)tileMatch selecting:(BOOL)selecting;
- (NSImage *)createEditorImage:(int)rowIndex;
- (void)allowUserToChooseImageOpenPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode
    contextInfo:(void *)context;
- (void)exportImage:(id)exportFilename;
- (void)setOriginalImagePath:(NSString *)path;
@end


@implementation MacOSaiXWindowController

- (id)init
{
    if (self = [super init])
    {
		viewMode = viewMosaicAndOriginal;
		statusBarShowing = YES;
		exportFormat = NSJPEGFileType;
	}
	
    return self;
}


- (NSString *)windowNibName
{
    return @"MacOSaiXDocument";
}


- (void)awakeFromNib
{
    viewMenu = [[[NSApp mainMenu] itemWithTitle:@"View"] submenu];
    fileMenu = [[[NSApp mainMenu] itemWithTitle:@"File"] submenu];

		// set up the toolbar
    pauseToolbarItem = nil;
    zoomToolbarMenuItem = [[NSMenuItem alloc] initWithTitle:@"Zoom" action:nil keyEquivalent:@""];
    [zoomToolbarMenuItem setSubmenu:zoomToolbarSubmenu];
    toolbarItems = [[NSMutableDictionary dictionary] retain];
    NSToolbar   *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"MacOSaiXDocument"] autorelease];
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [[self window] setToolbar:toolbar];
    
		// Make sure we have the latest and greatest list of plug-ins
	[[NSApp delegate] discoverPlugIns];

	{
			// Set up the "Setup" tab
		[tilesSetupView setTitlePosition:NSNoTitle];
		
			// Populate the original image pop-up menu
		NSEnumerator	*originalEnumerator = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Recent Originals"] objectEnumerator];
		NSDictionary	*originalDict = nil;
		while (originalDict = [originalEnumerator nextObject])
		{
			NSString	*originalPath = [originalDict objectForKey:@"Path"],
						*originalName = [originalDict objectForKey:@"Name"];
			NSImage		*originalThumbnail = [[NSImage alloc] initWithData:[originalDict objectForKey:@"Thumbnail Data"]];
			
			if ([[NSFileManager defaultManager] fileExistsAtPath:originalPath])
			{
				if (!originalName)
					originalName = [[originalPath lastPathComponent] stringByDeletingPathExtension];
				
				NSMenuItem	*originalItem = [[[NSMenuItem alloc] init] autorelease];
				[originalItem setTitle:originalName];
				[originalItem setRepresentedObject:originalPath];
				if (originalThumbnail)
					[originalItem setImage:originalThumbnail];
				[[originalImagePopUpButton menu] insertItem:originalItem
													atIndex:[originalImagePopUpButton numberOfItems] - 1];
			}
		}
		[originalImagePopUpButton selectItemAtIndex:0];
		
			// Load the names of the tile setup plug-ins
		NSEnumerator	*enumerator = [[[NSApp delegate] tilesSetupControllerClasses] objectEnumerator];
		Class			tilesSetupControllerClass;
		[tilesSetupPopUpButton removeAllItems];
		while (tilesSetupControllerClass = [enumerator nextObject])
			[tilesSetupPopUpButton addItemWithTitle:[tilesSetupControllerClass name]];
		[self setTilesSetupPlugIn:self];
		
			// Restore the last neighborhood size that the user chose.
		int				popUpIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"Neighborhood Size"] - 1;
		if (popUpIndex >= 0 && popUpIndex < [neighborhoodSizePopUpButton numberOfItems])
			[neighborhoodSizePopUpButton selectItemAtIndex:popUpIndex];
	}
	
	{
			// Set up the "Image Sources" tab
		[imageSourcesTableView setDoubleAction:@selector(editImageSource:)];

		[[imageSourcesTableView tableColumnWithIdentifier:@"Image Source Type"]
			setDataCell:[[[NSImageCell alloc] init] autorelease]];
		[imageSourcesRemoveButton setEnabled:NO];	// temporarily disabled for 2.0a1
	
			// Load the image source plug-ins and create an instance of each controller
		NSEnumerator	*enumerator = [[[NSApp delegate] imageSourceClasses] objectEnumerator];
		Class			imageSourceClass;
		[imageSourcesPopUpButton removeAllItems];
		[imageSourcesPopUpButton addItemWithTitle:@"Add Source of Images"];
		while (imageSourceClass = [enumerator nextObject])
		{
				// add the name of the image source to the pop-up menu
			[imageSourcesPopUpButton addItemWithTitle:[NSString stringWithFormat:@"%@...", [imageSourceClass name]]];
				// attach it to the menu item (it will be dealloced when the menu item releases it)
			[[imageSourcesPopUpButton lastItem] setRepresentedObject:imageSourceClass];
		}
	}
	
	{	// Set up the "Editor" tab
		[[editorTable tableColumnWithIdentifier:@"image"] setDataCell:[[[NSImageCell alloc] init] autorelease]];
	}
	
	[self setViewMode:viewMosaicAndTilesSetup];
	
		// For some reason IB insists on setting the drawer width to 200.  Have to set the size in code instead.
	[utilitiesDrawer setContentSize:NSMakeSize(400, [utilitiesDrawer contentSize].height)];
	
    selectedTile = nil;
    
//    NSRect		windowFrame;
//    if (finishLoading)
//    {
//		//	[self setViewMode:viewMode];
//		
//			// this doc was opened from a file
//		if ([[self document] isPaused])
//		{
//			[pauseToolbarItem setLabel:@"Resume"];
//			[pauseToolbarItem setImage:[NSImage imageNamed:@"Resume"]];
//			[[fileMenu itemWithTitle:@"Pause Matching"] setTitle:@"Resume Matching"];
//		}
//	
//			//	broken & disabled until next version
//		//	[self windowWillResize:[self window] toSize:storedWindowFrame.size];
//		//	[[self window] setFrame:storedWindowFrame display:YES];
//		windowFrame = [[self window] frame];
//		windowFrame.size = [self windowWillResize:[self window] toSize:windowFrame.size];
//		[[self window] setFrame:windowFrame display:YES animate:YES];
//    }
//    else
//    {
//			// this doc is new
//		windowFrame = [[self window] frame];
//		windowFrame.size = [self windowWillResize:[self window] toSize:windowFrame.size];
//		[[self window] setFrame:windowFrame display:YES animate:YES];
//    }
//	[pauseToolbarItem setLabel:@"Start Mosaic"];
}


- (void)windowDidLoad
{
	[super windowDidLoad];
	
		// Default to the most recently used original or prompt to choose one
		// if no previous original was found.
	[self chooseOriginalImage:self];
}


#pragma mark
#pragma mark Original image management


- (IBAction)chooseOriginalImage:(id)sender
{
	NSString	*originalPath = [[originalImagePopUpButton selectedItem] representedObject];
	
	if (originalPath)
		[self setOriginalImagePath:originalPath];
	else
	{
			// Prompt the user to choose the image from which to make a mosaic.
		NSOpenPanel	*oPanel = [NSOpenPanel openPanel];
		[oPanel setCanChooseFiles:YES];
		[oPanel setCanChooseDirectories:NO];
		[oPanel beginSheetForDirectory:nil
								  file:nil
								 types:[NSImage imageFileTypes]
						modalForWindow:[self window]
						 modalDelegate:self
						didEndSelector:@selector(chooseOriginalImagePanelDidEnd:returnCode:contextInfo:)
						   contextInfo:nil];
	}
}


- (void)chooseOriginalImagePanelDidEnd:(NSOpenPanel *)sheet 
							returnCode:(int)returnCode
						   contextInfo:(void *)context
{
    if (returnCode == NSOKButton)
		[self setOriginalImagePath:[[sheet filenames] objectAtIndex:0]];
}


- (void)setOriginalImagePath:(NSString *)path
{
	[[self document] setOriginalImagePath:path];
	
		// Remember this original for later use
	NSMutableArray	*originals = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"Recent Originals"] mutableCopy] autorelease];
	if (originals)
	{
			// Remove any previous entry from the defaults for the image at this path.
		NSEnumerator	*originalEnumerator = [originals objectEnumerator];
		NSDictionary	*originalDict = nil;
		while (originalDict = [originalEnumerator nextObject])
			if ([[originalDict objectForKey:@"Path"] isEqualToString:path])
			{
				[originals removeObject:originalDict];
				break;
			}
	}
	else
		originals = [NSMutableArray array];
	NSSize			origSize = [originalImage size];
	NSImage			*thumbnailImage = [[[NSImage alloc] initWithSize:NSMakeSize(16.0, 16.0)] autorelease];
	[thumbnailImage lockFocus];
		if (origSize.width > origSize.height)
			[originalImage drawInRect:NSMakeRect(0, (16.0 - 16.0 * origSize.height / origSize.width) / 2.0, 16.0, 16.0 * origSize.height / origSize.width) 
							 fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
		else
			[originalImage drawInRect:NSMakeRect((16.0 - 16.0 * origSize.width / origSize.height) / 2.0, 0, 16.0 * origSize.width / origSize.height, 32.0)
							 fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[thumbnailImage unlockFocus];
	[originals insertObject:[NSDictionary dictionaryWithObjectsAndKeys:
								path, @"Path", 
								[[path lastPathComponent] stringByDeletingPathExtension], @"Name", 
								[thumbnailImage TIFFRepresentation], @"Thumbnail Data",
								nil]
					atIndex:0];
	[[NSUserDefaults standardUserDefaults] setObject:originals forKey:@"Recent Originals"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	NSMenuItem	*originalItem = [[[NSMenuItem alloc] init] autorelease];
	[originalItem setTitle:[[path lastPathComponent] stringByDeletingPathExtension]];
	[originalItem setRepresentedObject:path];
	if (thumbnailImage)
		[originalItem setImage:thumbnailImage];
	
		// Update the original image pop-up menu.
	NSEnumerator	*itemEnumerator = [[[originalImagePopUpButton menu] itemArray] objectEnumerator];
	NSMenuItem		*item = nil;
	while (item = [itemEnumerator nextObject])
		if ([[item representedObject] isEqualToString:path])
		{
			[[originalImagePopUpButton menu] removeItem:item];
			break;
		}
	[originalImagePopUpButton selectItemAtIndex:0];
	[[originalImagePopUpButton menu] insertItem:originalItem atIndex:0];
	
		// Create an NSImage to hold the mosaic image (somewhat arbitrary size)
    [mosaicImage autorelease];
    mosaicImage = [[NSImage alloc] initWithSize:NSMakeSize(1600, 1600 * 
						[originalImage size].height / [originalImage size].width)];
    
	[mosaicView setOriginalImage:originalImage];
	[mosaicView setMosaicImage:mosaicImage];
	[mosaicView setViewMode:viewTilesOutline];
	
    mosaicImageUpdated = NO;

    mosaicImageLock = [[NSLock alloc] init];
    
		// Create a timer to update the window once per second.
    updateDisplayTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0
							   target:(id)self
							 selector:@selector(updateDisplay:)
							 userInfo:nil
							  repeats:YES] retain];
		// Create a timer to animate any selected tile ten times per second.
		// TODO: only do this when a tile is highlighted and in Tiles or Editor mode.
    animateTileTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1
							 target:(id)self
						       selector:@selector(animateSelectedTile:)
						       userInfo:nil
							repeats:YES] retain];

    [[NSNotificationCenter defaultCenter] addObserver:self
					     selector:@selector(mosaicViewDidScroll:)
						 name:@"View Did Scroll" object:nil];

    removedSubviews = nil;
    
    [self setZoom:self];
	
	// TODO: resize the window to respect the original's aspect ratio
}


- (void)pause
{
	if (![[self document] isPaused])
	{
			// Update the toolbar.
		[pauseToolbarItem setLabel:@"Resume"];
		[pauseToolbarItem setImage:[NSImage imageNamed:@"Resume"]];
		
			// Update the menu bar.
		[[fileMenu itemWithTitle:@"Pause Matching"] setTitle:@"Resume Matching"];
		
		[[self document] pause];
	}
}


- (void)resume
{
	if ([[self document] isPaused])
	{
		if ([[[[self document] tiles] objectAtIndex:0] bitmapRep] == nil)
		{
				// Make sure the tiles can't be tweaked now that the mosaic was started.
			[tilesSetupPopUpButton setEnabled:NO];
			NSMutableArray	*views = [NSMutableArray arrayWithObject:tilesSetupView];
			while ([views count] > 0)
			{
				NSView	*view = [views objectAtIndex:0];
				
				if ([view respondsToSelector:@selector(setEnabled:)])
					[(NSControl *)view setEnabled:NO];
				
				[views addObjectsFromArray:[view subviews]];
				[views removeObjectAtIndex:0];
			}
			[neighborhoodSizePopUpButton setEnabled:NO];
		}
		else
		{
				// Update the toolbar
			[pauseToolbarItem setLabel:@"Pause"];
			[pauseToolbarItem setImage:[NSImage imageNamed:@"Pause"]];
			
				// Update the menu bar
			[[fileMenu itemWithTitle:@"Resume Matching"] setTitle:@"Pause Matching"];
		}
		
		[[self document] resume];
	}
}


#pragma mark
#pragma mark ???


- (MacOSaiXDocument *)document
{
	return (MacOSaiXDocument *)[super document];
}

- (void)updateDisplay:(id)timer
{
    NSString	*statusMessage, *fullMessage;
    
    if ([[self document] isClosing]) return;
    
    // update the status bar
    if ([[self document] isCreatingTiles])
		statusMessage = [NSString stringWithFormat:@"Extracting tile images (%f%%)", 
												   [[self document] tileCreationPercentComplete]];
    else if ([[self document] isCalculatingImageMatches] && [[self document] isCalculatingDisplayedImages])
		statusMessage = [NSString stringWithString:@"Matching and finding unique tiles..."];
    else if ([[self document] isCalculatingImageMatches])
		statusMessage = [NSString stringWithString:@"Matching images..."];
    else if ([[self document] isCalculatingDisplayedImages])
		statusMessage = [NSString stringWithString:@"Finding unique tiles..."];
    else if ([[self document] isEnumeratingImageSources] > 0)
		statusMessage = [NSString stringWithString:@"Looking for new images..."];
    else if ([[self document] isPaused])
		statusMessage = [NSString stringWithString:@"Paused"];
    else
		statusMessage = [NSString stringWithString:@"No more images"];
	
    fullMessage = [NSString stringWithFormat:@"Images Matched: %d     Mosaic Quality: %2.1f%%     Status: %@",
											 [[self document] imagesMatched], overallMatch, statusMessage];
	if ([fullMessage sizeWithAttributes:[[statusMessageView attributedStringValue] attributesAtIndex:0 effectiveRange:nil]].width 
		> [statusMessageView frame].size.width)
		fullMessage = [NSString stringWithFormat:@"%d     %2.1f%%     %@",
												 [[self document] imagesMatched], overallMatch, statusMessage];
    [statusMessageView setStringValue:fullMessage];
    
    // update the mosaic image
    if (mosaicImageUpdated && [mosaicImageLock tryLock])
    {
		[mosaicView setMosaicImage:nil];
		[mosaicView setMosaicImage:mosaicImage];
		mosaicImageUpdated = NO;
		[mosaicImageLock unlock];
    }
    
    // update the image sources table
    [imageSourcesTableView reloadData];
    
    // autosave if it's time
//    if ([lastSaved timeIntervalSinceNow] < autosaveFrequency * -60)
//    {
//		[self saveDocument:self];
//		[lastSaved autorelease];
//		lastSaved = [[NSDate date] retain];
//    }
    
    // 
}


- (void)synchronizeMenus
{
    [[fileMenu itemWithTag:1] setTitle:([[self document] isPaused] ? @"Resume Matching" : @"Pause Matching")];
    
    [[viewMenu itemWithTitle:@"View Mosaic and Original"]
	setState:(viewMode == viewMosaicAndOriginal ? NSOnState : NSOffState)];
    [[viewMenu itemWithTitle:@"View Mosaic Alone"]
	setState:(viewMode == viewMosaicAlone ? NSOnState : NSOffState)];
    [[viewMenu itemWithTitle:@"View Mosaic Editor"]
	setState:(viewMode == viewMosaicEditor ? NSOnState : NSOffState)];

    [[viewMenu itemWithTitle:@"Show Status Bar"]
	setTitle:(statusBarShowing ? @"Hide Status Bar" : @"Show Status Bar")];
}


- (void)setTileOutlines:(NSArray *)tileOutlines
{
	[totalTilesField setIntValue:[tileOutlines count]];
	
	[[self document] setTileOutlines:tileOutlines];
	
	if (selectedTile)
		[self selectTileAtPoint:tileSelectionPoint];
		
	mosaicStarted = NO;
}


#pragma mark -
#pragma mark Tile setup methods

- (IBAction)setTilesSetupPlugIn:(id)sender
{
	NSString		*selectedPlugIn = [tilesSetupPopUpButton titleOfSelectedItem];
	NSEnumerator	*enumerator = [[[NSApp delegate] tilesSetupControllerClasses] objectEnumerator];
	Class			tilesSetupControllerClass;
	
	while (tilesSetupControllerClass = [enumerator nextObject])
		if ([selectedPlugIn isEqualToString:[tilesSetupControllerClass name]])
		{
			if (tilesSetupController)
			{
					// remove the tile setup that was have been set before
				[tilesSetupView setContentView:nil];
				[tilesSetupController release];
			}
			
				// create an instance of the class for this document
			tilesSetupController = [[tilesSetupControllerClass alloc] init];
			
				// let the plug-in know how to message back to us
			[tilesSetupController setDocument:[self document]];
			
				// Display the plug-in's view
			[tilesSetupView setContentView:[tilesSetupController setupView]];
			
			return;
		}
}


- (IBAction)setNeighborhoodSize:(id)sender
{
	[[self document] setNeighborhoodSize:[neighborhoodSizePopUpButton indexOfSelectedItem] + 1];
	
	if (selectedTile)
		[mosaicView highlightTile:selectedTile];
}


#pragma mark -
#pragma mark Image Sources tab methods


- (void)addNewImageSource:(id)sender
{
	if ([imageSourcesPopUpButton indexOfSelectedItem] > 0)
	{
		Class								imageSourceClass = [[imageSourcesPopUpButton selectedItem] representedObject];
		id<MacOSaiXImageSource>				newSource = [[[imageSourceClass alloc] init] autorelease];
		id<MacOSaiXImageSourceController>	controller = [[[[imageSourceClass editorClass] alloc] init] autorelease];
		
		[imageSourceEditorBox setContentView:[controller imageSourceView]];
		[controller setOKButton:imageSourceEditorOKButton];
		[controller editImageSource:newSource];
		
		[NSApp beginSheet:imageSourceEditorPanel 
		   modalForWindow:[self window]
		    modalDelegate:self 
		   didEndSelector:@selector(imageSourceEditorDidEnd:returnCode:contextInfo:) 
			  contextInfo:[[NSArray arrayWithObjects:newSource, controller, nil] retain]];
	}
}


- (IBAction)editImageSource:(id)sender
{
	// TBD: check if sheet already displayed?
	
	if (sender == imageSourcesTableView)
	{
		id<MacOSaiXImageSource>				originalSource = [[[self document] imageSources] objectAtIndex:[imageSourcesTableView selectedRow]],
											newSource = [[originalSource copyWithZone:[self zone]] autorelease];
		id<MacOSaiXImageSourceController>	controller = [[[[[newSource class] editorClass] alloc] init] autorelease];
		
		[imageSourceEditorBox setContentView:[controller imageSourceView]];
		[controller editImageSource:newSource];
		
		[NSApp beginSheet:imageSourceEditorPanel 
		   modalForWindow:[self window]
		    modalDelegate:self 
		   didEndSelector:@selector(imageSourceEditorDidEnd:returnCode:contextInfo:) 
			  contextInfo:[[NSArray arrayWithObjects:newSource, controller, originalSource, nil] retain]];
	}
}


- (void)imageSourceEditorDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	NSArray								*parameters = (NSArray *)contextInfo;
	id<MacOSaiXImageSource>				editedImageSource = [parameters objectAtIndex:0],
										originalImageSource = ([parameters count] == 3 ? [parameters lastObject] : nil);
//	id<MacOSaiXImageSourceController>	controller = [parameters objectAtIndex:1];
	
	[sheet orderOut:self];
	
	if (returnCode == NSOKButton)
	{
		[[self document] removeImageSource:originalImageSource];
		[[self document] addImageSource:editedImageSource];
		
		[imageSourcesTableView reloadData];
	}
	
	[imageSourceEditorBox setContentView:nil];
	[(id)contextInfo release];
}


- (IBAction)removeImageSource:(id)sender
{
	id<MacOSaiXImageSource>	imageSource = [[[self document] imageSources] objectAtIndex:[imageSourcesTableView selectedRow]];
	
	[[self document] removeImageSource:imageSource];
}


#pragma mark -
#pragma mark Images tab methods


	// Image source editor methods
- (IBAction)saveImageSource:(id)sender;
{
	[NSApp endSheet:imageSourceEditorPanel returnCode:NSOKButton];
}


- (IBAction)cancelImageSource:(id)sender
{
	[NSApp endSheet:imageSourceEditorPanel returnCode:NSCancelButton];
}


#pragma mark -
#pragma mark Editor methods


- (void)selectTileAtPoint:(NSPoint)thePoint
{
	tileSelectionPoint = thePoint;
	
	[selectedTile autorelease];
	selectedTile = nil;
		
    thePoint.x = thePoint.x / [mosaicView frame].size.width;
    thePoint.y = thePoint.y / [mosaicView frame].size.height;
    
        // TBD: this isn't terribly efficient...
	NSEnumerator	*tileEnumerator = [[[self document] tiles] objectEnumerator];
	Tile			*tile = nil;
	while (tile = [tileEnumerator nextObject])
        if ([[tile outline] containsPoint:thePoint])
        {
            selectedTile = [tile retain];
            [mosaicView highlightTile:selectedTile];
			
			if ([mosaicView viewMode] == viewHighlightedTile)
			{
				[editorLabel setStringValue:@"Image to use for selected tile:"];
				[editorUseCustomImage setEnabled:YES];
				[editorUseBestUniqueMatch setEnabled:YES];
				
				[editorTable scrollRowToVisible:0];
				[self updateEditor];
            }
			
			break;
        }
}


- (void)animateSelectedTile:(id)timer
{
    if (selectedTile && ![[self document] isClosing])
        [mosaicView animateHighlight];
}


- (void)updateEditor
{
    [selectedTileImages release];
    
    if (selectedTile)
    {
        [editorUseCustomImage setState:NSOffState];
        [editorUseBestUniqueMatch setState:NSOffState];
        [editorUserChosenImage setImage:nil];
        [editorChooseImage setEnabled:NO];
        [editorUseSelectedImage setEnabled:NO];
        selectedTileImages = [[NSMutableArray arrayWithCapacity:0] retain];
    }
    else
    {
        if ([selectedTile userChosenImageMatch])
        {
            [editorUseCustomImage setState:NSOffState];	// NSOnState];	temp for 2.0a1
            [editorUseBestUniqueMatch setState:NSOffState];
// TODO:            [editorUserChosenImage setImage:[[selectedTile userChosenImageMatch] image]];
        }
        else
        {
            [editorUseCustomImage setState:NSOffState];
            [editorUseBestUniqueMatch setState:NSOffState];	// NSOnState];	temp for 2.0a1
            [editorUserChosenImage setImage:nil];
            
            NSImage	*image = [[[NSImage alloc] initWithSize:[[selectedTile bitmapRep] size]] autorelease];
            [image addRepresentation:[selectedTile bitmapRep]];
            [editorUserChosenImage setImage:image];
        }
    
        [editorChooseImage setEnabled:NO];	// YES];	temp for 2.0a1
        [editorUseSelectedImage setEnabled:NO];	// YES];	temp for 2.0a1
        
        selectedTileImages = [[NSMutableArray arrayWithCapacity:[selectedTile matchCount]] retain];
        int	i;
        for (i = 0; i < [selectedTile matchCount]; i++)
            [selectedTileImages addObject:[NSNull null]];
    }
    
    [editorTable reloadData];
}


- (BOOL)showTileMatchInEditor:(ImageMatch *)tileMatch selecting:(BOOL)selecting
{
//    if (selectedTile == nil) return NO;
//    
//    int	i;
//    for (i = 0; i < [selectedTile matchCount]; i++)
//        if (&([selectedTile matches][i]) == tileMatch)
//        {
//            if (selecting)
//                [editorTable selectRow:i byExtendingSelection:NO];
//            [editorTable scrollRowToVisible:i];
//            return YES;
//        }
    
    return NO;
}


- (NSImage *)createEditorImage:(int)rowIndex
{
    NSImage				*image = nil;
    NSAffineTransform	*transform = [NSAffineTransform transform];
    NSSize				tileSize = [[selectedTile outline] bounds].size;
    float				scale;
    NSPoint				origin;
    NSBezierPath		*bezierPath = [NSBezierPath bezierPath];
    
	ImageMatch	*imageMatch = [[selectedTile matches] objectAtIndex:rowIndex];
	image = [[[self document] imageCache] cachedImageForIdentifier:[imageMatch imageIdentifier] 
														fromSource:[imageMatch imageSource]];
    if (image == nil)
        return [NSImage imageNamed:@"Blank"];
	
    image = [[image copy] autorelease];
    
    // scale the image to at most 80 pixels (the size of the editor column)
    if ([image size].width > [image size].height)
        [image setSize:NSMakeSize(80, 80 / [image size].width * [image size].height)];
    else
        [image setSize:NSMakeSize(80 / [image size].height * [image size].width, 80)];

    tileSize.width *= [mosaicImage size].width;
    tileSize.height *= [mosaicImage size].height;
    if (([image size].width / tileSize.width) < ([image size].height / tileSize.height))
    {
		scale = [image size].width / tileSize.width;
		origin = NSMakePoint(0.0, ([image size].height - tileSize.height * scale) / 2.0);
    }
    else
    {
		scale = [image size].height / tileSize.height;
		origin = NSMakePoint(([image size].width - tileSize.width * scale) / 2.0, 0.0);
    }
    [transform translateXBy:origin.x yBy:origin.y];
    [transform scaleXBy:scale yBy:scale];
    [transform scaleXBy:[mosaicImage size].width yBy:[mosaicImage size].height];
    [transform translateXBy:[[selectedTile outline] bounds].origin.x * -1
			yBy:[[selectedTile outline] bounds].origin.y * -1];
    
	NS_DURING
		[image lockFocus];
	NS_HANDLER
		NSLog(@"Could not lock focus on editor image");
	NS_ENDHANDLER
	// add the tile outline
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.5] set];	//lighten
	[bezierPath moveToPoint:NSMakePoint(0, 0)];
	[bezierPath lineToPoint:NSMakePoint(0, [image size].height)];
	[bezierPath lineToPoint:NSMakePoint([image size].width, [image size].height)];
	[bezierPath lineToPoint:NSMakePoint([image size].width, 0)];
	[bezierPath closePath];
	[bezierPath appendBezierPath:[transform transformBezierPath:[selectedTile outline]]];
	[bezierPath fill];
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set]; //darken
	[bezierPath stroke];
	
	// add a badge if it's the user chosen image
//	if ([[selectedTile matches] objectAtIndex:rowIndex] == [selectedTile displayMatch])
//	{
//	    NSBezierPath	*badgePath = [NSBezierPath bezierPathWithOvalInRect:
//						NSMakeRect([image size].width - 12, 2, 10, 10)];
//						
//	    [[NSColor colorWithCalibratedRed:1.0 green:0 blue:0 alpha:1.0] set];
//	    [badgePath fill];
//	    [[NSColor colorWithCalibratedRed:0.5 green:0 blue:0 alpha:1.0] set];
//	    [badgePath stroke];
//	}
    [image unlockFocus];
    [selectedTileImages replaceObjectAtIndex:rowIndex withObject:image];
    return image;
}


- (void)useCustomImage:(id)sender
{
/* TBD
    if ([selectedTile bestUniqueMatch] != nil)
	[selectedTile setUserChosenImageIndex:[selectedTile bestUniqueMatch]->tileImageIndex];
    else
	[selectedTile setUserChosenImageIndex:[selectedTile bestMatch]->tileImageIndex];
    [selectedTile setBestUniqueMatchIndex:-1];
	
    [refindUniqueTilesLock lock];
	refindUniqueTiles = YES;
    [refindUniqueTilesLock unlock];

    [self updateEditor];
*/
}


- (void)allowUserToChooseImage:(id)sender
{
/*
    NSOpenPanel		*oPanel = [NSOpenPanel openPanel];
    
    [oPanel setCanChooseFiles:YES];
    [oPanel setCanChooseDirectories:NO];
    [oPanel beginSheetForDirectory:NSHomeDirectory()
			      file:nil
			     types:[NSImage imageFileTypes]
		    modalForWindow:[self window]
		     modalDelegate:self
		    didEndSelector:@selector(allowUserToChooseImageOpenPanelDidEnd:returnCode:contextInfo:)
		       contextInfo:nil];
*/}


- (void)allowUserToChooseImageOpenPanelDidEnd:(NSOpenPanel *)sheet 
								   returnCode:(int)returnCode
								  contextInfo:(void *)context
{
/*
    CachedImage	*cachedImage;
    
    if (returnCode != NSOKButton) return;

    cachedImage = [[[CachedImage alloc] initWithIdentifier:[[sheet URLs] objectAtIndex:0] fromImageSource:manualImageSource] autorelease];
//TBD    [selectedTile setUserChosenImageIndex:[self addTileImage:cachedImage]];
//TBD    [selectedTile setBestUniqueMatchIndex:-1];
    
    [refindUniqueTilesLock lock];
//TBD	refindUniqueTiles = YES;
    [refindUniqueTilesLock unlock];

    [self updateEditor];

    [self updateChangeCount:NSChangeDone];
*/
}


- (void)useBestUniqueMatch:(id)sender
{
/*	TBD
    [selectedTile setUserChosenImageIndex:-1];
    
    [refindUniqueTilesLock lock];
	refindUniqueTiles = YES;
    [refindUniqueTilesLock unlock];

    [self updateEditor];
    
    [self updateChangeCount:NSChangeDone];
*/
}


- (void)useSelectedImage:(id)sender
{
/* TBD
    long	index = [selectedTile matches][[editorTable selectedRow]].tileImageIndex;
    
    [selectedTile setUserChosenImageIndex:index];
    [selectedTile setBestUniqueMatchIndex:-1];

    [refindUniqueTilesLock lock];
	refindUniqueTiles = YES;
    [refindUniqueTilesLock unlock];

    [self updateEditor];

    [self updateChangeCount:NSChangeDone];
*/
}


#pragma mark -
#pragma mark View methods


- (void)setViewCompareMode:(id)sender;
{
    [self setViewMode:viewMosaicAndOriginal];
}


- (void)setViewTileSetupMode:(id)sender
{
    [self setViewMode:viewMosaicAndTilesSetup];
}


- (void)setViewRegionsMode:(id)sender
{
    [self setViewMode:viewMosaicAndRegions];
}


- (void)setViewAloneMode:(id)sender;
{
    [self setViewMode:viewMosaicAlone];
}


- (void)setViewEditMode:(id)sender;
{
    [self setViewMode:viewMosaicEditor];
}


- (void)setViewMode:(int)mode
{
    if (mode == viewMode) return;
    
    viewMode = mode;
	[mosaicView highlightTile:nil];
	switch (mode)
	{
		case viewMosaicAndOriginal:
			[mosaicView setViewMode:viewMosaic];
			[utilitiesTabView selectTabViewItemWithIdentifier:@"Original"];
			[utilitiesDrawer open];
			break;
		case viewMosaicAndTilesSetup:
			[mosaicView setViewMode:viewTilesOutline];
			[utilitiesTabView selectTabViewItemWithIdentifier:@"Tiles"];
			[utilitiesDrawer open];
			break;
		case viewMosaicAndRegions:
			[mosaicView setViewMode:viewImageRegions];
			[utilitiesTabView selectTabViewItemWithIdentifier:@"Images"];
			[utilitiesDrawer open];
			break;
		case viewMosaicEditor:
			[mosaicView setViewMode:viewHighlightedTile];
			[mosaicView highlightTile:selectedTile];
			[self updateEditor];
			[editorTable scrollRowToVisible:0];
			[editorTable reloadData];
			[utilitiesTabView selectTabViewItemWithIdentifier:@"Editor"];
			[utilitiesDrawer open];
			break;
		case viewMosaicAlone:
			[mosaicView setViewMode:viewMosaic];
			[utilitiesDrawer close];
			break;
    }
    [self synchronizeMenus];
}


- (void)setZoom:(id)sender
{
    if ([sender isKindOfClass:[NSMenuItem class]])
    {
		if ([[sender title] isEqualToString:@"Minimum"]) zoom = 0.0;
		if ([[sender title] isEqualToString:@"Medium"]) zoom = 0.5;
		if ([[sender title] isEqualToString:@"Maximum"]) zoom = 1.0;
    }
    else zoom = [zoomSlider floatValue];
    
    // set the zoom...
    zoom = zoom;
    [zoomSlider setFloatValue:zoom];
    
    if (mosaicImage != nil)
    {
		NSRect	bounds, frame;
		
		frame = NSMakeRect(0, 0,
				[[mosaicScrollView contentView] frame].size.width + ([mosaicImage size].width - 
				[[mosaicScrollView contentView] frame].size.width) * zoom,
				[[mosaicScrollView contentView] frame].size.height + ([mosaicImage size].height - 
				[[mosaicScrollView contentView] frame].size.height) * zoom);
		bounds = NSMakeRect(NSMidX([[mosaicScrollView contentView] bounds]) * frame.size.width / 
						[mosaicView frame].size.width,
					NSMidY([[mosaicScrollView contentView] bounds]) * frame.size.height / 
						[mosaicView frame].size.height,
					frame.size.width -
						(frame.size.width - [[mosaicScrollView contentView] frame].size.width) * zoom,
					frame.size.height -
						(frame.size.height - [[mosaicScrollView contentView] frame].size.height) * zoom);
		bounds.origin.x = MIN(MAX(0, bounds.origin.x - bounds.size.width / 2.0),
							  frame.size.width - bounds.size.width);
		bounds.origin.y = MIN(MAX(0, bounds.origin.y - bounds.size.height / 2.0),
							  frame.size.height - bounds.size.height);
		[mosaicView setFrame:frame];
		[[mosaicScrollView contentView] setBounds:bounds];
		[mosaicScrollView setNeedsDisplay:YES];
    }
}


- (void)centerViewOnSelectedTile:(id)sender
{
    NSPoint	contentOrigin = NSMakePoint(NSMidX([[selectedTile outline] bounds]),
					     NSMidY([[selectedTile outline] bounds]));
    
    contentOrigin.x *= [mosaicView frame].size.width;
    contentOrigin.x -= [[mosaicScrollView contentView] bounds].size.width / 2;
    if (contentOrigin.x < 0) contentOrigin.x = 0;
    if (contentOrigin.x + [[mosaicScrollView contentView] bounds].size.width >
		[mosaicView frame].size.width)
		contentOrigin.x = [mosaicView frame].size.width - 
				[[mosaicScrollView contentView] bounds].size.width;

    contentOrigin.y *= [mosaicView frame].size.height;
    contentOrigin.y -= [[mosaicScrollView contentView] bounds].size.height / 2;
    if (contentOrigin.y < 0) contentOrigin.y = 0;
    if (contentOrigin.y + [[mosaicScrollView contentView] bounds].size.height >
		[mosaicView frame].size.height)
	contentOrigin.y = [mosaicView frame].size.height - 
			  [[mosaicScrollView contentView] bounds].size.height;

    [[mosaicScrollView contentView] scrollToPoint:contentOrigin];
    [mosaicScrollView reflectScrolledClipView:[mosaicScrollView contentView]];
}


- (void)mosaicViewDidScroll:(NSNotification *)notification
{
//    NSRect	orig, content,doc;
//    
//    if ([notification object] != mosaicScrollView) return;
//    
//    orig = [originalView bounds];
//    content = [[mosaicScrollView contentView] bounds];
//    doc = [mosaicView frame];
//    [originalView setFocusRect:NSMakeRect(content.origin.x * orig.size.width / doc.size.width,
//					  content.origin.y * orig.size.height / doc.size.height,
//					  content.size.width * orig.size.width / doc.size.width,
//					  content.size.height * orig.size.height / doc.size.height)];
//    [originalView setNeedsDisplay:YES];
}


- (void)toggleStatusBar:(id)sender
{
    NSRect	newFrame = [[self window] frame];
    int		i;
    
    if (statusBarShowing)
    {
		statusBarShowing = NO;
		removedSubviews = [[statusBarView subviews] copy];
		for (i = 0; i < [removedSubviews count]; i++)
			[[removedSubviews objectAtIndex:i] removeFromSuperview];
		[statusBarView retain];
		[statusBarView removeFromSuperview];
		newFrame.origin.y += [statusBarView frame].size.height;
		newFrame.size.height -= [statusBarView frame].size.height;
		newFrame.size = [self windowWillResize:[self window] toSize:newFrame.size];
		[[self window] setFrame:newFrame display:YES animate:YES];
		[[viewMenu itemWithTitle:@"Hide Status Bar"] setTitle:@"Show Status Bar"];
    }
    else
    {
		statusBarShowing = YES;
		newFrame.origin.y -= [statusBarView frame].size.height;
		newFrame.size.height += [statusBarView frame].size.height;
		newFrame.size = [self windowWillResize:[self window] toSize:newFrame.size];
		[[self window] setFrame:newFrame display:YES animate:YES];
	
		[statusBarView setFrame:NSMakeRect(0, [[mosaicScrollView superview] frame].size.height - [statusBarView frame].size.height, [[mosaicScrollView superview] frame].size.width, [statusBarView frame].size.height)];
		[[mosaicScrollView superview] addSubview:statusBarView];
		[statusBarView release];
		for (i = 0; i < [removedSubviews count]; i++)
		{
			[[removedSubviews objectAtIndex:i] setFrameSize:NSMakeSize([statusBarView frame].size.width,[[removedSubviews objectAtIndex:i] frame].size.height)];
			[statusBarView addSubview:[removedSubviews objectAtIndex:i]];
		}
		[removedSubviews release]; removedSubviews = nil;
	
		[[viewMenu itemWithTitle:@"Show Status Bar"] setTitle:@"Hide Status Bar"];
    }
}


- (void)toggleImageSourcesDrawer:(id)sender
{
    [utilitiesDrawer toggle:(id)sender];
    if ([utilitiesDrawer state] == NSDrawerClosedState)
		[[viewMenu itemWithTitle:@"Show Image Sources"] setTitle:@"Hide Image Sources"];
    else
		[[viewMenu itemWithTitle:@"Hide Image Sources"] setTitle:@"Show Image Sources"];
}


#pragma mark -
#pragma mark Utility methods


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    if ([[menuItem title] isEqualToString:@"Center on Selected Tile"])
		return (viewMode == viewMosaicEditor && selectedTile != nil && zoom != 0.0);
    else
		return [[self document] validateMenuItem:menuItem];
}


- (void)togglePause:(id)sender
{
//	NSEnumerator			*imageSourceEnumerator = [imageSources objectEnumerator];
//	id<MacOSaiXImageSource>	imageSource;

	if ([[self document] isPaused])
		[self resume];
	else
	{
		[self pause];
//		[pauseToolbarItem setLabel:@"Resume"];
//		[pauseToolbarItem setImage:[NSImage imageNamed:@"Resume"]];
//		[[fileMenu itemWithTitle:@"Pause Matching"] setTitle:@"Resume Matching"];
//		while (imageSource = [imageSourceEnumerator nextObject])
//			[imageSource pause];
//		paused = YES;
	}
}


#pragma mark -
#pragma mark Export image methods

- (void)beginExportImage:(id)sender
{
		// First pause the mosaic so we don't have a moving target.
	BOOL		wasPaused = [[self document] isPaused];
    [self pause];
    
		// Set up the save panel for exporting.
    NSSavePanel	*savePanel = [NSSavePanel savePanel];
    if ([exportWidth intValue] == 0)
    {
        [exportWidth setIntValue:[originalImage size].width * 4];
        [exportHeight setIntValue:[originalImage size].height * 4];
    }
    [savePanel setAccessoryView:exportPanelAccessoryView];
    
		// Ask the user where to export the image.
    [savePanel beginSheetForDirectory:NSHomeDirectory()
				 file:@"Mosaic.jpg"
		       modalForWindow:[self window]
			modalDelegate:self
		       didEndSelector:@selector(exportImageSavePanelDidEnd:returnCode:contextInfo:)
			  contextInfo:[NSNumber numberWithBool:wasPaused]];
}


- (IBAction)setJPEGExport:(id)sender
{
    exportFormat = NSJPEGFileType;
    [(NSSavePanel *)[sender window] setRequiredFileType:@"jpg"];
}


- (IBAction)setTIFFExport:(id)sender;
{
    exportFormat = NSTIFFFileType;
    [(NSSavePanel *)[sender window] setRequiredFileType:@"tiff"];
}


- (IBAction)setExportWidthFromHeight:(id)sender
{
    [exportWidth setIntValue:[exportHeight intValue] / [originalImage size].height * [originalImage size].width + 0.5];
}


- (IBAction)setExportHeightFromWidth:(id)sender
{
    [exportHeight setIntValue:[exportWidth intValue] / [originalImage size].width * [originalImage size].height + 0.5];
}


- (void)exportImageSavePanelDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];
	
    if (returnCode == NSOKButton)
    {
			// Display a progress panel while the export is underway.
		[progressPanelLabel setStringValue:@"Exporting mosaic image..."];
		[progressPanelIndicator startAnimation:self];
		[progressPanelIndicator setMaxValue:[[[self document] tiles] count]];
		[NSApp beginSheet:progressPanel
		   modalForWindow:[self window]
			modalDelegate:self
		   didEndSelector:nil
			  contextInfo:contextInfo];
		
			// Spawn a thread to do the export so the GUI doesn't get tied up.
		[NSApplication detachDrawingThread:@selector(exportImage:)
								  toTarget:self 
								withObject:[(NSSavePanel *)sheet filename]];
	}
}


- (void)exportImage:(NSString *)exportFilename
{
    NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	
		// Don't usurp the main thread.
	[NSThread setThreadPriority:0.1];

    NSImage		*exportImage = [[NSImage alloc] initWithSize:NSMakeSize([exportWidth intValue], [exportHeight intValue])];
	NS_DURING
		[exportImage lockFocus];
	NS_HANDLER
		NSLog(@"Could not lock focus on export image");
	NS_ENDHANDLER
	
    NSAffineTransform	*transform = [NSAffineTransform transform];
    [transform scaleXBy:[exportImage size].width yBy:[exportImage size].height];
	
	unsigned long		tileCount = [[[self document] tiles] count],
						tilesExported = 0;
	
	NSEnumerator		*tileEnumerator = [[[self document] tiles] objectEnumerator];
	Tile				*tile = nil;
	while (tile = [tileEnumerator nextObject])
    {
        NSAutoreleasePool	*pool2 = [[NSAutoreleasePool alloc] init];
        NSBezierPath		*clipPath = [transform transformBezierPath:[tile outline]];
        
        tilesExported++;
        [NSGraphicsContext saveGraphicsState];
        [clipPath addClip];
		
			// Get the image in use by this tile.
			// First try to get the high-res version from the image source, if it supports it.
			// Else use the version in the cache.
		NSImage		*pixletImage = nil;
		ImageMatch	*match = [tile displayedImageMatch];
		if (![[match imageIdentifier] hasPrefix:@"Unfetchable "])
			pixletImage = [[match imageSource] imageForIdentifier:[match imageIdentifier]];
		if (!pixletImage)
			pixletImage = [[[self document] imageCache] cachedImageForIdentifier:[match imageIdentifier] 
																	  fromSource:[match imageSource]];
		
			// Translate the tile's outline (in unit space) to the size of the exported image.
		NSRect		drawRect;
        if ([clipPath bounds].size.width / [pixletImage size].width <
            [clipPath bounds].size.height / [pixletImage size].height)
        {
            drawRect.size = NSMakeSize([clipPath bounds].size.height * [pixletImage size].width /
                        [pixletImage size].height,
                        [clipPath bounds].size.height);
            drawRect.origin = NSMakePoint([clipPath bounds].origin.x - 
                            (drawRect.size.width - [clipPath bounds].size.width) / 2.0,
                        [clipPath bounds].origin.y);
        }
        else
        {
            drawRect.size = NSMakeSize([clipPath bounds].size.width,
                        [clipPath bounds].size.width * [pixletImage size].height /
                        [pixletImage size].width);
            drawRect.origin = NSMakePoint([clipPath bounds].origin.x,
                        [clipPath bounds].origin.y - 
                            (drawRect.size.height - [clipPath bounds].size.height) / 2.0);
        }
		
			// Finally, draw the tile's image.
        [pixletImage drawInRect:drawRect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
		
			// Clean up
        [NSGraphicsContext restoreGraphicsState];
        [pool2 release];
		
		[self performSelectorOnMainThread:@selector(setProgressPercentComplete:) 
							   withObject:[NSNumber numberWithDouble:(tilesExported / tileCount * 100.0)] 
							waitUntilDone:YES];
    }
	
		// Now convert the image into the desired output format.
    NSBitmapImageRep	*exportRep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect(0, 0, [exportImage size].width, 
									     [exportImage size].height)];
    [exportImage unlockFocus];

	NSData		*bitmapData = (exportFormat == NSJPEGFileType) ? 
									[exportRep representationUsingType:NSJPEGFileType properties:nil] :
									[exportRep TIFFRepresentationUsingCompression:NSTIFFCompressionLZW factor:1.0];
    [bitmapData writeToFile:exportFilename atomically:YES];
    
    [pool release];
    [exportRep release];
    [exportImage release];
	
	[self performSelectorOnMainThread:@selector(closeProgressPanel) withObject:nil waitUntilDone:YES];
}


- (void)closeProgressPanel
{
	[NSApp endSheet:progressPanel];
	[progressPanel orderOut:nil];
}


- (void)setProgressPercentComplete:(NSNumber *)percentComplete
{
	[progressPanelIndicator setDoubleValue:[percentComplete doubleValue]];
}


// window delegate methods

#pragma mark -
#pragma mark Window delegate methods

- (void)windowDidBecomeMain:(NSNotification *)aNotification
{
    [self synchronizeMenus];
}


- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize
{
    float	aspectRatio = [mosaicImage size].width / [mosaicImage size].height,
			windowTop = [sender frame].origin.y + [sender frame].size.height,
			minHeight = 155;
    NSSize	diff;
    NSRect	screenFrame = [[sender screen] frame];
    
    proposedFrameSize.width = MIN(MAX(proposedFrameSize.width, 132),
								  screenFrame.size.width - [sender frame].origin.x);
    diff.width = [sender frame].size.width - [[sender contentView] frame].size.width;
    diff.height = [sender frame].size.height - [[sender contentView] frame].size.height;
    proposedFrameSize.width -= diff.width;
    windowTop -= diff.height + 16 + (statusBarShowing ? [statusBarView frame].size.height : 0);
    
    // Calculate the height of the window based on the proposed width
    //   and preserve the aspect ratio of the mosaic image.
    // If the height is too big for the screen, lower the width.
	proposedFrameSize.height = (proposedFrameSize.width - 16) / aspectRatio;
	if (proposedFrameSize.height > windowTop || proposedFrameSize.height < minHeight)
	{
	    proposedFrameSize.height = (proposedFrameSize.height < minHeight) ? minHeight : windowTop;
	    proposedFrameSize.width = proposedFrameSize.height * aspectRatio + 16;
	}
    
    // add height of scroll bar and status bar (if showing)
    proposedFrameSize.height += 16 + (statusBarShowing ? [statusBarView frame].size.height : 0);
    
    [self setZoom:self];
    
    proposedFrameSize.height += diff.height;
    proposedFrameSize.width += diff.width;

    return proposedFrameSize;
}


- (NSRect)windowWillUseStandardFrame:(NSWindow *)sender defaultFrame:(NSRect)defaultFrame
{
    defaultFrame.size = [self windowWillResize:sender toSize:defaultFrame.size];

    [mosaicScrollView setNeedsDisplay:YES];
    
    return defaultFrame;
}


- (void)windowDidResize:(NSNotification *)notification
{
		// this method is called during animated window resizing, not windowWillResize
    [self setZoom:self];
    [utilitiesTabView setNeedsDisplay:YES];
}



// Toolbar delegate methods

#pragma mark -
#pragma mark Toolbar delegate methods

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier
    willBeInsertedIntoToolbar:(BOOL)flag;
{
    NSToolbarItem	*toolbarItem = [toolbarItems objectForKey:itemIdentifier];

    if (toolbarItem)
		return toolbarItem;
    
    toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    
    if ([itemIdentifier isEqualToString:@"Zoom"])
    {
		[toolbarItem setMinSize:NSMakeSize(64, 14)];
		[toolbarItem setMaxSize:NSMakeSize(64, 14)];
		[toolbarItem setLabel:@"Zoom"];
		[toolbarItem setPaletteLabel:@"Zoom"];
		[toolbarItem setView:zoomToolbarView];
		[toolbarItem setMenuFormRepresentation:zoomToolbarMenuItem];
    }

    if ([itemIdentifier isEqualToString:@"ExportImage"])
    {
		[toolbarItem setImage:[NSImage imageNamed:@"ExportImage"]];
		[toolbarItem setLabel:@"Export Image"];
		[toolbarItem setPaletteLabel:@"Export Image"];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(beginExportImage:)];
		[toolbarItem setToolTip:@"Export an image of the mosaic"];
    }

    if ([itemIdentifier isEqualToString:@"UtilityDrawer"])
    {
		[toolbarItem setImage:[NSImage imageNamed:@"UtilityDrawer"]];
		[toolbarItem setLabel:@"Utility Drawer"];
		[toolbarItem setPaletteLabel:@"Utility Drawer"];
		[toolbarItem setTarget:utilitiesDrawer];
		[toolbarItem setAction:@selector(toggle:)];
		[toolbarItem setToolTip:@"Show/hide utility drawer"];
    }

    if ([itemIdentifier isEqualToString:@"Pause"])
    {
		[toolbarItem setImage:[NSImage imageNamed:@"Pause"]];
		[toolbarItem setLabel:[[self document] isPaused] ? @"Resume" : @"Pause"];
		[toolbarItem setPaletteLabel:[[self document] isPaused] ? @"Resume" : @"Pause"];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector(togglePause:)];
		pauseToolbarItem = toolbarItem;
    }
    
    [toolbarItems setObject:toolbarItem forKey:itemIdentifier];
    
    return toolbarItem;
}


- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem
{
    if ([[theItem itemIdentifier] isEqualToString:@"Pause"])
		return ([[[self document] tiles] count] > 0 && [[[self document] imageSources] count] > 0);
    else
		return YES;
}


- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar;
{
    return [NSArray arrayWithObjects:@"Zoom", @"ExportImage", @"Pause", @"UtilityDrawer", 
				     NSToolbarCustomizeToolbarItemIdentifier, NSToolbarSpaceItemIdentifier,
				     NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier,
				     nil];
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar;
{
    return [NSArray arrayWithObjects:@"Zoom", @"ExportImage", @"Pause", 
									 NSToolbarFlexibleSpaceItemIdentifier, @"UtilityDrawer", nil];
}


#pragma mark -
#pragma mark Tab view delegate methods

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	if (tabView == utilitiesTabView)
	{
		int selectedIndex =  [tabView indexOfTabViewItem:tabViewItem];
		
		if (selectedIndex == [utilitiesTabView indexOfTabViewItemWithIdentifier:@"Tiles"])
			[mosaicView setViewMode:viewTilesOutline];
		if (selectedIndex == [utilitiesTabView indexOfTabViewItemWithIdentifier:@"Images"])
			[mosaicView setViewMode:viewImageSources];
		if (selectedIndex == [utilitiesTabView indexOfTabViewItemWithIdentifier:@"Original"])
			[mosaicView setViewMode:viewMosaic];
		if (selectedIndex == [utilitiesTabView indexOfTabViewItemWithIdentifier:@"Regions"])
			[mosaicView setViewMode:viewImageRegions];
		if (selectedIndex == [utilitiesTabView indexOfTabViewItemWithIdentifier:@"Editor"])
			[mosaicView setViewMode:viewHighlightedTile];
	}
}


#pragma mark -
#pragma mark Table delegate methods

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == imageSourcesTableView)
		return [[[self document] imageSources] count];
		
    if (aTableView == editorTable)
		return (selectedTile == nil ? 0 : [selectedTile matchCount]);
	
	return 0;
}


- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if (aTableView == imageSourcesTableView)
    {
		id<MacOSaiXImageSource>	imageSource = [[[self document] imageSources] objectAtIndex:rowIndex];
		
		if ([[aTableColumn identifier] isEqualToString:@"Image Source Type"])
			return [imageSource image];
		else
		{
				// TBD: this won't work once entries get removed from the dictionary...
			long	imageCount = [[self document] countOfImagesFromSource:imageSource];
			id		descriptor = [imageSource descriptor];
			
			if ([descriptor isKindOfClass:[NSString class]])
				return [NSString stringWithFormat:@"%@\n(%ld images found)", descriptor, imageCount];
			else if ([descriptor isKindOfClass:[NSAttributedString class]])
			{
				// TODO: append attributed string
				return descriptor;
			}
			else
				return nil;
		}
    }
    else if (aTableView == editorTable)
    {
		NSImage	*image = nil;
		
		if (selectedTile)
		{
			image = [selectedTileImages objectAtIndex:rowIndex];
			if ([image isKindOfClass:[NSNull class]] && rowIndex != -1)
			{
				image = [self createEditorImage:rowIndex];
				[selectedTileImages replaceObjectAtIndex:rowIndex withObject:image];
			}
		}
		
		return image;
    }
	else
		return nil;
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if ([notification object] == editorTable)
    {
//        int	selectedRow = [editorTable selectedRow];
//        
//        if (selectedRow >= 0)
//            [matchValueTextField setStringValue:[NSString stringWithFormat:@"%f", 
//                                                    [selectedTile matches][selectedRow].matchValue]];
//        else
//            [matchValueTextField setStringValue:@""];
    }
}


#pragma mark


- (void)dealloc
{
    [mosaicImage release];
    [mosaicImageLock release];
	[selectedTile release];
    [selectedTileImages release];
    [toolbarItems release];
    [removedSubviews release];
    [zoomToolbarMenuItem release];
    [viewToolbarMenuItem release];
    [tileImages release];
    
    [super dealloc];
}

@end