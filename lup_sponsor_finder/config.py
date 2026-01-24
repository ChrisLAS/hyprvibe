"""
Configuration for LINUX Unplugged Podcast Sponsor Finder

Copy this file to config.py and fill in your API keys.
"""

import os

# OpenRouter API Key for episode analysis
# Get yours at: https://openrouter.ai/keys
OPENROUTER_API_KEY = os.getenv('OPENROUTER_API_KEY', '')

# Optional: Search API keys (for future web/Reddit/X searching)
# SerpAPI for web search: https://serpapi.com/
SERPAPI_KEY = os.getenv('SERPAPI_KEY', '')

# Reddit API credentials (for future Reddit analysis)
# Get yours at: https://www.reddit.com/prefs/apps
REDDIT_CLIENT_ID = os.getenv('REDDIT_CLIENT_ID', '')
REDDIT_CLIENT_SECRET = os.getenv('REDDIT_CLIENT_SECRET', '')
REDDIT_USER_AGENT = os.getenv('REDDIT_USER_AGENT', 'LINUX-Unplugged-Sponsor-Finder/1.0')

# Twitter/X API credentials (for future X analysis)
# Get yours at: https://developer.twitter.com/
TWITTER_BEARER_TOKEN = os.getenv('TWITTER_BEARER_TOKEN', '')

# Application settings
DEFAULT_EPISODE_LIMIT = 5
DEFAULT_MAX_SPONSORS = 5

# Output settings
OUTPUT_DIR = 'reports'
LOG_LEVEL = 'INFO'

# RSS Feed URL
RSS_FEED_URL = "https://feeds.jupiterbroadcasting.com/lup"
