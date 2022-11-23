//
//  ANANSettings.m
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

#import "ANANSettings.h"
#import "ANANReporter.h"
#import "ANANAbbreviation.h"
#import "ANANNameColor.h"
#import "ANANPopupTableCellView.h"

static NSString * const kUIIDColumnText = @"Text";
static NSString * const kUIIDColumnAbbreviation = @"Abbr";
static NSString * const kUIIDColumnName = @"Name";
static NSString * const kUIIDColumnColor = @"Color";

static void *abbreviationsContext = &abbreviationsContext;
static void *namedColorsContext = &namedColorsContext;
static void *displayAnchorNamesContext = &displayAnchorNamesContext;

static NSBundle *pluginBundle;

@interface ANANSettings ()
@property (strong) IBOutlet NSTextField *fontWidthLabel;
@property (strong) IBOutlet NSSlider *fontWidthControl;
@property (strong) IBOutlet NSPopUpButton *generalColorPicker;
@property (strong) IBOutlet NSTableView *abbreviationTableView;
@property (strong) IBOutlet NSTableView *colorsTableView;
@property (strong) IBOutlet NSButton *removeAbbreviationButton;
@property (strong) IBOutlet NSButton *removeColorButton;

@property (strong) NSMutableArray<ANANAbbreviation *> *abbreviations;
@property (strong) NSMutableArray<ANANNameColor *> *nameColors;
@property (assign) BOOL displayAnchorNames;
@end

@implementation ANANSettings

+ (instancetype)sharedSettings {
    static ANANSettings *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pluginBundle = [NSBundle bundleForClass:[self class]];
        sharedInstance = [ANANSettings new];
    });
    return sharedInstance;
}

- (id)init {
    self = [super initWithNibName:@"ANANSettings" bundle:pluginBundle];
    
    if (self != nil) {
        self.title = NSLocalizedStringFromTableInBundle(@"Anchor Annotations", nil, pluginBundle, @"Title of the Anchor Annotations tab in settings");
        self.representedObject = @"link";
        
        _abbreviations = [NSMutableArray new];
        _nameColors = [NSMutableArray new];
        
        NSUserDefaultsController *defaultsController = NSUserDefaultsController.sharedUserDefaultsController;
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kAbbreviationsKey]
                                options:NSKeyValueObservingOptionInitial
                                context:abbreviationsContext];
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kNameColorsKey]
                                options:NSKeyValueObservingOptionInitial
                                context:namedColorsContext];
        [defaultsController addObserver:self
                             forKeyPath:[@"values." stringByAppendingString:kDisplayAnchorNamesKey]
                                options:NSKeyValueObservingOptionInitial
                                context:displayAnchorNamesContext];
    }
    
    return self;
}

