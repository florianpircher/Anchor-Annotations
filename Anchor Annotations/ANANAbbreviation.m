//
//  ANANAbbreviation.m
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

#import "ANANAbbreviation.h"

@implementation ANANAbbreviation

- (NSString *)description {
    return [NSString stringWithFormat:@"<ANANAbbreviation '%@' -> '%@'>", _text, _abbreviation];
}

- (NSComparisonResult)compare:(ANANAbbreviation *)other {
    if (![other isKindOfClass:[ANANAbbreviation class]]) {
        return NSOrderedSame;
    }
    
    if (_text.length < other.text.length) {
        return NSOrderedDescending;
    }
    else if (_text.length > other.text.length) {
        return NSOrderedAscending;
    }
    else {
        return [_text localizedCompare:other.text];
    }
}

@end
