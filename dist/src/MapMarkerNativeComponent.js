import { codegenNativeCommands } from 'react-native';
export const Commands = codegenNativeCommands({
    supportedCommands: [
        'showCallout',
        'hideCallout',
        'animateMarkerToCoordinate',
        'setCoordinates',
        'redraw',
    ],
});