- (void)dealloc {
    NSUserDefaultsController *defaultsController = NSUserDefaultsController.sharedUserDefaultsController;
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kAbbreviationsKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kNameColorsKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kDisplayAnchorNamesKey]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == abbreviationsContext) {
        NSDictionary<NSString *, NSString *> *abbreviations = [NSUserDefaults.standardUserDefaults dictionaryForKey:kAbbreviationsKey];
        
        [_abbreviations removeAllObjects];
        
        for (NSString *text in abbreviations) {
            ANANAbbreviation *abbreviation = [ANANAbbreviation new];
            abbreviation.text = text;
            abbreviation.abbreviation = abbreviations[text];
            [_abbreviations addObject:abbreviation];
        }
        
        [self tableView:_abbreviationTableView sortDescriptorsDidChange:_abbreviationTableView.sortDescriptors];
    }
    else if (context == namedColorsContext) {
        NSDictionary<NSString *, NSNumber *> *nameColors = [NSUserDefaults.standardUserDefaults dictionaryForKey:kNameColorsKey];
        
        [_nameColors removeAllObjects];
        
        for (NSString *name in nameColors) {
            ANANNameColor *nameColor = [ANANNameColor new];
            nameColor.name = name;
            nameColor.colorId = [nameColors[name] integerValue];
            [_nameColors addObject:nameColor];
        }
        
        [self tableView:_colorsTableView sortDescriptorsDidChange:_colorsTableView.sortDescriptors];
    }
    else if (context == displayAnchorNamesContext) {
        _displayAnchorNames = [NSUserDefaults.standardUserDefaults boolForKey:kDisplayAnchorNamesKey];
        [self updateDisplayForTableView:_abbreviationTableView];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (NSUInteger)interfaceVersion {
    return 1;
}

- (void)loadPlugin {
    [self view];
}

- (void)viewDidLoad {
    for (NSTableColumn *column in _abbreviationTableView.tableColumns) {
        if ([column.identifier isEqualToString:kUIIDColumnText]) {
            column.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES];
        }
        else if ([column.identifier isEqualToString:kUIIDColumnAbbreviation]) {
            column.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(abbreviation)) ascending:YES];
        }
    }
    
    for (NSTableColumn *column in _colorsTableView.tableColumns) {
        if ([column.identifier isEqualToString:kUIIDColumnName]) {
            column.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(name)) ascending:YES];
        }
        else if ([column.identifier isEqualToString:kUIIDColumnColor]) {
            column.sortDescriptorPrototype = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(colorId)) ascending:YES];
        }
    }
    
    [self tableView:_abbreviationTableView sortDescriptorsDidChange:_abbreviationTableView.sortDescriptors];
    [self tableView:_colorsTableView sortDescriptorsDidChange:_colorsTableView.sortDescriptors];
    
    if (@available(macOS 11, *)) {} else {
        _fontWidthLabel.hidden = YES;
        _fontWidthControl.hidden = YES;
    }
    
    _generalColorPicker.menu = [self makeColorsMenuWithImageSize:NSMakeSize(14, 14)];
    [_generalColorPicker bind:NSSelectedTagBinding toObject:NSUserDefaultsController.sharedUserDefaultsController withKeyPath:[@"values." stringByAppendingString:kGeneralColorKey] options:nil];
}

- (NSImage *)colorSwatchImageWithSize:(NSSize)size forColorId:(NSInteger)colorId {
    NSColor *color = [ANANReporter colorForColorId:colorId];
    
    return [NSImage imageWithSize:size flipped:YES drawingHandler:^BOOL(NSRect rect) {
        CGContextRef context = NSGraphicsContext.currentContext.CGContext;
        
        NSColor *outlineColor = [color blendedColorWithFraction:0.2 ofColor:NSColor.blackColor];
        [outlineColor setFill];
        CGContextFillEllipseInRect(context, rect);
        
        [color setFill];
        CGContextFillEllipseInRect(context, NSInsetRect(rect, 1, 1));
        
        return YES;
    }];
}

- (NSMenu *)makeColorsMenuWithImageSize:(NSSize)imageSize {
    static NSMenu *menu = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        menu = [NSMenu new];
        NSMenuItem *textItem = [NSMenuItem new];
        textItem.title = NSLocalizedStringFromTableInBundle(@"0", @"Colors", pluginBundle, @"");
        textItem.tag = 0;
        textItem.image = [self colorSwatchImageWithSize:imageSize forColorId:0];
        [menu addItem:textItem];
        
        [menu addItem:[NSMenuItem separatorItem]];
        
        for (NSInteger i = 1; i <= 13; i++) {
            NSMenuItem *item = [NSMenuItem new];
            NSString *key = [NSString stringWithFormat:@"%ld", i];
            item.title = NSLocalizedStringFromTableInBundle(key, @"Colors", pluginBundle, @"");
            item.tag = i;
            item.image = [self colorSwatchImageWithSize:imageSize forColorId:i];
            [menu addItem:item];
        }
    });
    
    return [menu copy];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSView *view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    if ([tableColumn.identifier isEqualToString:kUIIDColumnColor]) {
        ANANPopupTableCellView *cellView = (ANANPopupTableCellView *)view;
        cellView.popupButton.menu = [self makeColorsMenuWithImageSize:NSMakeSize(12, 12)];
    }
    return view;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors {
    if (tableView == _abbreviationTableView) {
        [_abbreviations sortUsingDescriptors:tableView.sortDescriptors];
        [_abbreviationTableView reloadData];
    }
    else if (tableView == _colorsTableView) {
        [_nameColors sortUsingDescriptors:tableView.sortDescriptors];
        [_colorsTableView reloadData];
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == _abbreviationTableView) {
        return _abbreviations.count;
    }
    else if (tableView == _colorsTableView) {
        return _nameColors.count;
    }
    else {
        return 0;
    }
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == _abbreviationTableView) {
        if ([tableColumn.identifier isEqualToString:kUIIDColumnText]) {
            return _abbreviations[row].text;
        }
        else if ([tableColumn.identifier isEqualToString:kUIIDColumnAbbreviation]) {
            return _abbreviations[row].abbreviation;
        }
    }
    else if (tableView == _colorsTableView) {
        return _nameColors[row];
    }
    return nil;
}

