//
//  MDDisqusTokensModel.h
//  Disqus
//
//  Created by Andrew Kopanev on 3/16/14.
//  Copyright (c) 2014 Moqod. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MDDisqusTokensModel : NSObject

@property (nonatomic, retain) NSString				*accessToken;
@property (nonatomic, retain) NSString				*refreshToken;
@property (nonatomic, retain) NSString				*publicKey;

- (id)initWithPublicKey:(NSString *)publicKey;
- (void)dump;
- (void)reset;

@end
