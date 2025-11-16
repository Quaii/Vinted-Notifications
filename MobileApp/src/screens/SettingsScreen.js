import React, {useState, useEffect, useCallback} from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  Switch,
  TouchableOpacity,
  Alert,
} from 'react-native';
import Icon from '@react-native-vector-icons/material-icons';
import {PageHeader} from '../components';
import {useTheme} from '../contexts/ThemeContext';
import DatabaseService from '../services/DatabaseService';
import {APP_CONFIG} from '../constants/config';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * SettingsScreen
 * Modern settings with App, Advanced, and System sections
 */
const SettingsScreen = () => {
  const COLORS = useThemeColors();
  const {isDarkMode, toggleTheme} = useTheme();

  const [settings, setSettings] = useState({
    // System settings
    refreshDelay: APP_CONFIG.DEFAULT_REFRESH_DELAY,
    itemsPerQuery: APP_CONFIG.DEFAULT_ITEMS_PER_QUERY,
    banwords: '',
    // Advanced settings
    userAgent: '',
    defaultHeaders: '',
    proxyList: '',
    proxyListLink: '',
    checkProxies: false,
  });

  const [allowlist, setAllowlist] = useState([]);
  const [newCountry, setNewCountry] = useState('');
  const [loading, setLoading] = useState(false);

  const loadSettings = useCallback(async () => {
    try {
      setLoading(true);

      const refreshDelay = await DatabaseService.getParameter(
        'query_refresh_delay',
        APP_CONFIG.DEFAULT_REFRESH_DELAY,
      );
      const itemsPerQuery = await DatabaseService.getParameter(
        'items_per_query',
        APP_CONFIG.DEFAULT_ITEMS_PER_QUERY,
      );
      const banwords = await DatabaseService.getParameter('banwords', '');
      const userAgent = await DatabaseService.getParameter('user_agent', '');
      const defaultHeaders = await DatabaseService.getParameter('default_headers', '');
      const proxyList = await DatabaseService.getParameter('proxy_list', '');
      const proxyListLink = await DatabaseService.getParameter('proxy_list_link', '');
      const checkProxies = await DatabaseService.getParameter('check_proxies', 'False') === 'True';
      const countries = await DatabaseService.getAllowlist();

      setSettings({
        refreshDelay: parseInt(refreshDelay),
        itemsPerQuery: parseInt(itemsPerQuery),
        banwords,
        userAgent,
        defaultHeaders,
        proxyList,
        proxyListLink,
        checkProxies,
      });
      setAllowlist(countries);
    } catch (error) {
      console.error('Failed to load settings:', error);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadSettings();
  }, [loadSettings]);

  const handleSaveSettings = async () => {
    try {
      await DatabaseService.setParameter(
        'query_refresh_delay',
        settings.refreshDelay.toString(),
      );
      await DatabaseService.setParameter(
        'items_per_query',
        settings.itemsPerQuery.toString(),
      );
      await DatabaseService.setParameter('banwords', settings.banwords);
      await DatabaseService.setParameter('user_agent', settings.userAgent);
      await DatabaseService.setParameter('default_headers', settings.defaultHeaders);
      await DatabaseService.setParameter('proxy_list', settings.proxyList);
      await DatabaseService.setParameter('proxy_list_link', settings.proxyListLink);
      await DatabaseService.setParameter('check_proxies', settings.checkProxies ? 'True' : 'False');

      Alert.alert('Success', 'Settings saved successfully');
    } catch (error) {
      console.error('Failed to save settings:', error);
      Alert.alert('Error', 'Failed to save settings');
    }
  };

  const handleAddCountry = async () => {
    const countryCode = newCountry.trim().toUpperCase();
    if (!countryCode) {
      Alert.alert('Error', 'Please enter a country code');
      return;
    }

    if (countryCode.length !== 2) {
      Alert.alert('Error', 'Please enter a valid 2-letter country code (e.g., US, FR, DE)');
      return;
    }

    try {
      await DatabaseService.addToAllowlist(countryCode);
      setNewCountry('');
      loadSettings();
      Alert.alert('Success', 'Country added to allowlist');
    } catch (error) {
      console.error('Failed to add country:', error);
      Alert.alert('Error', 'Failed to add country');
    }
  };

  const handleRemoveCountry = async countryCode => {
    try {
      await DatabaseService.removeFromAllowlist(countryCode);
      loadSettings();
      Alert.alert('Success', 'Country removed from allowlist');
    } catch (error) {
      console.error('Failed to remove country:', error);
      Alert.alert('Error', 'Failed to remove country');
    }
  };

  const handleClearAllowlist = () => {
    Alert.alert(
      'Clear Allowlist',
      'Are you sure you want to remove all countries from the allowlist?',
      [
        {text: 'Cancel', style: 'cancel'},
        {
          text: 'Clear',
          style: 'destructive',
          onPress: async () => {
            try {
              await DatabaseService.clearAllowlist();
              loadSettings();
              Alert.alert('Success', 'Allowlist cleared');
            } catch (error) {
              Alert.alert('Error', 'Failed to clear allowlist');
            }
          },
        },
      ],
    );
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: COLORS.groupedBackground,
    },
    content: {
      padding: SPACING.lg,
    },
    section: {
      marginBottom: SPACING.xl,
    },
    sectionHeader: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: SPACING.md,
    },
    sectionTitle: {
      fontSize: FONT_SIZES.title3,
      fontWeight: '600',
      color: COLORS.text,
    },
    sectionDescription: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textTertiary,
      marginBottom: SPACING.md,
      lineHeight: 18,
    },
    clearAllText: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.link,
      fontWeight: '600',
    },
    card: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.xl,
      padding: SPACING.lg,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    settingRow: {
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      paddingVertical: SPACING.sm,
      borderBottomWidth: 1,
      borderBottomColor: COLORS.separator,
    },
    settingRowLast: {
      borderBottomWidth: 0,
    },
    settingLeft: {
      flex: 1,
      marginRight: SPACING.md,
    },
    settingLabel: {
      fontSize: FONT_SIZES.body,
      fontWeight: '500',
      color: COLORS.text,
      marginBottom: 2,
    },
    settingDescription: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textTertiary,
      lineHeight: 16,
    },
    inlineInput: {
      backgroundColor: COLORS.cardBackground,
      borderRadius: BORDER_RADIUS.md,
      paddingHorizontal: SPACING.sm,
      paddingVertical: SPACING.xs,
      fontSize: FONT_SIZES.body,
      color: COLORS.text,
      textAlign: 'right',
      minWidth: 60,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    inputUnit: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textTertiary,
      marginLeft: SPACING.xs,
    },
    multilineRow: {
      flexDirection: 'column',
      alignItems: 'stretch',
      paddingVertical: SPACING.sm,
      borderBottomWidth: 1,
      borderBottomColor: COLORS.separator,
    },
    multilineInput: {
      backgroundColor: COLORS.cardBackground,
      borderRadius: BORDER_RADIUS.md,
      padding: SPACING.sm,
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.text,
      marginTop: SPACING.xs,
      minHeight: 80,
      textAlignVertical: 'top',
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    addCountryRow: {
      flexDirection: 'row',
      alignItems: 'center',
      marginBottom: SPACING.sm,
    },
    countryInput: {
      flex: 1,
      backgroundColor: COLORS.cardBackground,
      borderRadius: BORDER_RADIUS.md,
      paddingHorizontal: SPACING.sm,
      paddingVertical: SPACING.xs + 2,
      fontSize: FONT_SIZES.body,
      color: COLORS.text,
      marginRight: SPACING.sm,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    addButton: {
      backgroundColor: COLORS.primary,
      width: 36,
      height: 36,
      borderRadius: 18,
      justifyContent: 'center',
      alignItems: 'center',
    },
    countryTags: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      gap: SPACING.xs,
    },
    countryTag: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: COLORS.buttonFill,
      borderRadius: BORDER_RADIUS.md,
      paddingHorizontal: SPACING.sm,
      paddingVertical: 6,
    },
    countryTagText: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.text,
      fontWeight: '500',
      marginRight: 4,
    },
    emptyText: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textTertiary,
      fontStyle: 'italic',
      textAlign: 'center',
      paddingVertical: SPACING.md,
    },
    saveButton: {
      backgroundColor: COLORS.primary,
      borderRadius: BORDER_RADIUS.lg,
      paddingVertical: SPACING.md,
      alignItems: 'center',
      flexDirection: 'row',
      justifyContent: 'center',
      marginTop: SPACING.lg,
    },
    saveButtonText: {
      color: '#FFFFFF',
      fontSize: FONT_SIZES.headline,
      fontWeight: '600',
      marginLeft: SPACING.sm,
    },
    bottomSpacer: {
      height: SPACING.xxl,
    },
  });

  return (
    <View style={styles.container}>
      <PageHeader title="Settings" showSettings={false} showBack={true} />
      <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>

        {/* App Settings */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>App Settings</Text>
          </View>
          <Text style={styles.sectionDescription}>
            Customize the appearance and behavior of the app
          </Text>
          <View style={styles.card}>
            <View style={[styles.settingRow, styles.settingRowLast]}>
              <View style={styles.settingLeft}>
                <Text style={styles.settingLabel}>Dark Mode</Text>
                <Text style={styles.settingDescription}>
                  {isDarkMode ? 'Dark mode enabled' : 'Light mode enabled'}
                </Text>
              </View>
              <Switch
                value={isDarkMode}
                onValueChange={toggleTheme}
                trackColor={{false: COLORS.buttonFill, true: COLORS.primary}}
              />
            </View>
          </View>
        </View>

        {/* Advanced Settings */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Advanced Settings</Text>
          </View>
          <Text style={styles.sectionDescription}>
            Configure advanced options for power users (leave empty for defaults)
          </Text>
          <View style={styles.card}>
            <View style={styles.multilineRow}>
              <Text style={styles.settingLabel}>User Agent</Text>
              <Text style={styles.settingDescription}>
                Custom user agent for API requests
              </Text>
              <TextInput
                style={styles.multilineInput}
                value={settings.userAgent}
                onChangeText={text => setSettings({...settings, userAgent: text})}
                placeholder="Mozilla/5.0..."
                placeholderTextColor={COLORS.placeholder}
                multiline
              />
            </View>

            <View style={styles.multilineRow}>
              <Text style={styles.settingLabel}>Default Headers</Text>
              <Text style={styles.settingDescription}>
                Custom HTTP headers (JSON format)
              </Text>
              <TextInput
                style={styles.multilineInput}
                value={settings.defaultHeaders}
                onChangeText={text => setSettings({...settings, defaultHeaders: text})}
                placeholder='{"Accept": "application/json"}'
                placeholderTextColor={COLORS.placeholder}
                multiline
              />
            </View>

            <View style={styles.multilineRow}>
              <Text style={styles.settingLabel}>Proxy List</Text>
              <Text style={styles.settingDescription}>
                Semicolon-separated proxy list (e.g., http://proxy1:port;http://proxy2:port)
              </Text>
              <TextInput
                style={styles.multilineInput}
                value={settings.proxyList}
                onChangeText={text => setSettings({...settings, proxyList: text})}
                placeholder="http://proxy1:8080;http://proxy2:3128"
                placeholderTextColor={COLORS.placeholder}
                multiline
              />
            </View>

            <View style={styles.multilineRow}>
              <Text style={styles.settingLabel}>Proxy List URL</Text>
              <Text style={styles.settingDescription}>
                URL to fetch proxy list from (one proxy per line)
              </Text>
              <TextInput
                style={styles.multilineInput}
                value={settings.proxyListLink}
                onChangeText={text => setSettings({...settings, proxyListLink: text})}
                placeholder="https://example.com/proxies.txt"
                placeholderTextColor={COLORS.placeholder}
                multiline
              />
            </View>

            <View style={[styles.settingRow, styles.settingRowLast]}>
              <View style={styles.settingLeft}>
                <Text style={styles.settingLabel}>Check Proxies</Text>
                <Text style={styles.settingDescription}>
                  Verify proxies before use (slower but more reliable)
                </Text>
              </View>
              <Switch
                value={settings.checkProxies}
                onValueChange={value => setSettings({...settings, checkProxies: value})}
                trackColor={{false: COLORS.buttonFill, true: COLORS.primary}}
              />
            </View>
          </View>
        </View>

        {/* System Settings */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>System Settings</Text>
          </View>
          <Text style={styles.sectionDescription}>
            Configure monitoring behavior and filtering
          </Text>
          <View style={styles.card}>
            <View style={styles.settingRow}>
              <View style={styles.settingLeft}>
                <Text style={styles.settingLabel}>Items Per Query</Text>
                <Text style={styles.settingDescription}>
                  Number of items to fetch per search
                </Text>
              </View>
              <TextInput
                style={styles.inlineInput}
                value={settings.itemsPerQuery.toString()}
                onChangeText={text =>
                  setSettings({...settings, itemsPerQuery: parseInt(text) || 20})
                }
                keyboardType="number-pad"
                returnKeyType="done"
              />
            </View>

            <View style={styles.settingRow}>
              <View style={styles.settingLeft}>
                <Text style={styles.settingLabel}>Query Refresh Delay</Text>
                <Text style={styles.settingDescription}>
                  How often to check for new items
                </Text>
              </View>
              <TextInput
                style={styles.inlineInput}
                value={settings.refreshDelay.toString()}
                onChangeText={text =>
                  setSettings({...settings, refreshDelay: parseInt(text) || 60})
                }
                keyboardType="number-pad"
                returnKeyType="done"
              />
              <Text style={styles.inputUnit}>sec</Text>
            </View>

            <View style={[styles.multilineRow, styles.settingRowLast]}>
              <Text style={styles.settingLabel}>Banned Words</Text>
              <Text style={styles.settingDescription}>
                Filter out items containing these words (separate with |||)
              </Text>
              <TextInput
                style={styles.multilineInput}
                value={settings.banwords}
                onChangeText={text => setSettings({...settings, banwords: text})}
                placeholder="word1|||word2|||word3"
                placeholderTextColor={COLORS.placeholder}
                multiline
              />
            </View>
          </View>
        </View>

        {/* Country Allowlist */}
        <View style={styles.section}>
          <View style={styles.sectionHeader}>
            <Text style={styles.sectionTitle}>Country Allowlist</Text>
            {allowlist.length > 0 && (
              <TouchableOpacity onPress={handleClearAllowlist}>
                <Text style={styles.clearAllText}>Clear All</Text>
              </TouchableOpacity>
            )}
          </View>
          <Text style={styles.sectionDescription}>
            Only show items from sellers in these countries (leave empty to allow all)
          </Text>
          <View style={styles.card}>
            <View style={styles.addCountryRow}>
              <TextInput
                style={styles.countryInput}
                value={newCountry}
                onChangeText={setNewCountry}
                placeholder="e.g., US, FR, DE"
                placeholderTextColor={COLORS.placeholder}
                autoCapitalize="characters"
                maxLength={2}
                returnKeyType="done"
                onSubmitEditing={handleAddCountry}
              />
              <TouchableOpacity
                style={styles.addButton}
                onPress={handleAddCountry}>
                <Icon name="add" size={20} color="#FFFFFF" />
              </TouchableOpacity>
            </View>

            {allowlist.length > 0 ? (
              <View style={styles.countryTags}>
                {allowlist.map(country => (
                  <View key={country} style={styles.countryTag}>
                    <Text style={styles.countryTagText}>{country}</Text>
                    <TouchableOpacity
                      onPress={() => handleRemoveCountry(country)}
                      hitSlop={{top: 8, bottom: 8, left: 8, right: 8}}>
                      <Icon name="close" size={14} color={COLORS.textSecondary} />
                    </TouchableOpacity>
                  </View>
                ))}
              </View>
            ) : (
              <Text style={styles.emptyText}>No countries in allowlist</Text>
            )}
          </View>
        </View>

        {/* Save Button */}
        <TouchableOpacity style={styles.saveButton} onPress={handleSaveSettings}>
          <Icon name="save" size={20} color="#FFFFFF" />
          <Text style={styles.saveButtonText}>Save Settings</Text>
        </TouchableOpacity>

        <View style={styles.bottomSpacer} />
      </ScrollView>
    </View>
  );
};

export default SettingsScreen;
