# iOS Anti-Detection Improvements

## Summary

This document outlines the comprehensive anti-detection improvements implemented in the iOS app to match and exceed the desktop app's capabilities.

## Verified Issues (All Confirmed True)

1. ✅ **No Proxy Protection**: iOS app was loading proxies but not using them
2. ✅ **IP Switching**: Wi-Fi ↔ Cellular transitions create obvious patterns
3. ✅ **Fresh Sessions**: Each request looked like a new visitor
4. ✅ **Mobile Fingerprint**: Only mobile user agents were used
5. ✅ **Request Timing**: Fixed delays, no randomization

## Implemented Improvements

### 1. Proxy Support ✅

**Implementation:**
- Full proxy support using `URLSessionConfiguration.connectionProxyDictionary`
- Proxy health checking with parallel testing
- Proxy rotation at session level (iOS limitation: can't do per-request)
- Support for both `proxy_list` (semicolon-separated) and `proxy_list_link` (URL)
- Automatic proxy switching on detection/blocking
- Proxy rechecking every 6 hours

**Key Features:**
- `checkProxiesHealth()` - Tests all proxies in parallel
- `parseProxy()` - Handles both `http://host:port` and `host:port` formats
- `rotateProxySession()` - Recreates session with new proxy every 10 requests
- Session-level proxy configuration (iOS API limitation)

### 2. Enhanced Session Management ✅

**Implementation:**
- Persistent cookie storage using `HTTPCookieStorage.shared`
- Session warming before API calls
- Automatic cookie refresh every 5 minutes
- Session reuse across requests
- Connection pooling (2 connections per host)

**Key Features:**
- `warmUpSession()` - Pre-warms session on initialization
- `ensureFreshCookies()` - Refreshes cookies when needed
- Cookie persistence across app restarts
- Session reuse reduces fingerprinting

### 3. Random Delays and Jitter ✅

**Implementation:**
- Random delays between 1.0-3.0 seconds with ±0.5s jitter
- Exponential backoff with jitter for errors
- Minimum delay enforcement between requests
- Human-like timing patterns

**Key Features:**
- `addRequestDelay()` - Adds random delay with jitter before requests
- `exponentialBackoffWithJitter()` - Smart backoff for retries
- Base delay: 1-3 seconds, jitter: ±0.5 seconds
- Prevents predictable request patterns

### 4. Enhanced User Agent Rotation ✅

**Implementation:**
- Added desktop user agents to rotation pool
- 11 total user agents (5 mobile, 6 desktop)
- Random selection per request
- Reduces mobile fingerprint detection

**User Agents Added:**
- Desktop Chrome (Mac, Windows, Linux)
- Desktop Safari (Mac)
- Additional iOS versions (17.0, iPad)

### 5. Network Change Detection ✅

**Implementation:**
- Real-time network monitoring using `NWPathMonitor`
- 30-second cooldown period after network changes
- Automatic request delay on Wi-Fi ↔ Cellular transitions
- Network availability tracking

**Key Features:**
- `setupNetworkMonitoring()` - Monitors network changes
- `checkNetworkCooldown()` - Enforces cooldown after changes
- Prevents obvious bot patterns from IP switching
- Logs network state changes

### 6. Improved Error Handling ✅

**Implementation:**
- Better detection of rate limiting (429) vs blocking (403)
- Exponential backoff with jitter for all errors
- Automatic proxy switching on 403 errors
- Session reset on persistent 401/403 errors
- Different strategies for different error codes

**Error Handling:**
- **200**: Success, return data
- **401/404**: Refresh cookies, retry with backoff
- **429**: Rate limited, exponential backoff (2-60s), switch proxy
- **403**: Blocked, reset session, switch proxy, longer backoff (5s+)
- **Other**: Generic exponential backoff

### 7. Request Batching & Connection Pooling ✅

**Implementation:**
- Connection pooling (2 connections per host)
- Request batching through delay management
- Reduced request frequency through intelligent timing
- Cache disabled to avoid stale data

**Key Features:**
- `httpMaximumConnectionsPerHost = 2`
- Request delay prevents rapid-fire requests
- Better resource management

### 8. Additional Anti-Detection Measures ✅

**Header Randomization:**
- Randomized `Accept-Language` header
- Header order variation
- Dynamic header generation per request

**Behavioral Mimicry:**
- Human-like request timing
- Variable delays between requests
- Session persistence mimics real users

## Configuration Parameters

New/Updated database parameters:
- `proxy_list` - Semicolon-separated proxy list
- `proxy_list_link` - URL to fetch proxies from
- `check_proxies` - Enable/disable proxy health checking ("True"/"False")
- `last_proxy_check_time` - Timestamp of last proxy check

## Code Structure

### Key Files Modified:
1. **VintedAPI.swift** - Complete rewrite with all anti-detection measures
2. **Config.swift** - Enhanced user agent list with desktop agents
3. **DatabaseService.swift** - Added proxy-related parameters

### Key Classes/Methods:
- `VintedAPI` - Main API client with all improvements
- `setupNetworkMonitoring()` - Network change detection
- `checkProxiesHealth()` - Proxy validation
- `addRequestDelay()` - Random delay with jitter
- `exponentialBackoffWithJitter()` - Smart retry logic
- `warmUpSession()` - Session pre-warming
- `rotateProxySession()` - Proxy rotation

## Limitations & Notes

### iOS-Specific Limitations:
1. **Per-Request Proxy**: iOS `URLSession` doesn't support per-request proxy configuration. We work around this by rotating at the session level (every 10 requests).

2. **Proxy Configuration**: Proxies are configured at the `URLSessionConfiguration` level, requiring session recreation for rotation.

3. **Network Framework**: Uses `Network` framework for monitoring, which is iOS 12+.

### Best Practices:
- Configure proxies in settings for best results
- Enable `check_proxies` to validate proxy health
- Monitor logs for detection patterns
- Adjust delays if needed based on usage patterns

## Testing Recommendations

1. **Proxy Testing**: Add proxies and verify they're being used
2. **Network Switching**: Test Wi-Fi ↔ Cellular transitions
3. **Rate Limiting**: Monitor 429 responses and backoff behavior
4. **Session Persistence**: Verify cookies persist across requests
5. **Error Handling**: Test various error scenarios (401, 403, 429)

## Comparison with Desktop App

| Feature | Desktop | iOS (Before) | iOS (After) |
|---------|---------|-------------|-------------|
| Proxy Support | ✅ | ❌ | ✅ |
| Session Management | ✅ | ⚠️ | ✅ |
| Random Delays | ✅ | ❌ | ✅ |
| Desktop User Agents | ✅ | ❌ | ✅ |
| Network Monitoring | ❌ | ❌ | ✅ |
| Error Handling | ✅ | ⚠️ | ✅ |
| Connection Pooling | ✅ | ❌ | ✅ |

## Future Enhancements

Potential improvements for future versions:
1. A/B testing framework for anti-detection measures
2. Analytics tracking for detection patterns
3. Machine learning for optimal delay patterns
4. Advanced fingerprint randomization
5. Request prioritization system

## Conclusion

All identified issues have been addressed. The iOS app now has comprehensive anti-detection measures that match and in some cases exceed the desktop app's capabilities. The implementation takes into account iOS-specific limitations while maximizing effectiveness.
