//
//  AIRGoogleMapManager.m
//  AirMaps
//
//  Created by Gil Birman on 9/1/16.
//

#ifdef HAVE_GOOGLE_MAPS


#import "AIRGoogleMapManager.h"
#import <React/RCTViewManager.h>
#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>
#import <React/RCTConvert+CoreLocation.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTViewManager.h>
#import <React/RCTConvert.h>
#import <React/UIView+React.h>
#import "RCTConvert+GMSMapViewType.h"
#import "AIRGoogleMap.h"
#import "AIRGoogleMapMarker.h"
#import "AIRGoogleMapCoordinate.h"
#import "RCTConvert+GMSMapViewType.h"
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>

#if __has_include(<ReactNativeMaps/generated/RNMapsAirModuleDelegate.h>)
#import <ReactNativeMaps/generated/RNMapsAirModuleDelegate.h>
#else
#import "RNMapsAirModuleDelegate.h"
#endif

static NSString *const RCTMapViewKey = @"MapView";


@interface AIRGoogleMapManager() <GMSMapViewDelegate>
{
    BOOL didCallOnMapReady;
}

- (UIView *)defaultInfoWindowForMarker:(GMSMarker *)marker;
- (NSAttributedString *)attributedTextForHTMLString:(NSString *)html
                                                 font:(UIFont *)font
                                                color:(UIColor *)color;
- (NSString *)normalizedStringForSnippet:(NSString *)snippet;
@end

static const CGFloat kAIRGenericInfoWindowMaxContentWidth = 260.0f;
static const CGFloat kAIRGenericInfoWindowMinContentWidth = 120.0f;
static const CGFloat kAIRGenericInfoWindowHorizontalPadding = 12.0f;
static const CGFloat kAIRGenericInfoWindowVerticalPadding = 10.0f;
static const CGFloat kAIRGenericInfoWindowInterLabelSpacing = 4.0f;

@implementation AIRGoogleMapManager

RCT_EXPORT_MODULE()

- (UIView *)view
{
    
    if (self.initialProps){
        if (self.initialProps[@"googleMapId"]){
            _googleMapId  = self.initialProps[@"googleMapId"];
        }
        if (self.initialProps[@"zoomTapEnabled"]){
            _zoomTapEnabled = self.initialProps[@"zoomTapEnabled"];
        }
        if (self.initialProps[@"loadingBackgroundColor"]){
            _backgroundColor = [RCTConvert UIColor:self.initialProps[@"loadingBackgroundColor"]];
        }
        if (self.initialProps[@"initialCamera"]){
            _camera = [RCTConvert GMSCameraPositionWithDefaults:self.initialProps[@"initialCamera"] existingCamera:nil];
        }
    }
    AIRGoogleMap *map = [[AIRGoogleMap alloc] initWithMapId:self.googleMapId initialCamera:self.camera backgroundColor:self.backgroundColor andZoomTapEnabled:self.zoomTapEnabled];
    map.bridge = self.bridge;
    map.delegate = self;
    map.isAccessibilityElement = NO;
    map.accessibilityElementsHidden = NO;
    map.settings.consumesGesturesInView = NO;
    if (self.customMapStyle != nil){
        map.customMapStyleString = self.customMapStyle;
    }
    
    UIPanGestureRecognizer *drag = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapDrag:)];
    [drag setMinimumNumberOfTouches:1];
    [drag setMaximumNumberOfTouches:1];
    [map addGestureRecognizer:drag];
    
    UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapDrag:)];
    [map addGestureRecognizer:pinch];
    
    return map;
}

