import React from 'react';
import {StyleSheet, View, Dimensions} from 'react-native';
import MapView, {Marker} from 'react-native-maps';

const {width, height} = Dimensions.get('window');

const LATITUDE = 46.2276;
const LONGITUDE = 2.2137;
const LATITUDE_DELTA = 10;
// const KML_FILE = 'https://pastebin.com/raw/5XcSeT0b';
const KML_FILE = 'https://www.google.com/maps/d/u/0/kml?forcekml=1&mid=1VCOOkE4fA1pQWs91UATGjbeOv-BsCNU';
// const KML_FILE = 'https://pastebin.com/raw/jAzGpq1F';

export default class MapKml extends React.Component<any, any> {
  map: any;
  constructor(props: any) {
    super(props);

    this.state = {
      region: {
        latitude: LATITUDE,
        longitude: LONGITUDE,
        latitudeDelta: LATITUDE_DELTA,
        longitudeDelta: LATITUDE_DELTA,
      },
    };
  }

  render() {
    return (
      <View style={styles.container}>
        <MapView
          ref={ref => {
            this.map = ref;
          }}
          provider={this.props.provider}
          style={styles.map}
          initialRegion={this.state.region}
          kmlSrc={KML_FILE}>
           <Marker
            coordinate={this.state.region}
            title="Test"
            description="Test"
          />
        </MapView>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    justifyContent: 'flex-end',
    alignItems: 'center',
  },
  scrollview: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  map: {
    width,
    height,
  },
});
