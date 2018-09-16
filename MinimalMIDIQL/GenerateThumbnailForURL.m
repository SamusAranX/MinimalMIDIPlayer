#import "Shared.h"

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    // To complete your generator please implement the function GenerateThumbnailForURL in GenerateThumbnailForURL.c
	
	@autoreleasepool {
		NSString *dataType = (__bridge NSString *)contentTypeUTI;
		NSDictionary *optionsDict = (__bridge NSDictionary *)options;
		NSImage *fileIcon = nil;
		BOOL iconMode = ([optionsDict objectForKey:(NSString *)kQLThumbnailOptionIconModeKey]) ? YES : NO;
		
		NSDictionary *propertiesDict = nil;
//		propertiesDict = @{(__bridge NSString*)kQLThumbnailPropertyExtensionKey : @"MIDI"}; // used to draw file extension onto icon image
		
		NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.peterwunder.MinimalMIDIQL"];
		
		if (iconMode) {
			// Return 
			fileIcon = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"AlbumArtQuickLookBigger" ofType:@"png"]];
			propertiesDict = @{@"IconFlavor" : @(kQLThumbnailIconGlossFlavor)};
		} else {
			fileIcon = [[NSWorkspace sharedWorkspace] iconForFileType:dataType];
		}
		
		[fileIcon setSize:maxSize];
		
		NSSize canvasSize = fileIcon.size;
		NSRect renderRect = NSMakeRect(0.0, 0.0, canvasSize.width, canvasSize.height);
		
		CGContextRef _context = QLThumbnailRequestCreateContext(thumbnail, canvasSize, true, (__bridge CFDictionaryRef)propertiesDict);
		if (_context) {
			NSGraphicsContext *_graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:(void *)_context flipped:NO];
			
			[NSGraphicsContext saveGraphicsState];
			
			[NSGraphicsContext setCurrentContext:_graphicsContext];
			[fileIcon drawInRect:renderRect];
			
			[NSGraphicsContext restoreGraphicsState];
			
			QLThumbnailRequestFlushContext(thumbnail, _context);
			CFRelease(_context);
		} else {
			NSLog(@"%@", @"no context");
			return kQLReturnNoError;
		}
	}
	
	return kQLReturnNoError;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
