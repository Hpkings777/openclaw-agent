#!/usr/bin/env bash
set -euo pipefail

DECODE_DIR="${1:?Usage: $0 <apktool-decode-dir>}"
echo "[patch] Patching APK decode at: $DECODE_DIR"

# =====================
# 1. AndroidManifest.xml
# =====================
echo "[patch] Patching AndroidManifest.xml..."
cd "$DECODE_DIR"

# Package rename
sed -i 's/package="com\.moonshot\.kimiclaw"/package="org.openclaw.agent"/' AndroidManifest.xml
sed -i 's|sharedUserId="com\.moonshot\.kimiclaw"|sharedUserId="org.openclaw.agent"|' AndroidManifest.xml
# Permission
sed -i 's|android:name="com\.moonshot\.kimiclaw\.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"|android:name="org.openclaw.agent.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"|g' AndroidManifest.xml
# Authorities
sed -i 's|android:authorities="com\.moonshot\.kimiclaw\.|android:authorities="org.openclaw.agent.|g' AndroidManifest.xml
# Queries
sed -i 's|<package android:name="com\.moonshot\.kimichat"/>|<package android:name="org.openclaw.chat"/>|' AndroidManifest.xml
# Component class paths
sed -i 's|android:name="com\.moonshot\.kimiclaw\.MainActivity"|android:name="org.openclaw.agent.MainActivity"|' AndroidManifest.xml
sed -i 's|android:name="com\.moonshot\.kimiclaw\.KimiClawService"|android:name="org.openclaw.agent.AgentService"|' AndroidManifest.xml
sed -i 's|android:name="com\.moonshot\.kimiclaw\.api\.automation\.KimiClawAccessibilityService"|android:name="org.openclaw.agent.api.automation.AgentAccessibilityService"|' AndroidManifest.xml
sed -i 's|android:name="com\.moonshot\.kimiclaw\.api\.automation\.KimiClawNotificationService"|android:name="org.openclaw.agent.api.automation.AgentNotificationService"|' AndroidManifest.xml
sed -i 's|android:name="com\.moonshot\.kimiclaw\.api\.automation\.KimiClawIME"|android:name="org.openclaw.agent.api.automation.AgentIME"|' AndroidManifest.xml
# XML resource references
sed -i 's|@xml/kimiclaw_ime_config|@xml/agent_ime_config|' AndroidManifest.xml
sed -i 's|@xml/kimi_claw_accessibility_config|@xml/agent_accessibility_config|' AndroidManifest.xml

# Add ApiConfigActivity before first ByteDance entry
sed -i '/name="com.bytedance.applog.migrate.MigrateDetectorActivity"/i\        <activity android:exported="true" android:name="org.openclaw.agent.ApiConfigActivity" android:theme="@style/Theme.TermuxApp.DayNight.DarkActionBar">\n            <intent-filter>\n                <action android:name="org.openclaw.agent.action.API_CONFIG" />\n                <category android:name="android.intent.category.DEFAULT" />\n            </intent-filter>\n        </activity>' AndroidManifest.xml

# =====================
# 2. Smali package rename
# =====================
echo "[patch] Renaming package in smali code..."
find smali -name "*.smali" -exec sed -i 's#com/moonshot/kimiclaw#org/openclaw/agent#g' {} +
if [ -d smali_classes2 ]; then
  find smali_classes2 -name "*.smali" -exec sed -i 's#com/moonshot/kimiclaw#org/openclaw/agent#g' {} +
fi

# =====================
# 3. Class rename (KimiClaw -> Agent)
# =====================
echo "[patch] Renaming KimiClaw -> Agent in smali..."
find smali -name "*.smali" -exec sed -i 's|KimiClaw|Agent|g' {} +
if [ -d smali_classes2 ]; then
  find smali_classes2 -name "*.smali" -exec sed -i 's|KimiClaw|Agent|g' {} +
fi

# =====================
# 4. API URL replacement
# =====================
echo "[patch] Replacing API URLs..."
find smali -name "*.smali" -exec sed -i 's|https://api.kimi.com/coding/v1|https://api.openai.com/v1|g' {} +
find smali -name "*.smali" -exec sed -i 's|https://api.kimi.com/coding|https://api.openai.com/v1|g' {} +
if [ -d smali_classes2 ]; then
  find smali_classes2 -name "*.smali" -exec sed -i 's|https://api.kimi.com/coding/v1|https://api.openai.com/v1|g' {} +
  find smali_classes2 -name "*.smali" -exec sed -i 's|https://api.kimi.com/coding|https://api.openai.com/v1|g' {} +
fi

# =====================
# 5. Smali directory rename
# =====================
echo "[patch] Renaming smali directories..."
if [ -d smali/org ]; then
  rm -rf smali/org
