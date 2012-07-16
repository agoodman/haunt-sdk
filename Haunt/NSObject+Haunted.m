//
//  NSObject+Haunted.m
//  Haunt
//
//  Created by Aubrey Goodman on 7/15/12.
//  Copyright (c) 2012 Migrant Studios. All rights reserved.
//

#import "NSObject+Haunted.h"
#import "Waypoint.h"


@interface NSObject (private)
+(RKObjectManager*)manager;
+(CLLocationManager*)locationManager;
+(void)setToken:(NSString*)aToken;
+(NSString*)token;
@end


static NSString* sToken;

@implementation NSObject (Haunted)

+ (void)setToken:(NSString *)aToken
{
    sToken = aToken;
}

+ (NSString*)token
{
    return sToken;
}

+ (RKObjectManager*)manager
{
    static RKObjectManager* sObjectManager;
    if( sObjectManager==nil ) {
        sObjectManager = [RKObjectManager objectManagerWithBaseURLString:[NSString stringWithFormat:@"https://haunt.herokuapp.com/devices/%@",[self token]]];
    }
    return sObjectManager;
}

+ (CLLocationManager*)locationManager
{
    static CLLocationManager* sLocationManager;
    if( sLocationManager==nil ) {
        sLocationManager = [CLLocationManager new];
        sLocationManager.delegate = (id<CLLocationManagerDelegate>)self;
    }
    return sLocationManager;
}

- (void)establishGeoFence
{
    CLLocationManager* tMgr = [self.class locationManager];
    if( tMgr.location==nil ) {
        NSLog(@"startMonitoringLocation");
        [tMgr startMonitoringSignificantLocationChanges];
    }else{
        CLRegion* tRegion = [[CLRegion alloc] initCircularRegionWithCenter:tMgr.location.coordinate radius:800 identifier:@"Haunt"];
        NSLog(@"establishGeoFence: %@",tRegion);
        [tMgr startMonitoringForRegion:tRegion desiredAccuracy:50];
        
        [self postWaypoint:tRegion.center];
    }
}

- (void)postWaypoint:(CLLocationCoordinate2D)aCoordinate
{
    Waypoint* tWaypoint = [Waypoint new];
    tWaypoint.lat = [NSNumber numberWithFloat:aCoordinate.latitude];
    tWaypoint.lng = [NSNumber numberWithFloat:aCoordinate.longitude];
    tWaypoint.measuredAt = [NSDate date];
    [[self.class manager] postObject:tWaypoint delegate:(id<RKObjectLoaderDelegate>)self];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region
{
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region
{
    [manager stopMonitoringForRegion:region];
    [self establishGeoFence];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    [manager stopMonitoringForRegion:region];
    async_main(^{
        Alert(@"Configuration Failed", @"Unable to configure location services");
    });
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [manager stopUpdatingLocation];
    [self establishGeoFence];
}

#pragma mark - RKObjectLoaderDelegate

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    NSLog(@"failed to post waypoint: %@",[error localizedDescription]);
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object
{
    NSLog(@"waypoint posted: %@",object);
    async_main(^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"WaypointCreated" object:nil];
    });
}


@end
