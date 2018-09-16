//
//  NSFont.m
//  MinimalMIDIQL
//
//  Created by Peter Wunder on 16.09.18.
//  Copyright © 2018 Peter Wunder. All rights reserved.
//

#import "NSFont+LineHeight.h"

@implementation NSFont (LineHeight)

- (CGFloat)lineHeight {
	return ceilf(self.ascender + ABS(self.descender) + self.leading);
}

@end