fi
if [ -d smali/com/moonshot/kimiclaw ]; then
  mkdir -p smali/org/openclaw/agent
  mv smali/com/moonshot/kimiclaw/* smali/org/openclaw/agent/
  rm -rf smali/com
fi

# =====================
# 6. Smali file rename (KimiClaw -> Agent)
# =====================
echo "[patch] Renaming smali files..."
find smali -name "*KimiClaw*" -type f | while read -r f; do
  nf=$(echo "$f" | sed 's/KimiClaw/Agent/g')
  mv "$f" "$nf"
  echo "  Renamed: $(basename "$f") -> $(basename "$nf")"
done

# =====================
# 7. Resource XML files
# =====================
echo "[patch] Updating resource XML files..."
# Copy accessibility config to new name
if [ -f res/xml/kimi_claw_accessibility_config.xml ]; then
  cp res/xml/kimi_claw_accessibility_config.xml res/xml/agent_accessibility_config.xml
  rm res/xml/kimi_claw_accessibility_config.xml
fi
# Copy IME config to new name
if [ -f res/xml/kimiclaw_ime_config.xml ]; then
  cp res/xml/kimiclaw_ime_config.xml res/xml/agent_ime_config.xml
  rm res/xml/kimiclaw_ime_config.xml
fi
# Update IME label
if [ -f res/xml/agent_ime_config.xml ]; then
  sed -i 's|android:label="KimiClaw"|android:label="OpenClaw Agent"|' res/xml/agent_ime_config.xml
fi

# =====================
# 8. public.xml — remove old entries, let aapt2 assign IDs to new files
# =====================
echo "[patch] Updating public.xml..."
sed -i '/name="kimi_claw_accessibility_config"/d' res/values/public.xml
sed -i '/name="kimiclaw_ime_config"/d' res/values/public.xml

# =====================
# 9. strings.xml (branding)
# =====================
echo "[patch] Updating branding strings..."
sed -i 's|Kimi Claw|OpenClaw Agent|g' res/values/strings.xml
sed -i 's|KimiClaw|OpenClaw Agent|g' res/values/strings.xml
sed -i 's|"com\.moonshot\.kimiclaw|"org.openclaw.agent|g' res/values/strings.xml
sed -i 's|com\.moonshot\.kimiclaw|org.openclaw.agent|g' res/values/strings.xml

# =====================
# 10. termux_preferences.xml (API Config entry)
# =====================
echo "[patch] Adding API Config to termux_preferences.xml..."
if [ -f res/xml/termux_preferences.xml ]; then
  sed -i 's|<PreferenceScreen xmlns:app="http://schemas.android.com/apk/res-auto">|<PreferenceScreen xmlns:android="http://schemas.android.com/apk/res/android" xmlns:app="http://schemas.android.com/apk/res-auto">|' res/xml/termux_preferences.xml
  sed -i '/<\/PreferenceScreen>/i\    <Preference app:summary="Configure API providers and keys" app:title="API Configuration">\n        <intent android:action="org.openclaw.agent.action.API_CONFIG" android:targetClass="org.openclaw.agent.ApiConfigActivity" android:targetPackage="org.openclaw.agent" />\n    </Preference>' res/xml/termux_preferences.xml
fi

# =====================
# 11. config.toml (BYOK)
# =====================
echo "[patch] Updating config.toml..."
CONFIG="assets/config.toml"
if [ -f "$CONFIG" ]; then
  sed -i 's|type = "kimi"|type = "openai-compatible"|' "$CONFIG"
  sed -i 's|https://api.kimi.com/coding/v1|https://api.openai.com/v1|g' "$CONFIG"
  sed -i 's|api_key = ""|api_key = "YOUR_API_KEY_HERE"|' "$CONFIG"
fi

# =====================
# 12. Clean remaining Moonshot path references in non-smali text files
# =====================
echo "[patch] Cleaning remaining path references..."
find res/values -name "*.xml" -exec sed -i 's|"com\.moonshot\.kimiclaw|"org.openclaw.agent|g' {} +
find assets -name "*.md" -exec sed -i 's|com\.moonshot\.kimiclaw|org.openclaw.agent|g' {} +
# Note: resource NAMES (drawable/kimiclaw, raw/kimiclaw, etc.) are kept as-is
# Only the values in strings.xml were changed above in step 9

# =====================
# 13. Verify
# =====================
echo ""
echo "========== VERIFICATION =========="
REMAINING=$(grep -rl "com/moonshot/kimiclaw" . 2>/dev/null | wc -l || echo 0)
echo "Remaining com.moonshot.kimiclaw refs: $REMAINING"
if [ "$REMAINING" -gt 0 ]; then
  echo "WARNING: Found files:"
  grep -rl "com/moonshot/kimiclaw" . 2>/dev/null
fi

REMAINING_KIMI=$(grep -r "KimiClaw" . --include="*.smali" 2>/dev/null | wc -l || echo 0)
echo "Remaining KimiClaw in smali: $REMAINING_KIMI"

REMAINING_URL=$(grep -r "api.kimi.com" . --include="*.smali" 2>/dev/null | wc -l || echo 0)
echo "Remaining api.kimi.com in smali: $REMAINING_URL"

echo ""
echo "[patch] Done! Package: org.openclaw.agent"