RCT_EXPORT_VIEW_PROPERTY(isAccessibilityElement, BOOL)
RCT_REMAP_VIEW_PROPERTY(testID, accessibilityIdentifier, NSString)
RCT_EXPORT_VIEW_PROPERTY(googleMapId, NSString)
RCT_EXPORT_VIEW_PROPERTY(initialCamera, GMSCameraPosition)
RCT_REMAP_VIEW_PROPERTY(camera, cameraProp, GMSCameraPosition)
RCT_EXPORT_VIEW_PROPERTY(initialRegion, MKCoordinateRegion)
RCT_EXPORT_VIEW_PROPERTY(region, MKCoordinateRegion)
RCT_EXPORT_VIEW_PROPERTY(showsBuildings, BOOL)
RCT_EXPORT_VIEW_PROPERTY(showsCompass, BOOL)
//RCT_EXPORT_VIEW_PROPERTY(showsScale, BOOL)  // Not supported by GoogleMaps
RCT_EXPORT_VIEW_PROPERTY(showsTraffic, BOOL)
RCT_EXPORT_VIEW_PROPERTY(zoomEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(rotateEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(scrollEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(scrollDuringRotateOrZoomEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(pitchEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(zoomTapEnabled, BOOL)
RCT_EXPORT_VIEW_PROPERTY(showsUserLocation, BOOL)
RCT_EXPORT_VIEW_PROPERTY(showsMyLocationButton, BOOL)
RCT_EXPORT_VIEW_PROPERTY(showsIndoors, BOOL)
RCT_EXPORT_VIEW_PROPERTY(showsIndoorLevelPicker, BOOL)
RCT_EXPORT_VIEW_PROPERTY(customMapStyleString, NSString)
RCT_EXPORT_VIEW_PROPERTY(mapPadding, UIEdgeInsets)
RCT_REMAP_VIEW_PROPERTY(paddingAdjustmentBehavior, paddingAdjustmentBehaviorString, NSString)
RCT_EXPORT_VIEW_PROPERTY(onMapReady, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMapLoaded, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onKmlReady, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPress, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onLongPress, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPanDrag, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onUserLocationChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMarkerPress, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMarkerSelect, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onMarkerDeselect, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onRegionChangeStart, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onRegionChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onRegionChangeComplete, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onPoiClick, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onIndoorLevelActivated, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onIndoorBuildingFocused, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(mapType, GMSMapViewType)
RCT_EXPORT_VIEW_PROPERTY(minZoomLevel, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(maxZoomLevel, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(kmlSrc, NSArray)
RCT_EXPORT_VIEW_PROPERTY(loadingBackgroundColor, UIColor)

RCT_EXPORT_METHOD(getCamera:(nonnull NSNumber *)reactTag
                  resolver: (RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            reject(@"Invalid argument", [NSString stringWithFormat:@"Invalid view returned from registry, expecting AIRGoogleMap, got: %@", view], NULL);
        } else {
            AIRGoogleMap *mapView = (AIRGoogleMap *)view;
            resolve(@{
                @"center": @{
                    @"latitude": @(mapView.camera.target.latitude),
                    @"longitude": @(mapView.camera.target.longitude),
                },
                @"pitch": @(mapView.camera.viewingAngle),
                @"heading": @(mapView.camera.bearing),
                @"zoom": @(mapView.camera.zoom),
            });
        }
    }];
}

RCT_EXPORT_METHOD(setCamera:(nonnull NSNumber *)reactTag
                  camera:(id)json)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRGoogleMap, got: %@", view);
        } else {
            AIRGoogleMap *mapView = (AIRGoogleMap *)view;
            GMSCameraPosition *camera = [RCTConvert GMSCameraPositionWithDefaults:json existingCamera:[mapView cameraProp]];
            [mapView setCameraProp:camera];
        }
    }];
}


RCT_EXPORT_METHOD(animateCamera:(nonnull NSNumber *)reactTag
                  withCamera:(id)json
                  withDuration:(CGFloat)duration)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRGoogleMap, got: %@", view);
        } else {
            [CATransaction begin];
            [CATransaction setAnimationDuration:duration/1000];
            AIRGoogleMap *mapView = (AIRGoogleMap *)view;
            GMSCameraPosition *camera = [RCTConvert GMSCameraPositionWithDefaults:json existingCamera:[mapView cameraProp]];
            [mapView animateToCameraPosition:camera];
            [CATransaction commit];
        }
    }];
}

RCT_EXPORT_METHOD(animateToRegion:(nonnull NSNumber *)reactTag
                  withRegion:(MKCoordinateRegion)region
                  withDuration:(CGFloat)duration)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRGoogleMap, got: %@", view);
        } else {
            // Core Animation must be used to control the animation's duration
            // See http://stackoverflow.com/a/15663039/171744
            [CATransaction begin];
            [CATransaction setAnimationDuration:duration/1000];
            AIRGoogleMap *mapView = (AIRGoogleMap *)view;
            GMSCameraPosition *camera = [AIRGoogleMap makeGMSCameraPositionFromMap:mapView andMKCoordinateRegion:region];
            [mapView animateToCameraPosition:camera];
            [CATransaction commit];
        }
    }];
}

