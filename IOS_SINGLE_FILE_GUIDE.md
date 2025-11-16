# Running Vinted Notifications on iOS - Single File Solutions

This guide provides **3 different single-file approaches** to run Vinted monitoring directly on your iPhone or iPad **without rewriting the Vinted API**.

---

## 📊 Quick Comparison

| Feature | Pythonista | PWA (HTML/JS) | Pyodide (Python in Browser) |
|---------|-----------|---------------|------------------------------|
| **Cost** | $9.99 one-time | Free | Free |
| **Installation** | App Store | Safari (Add to Home) | Safari (Add to Home) |
| **Python Code** | ✅ 100% Python | ❌ JavaScript | ✅ 100% Python |
| **Performance** | ⭐⭐⭐⭐⭐ Native | ⭐⭐⭐⭐ Fast | ⭐⭐ Slower (WASM) |
| **Offline Mode** | ✅ Yes | ✅ Yes (after load) | ❌ Needs initial download |
| **Background** | ⚠️ Limited | ⚠️ Limited | ⚠️ Limited |
| **Notifications** | ✅ iOS Native | ✅ Web Push | ✅ Web Push |
| **API Rewrite** | ❌ Not needed | ⚠️ Minimal (~50 lines) | ❌ Not needed |
| **File Size** | ~180 lines | ~450 lines | ~200 lines |
| **Setup Time** | 2 minutes | 30 seconds | 2 minutes |
| **Best For** | Python lovers | Everyone | Python purists |

---

## 1️⃣ Pythonista (Native iOS Python) ⭐ RECOMMENDED

### What You Get
- **Full Python 3.10** running natively on iOS
- Uses the **same Vinted API logic** as the main project
- Native iOS notifications via Pythonista's `notification` module
- Can run in background (with limitations)
- Professional Python IDE with debugging

### Setup Steps

1. **Buy Pythonista** ($9.99 on App Store)
   - https://apps.apple.com/app/pythonista-3/id1085978097

2. **Copy the script**
   - Open Pythonista
   - Create new file: `vinted_monitor.py`
   - Copy contents from `vinted_ios_pythonista.py`

3. **Configure**
   ```python
   TELEGRAM_TOKEN = "your_bot_token"
   TELEGRAM_CHAT_ID = "your_chat_id"

   QUERIES = [
       "https://www.vinted.fr/catalog?search_text=nike&price_to=50",
   ]

   CHECK_INTERVAL = 60  # seconds
   ```

4. **Run**
   - Tap ▶️ play button
   - Keep app open (or use iOS Shortcuts for automation)

### Pros & Cons

✅ **Pros:**
- Real Python code (no rewrite needed)
- Fast native execution
- Can install packages via `pip`
- Best for Python developers
- iOS Shortcuts integration

❌ **Cons:**
- Costs $9.99
- Must keep app in foreground (iOS limitation)
- No true background execution

---

## 2️⃣ Progressive Web App (PWA) ⭐⭐ EASIEST & FREE

### What You Get
- **Single HTML file** - works in any browser
- **Add to Home Screen** for app-like experience
- **Pure JavaScript** Vinted API client (~50 lines)
- Works on **any device** (iPhone, Android, desktop)
- Beautiful iOS-native UI design
- Web Push Notifications

### Setup Steps

1. **Download the file**
   - Save `vinted_ios_pwa.html` to your device
   - Or host it anywhere (GitHub Pages, Netlify, etc.)

2. **Open in Safari**
   - Navigate to the HTML file
   - Tap Share → **Add to Home Screen**
   - Name it "Vinted Monitor"

3. **Configure**
   - Open the app
   - Paste your Vinted search URLs (one per line)
   - (Optional) Add Telegram credentials
   - Set check interval
   - Tap **Start Monitoring**

4. **Grant Permissions**
   - Allow notifications when prompted

### Pros & Cons

✅ **Pros:**
- **100% FREE**
- No installation required
- Works offline after first load
- Beautiful iOS UI with animations
- Saves config to localStorage
- Cross-platform (works anywhere)
- Can be hosted online for remote access

❌ **Cons:**
- Vinted API reimplemented in JavaScript (but minimal)
- Tab must stay open in Safari
- Less powerful than native Python

### How It Works

The PWA uses a minimal JavaScript implementation of the Vinted API:

