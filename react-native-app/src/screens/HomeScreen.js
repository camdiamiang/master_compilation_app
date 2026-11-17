import React, { useEffect, useState } from 'react';
import { View, Text, ScrollView, StyleSheet, TextInput, Pressable, useWindowDimensions } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useRouter } from 'expo-router';
import { useTheme } from '../context/ThemeContext';
import CustomCard from '../components/CustomCard';
import SectionHeader from '../components/SectionHeader';

const LAB_ACTIVITIES = [
  { id: 1, icon: '◈', title: 'Getting started', subtitle: 'Your first steps with React Native', status: 'Complete', category: 'Complete' },
  { id: 2, icon: '▦', title: 'Components & props', subtitle: 'Build reusable pieces of an interface', status: 'Complete', category: 'Complete' },
  { id: 3, icon: '✳', title: 'Styling & layouts', subtitle: 'Shape screens with responsive Flexbox', status: 'Complete', category: 'Complete' },
  { id: 4, icon: '⟳', title: 'State & interaction', subtitle: 'Make your app react to the user', status: 'Complete', category: 'Complete' },
  { id: 5, icon: '⌘', title: 'Master compilation', subtitle: 'Bring every lab together in one app', status: 'In progress', category: 'In progress' },
  { id: 6, icon: '✦', title: 'Final project', subtitle: 'The next chapter of your mobile journey', status: 'Up next', category: 'Up next' },
];
const FILTERS = ['All labs', 'In progress', 'Complete'];

