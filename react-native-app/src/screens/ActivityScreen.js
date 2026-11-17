import React from 'react';
import { View, Text, ScrollView, StyleSheet } from 'react-native';
import { Stack, useLocalSearchParams, useRouter } from 'expo-router';
import { useTheme } from '../context/ThemeContext';
import CustomButton from '../components/CustomButton';
import SectionHeader from '../components/SectionHeader';

const CONTENT = {
  1: ['Set up the workspace', 'Meet the core components', 'Run the starter project'],
  2: ['Build with reusable components', 'Pass data through props', 'Compose a consistent interface'],
  3: ['Compose responsive Flexbox layouts', 'Use containers and spacing', 'Adapt screens to device sizes'],
  4: ['Manage local screen state', 'Respond to user input', 'Share values with Context'],
  5: ['Build a home dashboard and screen menu', 'Navigate through the lab collection', 'Personalize a shared theme and profile'],
  6: ['Plan your final experience', 'Bring your strongest ideas together', 'Share your finished build'],
};

const ActivityScreen = () => {
  const router = useRouter();
  const { colors } = useTheme();
  const { id, title } = useLocalSearchParams();
  const activityId = Number(Array.isArray(id) ? id[0] : id) || 5;
  const activityTitle = Array.isArray(title) ? title[0] : title || 'Lab activity';
  const steps = CONTENT[activityId] || CONTENT[5];
  return (
    <>
    <Stack.Screen options={{ title: activityTitle }} />
    <ScrollView style={[styles.screen, { backgroundColor: colors.background }]} contentContainerStyle={styles.content}>
      <View style={[styles.hero, { backgroundColor: colors.hero }]}>
        <Text style={styles.heroEyebrow}>FIELDNOTES  /  LAB 0{activityId}</Text>
        <Text style={styles.heroTitle}>{activityTitle}</Text>
        <Text style={styles.heroCopy}>A closer look at the ideas and skills behind this build.</Text>
        <View style={styles.pill}><Text style={styles.pillText}>{activityId === 5 ? 'IN PROGRESS' : activityId < 5 ? 'COMPLETE' : 'UP NEXT'}</Text></View>
      </View>
      <SectionHeader title="What you’ll explore" subtitle="The building blocks of this activity." />
      <View style={[styles.list, { backgroundColor: colors.card, borderColor: colors.border }]}>
        {steps.map((step, index) => <View key={step} style={[styles.step, index < steps.length - 1 && { borderBottomWidth: 1, borderBottomColor: colors.border }]}><View style={[styles.stepNumber, { backgroundColor: colors.primarySoft }]}><Text style={[styles.stepNumberText, { color: colors.primary }]}>0{index + 1}</Text></View><Text style={[styles.stepText, { color: colors.text }]}>{step}</Text><Text style={[styles.stepArrow, { color: colors.textSecondary }]}>↗</Text></View>)}
      </View>
      <View style={[styles.note, { backgroundColor: colors.primarySoft }]}><Text style={[styles.noteLabel, { color: colors.primary }]}>THE BIG IDEA</Text><Text style={[styles.noteCopy, { color: colors.text }]}>Good mobile experiences feel clear, considered, and at home on every screen.</Text></View>
      <CustomButton title="←  Back to the collection" variant="primary" onPress={() => router.back()} style={styles.button} />
    </ScrollView>
    </>
  );
};

const styles = StyleSheet.create({
  screen: { flex: 1 }, content: { padding: 20, paddingBottom: 36, maxWidth: 800, width: '100%', alignSelf: 'center' },
  hero: { borderRadius: 25, padding: 23, minHeight: 210, justifyContent: 'flex-end', overflow: 'hidden' }, heroEyebrow: { color: '#D9EF86', fontSize: 9, letterSpacing: 1.4, fontWeight: '800', marginBottom: 16 }, heroTitle: { color: '#F5F6EC', fontSize: 30, lineHeight: 34, fontWeight: '800', letterSpacing: -0.9 }, heroCopy: { color: 'rgba(245,246,236,0.74)', marginTop: 9, fontSize: 13, lineHeight: 19, maxWidth: 300 }, pill: { alignSelf: 'flex-start', marginTop: 16, paddingHorizontal: 10, paddingVertical: 6, borderRadius: 20, backgroundColor: 'rgba(255,255,255,0.13)' }, pillText: { color: '#F5F6EC', fontSize: 9, fontWeight: '800', letterSpacing: 0.9 },
  list: { borderRadius: 20, borderWidth: 1, paddingHorizontal: 15 }, step: { minHeight: 72, flexDirection: 'row', alignItems: 'center', gap: 12 }, stepNumber: { width: 35, height: 35, borderRadius: 12, alignItems: 'center', justifyContent: 'center' }, stepNumberText: { fontSize: 11, fontWeight: '800' }, stepText: { flex: 1, fontSize: 13, fontWeight: '600', lineHeight: 19 }, stepArrow: { fontSize: 15 }, note: { borderRadius: 18, padding: 17, marginTop: 17 }, noteLabel: { fontSize: 9, letterSpacing: 1.1, fontWeight: '800' }, noteCopy: { marginTop: 7, fontSize: 14, fontWeight: '600', lineHeight: 21 }, button: { marginTop: 21 },
});
export default ActivityScreen;
