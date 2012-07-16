//
//  NSObject+Haunted.h
//  Haunt
//
//  Created by Aubrey Goodman on 7/15/12.
//  Copyright (c) 2012 Migrant Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@interface NSObject (Haunted) <CLLocationManagerDelegate>

-(void)establishGeoFence;
-(void)postWaypoint:(CLLocationCoordinate2D)aCoord;

@end
