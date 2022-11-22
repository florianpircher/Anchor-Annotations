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
static void *fontWidthContext = &fontWidthContext;
static void *generalColorContext = &generalColorContext;
static void *nameColorsContext = &nameColorsContext;
static void *abbreviationsContext = &abbreviationsContext;
static void *abbreviationsAreCaseInsensitiveContext = &abbreviationsAreCaseInsensitiveContext;

@interface ANANReporter ()
@property (assign) BOOL includeInactiveLayers;
@property (assign) BOOL includeNestedAnchors;
@property (assign) BOOL displayAnchorNames;
@property (assign) CGFloat fontSize;
@property (assign) CGFloat fontWidth;
@property (strong) NSColor *generalColor;
@property (strong) NSDictionary<NSString *, NSColor *> *nameColors;
@property (strong) NSDictionary<NSString *, NSString *> *abbreviations;
/// The key-value pairs from `abbreviations` as tuple arrays sorted with the longest keys first descending to the shortest keys.
/// Updated every time `abbreviations` is updated.
@property (strong) NSArray<NSArray<NSString *> *> *sortedAbbreviations;
@property (assign) BOOL abbreviationsAreCaseInsensitive;
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
            kFontSizeKey: @13,
            kFontWidthKey: @90,
            kGeneralColorKey: @1,
            kNameColorsKey: @{},
            kAbbreviationsKey: @{
                @"top": @"↑",
                @"bottom": @"↓",
            },
            kAbbreviationsAreCaseInsensitiveKey: @YES,
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
                             forKeyPath:[@"values." stringByAppendingString:kFontWidthKey]
                                options:NSKeyValueObservingOptionInitial
                                context:fontWidthContext];
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
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kAbbreviationsAreCaseInsensitiveKey]
                                options:NSKeyValueObservingOptionInitial
                                context:abbreviationsAreCaseInsensitiveContext];
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
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kFontWidthKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kGeneralColorKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kNameColorsKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kAbbreviationsKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kAbbreviationsAreCaseInsensitiveKey]];
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
    else if (context == fontWidthContext) {
        _fontWidth = MAX(50, MIN(150, [NSUserDefaults.standardUserDefaults doubleForKey:kFontWidthKey]));
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
        
        NSMutableArray *sortedAbbreviations = [NSMutableArray new];
        for (NSString *pattern in _abbreviations) {
            [sortedAbbreviations addObject:@[pattern, _abbreviations[pattern]]];
        }
        [sortedAbbreviations sortUsingComparator:^NSComparisonResult(NSArray<NSString *> * _Nonnull a, NSArray<NSString *> * _Nonnull b) {
            if (a[0].length < b[0].length) {
                return NSOrderedDescending;
            }
            else if (a[0].length > b[0].length) {
                return NSOrderedAscending;
            }
            else {
                return NSOrderedSame;
            }
        }];
        _sortedAbbreviations = sortedAbbreviations;
        
        [_editViewController redraw];
    }
    else if (context == abbreviationsAreCaseInsensitiveContext) {
        _abbreviationsAreCaseInsensitive = [NSUserDefaults.standardUserDefaults boolForKey:kAbbreviationsAreCaseInsensitiveKey];
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
    NSStringCompareOptions options = _abbreviationsAreCaseInsensitive ? NSCaseInsensitiveSearch : 0;
    
    for (NSArray<NSString *> *abbreviation in _sortedAbbreviations) {
        name = [name stringByReplacingOccurrencesOfString:abbreviation[0] withString:abbreviation[1] options:options range:NSMakeRange(0, name.length)];
    }
    return name;
}

- (NSColor *)colorForAnchorName:(NSString *)name {
    return _nameColors[name] ?: _generalColor;
}

