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

static void *abbreviationsContext = &abbreviationsContext;
static void *namedColorsContext = &namedColorsContext;

@interface ANANSettings ()
@property (strong) IBOutlet NSTableView *abbreviationTableView;
@property (strong) IBOutlet NSTableView *colorsTableView;
@property (strong) IBOutlet NSButton *removeAbbreviationButton;
@property (strong) IBOutlet NSButton *removeColorButton;

@property (strong) NSMutableArray<ANANAbbreviation *> *abbreviations;
@property (strong) NSMutableArray<ANANNameColor *> *nameColors;
@end

@implementation ANANSettings

+ (instancetype)sharedSettings {
    static ANANSettings *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [ANANSettings new];
    });
    return sharedInstance;
}

- (id)init {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    self = [super initWithNibName:@"ANANSettings" bundle:bundle];
    
    if (self != nil) {
        self.title = NSLocalizedStringFromTableInBundle(@"Anchor Annotations", nil, bundle, @"Title of the Anchor Annotations tab in settings");
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
    }
    
    return self;
}

- (void)dealloc {
    NSUserDefaultsController *defaultsController = NSUserDefaultsController.sharedUserDefaultsController;
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kAbbreviationsKey]];
    [defaultsController removeObserver:self forKeyPath:[@"values." stringByAppendingString:kNameColorsKey]];
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
        
        [_abbreviationTableView reloadData];
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
        
        [_colorsTableView reloadData];
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
    _abbreviationTableView.delegate = self;
    _abbreviationTableView.dataSource = self;
    [_abbreviationTableView reloadData];
    
    _colorsTableView.delegate = self;
    _colorsTableView.dataSource = self;
    [_colorsTableView reloadData];
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
        if ([tableColumn.identifier isEqualToString:@"Text"]) {
            return _abbreviations[row].text;
        }
        else if ([tableColumn.identifier isEqualToString:@"Abbr"]) {
            return _abbreviations[row].abbreviation;
        }
    }
    else if (tableView == _colorsTableView) {
        return _nameColors[row];
    }
    return nil;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == _abbreviationTableView) {
        if ([tableColumn.identifier isEqualToString:@"Text"]) {
            NSTableCellView *cellView = [_abbreviationTableView makeViewWithIdentifier:@"Text" owner:self];
            cellView.textField.target = self;
            cellView.textField.action = @selector(updateAbbreviationText:);
            return cellView;
        }
        else if ([tableColumn.identifier isEqualToString:@"Abbr"]) {
            NSTableCellView *cellView = [_abbreviationTableView makeViewWithIdentifier:@"Abbr" owner:self];
            cellView.textField.target = self;
            cellView.textField.action = @selector(updateAbbreviationAbbr:);
            return cellView;
        }
    }
    else if (tableView == _colorsTableView) {
        if ([tableColumn.identifier isEqualToString:@"Name"]) {
            NSTableCellView *cellView = [_colorsTableView makeViewWithIdentifier:@"Name" owner:self];
            cellView.textField.target = self;
            cellView.textField.action = @selector(updateName:);
            return cellView;
        }
        else if ([tableColumn.identifier isEqualToString:@"Color"]) {
            ANANPopupTableCellView *cellView = [_colorsTableView makeViewWithIdentifier:@"Color" owner:self];
            cellView.popupButton.target = self;
            cellView.popupButton.action = @selector(updateColor:);
            return cellView;
        }
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

- (IBAction)updateAbbreviationText:(NSTextField *)sender {
    NSInteger row = [_abbreviationTableView rowForView:sender];
    if (row == -1) return;
    _abbreviations[row].text = [sender stringValue];
    [self writeAbbreviations];
}

- (IBAction)updateAbbreviationAbbr:(NSTextField *)sender {
    NSInteger row = [_abbreviationTableView rowForView:sender];
    if (row == -1) return;
    _abbreviations[row].abbreviation = [sender stringValue];
    [self writeAbbreviations];
}

- (IBAction)updateName:(NSTextField *)sender {
    NSInteger row = [_colorsTableView rowForView:sender];
    if (row == -1) return;
    _nameColors[row].name = [sender stringValue];
    [self writeNameColors];
}

- (IBAction)updateColor:(NSPopUpButton *)sender {
    NSInteger row = [_colorsTableView rowForView:sender];
    if (row == -1) return;
    _nameColors[row].colorId = [sender selectedTag];
    [self writeNameColors];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSTableView *tableView = notification.object;
    
    if (tableView == _abbreviationTableView) {
        _removeAbbreviationButton.enabled = tableView.selectedRowIndexes.count > 0;
    }
    else if (tableView == _colorsTableView) {
        _removeColorButton.enabled = tableView.selectedRowIndexes.count > 0;
    }
}

- (IBAction)addAbbreviation:(id)sender {
    ANANAbbreviation *newEntry = [ANANAbbreviation new];
    newEntry.text = @"someText";
    newEntry.abbreviation = @"abbr";
    [_abbreviations addObject:newEntry];
    [self writeAbbreviations];
}

- (IBAction)removeAbbreviation:(id)sender {
    NSIndexSet *indexSet = _abbreviationTableView.selectedRowIndexes;
    [_abbreviations removeObjectsAtIndexes:indexSet];
    [self writeAbbreviations];
}

- (IBAction)addColor:(id)sender {
    ANANNameColor *newEntry = [ANANNameColor new];
    newEntry.name = @"someName";
    newEntry.colorId = 5;
    [_nameColors addObject:newEntry];
    [self writeNameColors];
}

- (IBAction)removeColor:(id)sender {
    NSIndexSet *indexSet = _colorsTableView.selectedRowIndexes;
    [_nameColors removeObjectsAtIndexes:indexSet];
    [self writeNameColors];
}

@end