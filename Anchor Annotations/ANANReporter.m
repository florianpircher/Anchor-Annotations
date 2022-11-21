//
//  ANANReporter.m
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

#import "ANANReporter.h"
#import <GlyphsCore/GSLayer.h>
#import <GlyphsCore/GSAnchor.h>
#import <GlyphsCore/GSGlyphViewControllerProtocol.h>

/// Draw layer options key for the current drawing scale.
static NSString * const kGlyphsDrawOptionScaleKey = @"Scale";
static NSString * const kFontSizeKey = @"AnchorAnnotationsFontSize";
static NSString * const kNameColorsKey = @"AnchorAnnotationsNameColors";
static NSString * const kAbbreviationsKey = @"AnchorAnnotationsAbbreviations";
static NSString * const kIncludeInactiveLayersKey = @"AnchorAnnotationsIncludeInactiveLayers";

static void *fontSizeContext = &fontSizeContext;
static void *nameColorsContext = &nameColorsContext;
static void *abbreviationsContext = &abbreviationsContext;
static void *includeInactiveLayersContext = &includeInactiveLayersContext;

@interface ANANReporter ()
@property (assign) CGFloat fontSize;
@property (strong) NSDictionary<NSString *, NSColor *> *nameColors;
@property (strong) NSDictionary<NSString *, NSString *> *abbreviations;
@property (assign) BOOL includeInactiveLayers;
@end

@implementation ANANReporter {
    NSViewController <GSGlyphEditViewControllerProtocol> *_editViewController;
}

// MARK: Init

+ (void)initialize {
    if (self == [ANANReporter self]) {
        [NSUserDefaults.standardUserDefaults registerDefaults:@{
            kFontSizeKey: @10,
            kNameColorsKey: @{
                @"": @1,
            },
            kAbbreviationsKey: @{
                @"top": @"↑",
                @"bottom": @"↓",
                @"left": @"←",
                @"right": @"→",
                @"center": @"×",
            },
            kIncludeInactiveLayersKey: @YES,
        }];
    }
}

- (void)setController:(NSViewController <GSGlyphEditViewControllerProtocol>*)controller {
    _editViewController = controller;
}

- (NSViewController<GSGlyphEditViewControllerProtocol> *)controller {
    return _editViewController;
}

- (instancetype)init {
    self = [super init];
    
    if (self != nil) {
        NSUserDefaultsController *defaultsController = NSUserDefaultsController.sharedUserDefaultsController;
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kFontSizeKey]
                                options:NSKeyValueObservingOptionInitial
                                context:fontSizeContext];
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kNameColorsKey]
                                options:NSKeyValueObservingOptionInitial
                                context:nameColorsContext];
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kAbbreviationsKey]
                                options:NSKeyValueObservingOptionInitial
                                context:abbreviationsContext];
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kIncludeInactiveLayersKey]
                                options:NSKeyValueObservingOptionInitial
                                context:includeInactiveLayersContext];
    }
    
    return self;
}