RCT_EXPORT_METHOD(fitToElements:(nonnull NSNumber *)reactTag
                  edgePadding:(nonnull NSDictionary *)edgePadding
                  animated:(BOOL)animated)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRGoogleMap, got: %@", view);
        } else {
            AIRGoogleMap *mapView = (AIRGoogleMap *)view;
            [mapView fitToElementsWithEdgePadding:edgePadding animated:animated];
        }
    }];
}

RCT_EXPORT_METHOD(fitToSuppliedMarkers:(nonnull NSNumber *)reactTag
                  markers:(nonnull NSArray *)markers
                  edgePadding:(nonnull NSDictionary *)edgePadding
                  animated:(BOOL)animated)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRGoogleMap, got: %@", view);
        } else {
            AIRGoogleMap *mapView = (AIRGoogleMap *)view;
            [mapView fitToSuppliedMarkers:markers withEdgePadding:edgePadding animated:animated];
        }
    }];
}

RCT_EXPORT_METHOD(fitToCoordinates:(nonnull NSNumber *)reactTag
                  coordinates:(nonnull NSArray<AIRGoogleMapCoordinate *> *)coordinates
                  edgePadding:(nonnull NSDictionary *)edgePadding
                  animated:(BOOL)animated)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRGoogleMap, got: %@", view);
        } else {
            AIRGoogleMap *mapView = (AIRGoogleMap *)view;
            [mapView fitToCoordinates:coordinates withEdgePadding:edgePadding animated:animated];
        }
    }];
}

RCT_EXPORT_METHOD(takeSnapshot:(nonnull NSNumber *)reactTag
                  withWidth:(nonnull NSNumber *)width
                  withHeight:(nonnull NSNumber *)height
                  withRegion:(MKCoordinateRegion)region
                  format:(nonnull NSString *)format
                  quality:(nonnull NSNumber *)quality
                  result:(nonnull NSString *)result
                  withCallback:(RCTPromiseResolveBlock)callback)
{
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSString *pathComponent = [NSString stringWithFormat:@"Documents/snapshot-%.20lf.%@", timeStamp, format];
    NSString *filePath = [NSHomeDirectory() stringByAppendingPathComponent: pathComponent];
    
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRMap, got: %@", view);
        } else {
            NSMutableDictionary* config = [NSMutableDictionary new];
            
            [view takeSnapshotWithConfig:config success:callback error:^(NSString *code, NSString *message, NSError *error) {
                callback(@[error]);
            }];
            
            [config setObject:width forKey:@"width"];
            [config setObject:height forKey:@"height"];
            [config setObject:format forKey:@"format"];
            [config setObject:quality forKey:@"quality"];
            [config setObject:result forKey:@"result"];
            [config setObject:filePath forKey:@"filePath"];
            
            // TODO: currently we are ignoring width, height, region
            
            AIRGoogleMap* mapView = (AIRGoogleMap *) view;

            
            UIGraphicsBeginImageContextWithOptions(mapView.frame.size, YES, 0.0f);
            [mapView.layer renderInContext:UIGraphicsGetCurrentContext()];
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            
            NSData *data;
            if ([format isEqualToString:@"png"]) {
                data = UIImagePNGRepresentation(image);
                
            }
            else if([format isEqualToString:@"jpg"]) {
                data = UIImageJPEGRepresentation(image, quality.floatValue);
            }
            
            if ([result isEqualToString:@"file"]) {
                [data writeToFile:filePath atomically:YES];
                callback(@[[NSNull null], filePath]);
            }
            else if ([result isEqualToString:@"base64"]) {
                callback(@[[NSNull null], [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn]]);
            }
        }
        UIGraphicsEndImageContext();
    }];
}

RCT_EXPORT_METHOD(pointForCoordinate:(nonnull NSNumber *)reactTag
                  coordinate:(NSDictionary *)coordinate
                  resolver: (RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    CLLocationCoordinate2D coord =
    CLLocationCoordinate2DMake(
                               [coordinate[@"latitude"] doubleValue],
                               [coordinate[@"longitude"] doubleValue]
                               );
    
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRMap, got: %@", view);
        } else {
            id<RNMapsAirModuleDelegate> mapView = (id<RNMapsAirModuleDelegate>) view;
            resolve([mapView getPointForCoordinates:coord]);
        }
    }];
}

