#import "Shared.h"
#import <AVFoundation/AVFoundation.h>
#import <Quartz/Quartz.h>
//#import <QuickLook/QuickLook.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

dispatch_semaphore_t sema;

/* -----------------------------------------------------------------------------
 Generate a preview for file
 
 This function's job is to create preview for designated file
 ----------------------------------------------------------------------------- */

NSURL* GetSoundfontURL(NSURL* midiFile) {
	NSURL *fileDir = [midiFile URLByDeletingLastPathComponent];
	NSString *nameWithoutExt = [[midiFile.lastPathComponent stringByDeletingPathExtension] stringByRemovingPercentEncoding];
	
	NSArray *potentialSoundfonts = [NSArray arrayWithObjects:
									[NSString stringWithFormat:@"%@/%@.sf2", fileDir.path, nameWithoutExt],
									[NSString stringWithFormat:@"%@/%@.dls", fileDir.path, nameWithoutExt],
									[NSString stringWithFormat:@"%@/%@.sf2", fileDir.path, fileDir.lastPathComponent],
									[NSString stringWithFormat:@"%@/%@.dls", fileDir.path, fileDir.lastPathComponent],
									nil
									];
	
	for (NSString *sfPath in potentialSoundfonts) {
		if ([[NSFileManager defaultManager] fileExistsAtPath:sfPath]) {
			return [NSURL fileURLWithPath:sfPath];
		}
	}
	
	
	return nil;
}

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
	return kQLReturnNoError;
	
	// the preview plugin isn't even close to ready for primetime
	
	NSURL *fileURL = (__bridge NSURL*)url;
	NSURL *soundfontURL = GetSoundfontURL(fileURL);
	
	NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.peterwunder.MinimalMIDIQL"];
	
	NSImage *albumArt = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"AlbumArtQuickLookBigger" ofType:@"png"]];
	[albumArt setSize:NSMakeSize(500, 500)];
	
	NSSize nsSize = [albumArt size];
	CGSize cgSize = NSSizeToCGSize(nsSize);
	
	NSRect nsRect = NSMakeRect(0, 0, nsSize.width, nsSize.height);
	
	NSDictionary *propertiesDict = @{
									 @"InlinePreviewMode" : @YES
									 };
	
	CGContextRef _context = QLPreviewRequestCreateContext(preview, cgSize, true, (__bridge CFDictionaryRef)propertiesDict);
	if (_context) {
		NSGraphicsContext *_graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:(void *)_context flipped:NO];
		
		[NSGraphicsContext saveGraphicsState];
		
		[NSGraphicsContext setCurrentContext:_graphicsContext];
		[albumArt drawInRect:nsRect];
		
		// Disable this until I've found something that looks good
		if ((false)) {
			NSString *fileName = [fileURL lastPathComponent];
			CGSize stringSize = CGSizeMake(1000, 1000);
			CGFloat fontSize = 36;
			
			NSDictionary *attributes = nil;
			NSRect vertAlignRect = NSMakeRect(0, 0, nsRect.size.width, 75);
			
			do {
				NSLog(@"Trying system font with size %f", fontSize);
				NSFont *systemFont = [NSFont systemFontOfSize:fontSize];
				CGFloat lineHeight = [systemFont lineHeight];
				
				NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
				style.alignment = NSTextAlignmentCenter;
				style.minimumLineHeight = vertAlignRect.size.height/2 + lineHeight/2;
				style.lineBreakMode = NSLineBreakByTruncatingMiddle;
				
				attributes = @{
							   NSParagraphStyleAttributeName: style,
							   NSFontAttributeName: systemFont
							   };
				
				stringSize = [fileName sizeWithAttributes:attributes];
				
				fontSize -= 1;
			} while (stringSize.width > vertAlignRect.size.width || stringSize.height > vertAlignRect.size.height);
			
			[fileName drawInRect:vertAlignRect withAttributes:attributes];
		}
		
		[NSGraphicsContext restoreGraphicsState];
		
		QLPreviewRequestFlushContext(preview, _context);
		CFRelease(_context);
	} else {
		NSLog(@"%@", @"no context");
		return kQLReturnNoError;
	}
	
//	[[QLPreviewPanel sharedPreviewPanel] 
	
	AVMIDIPlayer *player = [[AVMIDIPlayer alloc] initWithContentsOfURL:fileURL soundBankURL:soundfontURL error:nil];
	[player prepareToPlay];
	
	// Create a semaphore
//	sema = dispatch_semaphore_create(0);
//	dispatch_semaphore_t sema = dispatch_semaphore_create(0);
	
	// Start playback and release the semaphore once finished
	[player play:^{
		NSLog(@"%@", @"Player stopped.");
//		dispatch_semaphore_signal(sema);
	}];
	
	NSURL *oldPreviewItem = nil;
	do {
		CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.25, false);
		NSURL *previewItem = [[[QLPreviewPanel sharedPreviewPanel] currentPreviewItem] previewItemURL];
		
		if (oldPreviewItem != nil && previewItem == nil) {
			NSLog(@"%@", @"BREAK");
			break;
		}
		
		oldPreviewItem = previewItem;
	} while (true);
	
	[player stop];
	
//	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);
	
	// TODO: https://github.com/clemmece/qlvorbis/blob/master/qlvorbis/Engine.mm
	
	// keep running for an additional second
//	CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1, false);
	
	// Wait here until the player completion block signals the semaphore to stop waiting
//	dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
//	NSLog(@"%@", @"Semaphore released!");
	
	return kQLReturnNoError;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
	// Implement only if supported
}
