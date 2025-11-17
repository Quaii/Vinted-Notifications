import React, {useState, useEffect, useCallback} from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Alert,
  TextInput,
  Modal,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import MaterialIcons from '@react-native-vector-icons/material-icons';
import {QueryCard, PageHeader} from '../components';
import DatabaseService from '../services/DatabaseService';
import MonitoringService from '../services/MonitoringService';
import VintedAPI from '../api/VintedAPI';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * Queries Screen
 * Manage search queries
 * iOS NATIVE DESIGN - Auto-starts monitoring when first query is added
 */
const QueriesScreen = ({navigation}) => {
  const COLORS = useThemeColors();

  const [queries, setQueries] = useState([]);
  const [loading, setLoading] = useState(false);
  const [modalVisible, setModalVisible] = useState(false);
  const [newQueryUrl, setNewQueryUrl] = useState('');
  const [newQueryName, setNewQueryName] = useState('');

  const loadQueries = useCallback(async () => {
    try {
      setLoading(true);
      const allQueries = await DatabaseService.getQueries();
      setQueries(allQueries);
    } catch (error) {
      console.error('Failed to load queries:', error);
      Alert.alert('Error', 'Failed to load queries');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    loadQueries();

    const unsubscribe = navigation.addListener('focus', loadQueries);
    return unsubscribe;
  }, [navigation, loadQueries]);

  const handleAddQuery = async () => {
    if (!newQueryUrl.trim()) {
      Alert.alert('Error', 'Please enter a Vinted URL');
      return;
    }

    // Validate URL
    if (!VintedAPI.isValidVintedUrl(newQueryUrl)) {
      Alert.alert('Error', 'Please enter a valid Vinted search URL');
      return;
    }

    try {
      await DatabaseService.addQuery(
        newQueryUrl.trim(),
        newQueryName.trim() || null,
      );

      // AUTO-START MONITORING (like Python version)
      // If this is the first query, monitoring will start automatically
      await MonitoringService.ensureMonitoringStarted();

      Alert.alert('Success', 'Query added successfully');
      setModalVisible(false);
      setNewQueryUrl('');
      setNewQueryName('');
      loadQueries();
    } catch (error) {
      console.error('Failed to add query:', error);
      Alert.alert('Error', 'Failed to add query. It may already exist.');
    }
  };

  const handleDeleteQuery = async query => {
    try {
      await DatabaseService.deleteQuery(query.id);
      Alert.alert('Success', 'Query deleted');
      loadQueries();
    } catch (error) {
      console.error('Failed to delete query:', error);
      Alert.alert('Error', 'Failed to delete query');
    }
  };

  const handleDeleteAllQueries = () => {
    Alert.alert(
      'Delete All Queries',
      'Are you sure you want to delete all queries? This action cannot be undone.',
      [
        {text: 'Cancel', style: 'cancel'},
        {
          text: 'Delete All',
          style: 'destructive',
          onPress: async () => {
            try {
              await DatabaseService.deleteAllQueries();
              Alert.alert('Success', 'All queries deleted');
              loadQueries();
            } catch (error) {
              Alert.alert('Error', 'Failed to delete queries');
            }
          },
        },
      ],
    );
  };

  const handleQueryPress = query => {
    // Navigate directly to Items tab with queryId param
    navigation.navigate('Items', {queryId: query.id});
  };

  const renderQuery = ({item}) => (
    <QueryCard
      query={item}
      onPress={handleQueryPress}
      onDelete={handleDeleteQuery}
    />
  );

  const renderEmpty = () => (
    <View style={styles.emptyState}>
      <View style={styles.emptyIcon}>
        <MaterialIcons name="search-off" size={48} color={COLORS.textTertiary} />
      </View>
      <Text style={styles.emptyStateText}>No search queries</Text>
      <Text style={styles.emptyStateSubtext}>
        Add a Vinted search URL to start tracking new items
      </Text>
      <TouchableOpacity
        style={styles.emptyStateButton}
        onPress={() => setModalVisible(true)}>
        <Text style={styles.emptyStateButtonText}>Add Your First Query</Text>
      </TouchableOpacity>
    </View>
  );

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: COLORS.groupedBackground,
    },
    listContainer: {
      paddingTop: 30,
      paddingBottom: SPACING.xxl * 2, // Extra space for FAB
    },
    queriesGroup: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      marginHorizontal: SPACING.md,
      marginVertical: SPACING.xs,
      borderRadius: BORDER_RADIUS.lg,
      overflow: 'hidden',
    },
    // Empty State
    emptyContainer: {
      flex: 1,
    },
    emptyState: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      paddingHorizontal: SPACING.md,
      paddingBottom: SPACING.xxl * 2,
    },
    emptyIcon: {
      marginBottom: SPACING.md,
    },
    emptyStateText: {
      fontSize: FONT_SIZES.title3,
      fontWeight: '600',
      color: COLORS.textSecondary,
      marginBottom: SPACING.xs,
    },
    emptyStateSubtext: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.textTertiary,
      textAlign: 'center',
      marginBottom: SPACING.xl,
    },
    emptyStateButton: {
      backgroundColor: COLORS.primary,
      paddingHorizontal: SPACING.xl,
      paddingVertical: SPACING.md,
      borderRadius: BORDER_RADIUS.lg,
    },
    emptyStateButtonText: {
      color: '#FFFFFF',
      fontSize: FONT_SIZES.body,
      fontWeight: '600',
    },
    // FAB (iOS style)
    fab: {
      position: 'absolute',
      right: SPACING.md,
      bottom: SPACING.md + 100, // Above tab bar (100px height)
      width: 56,
      height: 56,
      borderRadius: 28,
      backgroundColor: COLORS.primary,
      justifyContent: 'center',
      alignItems: 'center',
      shadowColor: '#000',
      shadowOffset: {width: 0, height: 4},
      shadowOpacity: 0.3,
      shadowRadius: 8,
      elevation: 8,
    },
    // Modal (iOS Sheet style)
    modalContainer: {
      flex: 1,
      justifyContent: 'flex-end',
      backgroundColor: 'rgba(0, 0, 0, 0.2)',
    },
    modalContent: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderTopLeftRadius: BORDER_RADIUS.xl,
      borderTopRightRadius: BORDER_RADIUS.xl,
      paddingTop: SPACING.md,
      paddingBottom: SPACING.xxl,
      maxHeight: '90%',
    },
    modalHeader: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      paddingHorizontal: SPACING.md,
      paddingBottom: SPACING.md,
      borderBottomWidth: 0.5,
      borderBottomColor: COLORS.separator,
    },
    modalTitle: {
      fontSize: FONT_SIZES.headline,
      fontWeight: '600',
      color: COLORS.text,
    },
    modalBody: {
      padding: SPACING.md,
    },
    inputLabel: {
      fontSize: FONT_SIZES.footnote,
      fontWeight: '600',
      color: COLORS.textSecondary,
      marginBottom: SPACING.xs,
      marginTop: SPACING.md,
      textTransform: 'uppercase',
      letterSpacing: 0.5,
    },
    inputGroup: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.lg,
      borderWidth: 1,
      borderColor: COLORS.separator,
      overflow: 'hidden',
    },
    input: {
      backgroundColor: COLORS.cardBackground,
      padding: SPACING.md,
      fontSize: FONT_SIZES.body,
      color: COLORS.text,
      minHeight: 44,
    },
    helperText: {
      fontSize: FONT_SIZES.footnote,
      color: COLORS.textTertiary,
      marginTop: SPACING.sm,
      marginBottom: SPACING.md,
      lineHeight: 18,
    },
    addButton: {
      backgroundColor: COLORS.primary,
      borderRadius: BORDER_RADIUS.lg,
      paddingVertical: SPACING.md,
      alignItems: 'center',
      marginTop: SPACING.md,
    },
    addButtonText: {
      color: '#FFFFFF',
      fontSize: FONT_SIZES.headline,
      fontWeight: '600',
    },
  });

  return (
    <View style={styles.container}>
      <PageHeader title="Queries" />
      {/* Queries List */}
      <FlatList
        data={queries}
        renderItem={renderQuery}
        keyExtractor={item => item.id.toString()}
        contentContainerStyle={
          queries.length === 0 ? styles.emptyContainer : styles.listContainer
        }
        ListEmptyComponent={renderEmpty}
        refreshing={loading}
        onRefresh={loadQueries}
      />

      {/* FAB - Add Query Button */}
      <TouchableOpacity
        style={styles.fab}
        onPress={() => setModalVisible(true)}>
        <MaterialIcons name="add" size={28} color="#FFFFFF" />
      </TouchableOpacity>

      {/* Add Query Modal (iOS Sheet) */}
      <Modal
        visible={modalVisible}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setModalVisible(false)}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.modalContainer}>
          <TouchableOpacity
            style={{flex: 1}}
            activeOpacity={1}
            onPress={() => setModalVisible(false)}
          />
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Add Search Query</Text>
              <TouchableOpacity onPress={() => setModalVisible(false)}>
                <MaterialIcons name="close" size={24} color={COLORS.text} />
              </TouchableOpacity>
            </View>

            <View style={styles.modalBody}>
              <Text style={styles.inputLabel}>Vinted Search URL</Text>
              <View style={styles.inputGroup}>
                <TextInput
                  style={styles.input}
                  placeholder="https://www.vinted.com/catalog?..."
                  placeholderTextColor={COLORS.placeholder}
                  value={newQueryUrl}
                  onChangeText={setNewQueryUrl}
                  autoCapitalize="none"
                  autoCorrect={false}
                  keyboardType="url"
                  multiline
                />
              </View>

              <Text style={styles.inputLabel}>Custom Name (Optional)</Text>
              <View style={styles.inputGroup}>
                <TextInput
                  style={styles.input}
                  placeholder="e.g., Nike Shoes"
                  placeholderTextColor={COLORS.placeholder}
                  value={newQueryName}
                  onChangeText={setNewQueryName}
                  returnKeyType="done"
                />
              </View>

              <Text style={styles.helperText}>
                Paste the full URL from a Vinted search. The app will automatically monitor this search and notify you of new items.
              </Text>

              <TouchableOpacity style={styles.addButton} onPress={handleAddQuery}>
                <Text style={styles.addButtonText}>Add Query</Text>
              </TouchableOpacity>
            </View>
          </View>
        </KeyboardAvoidingView>
      </Modal>
    </View>
  );
};

export default QueriesScreen;
