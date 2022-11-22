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
#import <GlyphsCore/GSAppDelegateProtocol.h>
#import "ANANSettings.h"

/// Draw layer options key for the current drawing scale.
static NSString * const kGlyphsDrawOptionScaleKey = @"Scale";

static void *includeInactiveLayersContext = &includeInactiveLayersContext;
static void *includeNestedAnchorsContext = &includeNestedAnchorsContext;
static void *displayAnchorNamesContext = &displayAnchorNamesContext;
static void *fontSizeContext = &fontSizeContext;
static void *generalColorContext = &generalColorContext;
static void *nameColorsContext = &nameColorsContext;
static void *abbreviationsContext = &abbreviationsContext;

@interface ANANReporter ()
@property (assign) BOOL includeInactiveLayers;
@property (assign) BOOL includeNestedAnchors;
@property (assign) BOOL displayAnchorNames;
@property (assign) CGFloat fontSize;
@property (strong) NSColor *generalColor;
@property (strong) NSDictionary<NSString *, NSColor *> *nameColors;
@property (strong) NSDictionary<NSString *, NSString *> *abbreviations;
@end

@implementation ANANReporter {
    NSViewController <GSGlyphEditViewControllerProtocol> *_editViewController;
}

// MARK: Init

+ (void)initialize {
    if (self == [ANANReporter self]) {
        [NSUserDefaults.standardUserDefaults registerDefaults:@{
            kIncludeInactiveLayersKey: @YES,
            kIncludeNestedAnchorsKey: @YES,
            kDisplayAnchorNamesKey: @YES,
            kFontSizeKey: @10,
            kGeneralColorKey: @1,
            kNameColorsKey: @{
                
            },
            kAbbreviationsKey: @{
                @"top": @"↑",
                @"bottom": @"↓",
                @"left": @"←",
                @"right": @"→",
                @"center": @"×",
            },
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
                             forKeyPath:[@"values." stringByAppendingString:kIncludeInactiveLayersKey]
                                options:NSKeyValueObservingOptionInitial
                                context:includeInactiveLayersContext];
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kIncludeNestedAnchorsKey]
                                options:NSKeyValueObservingOptionInitial
                                context:includeNestedAnchorsContext];
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kDisplayAnchorNamesKey]
                                options:NSKeyValueObservingOptionInitial
                                context:displayAnchorNamesContext];
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kFontSizeKey]
                                options:NSKeyValueObservingOptionInitial
                                context:fontSizeContext];
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kGeneralColorKey]
                                options:NSKeyValueObservingOptionInitial
                                context:generalColorContext];
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kNameColorsKey]
                                options:NSKeyValueObservingOptionInitial
                                context:nameColorsContext];
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kAbbreviationsKey]
                                options:NSKeyValueObservingOptionInitial
                                context:abbreviationsContext];
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSObject<GSAppDelegateProtocol> *appDelegate = (NSObject<GSAppDelegateProtocol> *)[NSApp delegate];
            if ([appDelegate respondsToSelector:@selector(addViewToPreferences:)]) {
                [appDelegate addViewToPreferences:[ANANSettings sharedSettings]];
            }
        });
    });
    
    return self;
}

- (void)dealloc {
    NSUserDefaultsController *defaultsController = NSUserDefaultsController.sharedUserDefaultsController;
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kIncludeInactiveLayersKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kIncludeNestedAnchorsKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kDisplayAnchorNamesKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kFontSizeKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kGeneralColorKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kNameColorsKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kAbbreviationsKey]];
    _editViewController = nil;
}

