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
import {useThemeColors, SPACING, FONT_SIZES} from '../constants/theme';

/**
 * Items Screen
 * Browse all found items
 * iOS NATIVE DESIGN - Read-only list of tracked items
 */
const ItemsScreen = ({navigation, route}) => {
  const COLORS = useThemeColors();

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
      <View style={styles.emptyIcon}>
        <Icon name="inventory-2" size={48} color={COLORS.textTertiary} />
      </View>
      <Text style={styles.emptyStateText}>No items found</Text>
      <Text style={styles.emptyStateSubtext}>
        {selectedQuery
          ? 'No items have been found for this query yet'
          : 'Add a search query to start tracking new items'}
      </Text>
    </View>
  );

  const renderHeader = () => {
    if (!selectedQuery) return null;

    return (
      <View style={styles.filterBanner}>
        <View style={styles.filterContent}>
          <Icon name="filter-list" size={18} color={COLORS.primary} />
          <Text style={styles.filterText}>
            {selectedQuery.query_name || 'Filtered Query'}
          </Text>
        </View>
        <TouchableOpacity
          onPress={() => navigation.goBack()}
          hitSlop={{top: 10, bottom: 10, left: 10, right: 10}}>
          <Icon name="close" size={18} color={COLORS.textSecondary} />
        </TouchableOpacity>
      </View>
    );
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: COLORS.groupedBackground,
    },
    // Filter Banner (iOS Style)
    filterBanner: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      backgroundColor: COLORS.secondaryGroupedBackground,
      paddingHorizontal: SPACING.md,
      paddingVertical: SPACING.sm,
      marginHorizontal: SPACING.md,
      marginTop: SPACING.md,
      marginBottom: SPACING.xs,
      borderRadius: SPACING.sm,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    filterContent: {
      flexDirection: 'row',
      alignItems: 'center',
      flex: 1,
    },
    filterText: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.text,
      fontWeight: '500',
      marginLeft: SPACING.sm,
      flex: 1,
    },
    // List
    listContainer: {
      paddingTop: SPACING.xs,
      paddingBottom: SPACING.md,
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
      paddingBottom: SPACING.xxl,
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
      lineHeight: 20,
    },
  });

  return (
    <View style={styles.container}>
      {/* Items List (iOS Grouped List) */}
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

export default ItemsScreen;
