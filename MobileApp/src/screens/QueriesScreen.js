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
import Icon from 'react-native-vector-icons/MaterialIcons';
import {QueryCard} from '../components';
import DatabaseService from '../services/DatabaseService';
import VintedAPI from '../api/VintedAPI';
import {COLORS, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * Queries Screen
 * Manage search queries
 */
const QueriesScreen = ({navigation}) => {
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
      <Icon name="search-off" size={64} color={COLORS.textLight} />
      <Text style={styles.emptyStateText}>No search queries</Text>
      <Text style={styles.emptyStateSubtext}>
        Add a Vinted search URL to start monitoring
      </Text>
      <TouchableOpacity
        style={styles.emptyStateButton}
        onPress={() => setModalVisible(true)}>
        <Text style={styles.emptyStateButtonText}>Add Your First Query</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Search Queries</Text>
        {queries.length > 0 && (
          <TouchableOpacity onPress={handleDeleteAllQueries}>
            <Text style={styles.deleteAllText}>Delete All</Text>
          </TouchableOpacity>
        )}
      </View>

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

      {/* Add Button */}
      {queries.length > 0 && (
        <TouchableOpacity
          style={styles.fab}
          onPress={() => setModalVisible(true)}>
          <Icon name="add" size={28} color={COLORS.surface} />
        </TouchableOpacity>
      )}

      {/* Add Query Modal */}
      <Modal
        visible={modalVisible}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setModalVisible(false)}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.modalContainer}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Add Search Query</Text>
              <TouchableOpacity onPress={() => setModalVisible(false)}>
                <Icon name="close" size={24} color={COLORS.text} />
              </TouchableOpacity>
            </View>

            <Text style={styles.inputLabel}>Vinted Search URL *</Text>
            <TextInput
              style={styles.input}
              placeholder="https://www.vinted.com/catalog?..."
              placeholderTextColor={COLORS.textLight}
              value={newQueryUrl}
              onChangeText={setNewQueryUrl}
              autoCapitalize="none"
              autoCorrect={false}
              multiline
            />

            <Text style={styles.inputLabel}>Custom Name (Optional)</Text>
            <TextInput
              style={styles.input}
              placeholder="e.g., Nike Shoes"
              placeholderTextColor={COLORS.textLight}
              value={newQueryName}
              onChangeText={setNewQueryName}
            />

            <Text style={styles.helperText}>
              Paste the full URL from a Vinted search. The app will monitor
              this search and notify you of new items.
            </Text>

            <TouchableOpacity style={styles.addButton} onPress={handleAddQuery}>
              <Text style={styles.addButtonText}>Add Query</Text>
            </TouchableOpacity>
          </View>
        </KeyboardAvoidingView>
      </Modal>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.background,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
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
  deleteAllText: {
    fontSize: FONT_SIZES.md,
    color: COLORS.error,
    fontWeight: '600',
  },
  listContainer: {
    paddingVertical: SPACING.sm,
  },
  emptyContainer: {
    flex: 1,
  },
  emptyState: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: SPACING.xxl,
  },
  emptyStateText: {
    fontSize: FONT_SIZES.xl,
    fontWeight: '600',
    color: COLORS.textSecondary,
    marginTop: SPACING.lg,
  },
  emptyStateSubtext: {
    fontSize: FONT_SIZES.md,
    color: COLORS.textLight,
    marginTop: SPACING.sm,
    textAlign: 'center',
  },
  emptyStateButton: {
    backgroundColor: COLORS.primary,
    paddingHorizontal: SPACING.lg,
    paddingVertical: SPACING.md,
    borderRadius: BORDER_RADIUS.md,
    marginTop: SPACING.lg,
  },
  emptyStateButtonText: {
    color: COLORS.surface,
    fontSize: FONT_SIZES.md,
    fontWeight: '600',
  },
  fab: {
    position: 'absolute',
    right: SPACING.lg,
    bottom: SPACING.lg,
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: COLORS.primary,
    justifyContent: 'center',
    alignItems: 'center',
    elevation: 8,
    shadowColor: COLORS.shadow,
    shadowOffset: {width: 0, height: 4},
    shadowOpacity: 0.3,
    shadowRadius: 8,
  },
  modalContainer: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: COLORS.overlay,
  },
  modalContent: {
    backgroundColor: COLORS.surface,
    borderTopLeftRadius: BORDER_RADIUS.xl,
    borderTopRightRadius: BORDER_RADIUS.xl,
    padding: SPACING.lg,
    maxHeight: '80%',
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: SPACING.lg,
  },
  modalTitle: {
    fontSize: FONT_SIZES.xxl,
    fontWeight: '700',
    color: COLORS.text,
  },
  inputLabel: {
    fontSize: FONT_SIZES.md,
    fontWeight: '600',
    color: COLORS.text,
    marginBottom: SPACING.sm,
    marginTop: SPACING.md,
  },
  input: {
    backgroundColor: COLORS.background,
    borderRadius: BORDER_RADIUS.md,
    padding: SPACING.md,
    fontSize: FONT_SIZES.md,
    color: COLORS.text,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  helperText: {
    fontSize: FONT_SIZES.sm,
    color: COLORS.textSecondary,
    marginTop: SPACING.md,
    marginBottom: SPACING.lg,
  },
  addButton: {
    backgroundColor: COLORS.primary,
    borderRadius: BORDER_RADIUS.md,
    padding: SPACING.md,
    alignItems: 'center',
  },
  addButtonText: {
    color: COLORS.surface,
    fontSize: FONT_SIZES.lg,
    fontWeight: '600',
  },
});

export default QueriesScreen;