- (NSColor *)colorForColorId:(NSInteger)colorId {
    switch (colorId) {
    case 1: return NSColor.systemRedColor;
    case 2: return NSColor.systemOrangeColor;
    case 3: return NSColor.systemBrownColor;
    case 4: return NSColor.systemYellowColor;
    case 5: return NSColor.systemGreenColor;
    case 9: return NSColor.systemBlueColor;
    case 10: return NSColor.systemPurpleColor;
    case 11: return NSColor.systemPinkColor;
    case 12: return NSColor.systemGrayColor;
    default: return NSColor.textColor;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == includeInactiveLayersContext) {
        _includeInactiveLayers = [NSUserDefaults.standardUserDefaults boolForKey:kIncludeInactiveLayersKey];
        [_editViewController redraw];
    }
    else if (context == includeNestedAnchorsContext) {
        _includeNestedAnchors = [NSUserDefaults.standardUserDefaults boolForKey:kIncludeNestedAnchorsKey];
        [_editViewController redraw];
    }
    else if (context == displayAnchorNamesContext) {
        _displayAnchorNames = [NSUserDefaults.standardUserDefaults boolForKey:kDisplayAnchorNamesKey];
        [_editViewController redraw];
    }
    else if (context == fontSizeContext) {
        _fontSize = MAX(1,  [NSUserDefaults.standardUserDefaults doubleForKey:kFontSizeKey]);
        [_editViewController redraw];
    }
    else if (context == generalColorContext) {
        NSInteger colorId = [NSUserDefaults.standardUserDefaults integerForKey:kGeneralColorKey];
        _generalColor = [self colorForColorId:colorId];
        [_editViewController redraw];
    }
    else if (context == nameColorsContext) {
        NSDictionary<NSString *, NSNumber *> *nameColorIds = [NSUserDefaults.standardUserDefaults dictionaryForKey:kNameColorsKey];
        NSMutableDictionary<NSString *, NSColor *> *nameColors = [NSMutableDictionary new];
        
        for (NSString *name in nameColorIds) {
            NSInteger colorId = [nameColorIds[name] integerValue];
            nameColors[name] = [self colorForColorId:colorId];
        }
        
        _nameColors = nameColors;
        [_editViewController redraw];
    }
    else if (context == abbreviationsContext) {
        _abbreviations = [NSUserDefaults.standardUserDefaults dictionaryForKey:kAbbreviationsKey];
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
    return _nameColors[name] ?: _generalColor;
}

- (void)drawAnnotationForLayer:(GSLayer *)layer isActive:(BOOL)isActive options:(NSDictionary *)options {
    CGFloat scale = [options[kGlyphsDrawOptionScaleKey] doubleValue];
    CGFloat unit = 1.0 / scale;
    
    NSAffineTransform *baseFontTransform = [NSAffineTransform transform];
    NSFontDescriptor *baseFontDescriptor = [[NSFont systemFontOfSize:_fontSize * unit].fontDescriptor fontDescriptorByAddingAttributes:@{
        NSFontFeatureSettingsAttribute: @[
            @{
                NSFontFeatureTypeIdentifierKey: @(kStylisticAlternativesType),
                NSFontFeatureSelectorIdentifierKey: @(kStylisticAltSixOnSelector),
            }
        ],
    }];
    NSFont *baseFont = [NSFont fontWithDescriptor:baseFontDescriptor size:0];
    
    NSShadow *textShadow = [NSShadow new];
    textShadow.shadowColor = NSColor.blackColor;
    textShadow.shadowOffset = NSZeroSize;
    textShadow.shadowBlurRadius = 0.5 * unit;
    
    CGFloat textOffsetX = 3.0 * unit;
    CGFloat textOffsetY = unit * (0.5 * (_fontSize + 0.1 * baseFont.descender));
    
    NSDictionary<NSString *, GSAnchor *> *anchors;
    NSSet<NSString *> *topLevelAnchors;
    
    if (_includeNestedAnchors) {
        NSMutableDictionary<NSString *, GSAnchor *> *nestedAnchors = [NSMutableDictionary new];
        
        for (GSAnchor *anchor in layer.anchorsTraversingComponents) {
            nestedAnchors[anchor.name] = anchor;
        }
        
        NSMutableSet *mutableTopLevelAnchors = [NSMutableSet new];
        
        for (NSString *topLevelAnchorName in layer.anchors) {
            [mutableTopLevelAnchors addObject:topLevelAnchorName];
            // enables selection because the nested anchor objects are different references
            nestedAnchors[topLevelAnchorName] = layer.anchors[topLevelAnchorName];
        }
        
        anchors = nestedAnchors;
        topLevelAnchors = mutableTopLevelAnchors;
    }
    else {
        anchors = layer.anchors;
    }
    
    for (NSString *anchorName in anchors) {
        GSAnchor *anchor = anchors[anchorName];
        
        if ([layer.selection containsObject:anchor]) {
            continue;
        }
        
        BOOL isNestedAnchor = topLevelAnchors != nil && ![topLevelAnchors containsObject:anchorName];
        NSColor *color = [self colorForAnchorName:anchorName];
        if (isNestedAnchor) {
            color = [color colorWithAlphaComponent:0.6];
        }
        NSPoint position = anchor.position;
        
        if (!isActive || isNestedAnchor) {
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
        
        if (_displayAnchorNames) {
            NSString *label = [self formatAnchorName:anchorName];
            NSPoint textPosition = NSMakePoint(position.x + textOffsetX, position.y - textOffsetY);
            NSAttributedString *annotation = [[NSAttributedString alloc] initWithString:label attributes:@{
                NSFontAttributeName: baseFont,
                NSForegroundColorAttributeName: color,
                NSShadowAttributeName: textShadow,
            }];
            [annotation drawAtPoint:textPosition];
        }
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