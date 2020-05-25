import * as React from 'react';
import { View, StyleSheet } from 'react-native';
import {
  ScreenStack,
  Screen as ScreenComponent,
  ScreenProps,
} from 'react-native-cool-modals';
import {
  StackNavigationState,
  StackActions,
  useTheme,
} from '@react-navigation/native';
import HeaderConfig from './HeaderConfig';
import {
  NativeStackNavigationHelpers,
  NativeStackDescriptorMap,
} from '../types';

const Screen = (ScreenComponent as unknown) as React.ComponentType<ScreenProps>;

type Props = {
  state: StackNavigationState;
  navigation: NativeStackNavigationHelpers;
  descriptors: NativeStackDescriptorMap;
};

export default function NativeStackView({
                                          state,
                                          navigation,
                                          descriptors,
                                        }: Props) {
  const { colors } = useTheme();

  return (
      <ScreenStack style={styles.container}>
        {state.routes.map(route => {
          const { options, render: renderScene } = descriptors[route.key];
          const {
            gestureEnabled,
            stackPresentation = 'push',
            stackAnimation,
            contentStyle,
          } = options;

          const {
            customStack,
            topOffset,
            showDragIndicator,
            allowsDragToDismiss,
            allowsTapToDismiss,
            anchorModaltoLongForm,
            onWillDismiss,
            backgroundOpacity,
            cornerRadius,
            headerHeight,
            isShortFormEnabled,
            shortFormHeight,
            springDamping,
            startFromShortForm,
            transitionDuration,
          } = options;

          return (
              <Screen
                  customStack={customStack}
                  topOffset={topOffset}
                  showDragIndicator={showDragIndicator}
                  allowsDragToDismiss={allowsDragToDismiss}
                  allowsTapToDismiss={allowsTapToDismiss}
                  anchorModaltoLongForm={anchorModaltoLongForm}
                  onWillDismiss={onWillDismiss}
                  modalBackgroundOpacity={backgroundOpacity}
                  cornerRadius={cornerRadius}
                  headerHeight={headerHeight}
                  isShortFormEnabled={isShortFormEnabled}
                  shortFormHeight={shortFormHeight}
                  springDamping={springDamping}
                  startFromShortForm={startFromShortForm}
                  transitionDuration={transitionDuration}
                  key={route.key}
                  style={StyleSheet.absoluteFill}
                  gestureEnabled={gestureEnabled}
                  stackPresentation={stackPresentation}
                  stackAnimation={stackAnimation}
                  onAppear={() => {
                    options?.onAppear?.()
                    navigation.emit({
                      type: 'appear',
                      target: route.key,
                    });
                  }}
                  onDismissed={() => {
                    options?.onDismissed?.()
                    navigation.emit({
                      type: 'dismiss',
                      target: route.key,
                    });

                    navigation.dispatch({
                      ...StackActions.pop(),
                      source: route.key,
                      target: state.key,
                    });
                  }}
                  onFinishTransitioning={() => {
                    navigation.emit({
                      type: 'finishTransitioning',
                      target: route.key,
                    });
                  }}>
                <View
                    style={[
                      styles.container,
                      {
                        backgroundColor:
                            stackPresentation !== 'transparentModal'
                                ? colors.background
                                : undefined,
                      },
                      contentStyle,
                    ]}>
                  {renderScene()}
                </View>
              </Screen>
          );
        })}
      </ScreenStack>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});
