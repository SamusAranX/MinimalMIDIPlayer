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
