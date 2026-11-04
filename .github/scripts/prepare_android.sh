#!/usr/bin/env bash
# Flutter 3.47's recommended NDK. Retry transient SDK ZIP/download failures.
set -euo pipefail
version=28.2.13676358
: "${ANDROID_HOME:?Android SDK is required}"
sdkmanager="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager"
echo "::notice title=Android SDK::Available disk: $(df -h / | tail -1); installed NDKs: $(ls "$ANDROID_HOME/ndk" 2>/dev/null | tr '\n' ' ')"
if [[ "${GITHUB_ACTIONS:-false}" == true ]] && (( $(df -Pm / | tail -1 | awk '{print $4}') < 18000 )); then
  # Hosted runners are ephemeral; these unrelated SDKs are never app inputs.
  sudo rm -rf /usr/share/dotnet /opt/ghc /usr/local/share/boost
fi
for attempt in 1 2 3; do
  if [[ -f "$ANDROID_HOME/ndk/$version/source.properties" && -x "$ANDROID_HOME/ndk/$version/toolchains/llvm/prebuilt/linux-x86_64/bin/clang" ]]; then
    echo "NDK $version is ready"
    exit 0
  fi
  if "$sdkmanager" --install "ndk;$version"; then
    echo "NDK $version installed"
    exit 0
  fi
  echo "Retrying failed Android NDK download ($attempt/3)"
  if [[ "${GITHUB_ACTIONS:-false}" == true ]]; then
    rm -rf "$ANDROID_HOME/ndk/$version" "$ANDROID_HOME/.temp" "$HOME/.android/cache"
  fi
done
echo 'Android NDK could not be installed after three attempts' >&2
exit 1
