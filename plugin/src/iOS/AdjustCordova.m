//
//  AdjustCordova.m
//  Adjust SDK
//
//  Created by Pedro Filipe (@nonelse) on 3rd April 2014.
//  Copyright (c) 2012-2017 Adjust GmbH. All rights reserved.
//

#import <Cordova/CDVPluginResult.h>

#import "AdjustCordova.h"
#import "AdjustCordovaDelegate.h"

#define KEY_APP_TOKEN               @"appToken"
#define KEY_ENVIRONMENT             @"environment"
#define KEY_LOG_LEVEL               @"logLevel"
#define KEY_SDK_PREFIX              @"sdkPrefix"
#define KEY_DEFAULT_TRACKER         @"defaultTracker"
#define KEY_EVENT_BUFFERING_ENABLED @"eventBufferingEnabled"
#define KEY_EVENT_TOKEN             @"eventToken"
#define KEY_REVENUE                 @"revenue"
#define KEY_CURRENCY                @"currency"
#define KEY_RECEIPT                 @"receipt"
#define KEY_TRANSACTION_ID          @"transactionId"
#define KEY_CALLBACK_PARAMETERS     @"callbackParameters"
#define KEY_PARTNER_PARAMETERS      @"partnerParameters"
#define KEY_IS_RECEIPT_SET          @"isReceiptSet"
#define KEY_USER_AGENT              @"userAgent"
#define KEY_REFERRER                @"referrer"
#define KEY_SHOULD_LAUNCH_DEEPLINK  @"shouldLaunchDeeplink"
#define KEY_SEND_IN_BACKGROUND      @"sendInBackground"
#define KEY_DELAY_START             @"delayStart"
#define KEY_DEVICE_KNOWN            @"isDeviceKnown"
#define KEY_SECRET_ID               @"secretId"
#define KEY_INFO_1                  @"info1"
#define KEY_INFO_2                  @"info2"
#define KEY_INFO_3                  @"info3"
#define KEY_INFO_4                  @"info4"

@implementation AdjustCordova {
    NSString *attributionCallbackId;
    NSString *eventFailedCallbackId;
    NSString *eventSucceededCallbackId;
    NSString *sessionFailedCallbackId;
    NSString *sessionSucceededCallbackId;
    NSString *deferredDeeplinkCallbackId;
}

#pragma mark - Object lifecycle methods

- (void)pluginInitialize {
    attributionCallbackId = nil;
    eventFailedCallbackId = nil;
    eventSucceededCallbackId = nil;
    sessionFailedCallbackId = nil;
    sessionSucceededCallbackId = nil;
    deferredDeeplinkCallbackId = nil;
}

#pragma mark - Public methods

