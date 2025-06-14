from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from flask_wtf.csrf import CSRFProtect
import db, core, os, re
from urllib.parse import urlparse, parse_qs
from datetime import datetime
from logger import get_logger
import configuration_values

# Migrate database if needed
db.migrate_db_if_needed()

# Get logger for this module
logger = get_logger(__name__)

# Create Flask app
app = Flask(__name__,
            template_folder=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'templates'),
            static_folder=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'static'))

# Secret key for session management - require environment variable for security
secret = os.environ.get('SECRET_KEY')
if not secret:
    raise RuntimeError("SECRET_KEY environment variable must be set before starting the web-UI")
app.secret_key = secret

# Enable CSRF protection
csrf = CSRFProtect(app)


@app.context_processor
def inject_version_info():
    is_up_to_date, current_ver, latest_version, github_url = core.check_version()
    return {
        'github_url': github_url,
        'current_version': current_ver,
        'latest_version': latest_version,
        'is_up_to_date': is_up_to_date
    }


@app.context_processor
def inject_current_year():
    return {'current_year': datetime.now().year}


@app.context_processor
def inject_theme_preference():
    params = db.get_all_parameters()
    theme = 'dark' if params.get('dark_mode', 'false') == 'true' else 'light'
    return {'theme': theme}


@app.context_processor
def inject_csrf_token():
    from flask_wtf.csrf import generate_csrf
    return {'csrf_token': generate_csrf()}


@app.route('/')
def index():
    # Get parameters
    params = db.get_all_parameters()

    # Get queries
    queries = db.get_queries()
    formatted_queries = []
    for i, query in enumerate(queries):
        parsed_query = urlparse(query[1])
        query_params = parse_qs(parsed_query.query)
        search_text = query_params.get('search_text', [None])[0]

        # Get the last timestamp for this query
        try:
            last_timestamp = db.get_last_timestamp(query[0])
            last_found_item = datetime.fromtimestamp(last_timestamp).strftime('%Y-%m-%d %H:%M:%S')
        except (TypeError, ValueError, OSError):
            last_found_item = "Never"

        formatted_queries.append({
            'id': query[0],  # Use actual query ID
            'query': query[1],
            'display': query[3] if query[3] else (search_text if search_text else query[1]),
            'last_found_item': last_found_item
        })

    # Get recent items
    items = db.get_items(limit=10)
    formatted_items = []
    for item in items:
        formatted_items.append({
            'id': item[0],
            'title': item[1],
            'price': item[2],
            'currency': item[3],
            'timestamp': datetime.fromtimestamp(item[4]).strftime('%Y-%m-%d %H:%M:%S'),
            'query': item[5],
            'photo_url': item[6]
        })

    # Get process status from the database
    telegram_running = db.get_parameter('telegram_process_running') == 'True'
    rss_running = db.get_parameter('rss_process_running') == 'True'
    
    # Get keep-alive status
    import keep_alive
    keep_alive_enabled = db.get_parameter('keep_alive_enabled') == 'True'
    keep_alive_status = keep_alive.get_keep_alive_status() if keep_alive_enabled else None
    keep_alive_running = keep_alive.is_keep_alive_running() if keep_alive_enabled else False

    # Get statistics for the dashboard
    stats = {
        'total_items': db.get_total_items_count(),
        'total_queries': db.get_total_queries_count(),
        'items_per_day': db.get_items_per_day()
    }

    # Get the last found item
    last_item = db.get_last_found_item()
    if last_item:
        stats['last_item'] = {
            'id': last_item[0],
            'title': last_item[1],
            'price': last_item[2],
            'currency': last_item[3],
            'timestamp': datetime.fromtimestamp(last_item[4]).strftime('%Y-%m-%d %H:%M:%S'),
            'query': last_item[5],
            'photo_url': last_item[6]
        }
    else:
        stats['last_item'] = None

    return render_template('index.html',
                           params=params,
                           queries=formatted_queries,
                           items=formatted_items,
                           telegram_running=telegram_running,
                           rss_running=rss_running,
                           keep_alive_enabled=keep_alive_enabled,
                           keep_alive_running=keep_alive_running,
                           keep_alive_status=keep_alive_status,
                           stats=stats)


