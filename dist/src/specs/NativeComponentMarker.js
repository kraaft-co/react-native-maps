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
export default codegenNativeComponent('RNMapsMarker', {});
