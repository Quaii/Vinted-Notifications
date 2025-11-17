import React, {useState, useEffect, useCallback} from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TextInput,
  TouchableOpacity,
  Alert,
  Modal,
  Dimensions,
  Image,
  Linking,
} from 'react-native';
import MaterialIcons from '@react-native-vector-icons/material-icons';
import {useFocusEffect} from '@react-navigation/native';
import {PageHeader, ItemCard} from '../components';
import DatabaseService from '../services/DatabaseService';
import {useThemeColors, SPACING, FONT_SIZES, BORDER_RADIUS} from '../constants/theme';

const {width} = Dimensions.get('window');
const CARD_WIDTH = (width - SPACING.lg * 3) / 2;

/**
 * ItemsScreen
 * Modern items list/grid with search and sort dropdown
 */
const ItemsScreen = ({navigation, route}) => {
  const COLORS = useThemeColors();

  const [items, setItems] = useState([]);
  const [filteredItems, setFilteredItems] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [sortBy, setSortBy] = useState('date-desc');
  const [viewMode, setViewMode] = useState('list'); // 'list' or 'grid'
  const [sortModalVisible, setSortModalVisible] = useState(false);
  const queryId = route.params?.queryId || null;

  const SORT_OPTIONS = [
    {label: 'Newest First', value: 'date-desc', icon: 'schedule'},
    {label: 'Oldest First', value: 'date-asc', icon: 'schedule'},
    {label: 'Price: Low to High', value: 'price-asc', icon: 'attach-money'},
    {label: 'Price: High to Low', value: 'price-desc', icon: 'attach-money'},
    {label: 'Name: A to Z', value: 'alpha-asc', icon: 'sort-by-alpha'},
    {label: 'Name: Z to A', value: 'alpha-desc', icon: 'sort-by-alpha'},
  ];

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

  // Reload items when screen is focused
  useFocusEffect(
    useCallback(() => {
      loadItems();
    }, [loadItems])
  );

  useEffect(() => {
    applyFilters(items, searchQuery, sortBy);
  }, [items, searchQuery, sortBy, applyFilters]);

  const handleSortSelect = (value) => {
    setSortBy(value);
    setSortModalVisible(false);
  };

  const renderGridItem = ({item}) => {
    const handlePress = () => {
      if (item.url) {
        Linking.openURL(item.url);
      }
    };

    return (
      <TouchableOpacity style={styles.gridCard} onPress={handlePress} activeOpacity={0.7}>
        <Image
          style={styles.gridImage}
          source={{uri: item.getPhotoUrl()}}
          resizeMode="cover"
        />
        <View style={styles.gridContent}>
          <Text style={styles.gridPrice}>{item.getFormattedPrice()}</Text>
          <Text style={styles.gridTitle} numberOfLines={2}>
            {item.title}
          </Text>
          {item.brand_title && (
            <Text style={styles.gridBrand} numberOfLines={1}>
              {item.brand_title}
            </Text>
          )}
        </View>
      </TouchableOpacity>
    );
  };

  const renderListItem = ({item, index}) => (
    <ItemCard item={item} isLast={index === filteredItems.length - 1} />
  );

  const renderEmpty = () => (
    <View style={styles.emptyState}>
      <MaterialIcons name="search-off" size={48} color={COLORS.textTertiary} />
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

  const currentSort = SORT_OPTIONS.find(opt => opt.value === sortBy);

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: COLORS.groupedBackground,
    },
    // Toolbar
    toolbar: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.lg,
      paddingBottom: SPACING.md,
      gap: SPACING.sm,
    },
    sortButton: {
      flex: 1,
      flexDirection: 'row',
      alignItems: 'center',
      justifyContent: 'space-between',
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.lg,
      paddingHorizontal: SPACING.md,
      height: 44,
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    sortButtonText: {
      fontSize: FONT_SIZES.body,
      fontWeight: '500',
      color: COLORS.text,
      flex: 1,
    },
    viewModeButtons: {
      flexDirection: 'row',
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: BORDER_RADIUS.lg,
      borderWidth: 1,
      borderColor: COLORS.separator,
      padding: 2,
    },
    viewModeButton: {
      padding: SPACING.xs,
      paddingHorizontal: SPACING.sm,
      borderRadius: BORDER_RADIUS.md,
    },
    viewModeButtonActive: {
      backgroundColor: COLORS.primary,
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
    // Results Count
    resultsCount: {
      paddingHorizontal: SPACING.lg,
      paddingBottom: SPACING.sm,
    },
    resultsText: {
      fontSize: FONT_SIZES.caption1,
      color: COLORS.textTertiary,
    },
    // List View
    listContent: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      marginHorizontal: SPACING.lg,
      borderRadius: BORDER_RADIUS.xl,
      overflow: 'hidden',
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    // Grid View
    gridContent: {
      paddingHorizontal: SPACING.lg,
    },
    gridCard: {
      width: CARD_WIDTH,
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderRadius: 20,
      marginBottom: SPACING.md,
      overflow: 'hidden',
      borderWidth: 1,
      borderColor: COLORS.separator,
    },
    gridImage: {
      width: '100%',
      height: CARD_WIDTH,
      backgroundColor: COLORS.buttonFill,
    },
    gridContent: {
      padding: SPACING.sm,
    },
    gridPrice: {
      fontSize: FONT_SIZES.headline,
      fontWeight: '700',
      color: COLORS.primary,
      marginBottom: 4,
    },
    gridTitle: {
      fontSize: FONT_SIZES.footnote,
      fontWeight: '500',
      color: COLORS.text,
      marginBottom: 2,
      lineHeight: 16,
    },
    gridBrand: {
      fontSize: FONT_SIZES.caption1,
      color: COLORS.textSecondary,
    },
    // Sort Modal
    modalContainer: {
      flex: 1,
      justifyContent: 'flex-end',
      backgroundColor: 'rgba(0, 0, 0, 0.3)',
    },
    modalContent: {
      backgroundColor: COLORS.secondaryGroupedBackground,
      borderTopLeftRadius: 20,
      borderTopRightRadius: 20,
      paddingTop: SPACING.md,
      paddingBottom: SPACING.xxl + 20,
    },
    modalHeader: {
      flexDirection: 'row',
      justifyContent: 'space-between',
      alignItems: 'center',
      paddingHorizontal: SPACING.lg,
      paddingBottom: SPACING.md,
      borderBottomWidth: 1,
      borderBottomColor: COLORS.separator,
    },
    modalTitle: {
      fontSize: FONT_SIZES.headline,
      fontWeight: '700',
      color: COLORS.text,
    },
    sortOption: {
      flexDirection: 'row',
      alignItems: 'center',
      paddingHorizontal: SPACING.lg,
      paddingVertical: SPACING.md,
      gap: SPACING.md,
    },
    sortOptionActive: {
      backgroundColor: COLORS.buttonFill,
    },
    sortOptionIcon: {
      width: 32,
      height: 32,
      borderRadius: 16,
      backgroundColor: COLORS.buttonFill,
      justifyContent: 'center',
      alignItems: 'center',
    },
    sortOptionIconActive: {
      backgroundColor: COLORS.primary,
    },
    sortOptionText: {
      flex: 1,
      fontSize: FONT_SIZES.body,
      fontWeight: '500',
      color: COLORS.text,
    },
    sortOptionTextActive: {
      color: COLORS.primary,
      fontWeight: '600',
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
          <MaterialIcons
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
              <MaterialIcons name="close" size={20} color={COLORS.textSecondary} />
            </TouchableOpacity>
          )}
        </View>
      </View>

      {/* Toolbar: Sort & View Mode */}
      <View style={styles.toolbar}>
        <TouchableOpacity
          style={styles.sortButton}
          onPress={() => setSortModalVisible(true)}>
          <Text style={styles.sortButtonText}>
            {currentSort?.label || 'Sort by'}
          </Text>
          <MaterialIcons name="unfold-more" size={20} color={COLORS.textSecondary} />
        </TouchableOpacity>

        <View style={styles.viewModeButtons}>
          <TouchableOpacity
            style={[styles.viewModeButton, viewMode === 'list' && styles.viewModeButtonActive]}
            onPress={() => setViewMode('list')}>
            <MaterialIcons
              name="view-list"
              size={20}
              color={viewMode === 'list' ? '#FFFFFF' : COLORS.textSecondary}
            />
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.viewModeButton, viewMode === 'grid' && styles.viewModeButtonActive]}
            onPress={() => setViewMode('grid')}>
            <MaterialIcons
              name="grid-view"
              size={20}
              color={viewMode === 'grid' ? '#FFFFFF' : COLORS.textSecondary}
            />
          </TouchableOpacity>
        </View>
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

      {/* Items List/Grid */}
      {filteredItems.length > 0 ? (
        viewMode === 'list' ? (
          <View style={styles.listContent}>
            <FlatList
              data={filteredItems}
              renderItem={renderListItem}
              keyExtractor={item => item.id.toString()}
              refreshing={loading}
              onRefresh={loadItems}
              showsVerticalScrollIndicator={false}
            />
          </View>
        ) : (
          <FlatList
            data={filteredItems}
            renderItem={renderGridItem}
            keyExtractor={item => item.id.toString()}
            numColumns={2}
            columnWrapperStyle={{justifyContent: 'space-between', paddingHorizontal: SPACING.lg}}
            contentContainerStyle={{paddingBottom: SPACING.xl}}
            refreshing={loading}
            onRefresh={loadItems}
            showsVerticalScrollIndicator={false}
          />
        )
      ) : (
        renderEmpty()
      )}

      {/* Sort Modal */}
      <Modal
        visible={sortModalVisible}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setSortModalVisible(false)}>
        <TouchableOpacity
          style={styles.modalContainer}
          activeOpacity={1}
          onPress={() => setSortModalVisible(false)}>
          <View style={styles.modalContent}>
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Sort By</Text>
              <TouchableOpacity onPress={() => setSortModalVisible(false)}>
                <MaterialIcons name="close" size={24} color={COLORS.text} />
              </TouchableOpacity>
            </View>

            {SORT_OPTIONS.map((option) => {
              const isActive = sortBy === option.value;
              return (
                <TouchableOpacity
                  key={option.value}
                  style={[styles.sortOption, isActive && styles.sortOptionActive]}
                  onPress={() => handleSortSelect(option.value)}>
                  <View style={[styles.sortOptionIcon, isActive && styles.sortOptionIconActive]}>
                    <MaterialIcons
                      name={option.icon}
                      size={18}
                      color={isActive ? '#FFFFFF' : COLORS.textSecondary}
                    />
                  </View>
                  <Text style={[styles.sortOptionText, isActive && styles.sortOptionTextActive]}>
                    {option.label}
                  </Text>
                  {isActive && (
                    <MaterialIcons name="check" size={24} color={COLORS.primary} />
                  )}
                </TouchableOpacity>
              );
            })}
          </View>
        </TouchableOpacity>
      </Modal>
    </View>
  );
};

export default ItemsScreen;
