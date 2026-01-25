# Google Cloud Text-to-Speech Setup Guide

## Overview

The dartboard emulator now supports Google Cloud's Neural and WaveNet voices - the most natural-sounding AI voices available! These voices sound incredibly realistic and human-like.

## ⭐ Features

### Available Voice Types

1. **Neural2 Voices** (Best Quality - Recommended)
   - 9 US English voices (male and female)
   - 4 British English voices
   - Extremely natural-sounding
   - Cost: ~$16 per 1M characters

2. **Studio Voices** (Premium Quality)
   - Highest quality available
   - Limited selection
   - Cost: ~$100 per 1M characters

3. **WaveNet Voices** (Good Quality)
   - Natural-sounding
   - More affordable
   - Cost: ~$16 per 1M characters

## 🚀 Quick Setup (5 minutes)

### Step 1: Get a Google Cloud Account

1. Go to [https://cloud.google.com](https://cloud.google.com)
2. Click "Get started for free"
3. Sign in with your Google account
4. You'll get **$300 free credits** for 90 days!

### Step 2: Enable Text-to-Speech API

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project or select an existing one
3. Go to "APIs & Services" > "Library"
4. Search for "Cloud Text-to-Speech API"
5. Click "Enable"

### Step 3: Create an API Key

1. Go to "APIs & Services" > "Credentials"
2. Click "+ CREATE CREDENTIALS"
3. Select "API key"
4. Copy the API key (looks like: `AIzaSy...`)
5. **Optional but recommended:** Click "Restrict key" and limit to "Cloud Text-to-Speech API"

### Step 4: Configure in the App

1. In the dartboard emulator, find the **Engine** dropdown
2. Select "Google Cloud"
3. A dialog will appear asking for your API key
4. Paste your API key
5. Click "Save & Test"
6. If successful, you'll see a confirmation message!

### Step 5: Select a Voice

1. After setup, select a voice from the **Neural Voice** dropdown
2. Try these recommended voices:
   - **US Male (Neural2) - Deep** - Professional male announcer
   - **US Female (Neural2) - Energetic** - Enthusiastic female caller
   - **British Male (Neural2)** - British male announcer
   - **US Female (Neural2) - Warm** - Friendly female voice

3. Select your favorite announcement **Style** (Professional, Excited, etc.)
4. Throw some darts and enjoy the natural-sounding announcements!

## 💰 Pricing

### Free Tier
- **1 million characters per month FREE**
- For dartboard announcements, this means:
  - ~50,000 dart throws per month (assuming ~20 chars/announcement)
  - More than enough for personal use!

### After Free Tier
- Neural2/WaveNet: $16 per 1 million characters
- Studio: $100 per 1 million characters
- Example: 100,000 dart throws = ~2M chars = ~$32/month (Neural2)

## 🎤 Voice Recommendations

### For Different Styles

**Professional Tournament Announcer:**
- Voice: `US Male (Neural2) - Professional` or `British Male (Neural2)`
- Style: Professional

**Excited Sports Commentator:**
- Voice: `US Female (Neural2) - Energetic`
- Style: Excited

**Calm Practice Session:**
- Voice: `US Female (Neural2) - Calm` or `US Female (Neural2) - Warm`
- Style: Calm

**Comedy/Entertainment:**
- Voice: `US Male (Neural2) - Casual`
- Style: Funny

**Military/Intense:**
- Voice: `US Male (Neural2) - Authoritative` or `US Male (Neural2) - Deep`
- Style: Drill Sergeant

## 🔧 Troubleshooting

### "Failed to validate API key"
- Check that you copied the entire API key
- Make sure Text-to-Speech API is enabled in your project
- Verify the API key isn't restricted to a different API
- Try creating a new, unrestricted API key

### "No sound playing"
- Check your browser volume
- Make sure announcer is toggled ON
- Try throwing a dart - there might be a delay on first use
- Check browser console for errors

### Voices sound robotic
- Make sure you selected a **Neural2** or **WaveNet** voice
- Studio voices are the highest quality if budget allows
- Standard voices will sound more robotic

### High costs
- Monitor usage in Google Cloud Console
- Set up budget alerts
- Consider switching to browser voices for practice
- Use Google voices only for special events/tournaments

## 🌟 Best Practices

1. **Test voices** - Try different voices to find your favorite
2. **Monitor usage** - Check Google Cloud Console monthly
3. **Set budgets** - Create budget alerts in Google Cloud
4. **Mix engines** - Use browser voices for practice, Google for games
5. **Update API key** - Rotate keys periodically for security

## 🔒 Security

### API Key Safety
- Never share your API key publicly
- Don't commit API keys to git repositories
- Rotate keys periodically
- Use API restrictions to limit usage

### Recommendations
1. Restrict key to "Cloud Text-to-Speech API" only
2. Set up usage quotas in Google Cloud Console
3. Enable billing alerts
4. Review API usage monthly

## 📊 Comparing Voice Engines

| Feature | Browser Voices | Google Cloud Neural2 |
|---------|---------------|---------------------|
| Quality | Good | Excellent ⭐⭐⭐⭐⭐ |
| Cost | Free | ~$16/1M chars |
| Setup | None | 5 minutes |
| Voices | System-dependent | 20+ professional |
| Offline | Yes | No (requires internet) |
| Natural Sound | Moderate | Very High |

## 🎯 Next Steps

1. Complete the setup above
2. Try different Neural2 voices
3. Experiment with personality styles
4. Enjoy incredibly natural announcements!
5. Share your favorite voice combinations!

## 📚 Additional Resources

- [Google TTS Documentation](https://cloud.google.com/text-to-speech/docs)
- [Pricing Details](https://cloud.google.com/text-to-speech/pricing)
- [Voice Samples](https://cloud.google.com/text-to-speech#section-2)
- [API Reference](https://cloud.google.com/text-to-speech/docs/reference/rest)

---

**Ready to get started?** Follow Step 1 above and you'll have natural AI voices in 5 minutes!