- (void)create:(CDVInvokedUrlCommand *)command {
    NSString *arguments = [command.arguments objectAtIndex:0];
    NSArray *jsonObject = [NSJSONSerialization JSONObjectWithData:[arguments dataUsingEncoding:NSUTF8StringEncoding]
                                                          options:0
                                                            error:NULL];

    NSString *appToken              = [[jsonObject valueForKey:KEY_APP_TOKEN] objectAtIndex:0];
    NSString *environment           = [[jsonObject valueForKey:KEY_ENVIRONMENT] objectAtIndex:0];
    NSString *logLevel              = [[jsonObject valueForKey:KEY_LOG_LEVEL] objectAtIndex:0];
    NSString *sdkPrefix             = [[jsonObject valueForKey:KEY_SDK_PREFIX] objectAtIndex:0];
    NSString *defaultTracker        = [[jsonObject valueForKey:KEY_DEFAULT_TRACKER] objectAtIndex:0];

    NSString *userAgent             = [[jsonObject valueForKey:KEY_USER_AGENT] objectAtIndex:0];
    NSString *secretId              = [[jsonObject valueForKey:KEY_SECRET_ID] objectAtIndex:0];
    NSString *info1                 = [[jsonObject valueForKey:KEY_INFO_1] objectAtIndex:0];
    NSString *info2                 = [[jsonObject valueForKey:KEY_INFO_2] objectAtIndex:0];
    NSString *info3                 = [[jsonObject valueForKey:KEY_INFO_3] objectAtIndex:0];
    NSString *info4                 = [[jsonObject valueForKey:KEY_INFO_4] objectAtIndex:0];

    NSNumber *delayStart            = [[jsonObject valueForKey:KEY_DELAY_START] objectAtIndex:0];
    NSNumber *isDeviceKnown         = [[jsonObject valueForKey:KEY_DEVICE_KNOWN] objectAtIndex:0];
    NSNumber *eventBufferingEnabled = [[jsonObject valueForKey:KEY_EVENT_BUFFERING_ENABLED] objectAtIndex:0];
    NSNumber *sendInBackground      = [[jsonObject valueForKey:KEY_SEND_IN_BACKGROUND] objectAtIndex:0];
    NSNumber *shouldLaunchDeeplink  = [[jsonObject valueForKey:KEY_SHOULD_LAUNCH_DEEPLINK] objectAtIndex:0];

    BOOL allowSuppressLogLevel = false;

    // Check for SUPPRESS log level
    if ([self isFieldValid:logLevel]) {
        if ([ADJLogger logLevelFromString:[logLevel lowercaseString]] == ADJLogLevelSuppress) {
            allowSuppressLogLevel = true;
        }
    }

    ADJConfig *adjustConfig = [ADJConfig configWithAppToken:appToken
                                                environment:environment
                                      allowSuppressLogLevel:allowSuppressLogLevel];

    if (![adjustConfig isValid]) {
        return;
    }

    // Log level
    if ([self isFieldValid:logLevel]) {
        [adjustConfig setLogLevel:[ADJLogger logLevelFromString:[logLevel lowercaseString]]];
    }

    // Event buffering
    if ([self isFieldValid:eventBufferingEnabled]) {
        [adjustConfig setEventBufferingEnabled:[eventBufferingEnabled boolValue]];
    }

    // SDK prefix
    if ([self isFieldValid:sdkPrefix]) {
        [adjustConfig setSdkPrefix:sdkPrefix];
    }

    // Default tracker
    if ([self isFieldValid:defaultTracker]) {
        [adjustConfig setDefaultTracker:defaultTracker];
    }

    // Send in background
    if ([self isFieldValid:sendInBackground]) {
        [adjustConfig setSendInBackground:[sendInBackground boolValue]];
    }

    // User agent
    if ([self isFieldValid:userAgent]) {
        [adjustConfig setUserAgent:userAgent];
    }

    // Delay start
    if ([self isFieldValid:delayStart]) {
        [adjustConfig setDelayStart:[delayStart doubleValue]];
    }

    // Device known
    if ([self isFieldValid:isDeviceKnown]) {
        [adjustConfig setIsDeviceKnown:[isDeviceKnown boolValue]];
    }

    // App Secret
    if ([self isFieldValid:secretId]
        && [self isFieldValid:info1]
        && [self isFieldValid:info2]
        && [self isFieldValid:info3]
        && [self isFieldValid:info4]) {
        [adjustConfig setAppSecret:[[NSNumber numberWithLongLong:[secretId longLongValue]] unsignedIntegerValue]
                             info1:[[NSNumber numberWithLongLong:[info1 longLongValue]] unsignedIntegerValue]
                             info2:[[NSNumber numberWithLongLong:[info2 longLongValue]] unsignedIntegerValue]
                             info3:[[NSNumber numberWithLongLong:[info3 longLongValue]] unsignedIntegerValue]
                             info4:[[NSNumber numberWithLongLong:[info4 longLongValue]] unsignedIntegerValue]];
    }

    BOOL isAttributionCallbackImplemented = attributionCallbackId != nil ? YES : NO;
    BOOL isEventSucceededCallbackImplemented = eventSucceededCallbackId != nil ? YES : NO;
    BOOL isEventFailedCallbackImplemented = eventFailedCallbackId != nil ? YES : NO;
    BOOL isSessionSucceededCallbackImplemented = sessionSucceededCallbackId != nil ? YES : NO;
    BOOL isSessionFailedCallbackImplemented = sessionFailedCallbackId != nil ? YES : NO;
    BOOL isDeferredDeeplinkCallbackImplemented = deferredDeeplinkCallbackId != nil ? YES : NO;
    BOOL shouldLaunchDeferredDeeplink = [self isFieldValid:shouldLaunchDeeplink] ? [shouldLaunchDeeplink boolValue] : YES;

    // Attribution delegate & other delegates
    if (isAttributionCallbackImplemented
        || isEventSucceededCallbackImplemented
        || isEventFailedCallbackImplemented
        || isSessionSucceededCallbackImplemented
        || isSessionFailedCallbackImplemented
        || isDeferredDeeplinkCallbackImplemented) {
        [adjustConfig setDelegate:
            [AdjustCordovaDelegate getInstanceWithSwizzleOfAttributionCallback:isAttributionCallbackImplemented
                                                        eventSucceededCallback:isEventSucceededCallbackImplemented
                                                           eventFailedCallback:isEventFailedCallbackImplemented
                                                      sessionSucceededCallback:isSessionSucceededCallbackImplemented
                                                         sessionFailedCallback:isSessionFailedCallbackImplemented
                                                      deferredDeeplinkCallback:isDeferredDeeplinkCallbackImplemented
                                                      andAttributionCallbackId:attributionCallbackId
                                                      eventSucceededCallbackId:eventSucceededCallbackId
                                                         eventFailedCallbackId:eventFailedCallbackId
                                                    sessionSucceededCallbackId:sessionSucceededCallbackId
                                                       sessionFailedCallbackId:sessionFailedCallbackId
                                                    deferredDeeplinkCallbackId:deferredDeeplinkCallbackId
                                                  shouldLaunchDeferredDeeplink:shouldLaunchDeferredDeeplink
                                                           withCommandDelegate:self.commandDelegate]];
    }

    [Adjust appDidLaunch:adjustConfig];
    [Adjust trackSubsessionStart];
}

