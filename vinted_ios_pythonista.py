#!/usr/bin/env python3
"""
Vinted Notifications for iOS - Single File Edition
Requires: Pythonista app on iOS (https://omz-software.com/pythonista/)

Instructions:
1. Install Pythonista from App Store ($9.99)
2. Copy this file to Pythonista
3. Edit TELEGRAM_TOKEN and TELEGRAM_CHAT_ID below
4. Add your search URLs to QUERIES list
5. Run the script
6. Use iOS Shortcuts to trigger notifications
"""

import requests
import time
import json
from urllib.parse import urlparse, parse_qsl
from datetime import datetime
import random

# ============================================================================
# CONFIGURATION - Edit these values
# ============================================================================
TELEGRAM_TOKEN = "your_bot_token_here"
TELEGRAM_CHAT_ID = "your_chat_id_here"

# Add your Vinted search URLs here
QUERIES = [
    "https://www.vinted.fr/catalog?search_text=nike&price_to=50",
    # Add more queries...
]

CHECK_INTERVAL = 60  # seconds between checks
ITEMS_PER_QUERY = 10

# ============================================================================
# Simple in-memory storage (you could use iOS's sqlite3 instead)
# ============================================================================
seen_items = set()

# ============================================================================
# Vinted API Client (minimal ~80 lines)
# ============================================================================
class VintedClient:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15',
            'Accept': 'application/json',
        })

    def search(self, url, nbr_items=20):
        """Search Vinted and return items"""
        # Extract domain and set locale
        parsed = urlparse(url)
        locale = parsed.netloc

        # Parse URL parameters
        params = self._parse_url(url, nbr_items)

        # Make API request
        api_url = f"https://{locale}/api/v2/catalog/items"

        try:
            # Get fresh cookies
            self.session.head(f"https://{locale}/")

            response = self.session.get(api_url, params=params)
            response.raise_for_status()
            data = response.json()

            return data.get('items', [])
        except Exception as e:
            print(f"Error searching Vinted: {e}")
            return []

    def _parse_url(self, url, nbr_items=20):
        """Parse Vinted URL into API parameters"""
        queries = parse_qsl(urlparse(url).query)

        params = {
            'search_text': '+'.join([v for k, v in queries if k == 'search_text']),
            'brand_ids': ','.join([v for k, v in queries if k == 'brand_ids[]']),
            'size_ids': ','.join([v for k, v in queries if k == 'size_ids[]']),
            'color_ids': ','.join([v for k, v in queries if k == 'color_ids[]']),
            'price_to': ','.join([v for k, v in queries if k == 'price_to']),
            'price_from': ','.join([v for k, v in queries if k == 'price_from']),
            'currency': ','.join([v for k, v in queries if k == 'currency']),
            'per_page': nbr_items,
            'order': 'newest_first',
        }

        # Remove empty params
        return {k: v for k, v in params.items() if v}

# ============================================================================
# Notification Handler
# ============================================================================
def send_telegram(message, url, photo_url=None):
    """Send notification via Telegram"""
    if not TELEGRAM_TOKEN or TELEGRAM_TOKEN == "your_bot_token_here":
        print(f"[Would send] {message}\n{url}")
        return

    api_url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"

    # Format message with image preview hack
    text = message
    if photo_url:
        text += f'\n<a href="{photo_url}">&#8205;</a>'

    payload = {
        'chat_id': TELEGRAM_CHAT_ID,
        'text': text,
        'parse_mode': 'HTML',
        'disable_web_page_preview': False
    }

    try:
        requests.post(api_url, json=payload)
    except Exception as e:
        print(f"Failed to send Telegram message: {e}")

def send_ios_notification(title, message, url):
    """Send iOS local notification (Pythonista specific)"""
    try:
        import notification
        notification.schedule(
            title=title,
            message=message,
            delay=0,
            sound_name='default',
            action_url=url
        )
    except ImportError:
        print("iOS notifications not available (not running in Pythonista)")

# ============================================================================
# Main monitoring loop
# ============================================================================
def process_item(item):
    """Process a single item and send notification if new"""
    item_id = str(item.get('id'))

    # Skip if already seen
    if item_id in seen_items:
        return False

    seen_items.add(item_id)

    # Extract item details
    title = item.get('title', 'Unknown')
    price = item.get('price', '?')
    currency = item.get('currency', '')
    brand = item.get('brand_title', 'No brand')
    url = item.get('url', '')
    photo = item.get('photo', {}).get('url') if item.get('photo') else None

    # Format message
    message = f"""🆕 {title}
💶 {price} {currency}
🛍️ {brand}"""

    # Send notifications
    send_telegram(message, url, photo)
    send_ios_notification("New Vinted Item", title, url)

    print(f"✓ New item: {title} - {price} {currency}")
    return True

def monitor_queries():
    """Main monitoring function"""
    client = VintedClient()
    new_count = 0

    for query_url in QUERIES:
        print(f"\n🔍 Checking: {query_url}")

        items = client.search(query_url, nbr_items=ITEMS_PER_QUERY)

        # Process items (newest first)
        for item in reversed(items):
            if process_item(item):
                new_count += 1

    return new_count

# ============================================================================
# Entry point
# ============================================================================
def main():
    print("=" * 50)
    print("Vinted Notifications for iOS")
    print("=" * 50)
    print(f"Monitoring {len(QUERIES)} queries")
    print(f"Checking every {CHECK_INTERVAL} seconds")
    print(f"Press Ctrl+C to stop\n")

    try:
        iteration = 0
        while True:
            iteration += 1
            timestamp = datetime.now().strftime("%H:%M:%S")
            print(f"\n[{timestamp}] Check #{iteration}")

            new_count = monitor_queries()

            if new_count > 0:
                print(f"✓ Found {new_count} new items!")
            else:
                print("No new items")

            print(f"Sleeping {CHECK_INTERVAL}s...")
            time.sleep(CHECK_INTERVAL)

    except KeyboardInterrupt:
        print("\n\n👋 Stopped monitoring")

if __name__ == "__main__":
    main()
