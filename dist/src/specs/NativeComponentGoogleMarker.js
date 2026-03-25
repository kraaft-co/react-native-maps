import { codegenNativeComponent, codegenNativeCommands } from 'react-native';
export const Commands = codegenNativeCommands({
    supportedCommands: [
        'setCoordinates',
        'animateToCoordinates',
        'showCallout',
        'hideCallout',
        'redrawCallout',
        'redraw',
    ],
});
export default codegenNativeComponent('RNMapsGoogleMarker', {
    // iOS-only: on Android, markers use the shared `RNMapsMarker` component.
    excludedPlatforms: ['android'],
});
