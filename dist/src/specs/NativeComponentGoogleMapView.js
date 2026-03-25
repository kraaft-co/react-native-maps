import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
import GoogleMapView from './NativeComponentGoogleMapView';
export const Commands = codegenNativeCommands({
    supportedCommands: [
        'animateToRegion',
        'setCamera',
        'animateCamera',
        'fitToElements',
        'fitToSuppliedMarkers',
        'fitToCoordinates',
        'setIndoorActiveLevelIndex',
    ],
});
export default codegenNativeComponent('RNMapsGoogleMapView', {
    excludedPlatforms: ['android'],
});
