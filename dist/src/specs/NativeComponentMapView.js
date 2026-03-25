import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
import FabricMapView from './NativeComponentMapView';
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
export default codegenNativeComponent('RNMapsMapView', {});