- (void)writeAbbreviations {
    NSMutableDictionary *data = [NSMutableDictionary new];
    
    for (ANANAbbreviation *entry in _abbreviations) {
        data[entry.text] = entry.abbreviation;
    }
    
    [NSUserDefaults.standardUserDefaults setObject:data forKey:kAbbreviationsKey];
}

- (void)writeNameColors {
    NSMutableDictionary *data = [NSMutableDictionary new];
    
    for (ANANNameColor *entry in _nameColors) {
        data[entry.name] = @(entry.colorId);
    }
    
    [NSUserDefaults.standardUserDefaults setObject:data forKey:kNameColorsKey];
}

- (void)commitTableCellEdit:(NSArray *)item {
    NSTableView *tableView = item[0];
    NSArray *dataSource = item[1];
    id entry = item[2];
    // remember what would be the first responder by its column and data entry
    NSInteger restoreFirstResponderColumn = -1;
    id restoreFirstResponderEntry = nil;
    NSResponder *naturalFirstResponder = tableView.window.firstResponder;
    if ([naturalFirstResponder isKindOfClass:[NSView class]]) {
        NSView *restorableFirstResponder = (NSView *)naturalFirstResponder;
        NSInteger restoreFirstResponderRow = [tableView rowForView:restorableFirstResponder];
        restoreFirstResponderColumn = [tableView columnForView:restorableFirstResponder];
        if (restoreFirstResponderRow != -1 && restoreFirstResponderColumn != -1) {
            restoreFirstResponderEntry = dataSource[restoreFirstResponderRow];
        }
    }
    [self tableView:tableView sortDescriptorsDidChange:tableView.sortDescriptors];
    NSInteger rowIndex = [dataSource indexOfObject:entry];
    if (rowIndex != NSNotFound) {
        [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:rowIndex] byExtendingSelection:NO];
        [tableView scrollRowToVisible:rowIndex];
    }
    if (restoreFirstResponderEntry != nil) {
        // restore remembered first responder
        NSInteger row = [dataSource indexOfObject:restoreFirstResponderEntry];
        if (row != -1) {
            [tableView editColumn:restoreFirstResponderColumn row:row withEvent:nil select:YES];
        }
    }
}

- (IBAction)updateAbbreviationText:(NSTextField *)sender {
    NSInteger row = [_abbreviationTableView rowForView:sender];
    if (row == -1) return;
    ANANAbbreviation *entry = _abbreviations[row];
    entry.text = [sender stringValue];
    [self writeAbbreviations];
    [self performSelector:@selector(commitTableCellEdit:) withObject:@[_abbreviationTableView, _abbreviations, entry] afterDelay:0];
}

