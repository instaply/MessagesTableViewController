//
//  Created by Jesse Squires
//  http://www.hexedbits.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSMessagesViewController
//
//
//  The MIT License
//  Copyright (c) 2013 Jesse Squires
//  http://opensource.org/licenses/MIT
//

#import "JSMessage.h"

@implementation JSAttachment

- (instancetype)initWithName:(NSString *)name contentType:(NSString *)contentType contentLength:(NSNumber*)contentLength url:(NSString*)url {
    if((self = [super init])){
        _name = name;
        _contentType = contentType;
        _contentLength = contentLength;
        _url = url;
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.contentType forKey:@"contentType"];
    [aCoder encodeObject:self.contentLength forKey:@"contentLength"];
    [aCoder encodeObject:self.url forKey:@"url"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _name = [aDecoder decodeObjectForKey:@"name"];
        _contentType = [aDecoder decodeObjectForKey:@"contentType"];
        _contentLength = [aDecoder decodeObjectForKey:@"contentLength"];
        _url = [aDecoder decodeObjectForKey:@"url"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithName:[self.name copy] contentType:[self.contentType copy] contentLength:self.contentLength url:[self.url copy]];
}

- (BOOL)isImage {
    return [self.contentType hasPrefix:@"image/"];
}

- (BOOL)isVideo {
    return [self.contentType hasPrefix:@"video/"];
}


@end

@implementation JSMessage

#pragma mark - Initialization

- (instancetype)initWithText:(NSString *)text
                      sender:(NSString *)sender
                        date:(NSDate *)date
{
    self = [super init];
    if (self) {
        _text = text ? text : @" ";
        _sender = sender;
        _date = date;
    }
    return self;
}

- (instancetype)initWithText:(NSString *)text
                      sender:(NSString *)sender
                        date:(NSDate *)date
                  attachment:(JSAttachment *)attachment
{
    self = [super init];
    if (self) {
        _text = text ? text : @" ";
        _sender = sender;
        _date = date;
        _attachment = attachment;
    }
    return self;
}

- (void)dealloc
{
    _text = nil;
    _sender = nil;
    _date = nil;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        _text = [aDecoder decodeObjectForKey:@"text"];
        _sender = [aDecoder decodeObjectForKey:@"sender"];
        _date = [aDecoder decodeObjectForKey:@"date"];
        _attachment = [aDecoder decodeObjectForKey:@"attachment"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.text forKey:@"text"];
    [aCoder encodeObject:self.sender forKey:@"sender"];
    [aCoder encodeObject:self.date forKey:@"date"];
    [aCoder encodeObject:self.attachment forKey:@"attachment"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    return [[[self class] allocWithZone:zone] initWithText:[self.text copy]
                                                    sender:[self.sender copy]
                                                      date:[self.date copy]
                                                attachment:[(JSAttachment *)self.attachment copy]];
}

@end