@app.route('/queries')
def queries():
    # Get queries
    all_queries = db.get_queries()
    formatted_queries = []
    for i, query in enumerate(all_queries):
        parsed_query = urlparse(query[1])
        query_params = parse_qs(parsed_query.query)
        search_text = query_params.get('search_text', [None])[0]

        # Get the last timestamp for this query
        try:
            last_timestamp = db.get_last_timestamp(query[0])
            last_found_item = datetime.fromtimestamp(last_timestamp).strftime('%Y-%m-%d %H:%M:%S')
        except (TypeError, ValueError, OSError):
            last_found_item = "Never"

        formatted_queries.append({
            'id': query[0],  # Use actual query ID instead of index
            'query': query[1],
            'name': query[3],  # Add the name field
            'display': query[3] if query[3] else (search_text if search_text else query[1]),
            'last_found_item': last_found_item
        })

    return render_template('queries.html', queries=formatted_queries)


@app.route('/add_query', methods=['POST'])
def add_query():
    query = request.form.get('query')
    name = request.form.get('name')
    if query:
        message, is_new_query = core.process_query(query, name)
        if is_new_query:
            flash(f'Query added: {query}', 'success')
        else:
            flash(message, 'warning')
    else:
        flash('No query provided', 'error')

    return redirect(url_for('queries'))


@app.route('/remove_query/<int:query_id>', methods=['POST'])
def remove_query(query_id):
    message, success = core.process_remove_query(str(query_id))
    if success:
        flash('Query removed', 'success')
    else:
        flash(message, 'error')

    return redirect(url_for('queries'))


@app.route('/remove_query/all', methods=['POST'])
def remove_all_queries():
    message, success = core.process_remove_query("all")
    if success:
        flash('All queries removed', 'success')
    else:
        flash(message, 'error')

    return redirect(url_for('queries'))


@app.route('/update_query_name/<int:query_id>', methods=['POST'])
def update_query_name(query_id):
    name = request.form.get('name')
    if db.update_query_name(query_id, name):
        flash('Query name updated successfully', 'success')
    else:
        flash('Failed to update query name', 'error')
    return redirect(url_for('queries'))


@app.route('/export_queries', methods=['GET'])
def export_queries():
    """Export all queries as JSON file for download"""
    try:
        json_data = db.export_queries_to_json()
        return jsonify({"success": True, "data": json_data})
    except Exception as e:
        logger.error(f"Error exporting queries: {e}", exc_info=True)
        return jsonify({"success": False, "error": str(e)})


@app.route('/import_queries', methods=['POST'])
def import_queries():
    """Import queries from uploaded JSON file"""
    try:
        if 'file' not in request.files:
            return jsonify({"success": False, "error": "No file provided"})
            
        file = request.files['file']
        if file.filename == '':
            return jsonify({"success": False, "error": "No file selected"})
            
        if not file.filename.endswith('.json'):
            return jsonify({"success": False, "error": "File must be JSON format"})
            
        # Read file content
        json_data = file.read().decode('utf-8')
        
        # Import queries
        success, message = db.import_queries_from_json(json_data)
        
        return jsonify({"success": success, "message": message})
    except Exception as e:
        logger.error(f"Error importing queries: {e}", exc_info=True)
        return jsonify({"success": False, "error": str(e)})


