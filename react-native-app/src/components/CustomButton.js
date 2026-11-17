import React from 'react';
import { TouchableOpacity, Text, StyleSheet } from 'react-native';
import { useTheme } from '../context/ThemeContext';

/**
 * CustomButton – a themed button with three visual variants.
 *
 * Props:
 *  - title    (string)            – button label
 *  - onPress  (function)          – tap handler
 *  - variant  ('primary' | 'secondary' | 'outline')
 *  - style    (object, optional)  – extra styles
 *  - disabled (boolean, optional) – disables interaction and dims the button
 */
const CustomButton = ({ title, onPress, variant = 'primary', style, disabled = false }) => {
  const { colors, isDarkMode } = useTheme();

  // Resolve background and text colors based on variant
  const resolveStyles = () => {
    switch (variant) {
      case 'secondary':
        return {
          bg: colors.primarySoft,
          textColor: colors.primary,
          borderColor: colors.primarySoft,
        };
      case 'outline':
        return {
          bg: 'transparent',
          textColor: colors.primary,
          borderColor: colors.primary,
        };
      case 'primary':
      default:
        return {
          bg: colors.primary,
          textColor: isDarkMode ? '#123F34' : '#FFFFFF',
          borderColor: colors.primary,
        };
    }
  };

  const { bg, textColor, borderColor } = resolveStyles();

  return (
    <TouchableOpacity
      onPress={onPress}
      disabled={disabled}
      activeOpacity={0.75}
      style={[
        styles.button,
        {
          backgroundColor: bg,
          borderColor,
          opacity: disabled ? 0.5 : 1,
        },
        style,
      ]}
    >
      <Text style={[styles.text, { color: textColor }]}>{title}</Text>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  button: {
    borderRadius: 12,
    borderWidth: 1.5,
    paddingVertical: 12,
    paddingHorizontal: 24,
    alignItems: 'center',
    justifyContent: 'center',
  },
  text: {
    fontSize: 15,
    fontWeight: '600',
  },
});

export default CustomButton;
