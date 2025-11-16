import React, {useState, useEffect, useCallback} from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TextInput,
  TouchableOpacity,
  Alert,
} from 'react-native';
import Icon from '@react-native-vector-icons/material-icons';
import {PageHeader, ItemCard} from '../components';
import DatabaseService from '../services/DatabaseService';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

/**
 * ItemsScreen
 * Modern items list with search and filters
 */
const ItemsScreen = ({navigation, route}) => {
  const COLORS = useThemeColors();

  const [items, setItems] = useState([]);
  const [filteredItems, setFilteredItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState('date-desc'); // date-desc, date-asc, price-asc, price-desc, alpha-asc, alpha-desc
  const queryId = route.params?.queryId || null;

  const applyFilters = useCallback((itemList, search, sort) => {
    let filtered = [...itemList];

    // Apply search filter
    if (search) {
      const lowerSearch = search.toLowerCase();
      filtered = filtered.filter(item => {
        return (
          item.title?.toLowerCase().includes(lowerSearch) ||
          item.brand_title?.toLowerCase().includes(lowerSearch) ||
          item.size_title?.toLowerCase().includes(lowerSearch)
        );
      });
    }

    // Apply sort
    filtered.sort((a, b) => {
      switch (sort) {
        case 'date-asc':
          return a.created_at_ts - b.created_at_ts;
        case 'date-desc':
          return b.created_at_ts - a.created_at_ts;
        case 'price-asc':
          return parseFloat(a.price || 0) - parseFloat(b.price || 0);
        case 'price-desc':
          return parseFloat(b.price || 0) - parseFloat(a.price || 0);
        case 'alpha-asc':
          return (a.title || '').localeCompare(b.title || '');
        case 'alpha-desc':
          return (b.title || '').localeCompare(a.title || '');
        default:
          return b.created_at_ts - a.created_at_ts;
      }
    });

    setFilteredItems(filtered);
  }, []);

  const loadItems = useCallback(async () => {
    try {
      setLoading(true);
      const allItems = await DatabaseService.getItems(queryId, 1000);
      setItems(allItems);
      applyFilters(allItems, searchQuery, sortBy);
    } catch (error) {
      console.error('Failed to load items:', error);
      Alert.alert('Error', 'Failed to load items');
    } finally {
      setLoading(false);
    }
  }, [queryId, searchQuery, sortBy, applyFilters]);

  useEffect(() => {
    loadItems();

    const unsubscribe = navigation.addListener('focus', loadItems);
    return unsubscribe;
  }, [navigation, loadItems]);

  useEffect(() => {
    applyFilters(items, searchQuery, sortBy);
  }, [items, searchQuery, sortBy, applyFilters]);

  const renderSortButton = (label, value, icon) => {
    const isActive = sortBy === value;
    return (
      <TouchableOpacity
        style={[styles.sortButton, isActive && styles.sortButtonActive]}
        onPress={() => setSortBy(value)}>
        <Icon
          name={icon}
          size={16}
          color={isActive ? '#FFFFFF' : COLORS.textSecondary}
        />
        <Text
          style={[
            styles.sortButtonText,
            isActive && styles.sortButtonTextActive,
          ]}>
          {label}
        </Text>
      </TouchableOpacity>
    );
  };

  const renderItem = ({item, index}) => (
    <ItemCard item={item} isLast={index === filteredItems.length - 1} />
  );

  const renderEmpty = () => (
    <View style={styles.emptyState}>
      <Icon name="search-off" size={48} color={COLORS.textTertiary} />
      <Text style={styles.emptyText}>
        {searchQuery ? 'No items match your search' : 'No items found'}
      </Text>
      <Text style={styles.emptySubtext}>
        {searchQuery
          ? 'Try adjusting your search terms'
          : 'Add a search query to start tracking new items'}
      </Text>
    </View>
  );

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: COLORS.groupedBackground,
    },
    // Search Bar
    searchContainer: {
      paddingHorizontal: SPACING.lg,
      paddingBottom: SPACING.md,
    },
    searchBar: {
      flexDirection: 'row',
      alignItems: 'center',
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.lg,
      paddingHorizontal: SPACING.md,
      height: 44,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    searchIcon: {
      marginRight: SPACING.sm,
    },
    searchInput: {
      flex: 1,
      fontSize: FONT_SIZES.body,
      color: COLORS.text,
      padding: 0,
    },
    clearButton: {
      padding: SPACING.xs,
    },
    // Filters
    filtersContainer: {
      paddingHorizontal: SPACING.lg,
      paddingBottom: SPACING.md,
    },
    filtersLabel: {
      fontSize: FONT_SIZES.caption1,
      fontWeight: '600',
      color: COLORS.textSecondary,
      textTransform: 'uppercase',
      letterSpacing: 0.5,
      marginBottom: SPACING.xs,
    },
    filtersRow: {
      flexDirection: 'row',
      flexWrap: 'wrap',
      gap: SPACING.xs,
    },
    sortButton: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.sm,
      paddingVertical: SPACING.xs,
      borderRadius: BORDER_RADIUS.md,
      backgroundColor: COLORS.buttonFill,
      gap: 4,
    },
    sortButtonActive: {
      backgroundColor: COLORS.primary,
    },
    sortButtonText: {
      fontSize: FONT_SIZES.footnote,
      fontWeight: '600',
      color: COLORS.textSecondary,
    },
    sortButtonTextActive: {
      color: '#FFFFFF',
    },
    comingSoon: {
      fontSize: FONT_SIZES.caption2,
      color: COLORS.textTertiary,
      fontStyle: 'italic',
      marginTop: SPACING.xs,
    },
    // List
    listContent: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      marginHorizontal: SPACING.lg,
      borderRadius: BORDER_RADIUS.xl,
      overflow: 'hidden',
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    // Results Count
    resultsCount: {
      paddingHorizontal: SPACING.lg,
      paddingBottom: SPACING.sm,
    },
    resultsText: {
      fontSize: FONT_SIZES.caption1,
      color: COLORS.textTertiary,
    },
    // Empty State
    emptyState: {
      flex: 1,
      justifyContent: 'center',
      alignItems: 'center',
      paddingVertical: SPACING.xxl * 2,
      paddingHorizontal: SPACING.lg,
    },
    emptyText: {
      fontSize: FONT_SIZES.title3,
      fontWeight: '600',
      color: COLORS.textSecondary,
      marginTop: SPACING.md,
      marginBottom: SPACING.xs,
    },
    emptySubtext: {
      fontSize: FONT_SIZES.subheadline,
      color: COLORS.textTertiary,
      textAlign: 'center',
      lineHeight: 20,
    },
  });

  return (
    <View style={styles.container}>
      <PageHeader title="Items" />

      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <View style={styles.searchBar}>
          <Icon
            name="search"
            size={20}
            color={COLORS.textTertiary}
            style={styles.searchIcon}
          />
          <TextInput
            style={styles.searchInput}
            placeholder="Search items..."
            placeholderTextColor={COLORS.placeholder}
            value={searchQuery}
            onChangeText={setSearchQuery}
            returnKeyType="search"
          />
          {searchQuery !== '' && (
            <TouchableOpacity
              style={styles.clearButton}
              onPress={() => setSearchQuery('')}>
              <Icon name="close" size={20} color={COLORS.textSecondary} />
            </TouchableOpacity>
          )}
        </View>
      </View>

      {/* Filters */}
      <View style={styles.filtersContainer}>
        <Text style={styles.filtersLabel}>Sort By</Text>
        <View style={styles.filtersRow}>
          {renderSortButton('Newest', 'date-desc', 'arrow-downward')}
          {renderSortButton('Oldest', 'date-asc', 'arrow-upward')}
          {renderSortButton('Price ↓', 'price-desc', 'trending-down')}
          {renderSortButton('Price ↑', 'price-asc', 'trending-up')}
          {renderSortButton('A-Z', 'alpha-asc', 'sort-by-alpha')}
          {renderSortButton('Z-A', 'alpha-desc', 'sort-by-alpha')}
        </View>
        <Text style={styles.comingSoon}>Brand filter coming soon</Text>
      </View>

      {/* Results Count */}
      {filteredItems.length > 0 && (
        <View style={styles.resultsCount}>
          <Text style={styles.resultsText}>
            {filteredItems.length} {filteredItems.length === 1 ? 'item' : 'items'}
            {searchQuery && ` matching "${searchQuery}"`}
          </Text>
        </View>
      )}

      {/* Items List */}
      {filteredItems.length > 0 ? (
        <View style={styles.listContent}>
          <FlatList
            data={filteredItems}
            renderItem={renderItem}
            keyExtractor={item => item.id.toString()}
            refreshing={loading}
            onRefresh={loadItems}
            showsVerticalScrollIndicator={false}
          />
        </View>
      ) : (
        renderEmpty()
      )}
    </View>
  );
};

export default ItemsScreen;
