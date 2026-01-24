#!/usr/bin/env python3
"""
Basic test script for RSS parsing without external dependencies
"""

import urllib.request
import xml.etree.ElementTree as ET
from datetime import datetime
import re

def test_rss_basic():
    """Test basic RSS parsing using built-in libraries"""
    RSS_URL = "https://feeds.jupiterbroadcasting.com/lup"

    print(f"Fetching RSS feed from {RSS_URL}...")

    try:
        # Fetch the RSS feed
        with urllib.request.urlopen(RSS_URL) as response:
            rss_content = response.read().decode('utf-8')

        print(f"Successfully fetched RSS content ({len(rss_content)} characters)")

        # Parse XML
        root = ET.fromstring(rss_content)

        # Find all items
        items = root.findall('.//item')
        live_items = root.findall('.//{http://www.podlove.org/simple-chapters}liveItem')

        print(f"Found {len(items)} regular episodes and {len(live_items)} live items")

        # Process first few items
        all_items = items[:3] + live_items[:1]  # First 3 episodes + 1 live item

        for i, item in enumerate(all_items, 1):
            title_elem = item.find('title')
            title = title_elem.text if title_elem is not None else "No title"

            pub_date_elem = item.find('pubDate')
            pub_date = pub_date_elem.text if pub_date_elem is not None else "No date"

            desc_elem = item.find('description')
            description = desc_elem.text[:200] + "..." if desc_elem is not None and desc_elem.text else "No description"

            print(f"\n{i}. {title}")
            print(f"   Published: {pub_date}")
            print(f"   Description: {description}")

        return True

    except Exception as e:
        print(f"Error: {e}")
        return False

if __name__ == "__main__":
    print("Testing basic RSS parsing functionality...")
    success = test_rss_basic()
    if success:
        print("\n✓ RSS parsing works! The feed is accessible and parseable.")
        print("Next steps:")
        print("1. Install dependencies: nix-shell -p python3Packages.feedparser python3Packages.requests")
        print("2. Get OpenRouter API key: https://openrouter.ai/keys")
        print("3. Set OPENROUTER_API_KEY environment variable")
        print("4. Test API: python3 test_openrouter.py")
        print("5. Run analysis: python3 lup_sponsor_finder.py --episodes 2")
    else:
        print("\n✗ RSS parsing failed. Check the feed URL or network connection.")
