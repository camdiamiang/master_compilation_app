import React from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';
import { useTheme } from '../context/ThemeContext';

const STACK = [
  { mark: 'R', name: 'React Native', detail: 'One interface, across devices' },
  { mark: 'E', name: 'Expo', detail: 'A smooth way to build and run' },
  { mark: 'N', name: 'React Navigation', detail: 'A place for every screen' },
  { mark: 'C', name: 'React Context', detail: 'One shared source of truth' },
];

const AboutScreen = () => {
  const { colors, userName, userCourse } = useTheme();
  return (
    <ScrollView style={[styles.screen, { backgroundColor: colors.background }]} contentContainerStyle={styles.content}>
      <View style={[styles.hero, { backgroundColor: colors.hero }]}><Text style={styles.monogram}>F.</Text><Text style={styles.heroEyebrow}>A MOBILE LAB JOURNAL</Text><Text style={styles.heroTitle}>Made for the{ '\n' }work in progress.</Text><Text style={styles.heroCopy}>A home for the experiments, small wins, and next ideas in mobile development.</Text></View>
      <Text style={[styles.sectionTitle, { color: colors.text }]}>Thoughtfully put together</Text>
      <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>{STACK.map((item, index) => <View key={item.name} style={[styles.row, index < STACK.length - 1 && { borderBottomWidth: 1, borderBottomColor: colors.border }]}><View style={[styles.mark, { backgroundColor: colors.primarySoft }]}><Text style={[styles.markText, { color: colors.primary }]}>{item.mark}</Text></View><View style={styles.copy}><Text style={[styles.name, { color: colors.text }]}>{item.name}</Text><Text style={[styles.detail, { color: colors.textSecondary }]}>{item.detail}</Text></View></View>)}</View>
      <View style={[styles.profile, { backgroundColor: colors.primarySoft }]}><Text style={[styles.profileLabel, { color: colors.primary }]}>BUILT BY</Text><Text style={[styles.profileName, { color: colors.text }]}>{userName}</Text><Text style={[styles.course, { color: colors.textSecondary }]}>{userCourse}</Text></View>
      <Text style={[styles.footer, { color: colors.textSecondary }]}>FIELDNOTES  ·  ACTIVITY 05</Text>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  screen: { flex: 1 }, content: { padding: 20, paddingBottom: 40, maxWidth: 800, width: '100%', alignSelf: 'center' }, hero: { borderRadius: 25, padding: 23, minHeight: 255, justifyContent: 'flex-end', overflow: 'hidden' }, monogram: { position: 'absolute', top: 10, right: 18, color: 'rgba(255,255,255,0.07)', fontSize: 130, fontWeight: '900' }, heroEyebrow: { color: '#D9EF86', letterSpacing: 1.3, fontSize: 9, fontWeight: '800', marginBottom: 13 }, heroTitle: { color: '#F5F6EC', fontSize: 30, lineHeight: 34, fontWeight: '800', letterSpacing: -0.8 }, heroCopy: { color: 'rgba(245,246,236,0.76)', fontSize: 13, lineHeight: 19, marginTop: 9, maxWidth: 295 }, sectionTitle: { fontSize: 17, fontWeight: '700', marginTop: 28, marginBottom: 12 }, card: { borderRadius: 20, borderWidth: 1, paddingHorizontal: 15 }, row: { flexDirection: 'row', alignItems: 'center', minHeight: 69, gap: 12 }, mark: { width: 35, height: 35, borderRadius: 12, alignItems: 'center', justifyContent: 'center' }, markText: { fontSize: 13, fontWeight: '900' }, copy: { flex: 1 }, name: { fontSize: 13, fontWeight: '700' }, detail: { fontSize: 11, marginTop: 3 }, profile: { padding: 16, borderRadius: 18, marginTop: 16 }, profileLabel: { fontSize: 9, letterSpacing: 1, fontWeight: '800' }, profileName: { fontSize: 16, fontWeight: '700', marginTop: 7 }, course: { fontSize: 12, marginTop: 3 }, footer: { textAlign: 'center', letterSpacing: 1, fontSize: 9, fontWeight: '700', marginTop: 25 },
});
export default AboutScreen;