- (void)trackEvent:(CDVInvokedUrlCommand *)command {
    NSString *arguments = [command.arguments objectAtIndex:0];
    NSArray *jsonObject = [NSJSONSerialization JSONObjectWithData:[arguments dataUsingEncoding:NSUTF8StringEncoding]
                                                          options:0
                                                            error:NULL];

    NSString *eventToken = [[jsonObject valueForKey:KEY_EVENT_TOKEN] objectAtIndex:0];
    NSString *revenue = [[jsonObject valueForKey:KEY_REVENUE] objectAtIndex:0];
    NSString *currency = [[jsonObject valueForKey:KEY_CURRENCY] objectAtIndex:0];
    NSString *receipt = [[jsonObject valueForKey:KEY_RECEIPT] objectAtIndex:0];
    NSString *transactionId = [[jsonObject valueForKey:KEY_TRANSACTION_ID] objectAtIndex:0];
    NSNumber *isReceiptSet = [[jsonObject valueForKey:KEY_IS_RECEIPT_SET] objectAtIndex:0];

    NSMutableArray *callbackParameters = [[NSMutableArray alloc] init];
    NSMutableArray *partnerParameters = [[NSMutableArray alloc] init];

    for (id item in [[jsonObject valueForKey:KEY_CALLBACK_PARAMETERS] objectAtIndex:0]) {
        [callbackParameters addObject:item];
    }

    for (id item in [[jsonObject valueForKey:KEY_PARTNER_PARAMETERS] objectAtIndex:0]) {
        [partnerParameters addObject:item];
    }

    ADJEvent *adjustEvent = [ADJEvent eventWithEventToken:eventToken];

    if (![adjustEvent isValid]) {
        return;
    }

    // Revenue and currency
    if ([self isFieldValid:revenue]) {
        double revenueValue = [revenue doubleValue];

        [adjustEvent setRevenue:revenueValue currency:currency];
    }

    // Callback parameters
    for (int i = 0; i < [callbackParameters count]; i += 2) {
        NSString *key = [callbackParameters objectAtIndex:i];
        NSObject *value = [callbackParameters objectAtIndex:(i+1)];

        [adjustEvent addCallbackParameter:key value:[NSString stringWithFormat:@"%@", value]];
    }

    // Partner parameters
    for (int i = 0; i < [partnerParameters count]; i += 2) {
        NSString *key = [partnerParameters objectAtIndex:i];
        NSObject *value = [partnerParameters objectAtIndex:(i+1)];

        [adjustEvent addPartnerParameter:key value:[NSString stringWithFormat:@"%@", value]];
    }

    // Deprecated
    // Transaction ID and receipt
    BOOL isTransactionIdSet = false;

    if ([self isFieldValid:isReceiptSet]) {
        if ([isReceiptSet boolValue]) {
            [adjustEvent setReceipt:[receipt dataUsingEncoding:NSUTF8StringEncoding] transactionId:transactionId];
        } else {
            if ([self isFieldValid:transactionId]) {
                [adjustEvent setTransactionId:transactionId];

                isTransactionIdSet = YES;
            }
        }
    }

    if (NO == isTransactionIdSet) {
        if ([self isFieldValid:transactionId]) {
            [adjustEvent setTransactionId:transactionId];
        }
    }

    [Adjust trackEvent:adjustEvent];
}

