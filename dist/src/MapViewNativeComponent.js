import { codegenNativeCommands } from 'react-native';
export const Commands = codegenNativeCommands({
    supportedCommands: [
        'animateToRegion',
        'setCamera',
        'animateCamera',
        'fitToElements',
        'fitToSuppliedMarkers',
        'fitToCoordinates',
        'setMapBoundaries',
        'setIndoorActiveLevelIndex',
    ],
});
