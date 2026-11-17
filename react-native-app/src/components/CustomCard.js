import React from 'react';
import { Pressable, View, Text, StyleSheet } from 'react-native';
import { useTheme } from '../context/ThemeContext';

const CustomCard = ({ title, subtitle, icon, onPress, style, number, status = 'Available' }) => {
  const { colors } = useTheme();
  return (
    <Pressable onPress={onPress} accessibilityRole="button" accessibilityLabel={`${title}, ${subtitle}`} style={({ pressed }) => [styles.card, { backgroundColor: colors.card, borderColor: colors.border, opacity: pressed ? 0.82 : 1 }, style]}>
      <View style={[styles.icon, { backgroundColor: colors.primarySoft }]}><Text style={styles.iconText}>{icon}</Text></View>
      <View style={styles.copy}>
        <View style={styles.meta}><Text style={[styles.number, { color: colors.primary }]}>{number}</Text><Text style={[styles.status, { color: colors.textSecondary }]}>{status}</Text></View>
        <Text style={[styles.title, { color: colors.text }]} numberOfLines={1}>{title}</Text>
        <Text style={[styles.subtitle, { color: colors.textSecondary }]} numberOfLines={2}>{subtitle}</Text>
      </View>
      <Text style={[styles.arrow, { color: colors.textSecondary }]}>↗</Text>
    </Pressable>
  );
};

const styles = StyleSheet.create({
  card: { flexDirection: 'row', alignItems: 'center', borderRadius: 20, borderWidth: 1, padding: 16, minHeight: 124 },
  icon: { width: 48, height: 48, borderRadius: 16, alignItems: 'center', justifyContent: 'center', marginRight: 14 },
  iconText: { fontSize: 23 }, copy: { flex: 1, minWidth: 0 },
  meta: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8, gap: 5 },
  number: { fontSize: 10, fontWeight: '800', letterSpacing: 1 },
  status: { fontSize: 10, fontWeight: '600' }, title: { fontSize: 15, fontWeight: '700' },
  subtitle: { fontSize: 12, lineHeight: 17, marginTop: 4 }, arrow: { fontSize: 17, marginLeft: 8, alignSelf: 'flex-start' },
});
export default CustomCard;