- (void)setOfflineMode:(CDVInvokedUrlCommand *)command {
    NSNumber *isEnabledNumber = [command argumentAtIndex:0 withDefault:nil];

    if (isEnabledNumber == nil) {
        return;
    }

    [Adjust setOfflineMode:[isEnabledNumber boolValue]];
}

- (void)setPushToken:(CDVInvokedUrlCommand *)command {
    NSString *token = [command argumentAtIndex:0 withDefault:nil];

    if (!([self isFieldValid:token])) {
        return;
    }

    [Adjust setDeviceToken:[token dataUsingEncoding:NSUTF8StringEncoding]];
}

- (void)appWillOpenUrl:(CDVInvokedUrlCommand *)command {
    NSString *urlString = [command argumentAtIndex:0 withDefault:nil];

    if (urlString == nil) {
        return;
    }

    NSURL *url;

    if ([NSString instancesRespondToSelector:@selector(stringByAddingPercentEncodingWithAllowedCharacters:)]) {
        url = [NSURL URLWithString:[urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        url = [NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    }
#pragma clang diagnostic pop

    [Adjust appWillOpenUrl:url];
}

- (void)getIdfa:(CDVInvokedUrlCommand *)command {
    NSString *idfa = [Adjust idfa];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:idfa];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getAdid:(CDVInvokedUrlCommand *)command {
    NSString *adid = [Adjust adid];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:adid];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getAttribution:(CDVInvokedUrlCommand *)command {
    ADJAttribution *attribution = [Adjust attribution];

    if (attribution == nil) {
        return;
    }
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [self addValueOrEmpty:attribution.trackerToken withKey:@"trackerToken" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.trackerName withKey:@"trackerName" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.network withKey:@"network" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.campaign withKey:@"campaign" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.creative withKey:@"creative" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.adgroup withKey:@"adgroup" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.clickLabel withKey:@"clickLabel" toDictionary:dictionary];
    [self addValueOrEmpty:attribution.adid withKey:@"adid" toDictionary:dictionary];

    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dictionary];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setEnabled:(CDVInvokedUrlCommand *)command {
    NSNumber *isEnabledNumber = [command argumentAtIndex:0 withDefault:nil];

    if (isEnabledNumber == nil) {
        return;
    }

    [Adjust setEnabled:[isEnabledNumber boolValue]];
}

- (void)isEnabled:(CDVInvokedUrlCommand *)command {
    BOOL isEnabled = [Adjust isEnabled];
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:isEnabled];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)sendFirstPackages:(CDVInvokedUrlCommand *)command {
    [Adjust sendFirstPackages];
}

- (void)setAttributionCallback:(CDVInvokedUrlCommand *)command {
    attributionCallbackId = command.callbackId;
}

- (void)setEventTrackingSucceededCallback:(CDVInvokedUrlCommand *)command {
    eventSucceededCallbackId = command.callbackId;
}

- (void)setEventTrackingFailedCallback:(CDVInvokedUrlCommand *)command {
    eventFailedCallbackId = command.callbackId;
}

- (void)setSessionTrackingSucceededCallback:(CDVInvokedUrlCommand *)command {
    sessionSucceededCallbackId = command.callbackId;
}

- (void)setSessionTrackingFailedCallback:(CDVInvokedUrlCommand *)command {
    sessionFailedCallbackId = command.callbackId;
}

- (void)setDeferredDeeplinkCallback:(CDVInvokedUrlCommand *)command {
    deferredDeeplinkCallbackId = command.callbackId;
}

- (void)addSessionCallbackParameter:(CDVInvokedUrlCommand *)command {
    NSString *key = [command argumentAtIndex:0 withDefault:nil];
    NSString *value = [command argumentAtIndex:1 withDefault:nil];

    if (!([self isFieldValid:key]) || !([self isFieldValid:value])) {
        return;
    }

    [Adjust addSessionCallbackParameter:key value:value];
}

- (void)removeSessionCallbackParameter:(CDVInvokedUrlCommand *)command {
    NSString *key = [command argumentAtIndex:0 withDefault:nil];

    if (!([self isFieldValid:key])) {
        return;
    }

    [Adjust removeSessionCallbackParameter:key];
}

- (void)resetSessionCallbackParameters:(CDVInvokedUrlCommand *)command {
    [Adjust resetSessionCallbackParameters];
}

- (void)addSessionPartnerParameter:(CDVInvokedUrlCommand *)command {
    NSString *key = [command argumentAtIndex:0 withDefault:nil];
    NSString *value = [command argumentAtIndex:1 withDefault:nil];

    if (!([self isFieldValid:key]) || !([self isFieldValid:value])) {
        return;
    }

    [Adjust addSessionPartnerParameter:key value:value];
}

- (void)removeSessionPartnerParameter:(CDVInvokedUrlCommand *)command {
    NSString *key = [command argumentAtIndex:0 withDefault:nil];

    if (!([self isFieldValid:key])) {
        return;
    }

    [Adjust removeSessionPartnerParameter:key];
}

- (void)resetSessionPartnerParameters:(CDVInvokedUrlCommand *)command {
    [Adjust resetSessionPartnerParameters];
}

// Android methods
- (void)onPause:(CDVInvokedUrlCommand *)command {}

- (void)onResume:(CDVInvokedUrlCommand *)command {}

- (void)setReferrer:(CDVInvokedUrlCommand *)command {}

- (void)getGoogleAdId:(CDVInvokedUrlCommand *)command {
    NSString *googleAdId = @"";
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:googleAdId];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getAmazonAdId:(CDVInvokedUrlCommand *)command {
    NSString *amazonAdId = @"";
    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:amazonAdId];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

#pragma mark - Private & helper methods

- (BOOL)isFieldValid:(NSObject *)field {
    return field != nil && ![field isKindOfClass:[NSNull class]];
}

- (void)addValueOrEmpty:(NSObject *)value
                withKey:(NSString *)key
           toDictionary:(NSMutableDictionary *)dictionary {
    if (nil != value) {
        [dictionary setObject:[NSString stringWithFormat:@"%@", value] forKey:key];
    } else {
        [dictionary setObject:@"" forKey:key];
    }
}

@end