@app.route('/items')
def items():
    query_id = request.args.get('query', '')  # Default to empty string instead of None
    limit = int(request.args.get('limit', 50))
    sort_by = request.args.get('sort', 'newest')  # Get sort parameter
    search_term = request.args.get('search', '')  # Get search parameter

    # Get items
    query_string = None
    if query_id:
        # Get the actual query string for the given ID
        queries = db.get_queries()
        for q in queries:
            if str(q[0]) == query_id:
                query_string = q[1]
                break

    items_data = db.get_items(limit=limit, query=query_string, sort_by=sort_by)
    formatted_items = []

    for item in items_data:
        item_data = {
            'title': item[1],
            'price': item[2],
            'currency': item[3],
            'timestamp': datetime.fromtimestamp(item[4]).strftime('%Y-%m-%d %H:%M:%S'),
            'query': parse_qs(urlparse(item[5]).query).get('search_text', [None])[0] if
            parse_qs(urlparse(item[5]).query).get('search_text', [None])[0] else item[5],
            'url': f'https://www.vinted.fr/items/{item[0]}',
            'photo_url': item[6]
        }
        
        # Apply search filter if search term is provided
        if search_term:
            # Ensure both search_term and title are strings to prevent AttributeError
            title = item_data['title'] or ''
            if search_term.lower() in title.lower():
                formatted_items.append(item_data)
        else:
            formatted_items.append(item_data)

    # Get queries for filter dropdown
    queries = db.get_queries()
    formatted_queries = []
    selected_query_display = None
    for i, q in enumerate(queries):
        parsed_query = urlparse(q[1])
        query_params = parse_qs(parsed_query.query)
        search_text = query_params.get('search_text', [None])[0]
        display_name = search_text if search_text else q[0]
        # Store display name for selected query
        if query_id == str(q[0]):
            selected_query_display = display_name
        formatted_queries.append({
            'id': str(q[0]),
            'query': str(q[0]),  # Ensure query is a string
            'display': display_name
        })

    return render_template('items.html',
                           items=formatted_items,
                           queries=formatted_queries,
                           selected_query=query_id,
                           selected_query_display=selected_query_display,
                           limit=limit,
                           sort_by=sort_by,
                           search_term=search_term)


@app.route('/config')
def config():
    params = db.get_all_parameters()
    return render_template('config.html', params=params, dark_mode=params.get('dark_mode', 'false'))


@app.route('/update_config', methods=['POST'])
def update_config():
    # Update Telegram parameters
    telegram_enabled = 'telegram_enabled' in request.form
    db.set_parameter('telegram_enabled', str(telegram_enabled).lower())
    db.set_parameter('telegram_token', request.form.get('telegram_token', ''))
    db.set_parameter('telegram_chat_id', request.form.get('telegram_chat_id', ''))

    # Update RSS parameters
    rss_enabled = 'rss_enabled' in request.form
    db.set_parameter('rss_enabled', str(rss_enabled).lower())
    db.set_parameter('rss_port', request.form.get('rss_port', '8080'))
    db.set_parameter('rss_max_items', request.form.get('rss_max_items', '100'))

    # Update System parameters
    db.set_parameter('items_per_query', request.form.get('items_per_query', '20'))
    db.set_parameter('query_refresh_delay', request.form.get('query_refresh_delay', '60'))
    
    # Update UI parameters
    dark_mode = 'dark_mode' in request.form
    db.set_parameter('dark_mode', str(dark_mode).lower())

    # Update Keep-Alive parameters
    keep_alive_enabled = 'keep_alive_enabled' in request.form
    db.set_parameter('keep_alive_enabled', str(keep_alive_enabled).lower())
    keep_alive_interval = request.form.get('keep_alive_interval', '300')
    # Validate interval range (60-3600 seconds)
    try:
        interval = int(keep_alive_interval)
        if interval < 60:
            interval = 60
        elif interval > 3600:
            interval = 3600
        db.set_parameter('keep_alive_interval', str(interval))
    except ValueError:
        db.set_parameter('keep_alive_interval', '300')  # Default fallback

    # Update Proxy parameters
    check_proxies = 'check_proxies' in request.form
    db.set_parameter('check_proxies', str(check_proxies).lower())
    db.set_parameter('proxy_list', request.form.get('proxy_list', ''))
    db.set_parameter('proxy_list_link', request.form.get('proxy_list_link', ''))

    # Reset proxy cache to force refresh on next use
    db.set_parameter('last_proxy_check_time', "1")
    logger.info("Proxy settings updated, cache reset")

    flash('Configuration updated', 'success')
    return redirect(url_for('config'))


