import React from 'react';
import {StyleSheet, View, Dimensions, ScrollView, Button} from 'react-native';
import MapView, {Marker} from 'react-native-maps';

const {width, height} = Dimensions.get('window');

const LATITUDE = 46.2276;
const LONGITUDE = 2.2137;
const LATITUDE_DELTA = 10;

const kmlFiles = [
  'https://pastebin.com/raw/5XcSeT0b',
  'https://pastebin.com/raw/jAzGpq1F',
  'https://www.google.com/maps/d/u/0/kml?forcekml=1&mid=1VCOOkE4fA1pQWs91UATGjbeOv-BsCNU'
];

export default class MapKml extends React.Component<any, any> {
  map: any;
  constructor(props: any) {
    super(props);

    this.state = {
      selectedKml: kmlFiles[0],
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
          kmlSrc={this.state.selectedKml}>
           <Marker
            coordinate={this.state.region}
            title="Test"
            description="Test"
          />
        </MapView>
        <View style={styles.simpleKmlSelectionSheet}>
          <ScrollView>
            {kmlFiles.map((kmlFile, index) => (
              <Button
                key={kmlFile} title={`file ${index} ${this.state.selectedKml === kmlFile ? '(selected)' : ''}`}
                onPress={() => this.setState({selectedKml: kmlFile})}
              />
            ))}
          </ScrollView>
        </View>
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
  simpleKmlSelectionSheet: {
    height: "20%",
  },
});