const HomeScreen = () => {
  const router = useRouter();
  const { colors, isDarkMode, userName, userCourse } = useTheme();
  const { width } = useWindowDimensions();
  const [filter, setFilter] = useState('All labs');
  const [query, setQuery] = useState('');
  const [greeting, setGreeting] = useState('Welcome back');

  useEffect(() => {
    const hour = new Date().getHours();
    setGreeting(hour < 12 ? 'Good morning' : hour < 18 ? 'Good afternoon' : 'Good evening');
  }, []);

  const visibleLabs = LAB_ACTIVITIES.filter((lab) =>
    (filter === 'All labs' || lab.category === filter) &&
    `${lab.title} ${lab.subtitle}`.toLowerCase().includes(query.trim().toLowerCase()),
  );
  const columns = width >= 760 ? 2 : 1;

  return (
    <SafeAreaView style={[styles.safe, { backgroundColor: colors.background }]} edges={['top']}>
      <StatusBar style={isDarkMode ? 'light' : 'dark'} />
      <ScrollView contentContainerStyle={[styles.content, { maxWidth: 1000, alignSelf: 'center', width: '100%' }]} showsVerticalScrollIndicator={false} keyboardShouldPersistTaps="handled">
        <View style={styles.topbar}>
          <View style={styles.brand}><View style={[styles.brandMark, { backgroundColor: colors.primary }]}><Text style={styles.brandGlyph}>F</Text></View><Text style={[styles.brandName, { color: colors.text }]}>FIELDNOTES<Text style={[styles.brandDot, { color: colors.primary }]}>.</Text></Text></View>
          <Pressable onPress={() => router.push('/settings')} accessibilityRole="button" accessibilityLabel="Open settings" style={[styles.avatar, { backgroundColor: colors.primarySoft }]}><Text style={[styles.avatarText, { color: colors.primary }]}>{(userName.trim()[0] || 'S').toUpperCase()}</Text></Pressable>
        </View>

        <Text style={[styles.eyebrow, { color: colors.primary }]}>{userCourse.toUpperCase()}  /  LAB JOURNAL</Text>
        <Text style={[styles.greeting, { color: colors.text }]}>{greeting},{'\n'}{userName.trim().split(/\s+/)[0] || 'Student'}.</Text>
        <Text style={[styles.intro, { color: colors.textSecondary }]}>Your ideas, experiments, and progress — all in one place.</Text>

        <View style={[styles.feature, { backgroundColor: colors.hero }]}>
          <View style={styles.featureTop}><Text style={[styles.featureLabel, { color: colors.heroText }]}>YOUR LEARNING JOURNEY</Text><View style={styles.featureBadge}><Text style={styles.featureBadgeText}>2026</Text></View></View>
          <Text style={[styles.featureTitle, { color: colors.heroText }]}>One app. Every{ '\n' }experiment.</Text>
          <Text style={styles.featureDescription}>A growing collection of the work behind your next big idea.</Text>
          <View style={styles.progressTrack}><View style={[styles.progressFill, { width: '83%' }]} /></View>
          <View style={styles.featureBottom}><Text style={[styles.progressText, { color: colors.heroText }]}>5 OF 6 LABS</Text><Text style={[styles.progressText, { color: colors.heroText }]}>83% COMPLETE</Text></View>
          <View style={styles.featureDecoration}><Text style={styles.featureDecorationText}>05</Text></View>
        </View>

        <View style={styles.statsRow}>
          <View style={[styles.stat, { backgroundColor: colors.card, borderColor: colors.border }]}><Text style={[styles.statValue, { color: colors.text }]}>05</Text><Text style={[styles.statLabel, { color: colors.textSecondary }]}>LABS BUILT</Text></View>
          <View style={[styles.stat, { backgroundColor: colors.card, borderColor: colors.border }]}><Text style={[styles.statValue, { color: colors.text }]}>01</Text><Text style={[styles.statLabel, { color: colors.textSecondary }]}>IN PROGRESS</Text></View>
          <View style={[styles.stat, { backgroundColor: colors.card, borderColor: colors.border }]}><Text style={[styles.statValue, { color: colors.primary }]}>06</Text><Text style={[styles.statLabel, { color: colors.textSecondary }]}>TOTAL LABS</Text></View>
        </View>

        <SectionHeader title="The lab collection" subtitle="Every build, in one place." action="01 — 06" />
        <View style={[styles.search, { backgroundColor: colors.card, borderColor: colors.border }]}><Text style={[styles.searchIcon, { color: colors.textSecondary }]}>⌕</Text><TextInput value={query} onChangeText={setQuery} placeholder="Find an activity..." placeholderTextColor={colors.textSecondary} style={[styles.searchInput, { color: colors.text }]} returnKeyType="search" accessibilityLabel="Search laboratory activities" /></View>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.filters}>
          {FILTERS.map((option) => <Pressable key={option} onPress={() => setFilter(option)} accessibilityRole="button" accessibilityState={{ selected: filter === option }} style={[styles.filter, { backgroundColor: filter === option ? colors.primary : colors.tab }]}><Text style={[styles.filterText, { color: filter === option ? '#FFFFFF' : colors.textSecondary }]}>{option}</Text></Pressable>)}
        </ScrollView>
        <View style={styles.grid}>{visibleLabs.map((lab) => <CustomCard key={lab.id} icon={lab.icon} title={lab.title} subtitle={lab.subtitle} number={`LAB 0${lab.id}`} status={lab.status} style={{ width: columns === 2 ? '48.5%' : '100%' }} onPress={() => router.push({ pathname: '/activity/[id]', params: { id: String(lab.id), title: lab.title } })} />)}</View>
        {visibleLabs.length === 0 ? <Text style={[styles.empty, { color: colors.textSecondary }]}>No activities match that search. Try another title.</Text> : null}

        <SectionHeader title="Make it yours" subtitle="A little space that feels like you." />
        <Pressable onPress={() => router.push('/settings')} accessibilityRole="button" style={[styles.settingsCard, { backgroundColor: colors.primarySoft }]}><View style={styles.settingsIcon}><Text style={[styles.settingsGlyph, { color: colors.primary }]}>✳</Text></View><View style={styles.settingsCopy}><Text style={[styles.settingsTitle, { color: colors.text }]}>Profile & appearance</Text><Text style={[styles.settingsSubtitle, { color: colors.textSecondary }]}>Update your details and theme</Text></View><Text style={[styles.settingsArrow, { color: colors.primary }]}>→</Text></Pressable>
        <Pressable onPress={() => router.push('/about')} accessibilityRole="button" style={styles.footer}><Text style={[styles.footerText, { color: colors.textSecondary }]}>FIELDNOTES  ·  MADE FOR WHAT'S NEXT</Text><Text style={[styles.footerLink, { color: colors.primary }]}>About the project ↗</Text></Pressable>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  safe: { flex: 1 }, content: { paddingHorizontal: 22, paddingTop: 10, paddingBottom: 40 },
  topbar: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 31 }, brand: { flexDirection: 'row', alignItems: 'center', gap: 9 }, brandMark: { width: 31, height: 31, borderRadius: 10, alignItems: 'center', justifyContent: 'center' }, brandGlyph: { color: '#fff', fontWeight: '900', fontSize: 17 }, brandName: { fontSize: 12, fontWeight: '900', letterSpacing: 2.2 }, brandDot: { fontSize: 17 }, avatar: { width: 39, height: 39, borderRadius: 15, alignItems: 'center', justifyContent: 'center' }, avatarText: { fontSize: 15, fontWeight: '800' },
  eyebrow: { fontSize: 10, fontWeight: '800', letterSpacing: 1.6, marginBottom: 10 }, greeting: { fontSize: 38, lineHeight: 43, fontWeight: '800', letterSpacing: -1.8 }, intro: { fontSize: 14, lineHeight: 21, marginTop: 10, marginBottom: 24 },
  feature: { borderRadius: 25, padding: 22, overflow: 'hidden', marginBottom: 13 }, featureTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' }, featureLabel: { fontSize: 9, fontWeight: '800', letterSpacing: 1.4, opacity: 0.78 }, featureBadge: { backgroundColor: 'rgba(255,255,255,0.13)', borderRadius: 20, paddingHorizontal: 10, paddingVertical: 5 }, featureBadgeText: { color: '#F5F6EC', fontSize: 10, fontWeight: '700' }, featureTitle: { fontSize: 29, lineHeight: 33, fontWeight: '800', letterSpacing: -0.9, marginTop: 17 }, featureDescription: { color: 'rgba(245,246,236,0.74)', fontSize: 12, lineHeight: 18, maxWidth: 260, marginTop: 8 }, progressTrack: { height: 4, borderRadius: 4, backgroundColor: 'rgba(255,255,255,0.18)', marginTop: 22, overflow: 'hidden' }, progressFill: { height: '100%', borderRadius: 4, backgroundColor: '#D9EF86' }, featureBottom: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 9 }, progressText: { fontSize: 9, fontWeight: '700', letterSpacing: 0.8, opacity: 0.8 }, featureDecoration: { position: 'absolute', right: 20, bottom: 40, opacity: 0.06 }, featureDecorationText: { color: '#fff', fontSize: 115, lineHeight: 120, fontWeight: '900' },
  statsRow: { flexDirection: 'row', gap: 9 }, stat: { flex: 1, minWidth: 0, borderWidth: 1, borderRadius: 17, paddingVertical: 14, paddingHorizontal: 13 }, statValue: { fontSize: 23, fontWeight: '800', letterSpacing: -0.5 }, statLabel: { fontSize: 8, fontWeight: '800', letterSpacing: 0.65, marginTop: 5 },
  search: { minHeight: 47, borderRadius: 15, borderWidth: 1, flexDirection: 'row', alignItems: 'center', paddingHorizontal: 13 }, searchIcon: { fontSize: 23, marginRight: 8 }, searchInput: { flex: 1, fontSize: 13, paddingVertical: 10 }, filters: { gap: 8, paddingVertical: 12, paddingRight: 4 }, filter: { borderRadius: 20, paddingHorizontal: 15, paddingVertical: 9 }, filterText: { fontSize: 11, fontWeight: '700' }, grid: { flexDirection: 'row', flexWrap: 'wrap', justifyContent: 'space-between', rowGap: 10 }, empty: { textAlign: 'center', paddingVertical: 20, fontSize: 13 },
  settingsCard: { borderRadius: 19, padding: 15, flexDirection: 'row', alignItems: 'center' }, settingsIcon: { width: 40, height: 40, borderRadius: 13, backgroundColor: 'rgba(100,160,120,0.13)', alignItems: 'center', justifyContent: 'center' }, settingsGlyph: { fontSize: 19 }, settingsCopy: { flex: 1, marginLeft: 12 }, settingsTitle: { fontSize: 13, fontWeight: '700' }, settingsSubtitle: { fontSize: 11, marginTop: 3 }, settingsArrow: { fontSize: 19 }, footer: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginTop: 29, gap: 12 }, footerText: { fontSize: 8, letterSpacing: 0.9, fontWeight: '700' }, footerLink: { fontSize: 10, fontWeight: '700' },
});

export default HomeScreen;
