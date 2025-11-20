//
//  Components.swift
//  Vinted Notifications
//
//  Reusable UI Components
//

import SwiftUI

// MARK: - LoadingView Component
struct LoadingView: View {
    @Environment(\.theme) var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            Text("Vinted Notifications")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(theme.text)
                .kerning(-1)
                .padding(.bottom, 8)

            // Tagline
            Text("NEVER MISS A DEAL")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(theme.textTertiary)
                .kerning(2)
                .padding(.bottom, 48)

            // Loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                .scaleEffect(1.5)
                .padding(.bottom, 16)

            // Loading text
            Text("Initializing...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}

// MARK: - PageHeader Component
struct PageHeader: View {
    let title: String
    var showSettings: Bool = true
    var showBack: Bool = false
    var centered: Bool = false
    var rightButton: AnyView? = nil

    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss

    var body: some View {
        HStack(alignment: .center) {
            if showBack {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: FontSizes.body, weight: .semibold))
                        Text("Back")
                            .font(.system(size: FontSizes.body))
                    }
                    .foregroundColor(theme.primary)
                }
            }

            if centered {
                Spacer()
            }

            Text(title)
                .font(.system(size: centered ? FontSizes.title1 : FontSizes.largeTitle, weight: .bold))
                .foregroundColor(theme.text)

            Spacer()

