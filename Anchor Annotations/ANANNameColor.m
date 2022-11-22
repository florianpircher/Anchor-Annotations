//
//  ANANNameColor.m
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

#import "ANANNameColor.h"

@implementation ANANNameColor

- (BOOL)isEqual:(ANANNameColor *)other {
    if (other == self) {
        return YES;
    }
    else if (other == nil || ![other isKindOfClass:[ANANNameColor class]]) {
        return NO;
    }
    else {
        return [_name isEqualToString:other.name] && _colorId == other.colorId;
    }
}

- (NSUInteger)hash {
    return _name.hash ^ _colorId;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<ANANNameColor '%@': %ld>", _name, _colorId];
}

@end
