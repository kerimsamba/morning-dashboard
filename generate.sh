#!/bin/bash
# Generate morning dashboard HTML
# Run this to refresh the data

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="$SCRIPT_DIR/index.html"

# Use env vars if set (GitHub Actions), otherwise fall back to defaults
APP_ID="${TRANSPORT_APP_ID:-e3114637}"
APP_KEY="${TRANSPORT_APP_KEY:-d19714141e23df4510b1af56b9a0f3af}"

echo "🔄 Generating dashboard..."

# --- TRAINS: Glasgow → Edinburgh (with arrival platforms) ---
TRAINS_GLQ=""
GLQ_DEPS=$(curl -sL "https://transportapi.com/v3/uk/train/station/GLQ/live.json?app_id=${APP_ID}&app_key=${APP_KEY}&destination=EDB&train_status=passenger")
for uid in $(echo "$GLQ_DEPS" | jq -r '.departures.all | map(select(.platform != "9" and .platform != "8")) | .[:3] | .[].train_uid'); do
  DEP_INFO=$(echo "$GLQ_DEPS" | jq -r --arg uid "$uid" '.departures.all[] | select(.train_uid == $uid) | "\(.aimed_departure_time)|\(.platform)"')
  DEP_TIME=$(echo "$DEP_INFO" | cut -d'|' -f1)
  DEP_PLAT=$(echo "$DEP_INFO" | cut -d'|' -f2)
  
  SVC=$(curl -sL "https://transportapi.com/v3/uk/train/service_timetables/${uid}:$(date +%Y-%m-%d).json?app_id=${APP_ID}&app_key=${APP_KEY}&live=true")
  ARR_PLAT=$(echo "$SVC" | jq -r '.stops[] | select(.station_code == "EDB") | .platform')
  ARR_TIME=$(echo "$SVC" | jq -r '.stops[] | select(.station_code == "EDB") | .aimed_arrival_time')
  
  TRAINS_GLQ+="<div class=\"train\"><span class=\"time\">${DEP_TIME}</span><span class=\"platform\">Plat ${DEP_PLAT} → ${ARR_PLAT}</span><span class=\"arr\">arr ${ARR_TIME}</span></div>"
done

# --- TRAINS: Edinburgh → Glasgow (with arrival platforms) ---
TRAINS_EDB=""
EDB_DEPS=$(curl -sL "https://transportapi.com/v3/uk/train/station/EDB/live.json?app_id=${APP_ID}&app_key=${APP_KEY}&destination=GLQ&train_status=passenger")
for uid in $(echo "$EDB_DEPS" | jq -r '.departures.all | .[:6] | .[].train_uid'); do
  DEP_INFO=$(echo "$EDB_DEPS" | jq -r --arg uid "$uid" '.departures.all[] | select(.train_uid == $uid) | "\(.aimed_departure_time)|\(.platform)"')
  DEP_TIME=$(echo "$DEP_INFO" | cut -d'|' -f1)
  DEP_PLAT=$(echo "$DEP_INFO" | cut -d'|' -f2)
  
  SVC=$(curl -sL "https://transportapi.com/v3/uk/train/service_timetables/${uid}:$(date +%Y-%m-%d).json?app_id=${APP_ID}&app_key=${APP_KEY}&live=true")
  ARR_PLAT=$(echo "$SVC" | jq -r '.stops[] | select(.station_code == "GLQ") | .platform')
  ARR_TIME=$(echo "$SVC" | jq -r '.stops[] | select(.station_code == "GLQ") | .aimed_arrival_time')
  
  # Skip low level arrivals (platform 8 or 9)
  [[ "$ARR_PLAT" == "8" || "$ARR_PLAT" == "9" ]] && continue
  
  TRAINS_EDB+="<div class=\"train\"><span class=\"time\">${DEP_TIME}</span><span class=\"platform\">Plat ${DEP_PLAT} → ${ARR_PLAT}</span><span class=\"arr\">arr ${ARR_TIME}</span></div>"
  
  # Limit to 3 trains
  [[ $(echo "$TRAINS_EDB" | grep -c "train") -ge 3 ]] && break
done

# --- WEATHER (Met Office) ---
# Glasgow: gcuvz3bch, Edinburgh: gcvwr3zrw
GLASGOW_DATA=$(curl -sL "https://weather.metoffice.gov.uk/forecast/gcuvz3bch" | head -100)
EDINBURGH_DATA=$(curl -sL "https://weather.metoffice.gov.uk/forecast/gcvwr3zrw" | head -100)