            if let button = rightButton {
                button
            } else if showSettings {
                NavigationLink(destination: SettingsView()) {
                    ZStack {
                        Circle()
                            .fill(theme.primary.opacity(0.15))
                            .frame(width: 36, height: 36)

                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .foregroundColor(theme.primary)
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, centered ? Spacing.xs : Spacing.sm)
        .padding(.bottom, centered ? Spacing.sm : Spacing.md)
        .background(theme.background)
    }
}

// MARK: - FeatureRow Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    @Environment(\.theme) var theme

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(theme.primary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: Spacing.xs / 2) {
                Text(title)
                    .font(.system(size: FontSizes.body, weight: .semibold))
                    .foregroundColor(theme.text)

                Text(description)
                    .font(.system(size: FontSizes.subheadline))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - InstructionStep Component
struct InstructionStep: View {
    let number: Int
    let text: String
    @Environment(\.theme) var theme

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.1))
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.system(size: FontSizes.footnote, weight: .bold))
                    .foregroundColor(theme.primary)
            }

            Text(text)
                .font(.system(size: FontSizes.subheadline))
                .foregroundColor(theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - StatWidget Component
struct StatWidget: View {
    let tag: String
    let value: String
    let subheading: String
    let lastUpdated: String
    let icon: String
    let iconColor: Color

    @Environment(\.theme) var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with tag and icon
            HStack {
                Text(tag)
                    .font(.system(size: FontSizes.caption1, weight: .bold))
                    .foregroundColor(theme.textTertiary)
                    .textCase(.uppercase)
                    .kerning(0.5)

                Spacer()

                // Icon in circular container
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.08))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(iconColor)
                }
            }
            .padding(.bottom, Spacing.xs)

            Spacer()

            // Content - Value and subheading
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(theme.text)
                    .kerning(-1)
                    .lineSpacing(52 - 48)

                if !subheading.isEmpty {
                    Text(subheading)
                        .font(.system(size: FontSizes.subheadline, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
            }

            Spacer()

            // Footer - Last updated
            Text(lastUpdated)
                .font(.system(size: FontSizes.caption2, weight: .medium))
                .foregroundColor(theme.textTertiary)
                .padding(.top, Spacing.xs)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
        .background(theme.secondaryGroupedBackground)
        .cornerRadius(BorderRadius.xl)
        .overlay(
            RoundedRectangle(cornerRadius: BorderRadius.xl)
                .stroke(theme.separator, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - ItemCard Component
struct ItemCard: View {
    let item: VintedItem
    var compact: Bool = false

    @Environment(\.theme) var theme
    @Environment(\.openURL) var openURL

    var body: some View {
        Button(action: {
            if let urlString = item.url, let url = URL(string: urlString) {
                openURL(url)
            }
        }) {
            HStack(spacing: Spacing.md) {
                // Photo - Larger size for better visibility
                AsyncImage(url: URL(string: item.photo ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(theme.buttonFill)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(theme.textTertiary)
                        )
                }
                .frame(width: compact ? 80 : 100, height: compact ? 80 : 100)
                .cornerRadius(BorderRadius.md)

                // Content - Title, brand, and time on the left
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(item.title)
                        .font(.system(size: FontSizes.body, weight: .medium))
                        .foregroundColor(theme.text)
                        .lineLimit(compact ? 1 : 2)

                    if let brand = item.brandTitle, !brand.isEmpty {
                        Text(brand)
                            .font(.system(size: FontSizes.subheadline))
                            .foregroundColor(theme.textSecondary)
                    }

                    if !compact {
                        Text(item.timeSincePosted())
                            .font(.system(size: FontSizes.caption1))
                            .foregroundColor(theme.textTertiary)
                    }
                }

                Spacer()

                // Price on the right side - centered and larger
                Text(item.formattedPrice())
                    .font(.system(size: FontSizes.title2, weight: .bold))
                    .foregroundColor(theme.primary)
            }
            .padding(Spacing.md)
            .background(theme.secondaryGroupedBackground)
            .cornerRadius(BorderRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - ItemGridCard Component
struct ItemGridCard: View {
    let item: VintedItem

    @Environment(\.theme) var theme
    @Environment(\.openURL) var openURL

    var body: some View {
        Button(action: {
            if let urlString = item.url, let url = URL(string: urlString) {
                openURL(url)
            }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                // Photo - fixed size for consistent grid layout with proper aspect ratio
                // FIXED: Added explicit width constraint and proper clipping order
                GeometryReader { geometry in
                    AsyncImage(url: URL(string: item.photo ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: 160)
                            .clipped()
                    } placeholder: {
                        Rectangle()
                            .fill(theme.buttonFill)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(theme.textTertiary)
                            )
                            .frame(width: geometry.size.width, height: 160)
                    }
                }
                .frame(height: 160)
                .clipped()

                // Content - fixed height for consistent card sizes
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Price - always present
                    Text(item.formattedPrice())
                        .font(.system(size: FontSizes.headline, weight: .bold))
                        .foregroundColor(theme.primary)
                        .lineLimit(1)

                    // Title - always 2 lines reserved
                    Text(item.title)
                        .font(.system(size: FontSizes.subheadline, weight: .medium))
                        .foregroundColor(theme.text)
                        .lineLimit(2)
                        .frame(height: FontSizes.subheadline * 2.4) // Reserve space for 2 lines

                    // Brand - always 1 line reserved (even if empty)
                    Group {
                        if let brand = item.brandTitle, !brand.isEmpty {
                            Text(brand)
                                .font(.system(size: FontSizes.caption1))
                                .foregroundColor(theme.textSecondary)
                                .lineLimit(1)
                        } else {
                            Text(" ")
                                .font(.system(size: FontSizes.caption1))
                                .lineLimit(1)
                        }
                    }
                    .frame(height: FontSizes.caption1 * 1.2) // Reserve space for 1 line
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Spacing.sm)
            }
            .frame(maxWidth: .infinity)
            .background(theme.secondaryGroupedBackground)
            .cornerRadius(BorderRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - QueryCard Component
struct QueryCard: View {
    let query: VintedQuery
    let onPress: () -> Void

    @Environment(\.theme) var theme

    var body: some View {
        Button(action: onPress) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(query.queryName)
                        .font(.system(size: FontSizes.headline, weight: .semibold))
                        .foregroundColor(theme.text)

                    Text(query.domain())
                        .font(.system(size: FontSizes.subheadline))
                        .foregroundColor(theme.textSecondary)
                }

                Text("Last item: \(query.lastItemTime())")
                    .font(.system(size: FontSizes.caption1))
                    .foregroundColor(theme.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.md)
            .background(theme.secondaryGroupedBackground)
            .cornerRadius(BorderRadius.xl)
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadius.xl)
                    .stroke(theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - CustomToggle Component
struct CustomToggle: View {
    @Binding var isOn: Bool
    let activeColor: Color
    let inactiveColor: Color

    var body: some View {
        Button(action: { isOn.toggle() }) {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 15.5)
                    .fill(isOn ? activeColor : inactiveColor)
                    .frame(width: 51, height: 31)

                Circle()
                    .fill(Color.white)
                    .frame(width: 27, height: 27)
                    .shadow(color: .black.opacity(0.2), radius: 2.5, x: 0, y: 2)
                    .padding(2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - CustomSegmentedControl Component
struct CustomSegmentedControl: View {
    let options: [String]
    @Binding var selectedIndex: Int
    @Environment(\.theme) var theme

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<options.count, id: \.self) { index in
                Button(action: { selectedIndex = index }) {
                    Text(options[index])
                        .font(.system(size: FontSizes.subheadline, weight: .semibold))
                        .foregroundColor(selectedIndex == index ? .white : theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xs)
                }
                .background(selectedIndex == index ? theme.primary : Color.clear)
                .cornerRadius(BorderRadius.md)
            }
        }
        .padding(2)
        .background(theme.buttonFill)
        .cornerRadius(BorderRadius.lg)
    }
}