- (void)drawAnnotationForLayer:(GSLayer *)layer isActive:(BOOL)isActive options:(NSDictionary *)options {
    CGFloat scale = [options[kGlyphsDrawOptionScaleKey] doubleValue];
    CGFloat unit = 1.0 / scale;
    
    NSFontDescriptor *baseFontDescriptor = [[NSFont systemFontOfSize:_fontSize * unit].fontDescriptor fontDescriptorByAddingAttributes:@{
        NSFontFeatureSettingsAttribute: @[
            @{
                NSFontFeatureTypeIdentifierKey: @(kStylisticAlternativesType),
                NSFontFeatureSelectorIdentifierKey: @(kStylisticAltSixOnSelector),
            }
        ],
        NSFontVariationAttribute: @{
            // wdth
            @2003072104: @(_fontWidth),
        },
    }];
    NSFont *baseFont = [NSFont fontWithDescriptor:baseFontDescriptor size:0];
    CGFloat pointSize = baseFont.pointSize;
    
    CGFloat textOffsetX = 3.0 * unit;
    CGFloat textOffsetY = -0.5 * pointSize;
    
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
    
    NSArray<NSString *> *sortedAnchorNames = [anchors keysSortedByValueWithOptions:NSSortStable usingComparator:^NSComparisonResult(GSAnchor * _Nonnull a, GSAnchor * _Nonnull b) {
        if (a.position.y < b.position.y) {
            return NSOrderedDescending;
        }
        else if (a.position.y > b.position.y) {
            return NSOrderedAscending;
        }
        else {
            return NSOrderedSame;
        }
    }];
    
    NSColor *canvasColor = _editViewController.graphicView.canvasColor ?: NSColor.textBackgroundColor;
    NSColor *strokeColor = [canvasColor colorWithAlphaComponent:0.7];
    
    NSMutableArray<NSValue *> *drawnRects = [NSMutableArray new];
    
    for (NSString *anchorName in sortedAnchorNames) {
        GSAnchor *anchor = anchors[anchorName];
        
        if ([layer.selection containsObject:anchor]) {
            continue;
        }
        
        BOOL isNestedAnchor = topLevelAnchors != nil && ![topLevelAnchors containsObject:anchorName];
        NSColor *color = [self colorForAnchorName:anchorName];
        NSPoint position = anchor.position;
        
        if (!isActive || isNestedAnchor) {
            // draw anchor point
            NSBezierPath *path = [NSBezierPath new];
            if (isNestedAnchor) {
                // triangle
                [path moveToPoint:NSMakePoint(position.x - 1.2 * unit, position.y + unit)];
                [path lineToPoint:NSMakePoint(position.x + 1.2 * unit, position.y + unit)];
                [path lineToPoint:NSMakePoint(position.x, position.y - unit)];
            }
            else {
                // diamond
                [path moveToPoint:NSMakePoint(position.x - (1.2 * unit), position.y)];
                [path lineToPoint:NSMakePoint(position.x, position.y + (1.2 * unit))];
                [path lineToPoint:NSMakePoint(position.x + (1.2 * unit), position.y)];
                [path lineToPoint:NSMakePoint(position.x, position.y - (1.2 * unit))];
            }
            [path closePath];
            [strokeColor setStroke];
            path.lineWidth = 2.0 * unit;
            [path stroke];
            path.lineWidth = 1.0 * unit;
            [color set];
            [path stroke];
            [path fill];
        }
        
        if (_displayAnchorNames) {
            NSString *label = [self formatAnchorName:anchorName];
            
            NSAttributedString *annotation = [[NSAttributedString alloc] initWithString:label attributes:@{
                NSFontAttributeName: baseFont,
                NSStrokeColorAttributeName: strokeColor,
                NSStrokeWidthAttributeName: @(unit * (100.0 / pointSize)),
            }];
            
            NSPoint idealPosition = NSMakePoint(position.x + textOffsetX, position.y + textOffsetY);
            CGFloat insetOriginY = 0.1 * pointSize;
            CGFloat insetHeight = 0.2 * pointSize + insetOriginY;
            NSRect rect = NSZeroRect;
            rect.origin = idealPosition;
            rect.origin.y += insetOriginY;
            rect.size = [annotation size];
            rect.size.height -= insetHeight;
            
            BOOL didShift = NO;
            NSInteger shiftCount = 0;
            do {
                didShift = NO;
                for (NSValue *otherRectValue in drawnRects) {
                    NSRect otherRect = [otherRectValue rectValue];
                    if (NSMinX(rect) < NSMaxX(otherRect) && NSMaxX(rect) > NSMinX(otherRect)) {
                        if (NSMinY(rect) < NSMaxY(otherRect) && NSMaxY(rect) > NSMinY(otherRect)) {
                            CGFloat delta = NSMaxY(rect) - NSMinY(otherRect);
                            // shift by slightly more so that any rounding errors are mitigated
                            // (otherwise, the next for loop might detect a miniscule, i.e. rounding error, overlap)
                            rect.origin.y -= delta * 1.01;
                            didShift = YES;
                            shiftCount += 1;
                        }
                    }
                }
            } while (didShift && shiftCount < 16);
            
            if (shiftCount == 15) {
                NSLog(@"Anchor Annotations: Error: did reach max shift count of %ld with anchor %@", shiftCount, anchor);
            }
            if (shiftCount > 0) {
                NSBezierPath *connector = [NSBezierPath new];
                [connector moveToPoint:anchor.position];
                [connector lineToPoint:NSMakePoint(anchor.position.x, rect.origin.y + 0.4 * pointSize)];
                [connector lineToPoint:NSMakePoint(anchor.position.x + 2.0 * unit, rect.origin.y + 0.4 * pointSize)];
                connector.lineWidth = 0.7 * unit;
                [[color colorWithAlphaComponent:0.4] setStroke];
                [connector stroke];
            }
            
            [drawnRects addObject:[NSValue valueWithRect:rect]];
            NSPoint textPosition = rect.origin;
            textPosition.y -= insetOriginY;
            
            [annotation drawAtPoint:textPosition];
            
            annotation = [[NSAttributedString alloc] initWithString:label attributes:@{
                NSFontAttributeName: baseFont,
                NSForegroundColorAttributeName: color,
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