- (void)dealloc {
    NSUserDefaultsController *defaultsController = NSUserDefaultsController.sharedUserDefaultsController;
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kFontSizeKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kNameColorsKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kAbbreviationsKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kIncludeInactiveLayersKey]];
    _editViewController = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == fontSizeContext) {
        _fontSize = MAX(1,  [NSUserDefaults.standardUserDefaults doubleForKey:kFontSizeKey]);
        [_editViewController redraw];
    }
    else if (context == nameColorsContext) {
        NSDictionary<NSString *, NSNumber *> *nameColorIds = [NSUserDefaults.standardUserDefaults dictionaryForKey:kNameColorsKey];
        NSMutableDictionary<NSString *, NSColor *> *nameColors = [NSMutableDictionary new];
        
        for (NSString *name in nameColorIds) {
            NSInteger colorId = [nameColorIds[name] integerValue];
            NSColor *color;
            
            switch (colorId) {
            case 1: color = NSColor.systemRedColor; break;
            case 2: color = NSColor.systemOrangeColor; break;
            case 3: color = NSColor.systemBrownColor; break;
            case 4: color = NSColor.systemYellowColor; break;
            case 5: color = NSColor.systemGreenColor; break;
            case 9: color = NSColor.systemBlueColor; break;
            case 10: color = NSColor.systemPurpleColor; break;
            case 11: color = NSColor.systemPinkColor; break;
            case 12: color = NSColor.systemGrayColor; break;
            default: color = NSColor.textColor; break;
            }
            
            nameColors[name] = color;
        }
        
        _nameColors = nameColors;
        [_editViewController redraw];
    }
    else if (context == abbreviationsContext) {
        _abbreviations = [NSUserDefaults.standardUserDefaults dictionaryForKey:kAbbreviationsKey];
        [_editViewController redraw];
    }
    else if (context == includeInactiveLayersContext) {
        _includeInactiveLayers = [NSUserDefaults.standardUserDefaults boolForKey:kIncludeInactiveLayersKey];
        [_editViewController redraw];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

// MARK: Glyphs API

- (NSUInteger)interfaceVersion {
    return 1;
}

- (NSString *)title {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    return NSLocalizedStringFromTableInBundle(@"Anchor Annotations", nil, bundle, @"Title of the menu item to activate the plugin in the format “Show …”");
}

- (NSString *)keyEquivalent {
    return nil;
}

- (NSEventModifierFlags)modifierMask {
    return 0;
}

// MARK: Plugin

- (NSString *)formatAnchorName:(NSString *)name {
    for (NSString *pattern in _abbreviations) {
        name = [name stringByReplacingOccurrencesOfString:pattern withString:_abbreviations[pattern] options:NSCaseInsensitiveSearch range:NSMakeRange(0, name.length)];
    }
    return name;
}

- (NSColor *)colorForAnchorName:(NSString *)name {
    return _nameColors[name] ?: _nameColors[@""];
}

- (void)drawAnnotationForLayer:(GSLayer *)layer isActive:(BOOL)isActive options:(NSDictionary *)options {
    CGFloat scale = [options[kGlyphsDrawOptionScaleKey] doubleValue];
    CGFloat unit = 1.0 / scale;
    
    NSAffineTransform *baseFontTransform = [NSAffineTransform transform];
    [baseFontTransform scaleBy:unit];
    NSFontDescriptor *baseFontDescriptor = [[NSFont systemFontOfSize:_fontSize].fontDescriptor fontDescriptorByAddingAttributes:@{
        NSFontFeatureSettingsAttribute: @[
            @{
                NSFontFeatureTypeIdentifierKey: @(kStylisticAlternativesType),
                NSFontFeatureSelectorIdentifierKey: @(kStylisticAltSixOnSelector),
            }
        ],
    }];
    NSFont *baseFont = [NSFont fontWithDescriptor:baseFontDescriptor textTransform:baseFontTransform];
    
    NSShadow *textShadow = [NSShadow new];
    textShadow.shadowColor = NSColor.textBackgroundColor;
    textShadow.shadowOffset = NSZeroSize;
    textShadow.shadowBlurRadius = unit;
    
    CGFloat textOffsetX = 3.0 * unit;
    CGFloat textOffsetY = unit * (0.5 * (_fontSize + 0.1 * baseFont.descender));
    
    for (NSString *anchorName in layer.anchors) {
        GSAnchor *anchor = layer.anchors[anchorName];
        
        if ([layer.selection containsObject:anchor]) {
            continue;
        }
        
        NSString *label = [self formatAnchorName:anchorName];
        NSColor *color = [self colorForAnchorName:anchorName];
        NSPoint position = anchor.position;
        
        if (!isActive) {
            // draw anchor point
            NSBezierPath *path = [NSBezierPath new];
            [path moveToPoint:NSMakePoint(position.x - unit, position.y)];
            [path lineToPoint:NSMakePoint(position.x, position.y + unit)];
            [path lineToPoint:NSMakePoint(position.x + unit, position.y)];
            [path lineToPoint:NSMakePoint(position.x, position.y - unit)];
            [path closePath];
            [NSColor.textBackgroundColor setStroke];
            path.lineWidth = 2.0 * unit;
            [path stroke];
            path.lineWidth = 1.0 * unit;
            [color set];
            [path stroke];
            [path fill];
        }
        
        NSPoint textPosition = NSMakePoint(position.x + textOffsetX, position.y - textOffsetY);
        NSAttributedString *annotation = [[NSAttributedString alloc] initWithString:label attributes:@{
            NSFontAttributeName: baseFont,
            NSForegroundColorAttributeName: color,
            NSShadowAttributeName: textShadow,
        }];
        [annotation drawAtPoint:textPosition];
    }
}

- (void)drawForegroundForLayer:(GSLayer *)layer options:(NSDictionary *)options {
    [self drawAnnotationForLayer:layer isActive:YES options:options];
}

- (void)drawForegroundForInactiveLayer:(GSLayer *)layer options:(NSDictionary *)options {
    if (_includeInactiveLayers) {
        [self drawAnnotationForLayer:layer isActive:NO options:options];
    }
}

@end
