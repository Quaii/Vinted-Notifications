import React, {useState, useEffect, useCallback} from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Alert,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {ItemCard} from '../components';
import DatabaseService from '../services/DatabaseService';
import {COLORS, SPACING, FONT_SIZES} from '../constants/theme';

/**
 * Items Screen
 * Browse all found items
 */
const ItemsScreen = ({navigation, route}) => {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [selectedQuery, setSelectedQuery] = useState(null);
  const queryId = route.params?.queryId || null;

  const loadItems = useCallback(async () => {
    try {
      setLoading(true);
      const allItems = await DatabaseService.getItems(queryId, 100);
      setItems(allItems);

      // Load query name if filtering by query
      if (queryId) {
        const query = await DatabaseService.getQuery(queryId);
        setSelectedQuery(query);
      }
    } catch (error) {
      console.error('Failed to load items:', error);
      Alert.alert('Error', 'Failed to load items');
    } finally {
      setLoading(false);
    }
  }, [queryId]);

  useEffect(() => {
    loadItems();

    const unsubscribe = navigation.addListener('focus', loadItems);
    return unsubscribe;
  }, [navigation, loadItems]);

  const renderItem = ({item}) => <ItemCard item={item} />;

  const renderEmpty = () => (
    <View style={styles.emptyState}>
      <Icon name="inventory-2" size={64} color={COLORS.textLight} />
      <Text style={styles.emptyStateText}>No items found</Text>
      <Text style={styles.emptyStateSubtext}>
        {selectedQuery
          ? 'No items have been found for this query yet'
          : 'Start monitoring to find new items'}
      </Text>
    </View>
  );

  const renderHeader = () => {
    if (!selectedQuery) return null;

    return (
      <View style={styles.filterBanner}>
        <View style={styles.filterInfo}>
          <Icon name="filter-list" size={20} color={COLORS.primary} />
          <Text style={styles.filterText}>
            Filtered by: {selectedQuery.query_name}
          </Text>
        </View>
        <TouchableOpacity onPress={() => navigation.goBack()}>
          <Icon name="close" size={20} color={COLORS.textSecondary} />
        </TouchableOpacity>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Found Items</Text>
        <Text style={styles.headerSubtitle}>
          {items.length} item{items.length !== 1 ? 's' : ''}
        </Text>
      </View>

      {/* Items List */}
      <FlatList
        data={items}
        renderItem={renderItem}
        keyExtractor={item => item.id.toString()}
        contentContainerStyle={
          items.length === 0 ? styles.emptyContainer : styles.listContainer
        }
        ListHeaderComponent={renderHeader}
        ListEmptyComponent={renderEmpty}
        refreshing={loading}
        onRefresh={loadItems}
      />
    </View>
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
    marginBottom: SPACING.xs,
  },
  headerSubtitle: {
    fontSize: FONT_SIZES.md,
    color: COLORS.textSecondary,
  },
  filterBanner: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    backgroundColor: COLORS.primaryLight + '20',
    padding: SPACING.md,
    marginBottom: SPACING.sm,
  },
  filterInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  filterText: {
    fontSize: FONT_SIZES.md,
    color: COLORS.primary,
    fontWeight: '600',
    marginLeft: SPACING.sm,
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
});

export default ItemsScreen;
