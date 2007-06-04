//
//  MacOSaiXPDFExporterPlugIn.m
//  MacOSaiX
//
//  Created by Frank Midgley on 5/31/07.
//  Copyright 2007 Frank M. Midgley. All rights reserved.
//

#import "MacOSaiXPDFExporterPlugIn.h"

#import "MacOSaiXPDFExportEditor.h"
#import "MacOSaiXPDFExporter.h"
#import "MacOSaiXPDFExportSettings.h"


@implementation MacOSaiXPDFExporterPlugIn


+ (NSImage *)image
{
	return nil;
}


+ (Class)dataSourceClass
{
	return [MacOSaiXPDFExportSettings class];
}


+ (Class)editorClass
{
	return [MacOSaiXPDFExportEditor class];
}


+ (Class)preferencesEditorClass
{
	return nil;
}


+ (Class)exporterClass
{
	return [MacOSaiXPDFExporter class];
}


@end
