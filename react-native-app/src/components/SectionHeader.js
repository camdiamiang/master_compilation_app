import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { useTheme } from '../context/ThemeContext';

const SectionHeader = ({ title, subtitle, action }) => {
  const { colors } = useTheme();
  return <View style={styles.container}><View style={styles.copy}><Text style={[styles.title, { color: colors.text }]}>{title}</Text>{subtitle ? <Text style={[styles.subtitle, { color: colors.textSecondary }]}>{subtitle}</Text> : null}</View>{action ? <Text style={[styles.action, { color: colors.primary }]}>{action}</Text> : null}</View>;
};

const styles = StyleSheet.create({ container: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginTop: 27, marginBottom: 13 }, copy: { flex: 1 }, title: { fontSize: 18, fontWeight: '700', letterSpacing: -0.3 }, subtitle: { fontSize: 12, marginTop: 3 }, action: { fontSize: 12, fontWeight: '700' } });
export default SectionHeader;
