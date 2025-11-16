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
      backgroundColor: COLORS.background,
    },
    header: {
      padding: SPACING.md,
      paddingTop: SPACING.lg,
      backgroundColor: COLORS.surface,
      borderBottomWidth: 1,
      borderBottomColor: COLORS.border,
    },
    headerTitle: {
      fontSize: FONT_SIZES.xxl,
      fontWeight: '700',
      color: COLORS.text,
    },
    section: {
      backgroundColor: COLORS.surface,
      marginTop: SPACING.md,
      padding: SPACING.md,
    },
    sectionHeader: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      marginBottom: SPACING.sm,
    },
    sectionTitle: {
      fontSize: FONT_SIZES.lg,
      fontWeight: '700',
      color: COLORS.text,
      marginBottom: SPACING.sm,
    },
    sectionDescription: {
      fontSize: FONT_SIZES.sm,
      color: COLORS.textSecondary,
      marginBottom: SPACING.md,
    },
    settingItem: {
      paddingVertical: SPACING.md,
      borderBottomWidth: 1,
      borderBottomColor: COLORS.border,
    },
    settingInfo: {
      flex: 1,
    },
    settingLabel: {
      fontSize: FONT_SIZES.md,
      fontWeight: '600',
      color: COLORS.text,
      marginBottom: SPACING.xs,
    },
    settingDescription: {
      fontSize: FONT_SIZES.sm,
      color: COLORS.textSecondary,
    },
    numberInput: {
      backgroundColor: COLORS.background,
      borderRadius: BORDER_RADIUS.md,
      padding: SPACING.md,
      fontSize: FONT_SIZES.md,
      color: COLORS.text,
      borderWidth: 1,
      borderColor: COLORS.border,
      marginTop: SPACING.sm,
      width: 100,
    },
    textInput: {
      backgroundColor: COLORS.background,
      borderRadius: BORDER_RADIUS.md,
      padding: SPACING.md,
      fontSize: FONT_SIZES.md,
      color: COLORS.text,
      borderWidth: 1,
      borderColor: COLORS.border,
      marginTop: SPACING.sm,
    },
    multilineInput: {
      minHeight: 100,
      textAlignVertical: 'top',
    },
    addCountryContainer: {
      flexDirection: 'row',
      marginBottom: SPACING.md,
    },
    countryInput: {
      flex: 1,
      backgroundColor: COLORS.background,
      borderRadius: BORDER_RADIUS.md,
      padding: SPACING.md,
      fontSize: FONT_SIZES.md,
      color: COLORS.text,
      borderWidth: 1,
      borderColor: COLORS.border,
      marginRight: SPACING.sm,
    },
    addCountryButton: {
      backgroundColor: COLORS.primary,
      borderRadius: BORDER_RADIUS.md,
      width: 48,
      justifyContent: 'center',
      alignItems: 'center',
    },
    countryList: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      marginTop: SPACING.sm,
    },
    countryTag: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: COLORS.primaryLight + '20',
      borderRadius: BORDER_RADIUS.md,
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.sm,
      marginRight: SPACING.sm,
      marginBottom: SPACING.sm,
    },
    countryTagText: {
      fontSize: FONT_SIZES.md,
      fontWeight: '600',
      color: COLORS.primary,
      marginRight: SPACING.sm,
    },
    removeCountryButton: {
      padding: SPACING.xs,
    },
    emptyText: {
      fontSize: FONT_SIZES.sm,
      color: COLORS.textLight,
      fontStyle: 'italic',
      marginTop: SPACING.sm,
    },
    clearText: {
      fontSize: FONT_SIZES.sm,
      color: COLORS.error,
      fontWeight: '600',
    },
    saveButton: {
      backgroundColor: COLORS.success,
      flexDirection: 'row',
      justifyContent: 'center',
      alignItems: 'center',
      padding: SPACING.md,
      margin: SPACING.md,
      borderRadius: BORDER_RADIUS.md,
    },
    saveButtonText: {
      color: COLORS.surface,
      fontSize: FONT_SIZES.lg,
      fontWeight: '600',
      marginLeft: SPACING.sm,
    },
    bottomSpacer: {
      height: SPACING.xxl,
    },
  });

  return (
    <ScrollView style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Settings</Text>
      </View>

      {/* Monitoring Settings */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Monitoring</Text>

        <View style={styles.settingItem}>
          <View style={styles.settingInfo}>
            <Text style={styles.settingLabel}>Refresh Delay (seconds)</Text>
            <Text style={styles.settingDescription}>
              How often to check for new items
            </Text>
          </View>
          <TextInput
            style={styles.numberInput}
            value={settings.refreshDelay.toString()}
            onChangeText={text =>
              setSettings({...settings, refreshDelay: parseInt(text) || 60})
            }
            keyboardType="number-pad"
          />
        </View>

        <View style={styles.settingItem}>
          <View style={styles.settingInfo}>
            <Text style={styles.settingLabel}>Items Per Query</Text>
            <Text style={styles.settingDescription}>
              Number of items to fetch per search
            </Text>
          </View>
          <TextInput
            style={styles.numberInput}
            value={settings.itemsPerQuery.toString()}
            onChangeText={text =>
              setSettings({...settings, itemsPerQuery: parseInt(text) || 20})
            }
            keyboardType="number-pad"
          />
        </View>
      </View>

      {/* Notifications */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Notifications</Text>

        <View style={styles.settingItem}>
          <View style={styles.settingInfo}>
            <Text style={styles.settingLabel}>Enable Notifications</Text>
            <Text style={styles.settingDescription}>
              Receive push notifications for new items
            </Text>
          </View>
          <Switch
            value={settings.notificationsEnabled}
            onValueChange={value =>
              setSettings({...settings, notificationsEnabled: value})
            }
            trackColor={{false: COLORS.border, true: COLORS.primaryLight}}
            thumbColor={
              settings.notificationsEnabled ? COLORS.primary : COLORS.textLight
            }
          />
        </View>

        <View style={styles.settingItem}>
          <Text style={styles.settingLabel}>Message Template</Text>
          <Text style={styles.settingDescription}>
            Use {'{'} title {'}'}, {'{'} price {'}'}, {'{'} brand {'}'}, {'{'} size {'}'}
          </Text>
          <TextInput
            style={[styles.textInput, styles.multilineInput]}
            value={settings.messageTemplate}
            onChangeText={text =>
              setSettings({...settings, messageTemplate: text})
            }
            multiline
            numberOfLines={4}
            placeholder="🆕 Title: {title}&#10;💶 Price: {price}&#10;🛍️ Brand: {brand}"
            placeholderTextColor={COLORS.textLight}
          />
        </View>
      </View>

      {/* Filters */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Filters</Text>

        <View style={styles.settingItem}>
          <Text style={styles.settingLabel}>Banned Words</Text>
          <Text style={styles.settingDescription}>
            Separate multiple words with ||| (will filter items containing these
            words)
          </Text>
          <TextInput
            style={styles.textInput}
            value={settings.banwords}
            onChangeText={text => setSettings({...settings, banwords: text})}
            placeholder="word1|||word2|||word3"
            placeholderTextColor={COLORS.textLight}
          />
        </View>
      </View>

      {/* Country Allowlist */}
      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Country Allowlist</Text>
          {allowlist.length > 0 && (
            <TouchableOpacity onPress={handleClearAllowlist}>
              <Text style={styles.clearText}>Clear All</Text>
            </TouchableOpacity>
          )}
        </View>
        <Text style={styles.sectionDescription}>
          Only show items from sellers in these countries (leave empty for all)
        </Text>

        <View style={styles.addCountryContainer}>
          <TextInput
            style={styles.countryInput}
            value={newCountry}
            onChangeText={setNewCountry}
            placeholder="e.g., US, FR, DE"
            placeholderTextColor={COLORS.textLight}
            autoCapitalize="characters"
            maxLength={2}
          />
          <TouchableOpacity
            style={styles.addCountryButton}
            onPress={handleAddCountry}>
            <Icon name="add" size={24} color={COLORS.surface} />
          </TouchableOpacity>
        </View>

        {allowlist.length > 0 ? (
          <View style={styles.countryList}>
            {allowlist.map(country => (
              <View key={country} style={styles.countryTag}>
                <Text style={styles.countryTagText}>{country}</Text>
                <TouchableOpacity
                  onPress={() => handleRemoveCountry(country)}
                  style={styles.removeCountryButton}>
                  <Icon name="close" size={16} color={COLORS.error} />
                </TouchableOpacity>
              </View>
            ))}
          </View>
        ) : (
          <Text style={styles.emptyText}>No countries in allowlist</Text>
        )}
      </View>

      {/* Save Button */}
      <TouchableOpacity style={styles.saveButton} onPress={handleSaveSettings}>
        <Icon name="save" size={24} color={COLORS.surface} />
        <Text style={styles.saveButtonText}>Save Settings</Text>
      </TouchableOpacity>

      <View style={styles.bottomSpacer} />
    </ScrollView>
  );
};

export default SettingsScreen;
