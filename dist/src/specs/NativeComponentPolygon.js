import { codegenNativeComponent } from 'react-native';
export default codegenNativeComponent('RNMapsPolygon', {
    // iOS-only: on Android, polygons use the shared `RNMapsGooglePolygon` component.
    excludedPlatforms: ['android'],
});