@app.route('/auto_save_toggle', methods=['POST'])
def auto_save_toggle():
    """Auto-save toggle changes via AJAX"""
    try:
        data = request.get_json()
        toggle_name = data.get('toggle_name')
        toggle_value = data.get('toggle_value')
        
        # Validate toggle name to prevent unauthorized parameter updates
        allowed_toggles = ['telegram_enabled', 'rss_enabled', 'dark_mode', 'check_proxies', 'keep_alive_enabled']
        
        if toggle_name not in allowed_toggles:
            return jsonify({'status': 'error', 'message': 'Invalid toggle name'}), 400
        
        # Convert boolean to string format expected by the database
        if toggle_name == 'dark_mode':
            db.set_parameter(toggle_name, str(toggle_value).lower())
        else:
            db.set_parameter(toggle_name, str(toggle_value))
        
        # Reset proxy cache if proxy settings changed
        if toggle_name == 'check_proxies':
            db.set_parameter('last_proxy_check_time', "1")
            logger.info("Proxy check setting updated, cache reset")
        
        logger.info(f"Auto-saved toggle: {toggle_name} = {toggle_value}")
        return jsonify({'status': 'success', 'message': 'Toggle saved automatically'})
        
    except Exception as e:
        logger.error(f"Error auto-saving toggle: {str(e)}")
        return jsonify({'status': 'error', 'message': 'Failed to save toggle'}), 500


@app.route('/control/<process_name>/<action>', methods=['POST'])
def control_process(process_name, action):
    if process_name not in ['telegram', 'rss']:
        return jsonify({'status': 'error', 'message': 'Invalid process name'})

    if action == 'start':
        if process_name == 'telegram':
            # Check current status
            if db.get_parameter('telegram_process_running') == 'True':
                return jsonify({'status': 'warning', 'message': 'Telegram bot already running'})

            # Check if telegram_token and telegram_chat_id are set
            telegram_token = db.get_parameter('telegram_token')
            telegram_chat_id = db.get_parameter('telegram_chat_id')
            if not telegram_token or not telegram_chat_id:
                return jsonify({'status': 'error',
                                'message': 'Please set Telegram token and chat ID in the configuration panel before starting the Telegram process'})

            # Update process status in the database
            # The manager process will detect this and start the process
            db.set_parameter('telegram_process_running', 'True')
            logger.info("Telegram bot process start requested")
            return jsonify({'status': 'success', 'message': 'Telegram bot start requested'})

        elif process_name == 'rss':
            # Check current status
            if db.get_parameter('rss_process_running') == 'True':
                return jsonify({'status': 'warning', 'message': 'RSS feed already running'})

            # Update process status in the database
            # The manager process will detect this and start the process
            db.set_parameter('rss_process_running', 'True')
            logger.info("RSS feed process start requested")
            return jsonify({'status': 'success', 'message': 'RSS feed start requested'})

    elif action == 'stop':
        if process_name == 'telegram':
            # Check current status
            if db.get_parameter('telegram_process_running') != 'True':
                return jsonify({'status': 'warning', 'message': 'Telegram bot not running'})

            # Update process status in the database
            # The manager process will detect this and stop the process
            db.set_parameter('telegram_process_running', 'False')
            logger.info("Telegram bot process stop requested")
            return jsonify({'status': 'success', 'message': 'Telegram bot stop requested'})

        elif process_name == 'rss':
            # Check current status
            if db.get_parameter('rss_process_running') != 'True':
                return jsonify({'status': 'warning', 'message': 'RSS feed not running'})

            # Update process status in the database
            # The manager process will detect this and stop the process
            db.set_parameter('rss_process_running', 'False')
            logger.info("RSS feed process stop requested")
            return jsonify({'status': 'success', 'message': 'RSS feed stop requested'})

    return jsonify({'status': 'error', 'message': 'Invalid action'})


