#!/usr/bin/env python3
"""
Test script for OpenRouter API integration
"""

import requests
import os
import json

def test_openrouter_api():
    """Test the OpenRouter API with a simple request"""
    api_key = os.getenv('OPENROUTER_API_KEY')

    if not api_key:
        print("❌ OPENROUTER_API_KEY environment variable not set")
        print("Get your API key from: https://openrouter.ai/keys")
        print("Then run: export OPENROUTER_API_KEY='your-key-here'")
        return False

    print("🔗 Testing OpenRouter API connection...")

    try:
        response = requests.post(
            'https://openrouter.ai/api/v1/chat/completions',
            headers={
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'https://github.com/your-repo',
                'X-Title': 'LINUX Unplugged Sponsor Finder'
            },
            json={
                'model': 'anthropic/claude-3-haiku:beta',
                'messages': [{'role': 'user', 'content': 'Say "Hello from LINUX Unplugged!" in exactly 5 words.'}],
                'max_tokens': 50,
                'temperature': 0.3
            },
            timeout=30
        )

        if response.status_code == 200:
            result = response.json()
            content = result['choices'][0]['message']['content'].strip()
            print(f"✅ OpenRouter API working! Response: {content}")

            # Check usage info
            if 'usage' in result:
                usage = result['usage']
                print(f"📊 Tokens used: {usage.get('total_tokens', 'unknown')}")

            return True
        else:
            print(f"❌ OpenRouter API error: {response.status_code}")
            print(f"Response: {response.text}")
            return False

    except Exception as e:
        print(f"❌ Error connecting to OpenRouter: {e}")
        return False

if __name__ == "__main__":
    print("Testing OpenRouter API integration...")
    success = test_openrouter_api()

    if success:
        print("\n🎉 OpenRouter is working! You can now run the full analysis:")
        print("python3 lup_sponsor_finder.py --episodes 2")
    else:
        print("\n💡 Make sure your OPENROUTER_API_KEY is correct and you have credits.")
















