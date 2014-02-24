//
//  STKAvatar.m
//  Strik
//
//  Created by Matthijn on Feb 23, 2014.
//  Copyright (c) 2014 Indev. All rights reserved.
//

#import "STKModel.h"

typedef NS_ENUM(NSInteger, AvatarType)
{
	AvatarTypeProfile,
	AvatarTypeClient
};

typedef void(^AvatarFetchResultBlock)(CCTexture *avatarTexture, AvatarType avatarType);

@interface STKAvatar : STKModel

@property (readonly) NSString *identifier;

// The avatar type (e.g profile picture, or chosen from the client avatar collection)
@property (readonly) AvatarType avatarType;

- (id)initWithAvatarIdentifier:(NSString *)identifier;
+ (STKAvatar*)avatarWithIdentifier:(NSString*)identifier;

- (void)fetchAvatarWithCallback:(AvatarFetchResultBlock)callback;

@end