# Extract first temperature from the forecast (current hour)
GLASGOW_TEMP=$(echo "$GLASGOW_DATA" | grep -o '[0-9]\+°' | head -1 || echo "?°")
EDINBURGH_TEMP=$(echo "$EDINBURGH_DATA" | grep -o '[0-9]\+°' | head -1 || echo "?°")

GLASGOW_DESC="Met Office"
EDINBURGH_DESC="Met Office"

# --- REDDIT: AI Coding ---
# Reddit blocks direct API calls from servers - ask me for Reddit updates instead
REDDIT="<div class='reddit-item' style='color: var(--muted)'>Ask Clawd for the latest from r/ClaudeAI, r/cursor, r/claudecode</div>"

# --- UK NEWS (BBC RSS) ---
NEWS=$(curl -sL "https://feeds.bbci.co.uk/news/uk/rss.xml" | sed -n 's:.*<title>\(.*\)</title>.*:\1:p' | sed 's/<!\[CDATA\[//g; s/\]\]>//g' | tail -n +3 | head -5 | while read -r title; do
  echo "<div class=\"news-item\">$title</div>"
done)

TIMESTAMP=$(date "+%H:%M %d %b %Y")

# --- BUILD HTML ---
cat > "$OUTPUT" << HTMLEOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Morning Dashboard</title>
  <style>
    :root {
      --bg: #1a1a2e;
      --card: #16213e;
      --accent: #0f3460;
      --text: #e8e8e8;
      --muted: #8892a0;
      --green: #4ade80;
      --yellow: #fbbf24;
      --red: #f87171;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: var(--bg);
      color: var(--text);
      padding: 20px;
      max-width: 900px;
      margin: 0 auto;
    }
    h1 { font-size: 1.5rem; margin-bottom: 20px; color: var(--muted); }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 20px; }
    @media (max-width: 600px) { .grid { grid-template-columns: 1fr; } }
    .card {
      background: var(--card);
      border-radius: 12px;
      padding: 16px;
    }
    .card h2 {
      font-size: 0.9rem;
      color: var(--muted);
      margin-bottom: 12px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .train {
      display: flex;
      justify-content: space-between;
      padding: 8px 0;
      border-bottom: 1px solid var(--accent);
    }
    .train:last-child { border-bottom: none; }
    .train .time { font-weight: 600; font-size: 1.1rem; }
    .train .platform { color: var(--muted); }
    .status.ok { color: var(--green); }
    .status.delayed { color: var(--yellow); }
    .status.cancelled { color: var(--red); }
    .train .arr { color: var(--muted); font-size: 0.85rem; }
    .weather {
      display: flex;
      align-items: center;
      gap: 16px;
    }
    .weather .temp { font-size: 2.2rem; font-weight: 300; }
    .weather .desc { color: var(--muted); font-size: 0.95rem; }
    .full-width { grid-column: 1 / -1; }
    .news-item, .reddit-item {
      padding: 10px 0;
      border-bottom: 1px solid var(--accent);
    }
    .news-item:last-child, .reddit-item:last-child { border-bottom: none; }
    .reddit-item a {
      color: var(--text);
      text-decoration: none;
    }
    .reddit-item a:hover { text-decoration: underline; }
    .meta { font-size: 0.8rem; color: var(--muted); margin-top: 4px; }
    .updated { text-align: center; color: var(--muted); font-size: 0.8rem; margin-top: 20px; }
  </style>
</head>
<body>
  <h1>☀️ Good Morning</h1>
  
  <div class="grid">
    <div class="card">
      <h2>🚂 Glasgow → Edinburgh</h2>
      ${TRAINS_GLQ}
    </div>
    <div class="card">
      <h2>🚂 Edinburgh → Glasgow</h2>
      ${TRAINS_EDB}
    </div>
    
    <div class="card">
      <h2>🌤 Glasgow</h2>
      <div class="weather">
        <span class="temp">${GLASGOW_TEMP}</span>
        <span class="desc">${GLASGOW_DESC}</span>
      </div>
    </div>
    <div class="card">
      <h2>🌤 Edinburgh</h2>
      <div class="weather">
        <span class="temp">${EDINBURGH_TEMP}</span>
        <span class="desc">${EDINBURGH_DESC}</span>
      </div>
    </div>
    
    <div class="card full-width">
      <h2>🤖 AI Coding Reddit</h2>
      ${REDDIT}
    </div>
    
    <div class="card full-width">
      <h2>📰 UK News</h2>
      ${NEWS}
    </div>
  </div>
  
  <div class="updated">Updated: ${TIMESTAMP}</div>
</body>
</html>
HTMLEOF

echo "✅ Dashboard generated: $OUTPUT"