```javascript
// Simplified Vinted API client (50 lines)
class VintedAPI {
    static async search(url, perPage = 10) {
        const locale = new URL(url).hostname;
        const params = this.parseUrl(url, perPage);

        const apiUrl = `https://${locale}/api/v2/catalog/items?` +
            new URLSearchParams(params).toString();

        const response = await fetch(apiUrl);
        const data = await response.json();
        return data.items || [];
    }
}
```

**No Python rewrite needed** - it's just HTTP requests!

---

## 3️⃣ Pyodide (Python in Browser via WebAssembly)

### What You Get
- **Real Python code** running in Safari via WebAssembly
- **Same Python syntax** as the main project
- Runs in browser (no app needed)
- Edit Python code directly in the web interface

### Setup Steps

1. **Open the file**
   - Open `vinted_ios_pyodide.html` in Safari
   - Wait for Python runtime to load (~30s first time)

2. **Edit the code**
   - Modify the Python code in the textarea:
   ```python
   QUERIES = [
       "https://www.vinted.fr/catalog?search_text=nike",
   ]
   TELEGRAM_TOKEN = "your_token"
   ```

3. **Run**
   - Tap "Run Python Code"
   - Watch the output console

### Pros & Cons

✅ **Pros:**
- Real Python code (familiar syntax)
- No app installation
- Free
- Can edit code in browser

❌ **Cons:**
- **Slow** initial load (downloads 10MB+ Python runtime)
- Higher memory usage
- Less reliable than native Python
- Some libraries don't work in WASM

---

## 🏆 Recommendation

### For Most Users: **PWA** (Option 2)
- Free, fast, beautiful UI
- Works immediately
- No learning curve
- Best mobile experience

### For Python Developers: **Pythonista** (Option 1)
- Worth the $9.99 if you code Python
- Native performance
- Can reuse existing Python libraries
- Best for tinkering and customization

### For Experimentation: **Pyodide** (Option 3)
- Cool tech demo
- Good for learning
- Not recommended for daily use

---

## 📱 iOS Background Limitations

⚠️ **Important:** iOS does not allow true background execution for web apps or third-party Python apps. All approaches require:

- **Safari tab stays open** (PWA)
- **App in foreground** (Pythonista)

### Workarounds

1. **iOS Shortcuts Automation**
   - Create a shortcut to open the app
   - Set automation to run periodically

2. **Use the full Python backend**
   - Run the main Vinted-Notifications on a server
   - Use these iOS apps to view/configure remotely

3. **Hybrid approach**
   - Run Python backend on a Raspberry Pi at home
   - Access via web UI from iPhone
   - Get Telegram notifications anywhere

---

## 🔧 Extending the Single-File Apps

All three files can be extended with:

### Additional Notification Channels

```python
# Add Discord webhook (works in all versions)
import requests

def send_discord(webhook_url, message, url):
    requests.post(webhook_url, json={
        "content": f"{message}\n{url}"
    })
```

### Custom Filtering

```python
# Add price filtering
def should_notify(item):
    price = float(item['price'])
    if price > 100:
        return False
    if 'fake' in item['title'].lower():
        return False
    return True
```

### Data Persistence

```javascript
// PWA: LocalStorage (already implemented)
localStorage.setItem('seenItems', JSON.stringify(items));

// Pythonista: SQLite
import sqlite3
conn = sqlite3.connect('vinted.db')
```

---

## 🆚 Comparison to Full Project

| Feature | Single-File Apps | Full Project |
|---------|------------------|--------------|
| Setup Time | < 5 min | 15-30 min |
| Maintenance | Zero | Updates needed |
| Scalability | 1-5 queries | Unlimited |
| Features | Basic monitoring | Full suite |
| Background | ❌ | ✅ (server) |
| Multi-device | Manual sync | Centralized DB |
| Web UI | Basic/None | Professional |
| Best For | Personal use | Power users |

---

## 📖 Next Steps

1. **Try the PWA first** (no cost, works immediately)
2. **If you like it**, consider Pythonista for better performance
3. **For serious use**, deploy the full Python backend on a server

---

## 🐛 Troubleshooting

### PWA: "Failed to fetch"
- Check your internet connection
- Try different Vinted domain (e.g., .de instead of .fr)
- Open browser console (Safari → Develop → Show JavaScript Console)

### Pythonista: "Module not found"
- Make sure script is in the root directory
- Check that `requests` is installed: `import requests`

### Pyodide: "Loading forever"
- Clear Safari cache
- Try on WiFi (initial download is large)
- Check browser console for errors

---

## 📝 License

These single-file implementations are released under the same license as the main project (GNU AGPL v3).

Feel free to modify and share!

---

**Questions?** Open an issue on GitHub or check the main project README.