@app.route('/control/status', methods=['GET'])
def process_status():
    # Get process status from the database
    telegram_running = db.get_parameter('telegram_process_running') == 'True'
    rss_running = db.get_parameter('rss_process_running') == 'True'
    
    # Get keep-alive status
    import keep_alive
    keep_alive_enabled = db.get_parameter('keep_alive_enabled') == 'True'
    keep_alive_status = keep_alive.get_keep_alive_status() if keep_alive_enabled else None
    keep_alive_running = keep_alive.is_keep_alive_running() if keep_alive_enabled else False

    return jsonify({
        'telegram': telegram_running,
        'rss': rss_running
    })


@app.route('/allowlist')
def allowlist():
    countries = db.get_allowlist()
    if countries == 0:
        countries = []

    return render_template('allowlist.html', countries=countries)


@app.route('/add_country', methods=['POST'])
def add_country():
    country = request.form.get('country', '').strip()
    if country:
        message, country_list = core.process_add_country(country)
        flash(message, 'success' if 'added' in message else 'warning')
    else:
        flash('No country provided', 'error')

    return redirect(url_for('allowlist'))


@app.route('/remove_country/<country>', methods=['POST'])
def remove_country(country):
    message, country_list = core.process_remove_country(country)
    flash(message, 'success')

    return redirect(url_for('allowlist'))


@app.route('/clear_allowlist', methods=['POST'])
def clear_allowlist():
    db.clear_allowlist()
    flash('Allowlist cleared', 'success')

    return redirect(url_for('allowlist'))


@app.route('/logs')
def logs():
    return render_template('logs.html')


@app.route('/api/logs')
def api_logs():
    offset = int(request.args.get('offset', 0))
    limit = int(request.args.get('limit', 100))
    level_filter = request.args.get('level', 'all')

    log_file_path = os.path.join('logs', 'vinted.log')

    if not os.path.exists(log_file_path):
        return jsonify({'logs': [], 'total': 0})

    # Parse log file
    log_entries = []
    total_matching_entries = 0

    try:
        with open(log_file_path, 'r', encoding='utf-8') as file:
            # Read all lines from the file
            all_lines = file.readlines()

            # Process lines in reverse order (newest first)
            all_lines.reverse()

            # Regular expression to parse log lines
            # Format: 2023-09-15 12:34:56,789 - module_name - LEVEL - Message
            log_pattern = r'(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}) - ([^-]+) - ([A-Z]+) - (.+)'

            current_entry = 0

            for line in all_lines:
                match = re.match(log_pattern, line.strip())
                if match:
                    timestamp, module, level, message = match.groups()

                    # Apply level filter if specified
                    if level_filter != 'all' and level != level_filter:
                        continue

                    total_matching_entries += 1

                    # Skip entries before offset
                    if total_matching_entries <= offset:
                        continue

                    # Add entry if within limit
                    if current_entry < limit:
                        log_entries.append({
                            'timestamp': timestamp,
                            'module': module.strip(),
                            'level': level,
                            'message': message
                        })
                        current_entry += 1

                    # Stop if we've reached the limit
                    if current_entry >= limit:
                        break
    except Exception as e:
        logger.error(f"Error reading log file: {e}")
        return jsonify({'logs': [], 'total': 0, 'error': str(e)})

    return jsonify({
        'logs': log_entries,
        'total': total_matching_entries
    })


def web_ui_process():
    logger.info("Web UI process started")
    try:
        app.run(host='0.0.0.0', port=configuration_values.WEB_UI_PORT, debug=False)
    except (KeyboardInterrupt, SystemExit):
        logger.info("Web UI process stopped")
    except Exception as e:
        logger.error(f"Error in web UI process: {e}", exc_info=True)
