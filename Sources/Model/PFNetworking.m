//
//  PFNetworking.m
//  PlaceFinder
//
//  Created by Anton on 5/13/20.
//  Copyright © 2020 Anton. All rights reserved.
//

#import "PFNetworking.h"
#import <UIKit/UIKit.h>

NSString* const apiKey = @"AIzaSyBPsziH_ZUzf6dty3UGMGXE2_hli___MIA"; //@"AIzaSyCCOAaGJlvgPhCRB1-ppj9vW2kq9hwQKNg"
NSString* const cityURLFormat = @"https://maps.googleapis.com/maps/api/place/textsearch/json?query=%@&key=%@";
NSString* const locationURLFormat = @"https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=%.7f,%.7f&radius=5000&key=%@";
NSString* const imageURLFormat = @"https://maps.googleapis.com/maps/api/place/photo?maxwidth=600&photoreference=%@&key=%@";
NSString* const detailsURLFormat = @"https://maps.googleapis.com/maps/api/place/details/json?place_id=%@&fields=rating,formatted_phone_number,adr_address&key=%@";

@implementation PFNetworking

+ (NSMutableURLRequest*)apiRequestWith:(NSString*)urlString {
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];

    [request setURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:@"GET"];
    [request addValue:@"text/plain" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"text/plain" forHTTPHeaderField:@"Accept"];
    return request;
}

+ (void)requestCityCoordinates:(NSString*)city completion:(void (^)(CLLocationCoordinate2D coordinate, NSString* _Nullable errorString))completion {
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(0, 0);

    if (city == nil || [city isEqualToString:@""]) {
        completion(coordinate, @"Empty city name");
        return;
    }

    NSMutableURLRequest* request = [self apiRequestWith:[NSString stringWithFormat:cityURLFormat, city, apiKey]];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString* requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSData* responseData = [requestReply dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];

        if (error != nil) {
            completion(coordinate, error.localizedDescription);
        } else {
            NSString* status = [jsonDict objectForKey:@"status"];
            if ([status isEqualToString:@"OK"]) {
                NSString* latitudeString = [[jsonDict valueForKeyPath:@"results.geometry.location.lat"] firstObject];
                NSString* longitudeString = [[jsonDict valueForKeyPath:@"results.geometry.location.lng"] firstObject];

                completion(CLLocationCoordinate2DMake(latitudeString.doubleValue, longitudeString.doubleValue), nil);

            } else {
                NSString* errorMessage = [jsonDict objectForKey:@"error_message"];
                if (errorMessage == nil) {
                    errorMessage = [NSString stringWithFormat:@"Can't find city \"%@\"", city];
                }
                completion(coordinate, errorMessage);
            }
        }

    }] resume];
}

+ (void)requestPlacesFor:(CLLocationCoordinate2D)coordinate completion:(void (^)(NSArray<NSDictionary*>* _Nullable results, NSString* _Nullable errorString))completion {
    NSMutableURLRequest* request = [self apiRequestWith:[NSString stringWithFormat:locationURLFormat, coordinate.latitude, coordinate.longitude, apiKey]];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString* requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSData* responseData = [requestReply dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];

        if (error != nil) {
            completion(nil, error.localizedDescription);
        } else {
            NSString* status = [jsonDict objectForKey:@"status"];
            if ([status isEqualToString:@"OK"]) {
                completion([jsonDict objectForKey:@"results"], nil);
            } else {
                completion(nil, [jsonDict objectForKey:@"error_message"]);
            }
        }

    }] resume];
}

+ (void)requestImageWith:(NSString*)imageReference completion:(void (^)(UIImage* _Nullable image))completion {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString* imageURLString = [NSString stringWithFormat:imageURLFormat, imageReference, apiKey];
        NSData* data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:imageURLString]];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data == nil) {
                completion(nil);
            } else {
                completion([UIImage imageWithData:data]);
            }
        });
    });
}

+ (void)requestDetailsFor:(NSString*)placeID completion:(void (^)(NSDictionary* _Nullable details))completion {
    NSMutableURLRequest* request = [self apiRequestWith:[NSString stringWithFormat:detailsURLFormat, placeID, apiKey]];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSString* requestReply = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        NSData* responseData = [requestReply dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* jsonDict = [NSJSONSerialization JSONObjectWithData:responseData options:kNilOptions error:&error];

        if (error != nil) {
            completion(nil);
        } else {
            NSString* status = [jsonDict objectForKey:@"status"];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([status isEqualToString:@"OK"]) {
                    completion([jsonDict objectForKey:@"result"]);
                } else {
                    completion(nil);
                }
            });
        }

    }] resume];
}

@end
