//
//  Shared.h
//  MinimalMIDIQL
//
//  Created by Peter Wunder on 12.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import "NSFont+LineHeight.h"

typedef NS_ENUM(NSInteger, QLThumbnailIconFlavor)
{
	kQLThumbnailIconPlainFlavor		= 0,
	kQLThumbnailIconShadowFlavor	= 1,
	kQLThumbnailIconBookFlavor		= 2,
	kQLThumbnailIconMovieFlavor		= 3,
	kQLThumbnailIconAddressFlavor	= 4,
	kQLThumbnailIconImageFlavor		= 5,
	kQLThumbnailIconGlossFlavor		= 6,
	kQLThumbnailIconSlideFlavor		= 7,
	kQLThumbnailIconSquareFlavor	= 8,
	kQLThumbnailIconBorderFlavor	= 9,
	// = 10,
	kQLThumbnailIconCalendarFlavor	= 11,
	kQLThumbnailIconPatternFlavor	= 12,
};

typedef NS_ENUM(NSInteger, QLPreviewMode)
{
	kQLPreviewNoMode		= 0,
	kQLPreviewGetInfoMode	= 1,	// File -> Get Info and Column view in Finder
	kQLPreviewCoverFlowMode	= 2,	// Finder's Cover Flow view
	kQLPreviewSpotlightMode	= 4,	// Desktop Spotlight search popup bubble
	kQLPreviewQuicklookMode	= 5,	// File -> Quick Look in Finder (also qlmanage -p)
	// From 10.13 High Sierra:
	kQLPreviewHSQuicklookMode	= 6,	// File -> Quick Look in Finder
	kQLPreviewHSSpotlightMode	= 9,	// Desktop Spotlight search context bubble
};
