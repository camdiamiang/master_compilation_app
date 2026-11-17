import React from 'react';
import { View, Text, Switch, TextInput, ScrollView, StyleSheet } from 'react-native';
import { useTheme } from '../context/ThemeContext';
import SectionHeader from '../components/SectionHeader';

const SettingsScreen = () => {
  const { colors, isDarkMode, toggleTheme, setLightTheme, userName, setUserName, userCourse, setUserCourse } = useTheme();
  const reset = () => { setLightTheme(); setUserName('Alex Rivera'); setUserCourse('BS Information Technology'); };
  return (
    <ScrollView style={[styles.screen, { backgroundColor: colors.background }]} contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
      <Text style={[styles.intro, { color: colors.textSecondary }]}>Set up your space. Your changes show up right away across the app.</Text>
      <SectionHeader title="Appearance" subtitle="Choose a look that feels right." />
      <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <View style={styles.row}><View style={[styles.icon, { backgroundColor: colors.tab }]}><Text style={[styles.iconText, { color: colors.primary }]}>{isDarkMode ? '☾' : '☼'}</Text></View><View style={styles.copy}><Text style={[styles.label, { color: colors.text }]}>Dark appearance</Text><Text style={[styles.hint, { color: colors.textSecondary }]}>{isDarkMode ? 'Easy on the eyes, day or night.' : 'Bright, calm, and easy to read.'}</Text></View><Switch value={isDarkMode} onValueChange={toggleTheme} trackColor={{ false: colors.border, true: colors.primary }} thumbColor="#FFFFFF" accessibilityLabel="Toggle dark appearance" /></View>
      </View>
      <SectionHeader title="Your profile" subtitle="A name and a little context." />
      <View style={[styles.card, { backgroundColor: colors.card, borderColor: colors.border }]}>
        <Text style={[styles.inputLabel, { color: colors.textSecondary }]}>YOUR NAME</Text>
        <TextInput value={userName} onChangeText={setUserName} placeholder="Your name" placeholderTextColor={colors.textSecondary} autoCapitalize="words" maxLength={40} style={[styles.input, { color: colors.text, backgroundColor: colors.field, borderColor: colors.border }]} accessibilityLabel="Your name" />
        <Text style={[styles.inputLabel, { color: colors.textSecondary, marginTop: 19 }]}>COURSE OR PROGRAM</Text>
        <TextInput value={userCourse} onChangeText={setUserCourse} placeholder="Your course or program" placeholderTextColor={colors.textSecondary} maxLength={60} style={[styles.input, { color: colors.text, backgroundColor: colors.field, borderColor: colors.border }]} accessibilityLabel="Course or program" />
      </View>
      <View style={[styles.preview, { backgroundColor: colors.primarySoft }]}><Text style={[styles.previewLabel, { color: colors.primary }]}>YOUR DASHBOARD</Text><Text style={[styles.previewName, { color: colors.text }]}>{userName.trim() || 'Your name'}{userCourse.trim() ? `  ·  ${userCourse}` : ''}</Text><Text style={[styles.previewHint, { color: colors.textSecondary }]}>This profile appears on your home screen.</Text></View>
      <Text onPress={reset} accessibilityRole="button" style={[styles.reset, { color: colors.textSecondary }]}>Reset profile and appearance</Text>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  screen: { flex: 1 }, content: { padding: 20, paddingBottom: 42, maxWidth: 800, width: '100%', alignSelf: 'center' }, intro: { fontSize: 14, lineHeight: 21, marginTop: 4 }, card: { borderRadius: 20, borderWidth: 1, padding: 17 }, row: { flexDirection: 'row', alignItems: 'center' }, icon: { height: 42, width: 42, borderRadius: 14, alignItems: 'center', justifyContent: 'center' }, iconText: { fontSize: 21 }, copy: { flex: 1, marginLeft: 12, marginRight: 8 }, label: { fontSize: 14, fontWeight: '700' }, hint: { fontSize: 11, lineHeight: 16, marginTop: 4 }, inputLabel: { fontSize: 9, fontWeight: '800', letterSpacing: 1.1, marginBottom: 8 }, input: { borderWidth: 1, borderRadius: 13, paddingHorizontal: 13, paddingVertical: 12, fontSize: 14 }, preview: { borderRadius: 18, padding: 16, marginTop: 18 }, previewLabel: { fontSize: 9, fontWeight: '800', letterSpacing: 1 }, previewName: { fontSize: 14, fontWeight: '700', marginTop: 8 }, previewHint: { fontSize: 11, marginTop: 4 }, reset: { textAlign: 'center', paddingVertical: 20, fontSize: 12, fontWeight: '600' },
});
export default SettingsScreen;
