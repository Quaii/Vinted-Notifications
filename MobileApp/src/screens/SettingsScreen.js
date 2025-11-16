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
import Icon from 'react-native-vector-icons/MaterialIcons';
import DatabaseService from '../services/DatabaseService';
import {APP_CONFIG} from '../constants/config';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * Settings Screen
 * Configure app settings
 * iOS NATIVE DESIGN - iOS Settings app style with grouped lists
 */
const SettingsScreen = () => {
  const COLORS = useThemeColors();
  const [settings, setSettings] = useState({
    refreshDelay: APP_CONFIG.DEFAULT_REFRESH_DELAY,
    itemsPerQuery: APP_CONFIG.DEFAULT_ITEMS_PER_QUERY,
    messageTemplate: '',
    banwords: '',
    notificationsEnabled: true,
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
      const messageTemplate = await DatabaseService.getParameter(
        'message_template',
        '',
      );
      const banwords = await DatabaseService.getParameter('banwords', '');
      const notificationsEnabled = await DatabaseService.getParameter(
        'notifications_enabled',
        '1',
      );
      const countries = await DatabaseService.getAllowlist();

      setSettings({
        refreshDelay: parseInt(refreshDelay),
        itemsPerQuery: parseInt(itemsPerQuery),
        messageTemplate,
        banwords,
        notificationsEnabled: notificationsEnabled === '1',
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
      await DatabaseService.setParameter(
        'message_template',
        settings.messageTemplate,
      );
      await DatabaseService.setParameter('banwords', settings.banwords);
      await DatabaseService.setParameter(
        'notifications_enabled',
        settings.notificationsEnabled ? '1' : '0',
      );

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
    // iOS Grouped List Sections
    section: {
      marginTop: SPACING.lg,
    },
    sectionHeader: {
      paddingHorizontal: SPACING.md,
      paddingTop: SPACING.sm,
      paddingBottom: SPACING.xs,
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
    },
    sectionHeaderText: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textTertiary,
      textTransform: 'uppercase',
      letterSpacing: 0.5,
    },
    sectionFooter: {
      paddingHorizontal: SPACING.md,
      paddingTop: SPACING.xs,
      paddingBottom: SPACING.sm,
    },
    sectionFooterText: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textTertiary,
      lineHeight: 16,
    },
    clearAllText: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.link,
      textTransform: 'uppercase',
      letterSpacing: 0.5,
    },
    // iOS List Group
    listGroup: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      marginHorizontal: SPACING.md,
      borderRadius: BORDER_RADIUS.lg,
      overflow: 'hidden',
    },
    // iOS List Row
    listRow: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.sm + 2,
      minHeight: 44,
      borderBottomWidth: 0.5,
      borderBottomColor: COLORS.separator,
    },
    listRowLast: {
      borderBottomWidth: 0,
    },
    listRowContent: {
      flex: 1,
    },
    listRowLabel: {
      fontSize: FONT_SIZES.body,
      color: COLORS.text,
      marginBottom: 2,
    },
    listRowDescription: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textTertiary,
      lineHeight: 16,
    },
    listRowValue: {
      marginLeft: SPACING.sm,
    },
    // iOS Text Input (inline)
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
    // Multiline Input Row
    multilineRow: {
      flexDirection: 'column',
      alignItems: 'stretch',
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.sm,
      borderBottomWidth: 0.5,
      borderBottomColor: COLORS.separator,
    },
    multilineInput: {
      backgroundColor: COLORS.cardBackground,
      borderRadius: BORDER_RADIUS.md,
      padding: SPACING.sm,
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.text,
      marginTop: SPACING.xs,
      minHeight: 88,
      textAlignVertical: 'top',
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    // Country Allowlist
    addCountryRow: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.sm,
      borderBottomWidth: 0.5,
      borderBottomColor: COLORS.separator,
    },
    countryInput: {
      flex: 1,
      backgroundColor: COLORS.cardBackground,
      borderRadius: BORDER_RADIUS.md,
      paddingHorizontal: SPACING.sm,
      paddingVertical: SPACING.xs,
      fontSize: FONT_SIZES.body,
      color: COLORS.text,
      marginRight: SPACING.sm,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    addButton: {
      backgroundColor: COLORS.primary,
      width: 32,
      height: 32,
      borderRadius: 16,
      justifyContent: 'center',
      alignItems: 'center',
    },
    countryTagsRow: {
      flexDirection: 'column',
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.sm,
    },
    countryTags: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      marginTop: -SPACING.xs,
    },
    countryTag: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: COLORS.buttonFill,
      borderRadius: BORDER_RADIUS.md,
      paddingHorizontal: SPACING.sm,
      paddingVertical: 6,
      marginRight: SPACING.xs,
      marginTop: SPACING.xs,
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
    },
    // Save Button (iOS Style)
    saveButtonContainer: {
      marginTop: SPACING.lg,
      marginHorizontal: SPACING.md,
      marginBottom: SPACING.xl,
    },
    saveButton: {
      backgroundColor: COLORS.primary,
      borderRadius: BORDER_RADIUS.lg,
      paddingVertical: SPACING.md,
      alignItems: 'center',
      flexDirection: 'row',
      justifyContent: 'center',
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
    <ScrollView style={styles.container}>
      {/* Monitoring Section */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionHeaderText}>MONITORING</Text>
        </View>
        <View style={styles.listGroup}>
          <View style={styles.listRow}>
            <View style={styles.listRowContent}>
              <Text style={styles.listRowLabel}>Check Interval</Text>
              <Text style={styles.listRowDescription}>
                How often to check for new items
              </Text>
            </View>
            <TextInput
              style={[styles.inlineInput, styles.listRowValue]}
              value={settings.refreshDelay.toString()}
              onChangeText={text =>
                setSettings({...settings, refreshDelay: parseInt(text) || 60})
              }
              keyboardType="number-pad"
              returnKeyType="done"
            />
            <Text style={styles.listRowDescription}> sec</Text>
          </View>

          <View style={[styles.listRow, styles.listRowLast]}>
            <View style={styles.listRowContent}>
              <Text style={styles.listRowLabel}>Items Per Query</Text>
              <Text style={styles.listRowDescription}>
                Number of items to fetch per search
              </Text>
            </View>
            <TextInput
              style={[styles.inlineInput, styles.listRowValue]}
              value={settings.itemsPerQuery.toString()}
              onChangeText={text =>
                setSettings({...settings, itemsPerQuery: parseInt(text) || 20})
              }
              keyboardType="number-pad"
              returnKeyType="done"
            />
          </View>
        </View>
      </View>

      {/* Notifications Section */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionHeaderText}>NOTIFICATIONS</Text>
        </View>
        <View style={styles.listGroup}>
          <View style={styles.listRow}>
            <View style={styles.listRowContent}>
              <Text style={styles.listRowLabel}>Enable Notifications</Text>
              <Text style={styles.listRowDescription}>
                Receive push notifications for new items
              </Text>
            </View>
            <Switch
              value={settings.notificationsEnabled}
              onValueChange={value =>
                setSettings({...settings, notificationsEnabled: value})
              }
            />
          </View>

          <View style={[styles.multilineRow, styles.listRowLast]}>
            <Text style={styles.listRowLabel}>Message Template</Text>
            <Text style={styles.listRowDescription}>
              Use {'{title}'}, {'{price}'}, {'{brand}'}, {'{size}'}
            </Text>
            <TextInput
              style={styles.multilineInput}
              value={settings.messageTemplate}
              onChangeText={text =>
                setSettings({...settings, messageTemplate: text})
              }
              multiline
              numberOfLines={3}
              placeholder="🆕 Title: {title}&#10;💶 Price: {price}&#10;🛍️ Brand: {brand}"
              placeholderTextColor={COLORS.placeholder}
            />
          </View>
        </View>
      </View>

      {/* Filters Section */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionHeaderText}>FILTERS</Text>
        </View>
        <View style={styles.listGroup}>
          <View style={[styles.multilineRow, styles.listRowLast]}>
            <Text style={styles.listRowLabel}>Banned Words</Text>
            <Text style={styles.listRowDescription}>
              Separate multiple words with ||| (filters out matching items)
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

      {/* Country Allowlist Section */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionHeaderText}>COUNTRY ALLOWLIST</Text>
          {allowlist.length > 0 && (
            <TouchableOpacity onPress={handleClearAllowlist}>
              <Text style={styles.clearAllText}>Clear All</Text>
            </TouchableOpacity>
          )}
        </View>
        <View style={styles.listGroup}>
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
            <View style={[styles.countryTagsRow, styles.listRowLast]}>
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
            </View>
          ) : (
            <View style={[styles.listRow, styles.listRowLast]}>
              <Text style={styles.emptyText}>No countries in allowlist</Text>
            </View>
          )}
        </View>
        <View style={styles.sectionFooter}>
          <Text style={styles.sectionFooterText}>
            Only show items from sellers in these countries (leave empty to allow all countries)
          </Text>
        </View>
      </View>

      {/* Save Button */}
      <View style={styles.saveButtonContainer}>
        <TouchableOpacity style={styles.saveButton} onPress={handleSaveSettings}>
          <Icon name="save" size={20} color="#FFFFFF" />
          <Text style={styles.saveButtonText}>Save Settings</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.bottomSpacer} />
    </ScrollView>
  );
};

export default SettingsScreen;
