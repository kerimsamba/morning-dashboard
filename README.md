# Morning Dashboard

Personal morning dashboard with:
- 🚂 Train times (Glasgow ↔ Edinburgh, high level only)
- 🌤 Weather (Glasgow & Edinburgh)
- 📰 UK News headlines

## Setup

1. **Add GitHub Secrets** (Settings → Secrets → Actions):
   - `TRANSPORT_APP_ID`: Your TransportAPI app ID
   - `TRANSPORT_APP_KEY`: Your TransportAPI app key

2. **Enable GitHub Pages** (Settings → Pages):
   - Source: Deploy from branch
   - Branch: `main`, folder: `/ (root)`

3. **Done!** Dashboard updates automatically at 6am & 5pm on weekdays.

## Manual refresh

```bash
./generate.sh && open index.html
```

## Local development

The script works locally too — API keys are embedded as fallbacks.