RCT_EXPORT_METHOD(coordinateForPoint:(nonnull NSNumber *)reactTag
                  point:(NSDictionary *)point
                  resolver: (RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    CGPoint pt = CGPointMake(
                             [point[@"x"] doubleValue],
                             [point[@"y"] doubleValue]
                             );
    
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRMap, got: %@", view);
        } else {
            id<RNMapsAirModuleDelegate> mapView = (id<RNMapsAirModuleDelegate>) view;
            resolve([view getCoordinatesForPoint:pt]);
        }
    }];
}

RCT_EXPORT_METHOD(getMarkersFrames:(nonnull NSNumber *)reactTag
                  onlyVisible:(BOOL)onlyVisible
                  resolver: (RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRMap, got: %@", view);
        } else {
            AIRGoogleMap *mapView = (AIRGoogleMap *)view;
            resolve([mapView getMarkersFramesWithOnlyVisible:onlyVisible]);
        }
    }];
}

RCT_EXPORT_METHOD(getMapBoundaries:(nonnull NSNumber *)reactTag
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRGoogleMap, got: %@", view);
        } else {
            resolve([view getMapBoundaries]);
        }
    }];
}

RCT_EXPORT_METHOD(setMapBoundaries:(nonnull NSNumber *)reactTag
                  northEast:(CLLocationCoordinate2D)northEast
                  southWest:(CLLocationCoordinate2D)southWest)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRGoogleMap, got: %@", view);
        } else {
            AIRGoogleMap *mapView = (AIRGoogleMap *)view;
            
            GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:northEast coordinate:southWest];
            
            mapView.cameraTargetBounds = bounds;
        }
    }];
}

RCT_EXPORT_METHOD(setIndoorActiveLevelIndex:(nonnull NSNumber *)reactTag
                  levelIndex:(NSInteger) levelIndex)
{
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        id view = viewRegistry[reactTag];
        if (![view isKindOfClass:[AIRGoogleMap class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting AIRGoogleMap, got: %@", view);
        } else {
            AIRGoogleMap *mapView = (AIRGoogleMap *)view;
            if (!mapView.indoorDisplay) {
                return;
            }
            if ( levelIndex < [mapView.indoorDisplay.activeBuilding.levels count]) {
                mapView.indoorDisplay.activeLevel = mapView.indoorDisplay.activeBuilding.levels[levelIndex];
            }
        }
    }];
}

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (NSDictionary *)constantsToExport {
    return @{ @"legalNotice": [GMSServices openSourceLicenseInfo] };
}

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture {
    self.isGesture = gesture;
    AIRGoogleMap *googleMapView = (AIRGoogleMap *)mapView;
    [googleMapView willMove:gesture];
}

- (void)mapViewDidStartTileRendering:(GMSMapView *)mapView {
    AIRGoogleMap *googleMapView = (AIRGoogleMap *)mapView;
    [googleMapView didPrepareMap];
}