- (IBAction)updateAbbreviationAbbr:(NSTextField *)sender {
    NSInteger row = [_abbreviationTableView rowForView:sender];
    if (row == -1) return;
    ANANAbbreviation *entry = _abbreviations[row];
    entry.abbreviation = [sender stringValue];
    [self writeAbbreviations];
    [self performSelector:@selector(commitTableCellEdit:) withObject:@[_abbreviationTableView, _abbreviations, entry] afterDelay:0];
}

- (IBAction)updateName:(NSTextField *)sender {
    NSInteger row = [_colorsTableView rowForView:sender];
    if (row == -1) return;
    ANANNameColor *entry = _nameColors[row];
    entry.name = [sender stringValue];
    [self writeNameColors];
    [self performSelector:@selector(commitTableCellEdit:) withObject:@[_colorsTableView, _nameColors, entry] afterDelay:0];
}

- (IBAction)updateColor:(NSPopUpButton *)sender {
    NSInteger row = [_colorsTableView rowForView:sender];
    if (row == -1) return;
    ANANNameColor *entry = _nameColors[row];
    entry.colorId = [sender selectedTag];
    [self writeNameColors];
    [self performSelector:@selector(commitTableCellEdit:) withObject:@[_colorsTableView, _nameColors, entry] afterDelay:0];
}

- (void)updateDisplayForTableView:(NSTableView *)tableView {
    if (tableView == _abbreviationTableView) {
        _removeAbbreviationButton.enabled = tableView.selectedRowIndexes.count > 0 && _displayAnchorNames;
    }
    else if (tableView == _colorsTableView) {
        _removeColorButton.enabled = tableView.selectedRowIndexes.count > 0;
    }
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = notification.object;
    [self updateDisplayForTableView:tableView];
}

- (IBAction)addAbbreviation:(id)sender {
    ANANAbbreviation *newEntry = [ANANAbbreviation new];
    newEntry.text = NSLocalizedStringFromTableInBundle(@"newText", nil, pluginBundle, @"Initial text for a new abbreviation replacement pattern");
    newEntry.abbreviation = NSLocalizedStringFromTableInBundle(@"newAbbr", nil, pluginBundle, @"Initial text for a new abbreviation");
    [_abbreviations addObject:newEntry];
    [self writeAbbreviations];
    [self tableView:_abbreviationTableView sortDescriptorsDidChange:_abbreviationTableView.sortDescriptors];
    NSInteger insertionIndex = [_abbreviations indexOfObject:newEntry];
    if (insertionIndex != NSNotFound) {
        [_abbreviationTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:insertionIndex] byExtendingSelection:NO];
        [_abbreviationTableView editColumn:0 row:insertionIndex withEvent:nil select:YES];
    }
}

- (IBAction)removeAbbreviation:(id)sender {
    NSIndexSet *indexSet = _abbreviationTableView.selectedRowIndexes;
    [_abbreviations removeObjectsAtIndexes:indexSet];
    [self writeAbbreviations];
    [self updateDisplayForTableView:_abbreviationTableView];
}

- (IBAction)addColor:(id)sender {
    ANANNameColor *newEntry = [ANANNameColor new];
    newEntry.name = NSLocalizedStringFromTableInBundle(@"newAnchorName", nil, pluginBundle, @"Initial text for a new anchor name");
    newEntry.colorId = 1;
    [_nameColors addObject:newEntry];
    [self writeNameColors];
    [self tableView:_colorsTableView sortDescriptorsDidChange:_colorsTableView.sortDescriptors];
    NSInteger insertionIndex = [_nameColors indexOfObject:newEntry];
    if (insertionIndex != NSNotFound) {
        [_colorsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:insertionIndex] byExtendingSelection:NO];
        [_colorsTableView editColumn:0 row:insertionIndex withEvent:nil select:YES];
    }
}

- (IBAction)removeColor:(id)sender {
    NSIndexSet *indexSet = _colorsTableView.selectedRowIndexes;
    [_nameColors removeObjectsAtIndexes:indexSet];
    [self writeNameColors];
    [self updateDisplayForTableView:_colorsTableView];
}

@end
