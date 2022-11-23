//
//  ANANReporter.h
//  Anchor Annotations
//
//  Copyright 2022 Florian Pircher
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <Cocoa/Cocoa.h>
#import <GlyphsCore/GlyphsReporterProtocol.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const kIncludeInactiveLayersKey = @"AnchorAnnotationsIncludeInactiveLayers";
static NSString * const kIncludeNestedAnchorsKey = @"AnchorAnnotationsIncludeNestedAnchors";
static NSString * const kDisplayAnchorNamesKey = @"AnchorAnnotationsDisplayAnchorNames";
static NSString * const kFontSizeKey = @"AnchorAnnotationsFontSize";
static NSString * const kFontWidthKey = @"AnchorAnnotationsFontWidth";
static NSString * const kGeneralColorKey = @"AnchorAnnotationsGeneralColor";
static NSString * const kNameColorsKey = @"AnchorAnnotationsNameColors";
static NSString * const kAbbreviationsKey = @"AnchorAnnotationsAbbreviations";
static NSString * const kAbbreviationsAreCaseInsensitiveKey = @"AnchorAnnotationsAbbreviationsAreCaseInsensitive";

@interface ANANReporter : NSObject <GlyphsReporter>

+ (NSColor *)colorForColorId:(NSInteger)colorId;

@end

NS_ASSUME_NONNULL_END