- (void)mapViewDidFinishTileRendering:(GMSMapView *)mapView {
    AIRGoogleMap *googleMapView = (AIRGoogleMap *)mapView;
    [googleMapView mapViewDidFinishTileRendering];
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker {
    AIRGoogleMap *googleMapView = (AIRGoogleMap *)mapView;
    return [googleMapView didTapMarker:marker];
}

- (void)mapView:(GMSMapView *)mapView didTapOverlay:(GMSPolygon *)polygon {
    AIRGoogleMap *googleMapView = (AIRGoogleMap *)mapView;
    [googleMapView didTapPolygon:polygon];
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate {
    AIRGoogleMap *googleMapView = (AIRGoogleMap *)mapView;
    [googleMapView didTapAtCoordinate:coordinate];
}

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
    AIRGoogleMap *googleMapView = (AIRGoogleMap *)mapView;
    [googleMapView didLongPressAtCoordinate:coordinate];
}

- (void)mapView:(GMSMapView *)mapView didChangeCameraPosition:(GMSCameraPosition *)position {
    AIRGoogleMap *googleMapView = (AIRGoogleMap *)mapView;
    [googleMapView didChangeCameraPosition:position isGesture:self.isGesture];
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position {
    AIRGoogleMap *googleMapView = (AIRGoogleMap *)mapView;
    [googleMapView idleAtCameraPosition:position isGesture:self.isGesture];
}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoWindow:(GMSMarker *)marker {
    if (![marker isKindOfClass:[AIRGMSMarker class]]) {
      return [self defaultInfoWindowForMarker:marker];
    }
    AIRGMSMarker *aMarker = (AIRGMSMarker *)marker;
    return [aMarker.fakeMarker markerInfoWindow];}

- (UIView *)mapView:(GMSMapView *)mapView markerInfoContents:(GMSMarker *)marker {
    if (![marker isKindOfClass:[AIRGMSMarker class]]) {
      return [self defaultInfoWindowForMarker:marker];
    }
    AIRGMSMarker *aMarker = (AIRGMSMarker *)marker;
    return [aMarker.fakeMarker markerInfoContents];
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker {
    if (![marker isKindOfClass:[AIRGMSMarker class]]) {
      return;
    }

    AIRGMSMarker *aMarker = (AIRGMSMarker *)marker;
    [aMarker.fakeMarker didTapInfoWindowOfMarker:aMarker];
}

- (void)mapView:(GMSMapView *)mapView didBeginDraggingMarker:(GMSMarker *)marker {
    if (![marker isKindOfClass:[AIRGMSMarker class]]) {
      return;
    }
    AIRGMSMarker *aMarker = (AIRGMSMarker *)marker;
    [aMarker.fakeMarker didBeginDraggingMarker:aMarker];
}

- (void)mapView:(GMSMapView *)mapView didEndDraggingMarker:(GMSMarker *)marker {
    if (![marker isKindOfClass:[AIRGMSMarker class]]) {
      return;
    }
    AIRGMSMarker *aMarker = (AIRGMSMarker *)marker;
    [aMarker.fakeMarker didEndDraggingMarker:aMarker];
}

- (void)mapView:(GMSMapView *)mapView didDragMarker:(GMSMarker *)marker {
    if (![marker isKindOfClass:[AIRGMSMarker class]]) {
      return;
    }

    AIRGMSMarker *aMarker = (AIRGMSMarker *)marker;
    [aMarker.fakeMarker didDragMarker:aMarker];
}

- (void)mapView:(GMSMapView *)mapView
didTapPOIWithPlaceID:(NSString *)placeID
           name:(NSString *)name
       location:(CLLocationCoordinate2D)location {
    AIRGoogleMap *googleMapView = (AIRGoogleMap *)mapView;
    [googleMapView didTapPOIWithPlaceID:placeID name:name location:location];
}

#pragma mark Gesture Recognizer Handlers

- (void)handleMapDrag:(UIPanGestureRecognizer*)recognizer {
    AIRGoogleMap *map = (AIRGoogleMap *)recognizer.view;
    if (!map.onPanDrag) return;
    
    CGPoint touchPoint = [recognizer locationInView:map];
    CLLocationCoordinate2D coord = [map.projection coordinateForPoint:touchPoint];
    map.onPanDrag(@{
        @"coordinate": @{
            @"latitude": @(coord.latitude),
            @"longitude": @(coord.longitude),
        },
        @"position": @{
            @"x": @(touchPoint.x),
            @"y": @(touchPoint.y),
        },
        @"numberOfTouches": @(recognizer.numberOfTouches),
    });
    
}

- (UIView *)defaultInfoWindowForMarker:(GMSMarker *)marker {
    NSString *title = marker.title ?: @"";
    NSString *snippet = marker.snippet ?: @"";
    if (title.length == 0 && snippet.length == 0) {
        return nil;
    }

    UIFont *titleFont = [UIFont boldSystemFontOfSize:16.0f];
    UIFont *snippetFont = [UIFont systemFontOfSize:14.0f];

    UILabel *titleLabel = nil;
    CGSize titleSize = CGSizeZero;
    if (title.length > 0) {
        titleLabel = [[UILabel alloc] init];
        titleLabel.text = title;
        titleLabel.font = titleFont;
        titleLabel.textColor = [UIColor blackColor];
        titleLabel.numberOfLines = 0;
        titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        titleSize = [titleLabel sizeThatFits:CGSizeMake(kAIRGenericInfoWindowMaxContentWidth, CGFLOAT_MAX)];
    }

    UILabel *snippetLabel = nil;
    CGSize snippetSize = CGSizeZero;
    if (snippet.length > 0) {
        snippetLabel = [[UILabel alloc] init];
        snippetLabel.numberOfLines = 0;
        snippetLabel.lineBreakMode = NSLineBreakByWordWrapping;
        NSAttributedString *formattedSnippet = [self attributedTextForHTMLString:snippet
                                                                            font:snippetFont
                                                                           color:[UIColor darkGrayColor]];
        if (formattedSnippet) {
            snippetLabel.attributedText = formattedSnippet;
        } else {
            snippetLabel.font = snippetFont;
            snippetLabel.textColor = [UIColor darkGrayColor];
            snippetLabel.text = [self normalizedStringForSnippet:snippet];
        }
        snippetSize = [snippetLabel sizeThatFits:CGSizeMake(kAIRGenericInfoWindowMaxContentWidth, CGFLOAT_MAX)];
    }

    CGFloat contentWidth = MAX(titleSize.width, snippetSize.width);
    if (contentWidth == 0) {
        contentWidth = kAIRGenericInfoWindowMinContentWidth;
    }
    contentWidth = MIN(kAIRGenericInfoWindowMaxContentWidth,
                       MAX(kAIRGenericInfoWindowMinContentWidth, contentWidth));

    if (titleLabel) {
        titleSize = [titleLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    }
    if (snippetLabel) {
        snippetSize = [snippetLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    }

    CGFloat currentY = kAIRGenericInfoWindowVerticalPadding;
    UIView *container = [[UIView alloc] initWithFrame:CGRectZero];

    if (titleLabel) {
        titleLabel.frame = CGRectMake(kAIRGenericInfoWindowHorizontalPadding,
                                      currentY,
                                      contentWidth,
                                      titleSize.height);
        currentY += titleSize.height;
        [container addSubview:titleLabel];
        if (snippetLabel) {
            currentY += kAIRGenericInfoWindowInterLabelSpacing;
        }
    }

    if (snippetLabel) {
        snippetLabel.frame = CGRectMake(kAIRGenericInfoWindowHorizontalPadding,
                                        currentY,
                                        contentWidth,
                                        snippetSize.height);
        currentY += snippetSize.height;
        [container addSubview:snippetLabel];
    }

    currentY += kAIRGenericInfoWindowVerticalPadding;
    CGFloat totalWidth = contentWidth + (kAIRGenericInfoWindowHorizontalPadding * 2.0f);
    container.frame = CGRectMake(0, 0, totalWidth, currentY);
    container.backgroundColor = [UIColor whiteColor];
    container.layer.cornerRadius = 12.0f;
    container.layer.borderWidth = 1.0f / UIScreen.mainScreen.scale;
    container.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.08f].CGColor;
    container.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.2f].CGColor;
    container.layer.shadowOpacity = 0.3f;
    container.layer.shadowRadius = 6.0f;
    container.layer.shadowOffset = CGSizeMake(0, 2.0f);

    return container;
}

- (NSAttributedString *)attributedTextForHTMLString:(NSString *)html
                                               font:(UIFont *)font
                                              color:(UIColor *)color {
    if (html.length == 0) {
        return nil;
    }
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: color
    };

    if (!data) {
        NSString *normalized = [self normalizedStringForSnippet:html];
        return [[NSAttributedString alloc] initWithString:normalized attributes:attributes];
    }

    NSDictionary *options = @{
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
    };
    NSError *error = nil;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithData:data
                                                                                         options:options
                                                                              documentAttributes:nil
                                                                                           error:&error];
    if (!attributedString) {
        NSString *normalized = [self normalizedStringForSnippet:html];
        return [[NSAttributedString alloc] initWithString:normalized attributes:attributes];
    }

    NSRange fullRange = NSMakeRange(0, attributedString.length);
    [attributedString addAttributes:attributes range:fullRange];
    return attributedString;
}

- (NSString *)normalizedStringForSnippet:(NSString *)snippet {
    if (snippet.length == 0) {
        return @"";
    }
    NSError *error = nil;
    NSRegularExpression *breakRegex = [NSRegularExpression regularExpressionWithPattern:@"<br\\s*/?>"
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:&error];
    NSString *result = snippet;
    if (breakRegex) {
        result = [breakRegex stringByReplacingMatchesInString:snippet
                                                      options:0
                                                        range:NSMakeRange(0, snippet.length)
                                                 withTemplate:@"\n"];
    }
    result = [result stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@" "];
    return result;
}

@end
#endif
