#!/usr/bin/env python3
"""Apply reviewed portable T3 preferences without replacing device-owned settings."""
import argparse
import datetime
import json
import os
from pathlib import Path
import tempfile

SERVER_KEYS = set('''favorites providerModelPreferences storageCleanup responseStreamingMode
 enableProviderUpdateChecks continueThreadsAfterServerUpdate enableAgentBrowserAccess
 defaultAutoPull defaultProjectScripts defaultModelSelection fallbackModelSelection
 defaultRuntimeMode enableAgentDeviceAccess enableDeviceSupport sidebarAutoSettleAfterDays
 compactIdleThreads idleCompaction snoozeLimitedThreads autoResumeLimitedThreads snoozePresets
 hiddenThreadTags hideTaggedThreads guestSharingEnabled linkedEnvironmentsEnabled
 sidebarAutoSettleKeepPullRequests sidebarAutoSettleOnMerge backgroundActivity
 automaticGitFetchInterval providerHealthRefreshInterval backgroundActivityProfile
 defaultThreadEnvMode newWorktreesStartFromOrigin worktreeSubmodules addProjectBaseDirectory
 textGenerationModelSelection threadTitleInstructions branchNamingMode branchNamePrefix
 branchNameInstructions removeAgentCreditsOnMerge sourceControlWritingStyle
 sourceControlWriterModelSelection reviewGuidesEnabled reviewGuideModelSelection
 reviewGuideInstructions pullRequestMergeMethod cursorKeychainUsageEnabled
 usagePriceOverrides usageModelAliases usageModelFilter'''.split())
CLIENT_KEYS = set('''appearanceContrast browserAutoShowFloatingPreview browserDefaultAppearance browserDefaultProfileId
 browserDefaultViewport browserDefaultZoomFactor browserLinkTarget browserRecordingFrameRate
 browserRecordingShowKeyPresses browserRecordingShowMousePresses chatWidth composerCollapseOnScroll
 composerRichTextEnabled confirmQuit confirmThreadArchive confirmThreadDelete
 confirmThreadUnpin contextWindowMeterEnabled diffColorScheme diffFilesCollapsed
 diffIgnoreWhitespace diffLayout environmentIdentificationMode favorites
 followUpBehavior fontFamilyCode fontFamilyComposer fontFamilySans
 fontFamilyTerminal fontSizeCode fontSizeInterface fontSizePrompt
 fontSizeTerminal fontSmoothing glassOpacity inAppNotificationsEnabled
 legacySidebarEnabled loadBalancingEnabled loadBalancingWeights notificationMode
 panelAnimationDurationMs persistComposerContextStrip planModeEnabled proactivePanelsEnabled
 providerModelPreferences pullRequestLinksOpenInApp sendShortcut showSkillsInSlashMenu
 sidebarProjectGroupingMode sidebarProjectSortOrder sidebarThreadPreviewCount sidebarThreadSortOrder
 sidebarWorkingShelfEnabled snapShotAnimations snapShotEnabled snapShotFlash
 snapShotIncludeAccessibility snapShotPlaySound snapShotShortcut snapShotSound
 timestampFormat wordWrap'''.split())
# These refer to local browser instances, project/environment IDs, onboarding, or
# the versions installed on this particular machine. Keep existing target values.
LOCAL_CLIENT_KEYS = {
    'browserProfiles', 'sidebarProjectGroupingOverrides',
    'pullRequestMergeMethodOverrides', 'onboardingCompletedAt',
    'dismissedProviderUpdateNotificationKeys',
}
LINUX_NAVIGATION = [
    {'key': 'f6', 'command': 'workspace.focusNext'},
    {'key': 'shift+f6', 'command': 'workspace.focusPrevious'},
    {'key': 'mod+f6', 'command': 'workspace.focusNext'},
    {'key': 'mod+shift+f6', 'command': 'workspace.focusPrevious'},
]


def read(path, fallback):
    return json.loads(path.read_text()) if path.exists() else fallback


def write(path, value):
    old = read(path, None)
    if old == value:
        return False
    if path.exists():
        stamp = datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
        backup = path.with_name(path.name + '.before-portable-sync-' + stamp)
        with open(backup, 'x', opener=lambda p, f: os.open(p, f, 0o600)) as stream:
            stream.write(path.read_text())
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False) as stream:
        temporary = Path(stream.name)
        json.dump(value, stream, indent=2, ensure_ascii=False)
        stream.write('\n')
    try:
        temporary.chmod(0o600)
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, default=Path(__file__).parent)
    parser.add_argument('--destination', type=Path, default=Path.home() / '.t3/userdata')
    parser.add_argument('--platform', default=os.uname().sysname.lower())
    parser.add_argument('--defaults-only', action='store_true')
    args = parser.parse_args()
    args.destination.mkdir(parents=True, exist_ok=True, mode=0o700)
    changes = []
    for name in ['settings.json', 'client-settings.json', 'keybindings.json']:
        source = read(args.source / name, None)
        if source is None:
            raise ValueError(f'Missing reviewed source: {name}')
        target = args.destination / name
        if args.defaults_only and target.exists():
            existing = read(target, {})
            if isinstance(source, dict):
                source = {k: v for k, v in source.items() if k not in existing}
            else:
                continue
        if name == 'settings.json':
            unknown = source.keys() - SERVER_KEYS
            if unknown:
                raise ValueError('Review non-portable server keys before syncing: ' + ', '.join(sorted(unknown)))
            current = read(target, {})
            merged = {**current, **source}
            if 'sourceControlWritingStyle' in source:
                merged['sourceControlWritingStyle'] = {**current.get('sourceControlWritingStyle', {}), **source['sourceControlWritingStyle']}
                # Instructions are deliberately machine-owned and never published.
                if 'customInstructions' in current.get('sourceControlWritingStyle', {}):
                    merged['sourceControlWritingStyle']['customInstructions'] = current['sourceControlWritingStyle']['customInstructions']
        elif name == 'client-settings.json':
            unknown = source.keys() - CLIENT_KEYS - LOCAL_CLIENT_KEYS
            if unknown:
                raise ValueError('Review new client keys before syncing: ' + ', '.join(sorted(unknown)))
            current = read(target, {})
            merged = {**current, **{k: v for k, v in source.items() if k not in LOCAL_CLIENT_KEYS}}
            # Seed machine-owned defaults on a new installation without copying
            # another device's identifiers or onboarding completion timestamp.
            for key in ['browserProfiles', 'sidebarProjectGroupingOverrides', 'pullRequestMergeMethodOverrides', 'dismissedProviderUpdateNotificationKeys']:
                merged.setdefault(key, [] if key in ['browserProfiles', 'dismissedProviderUpdateNotificationKeys'] else {})
        else:
            merged = list(source)
            if 'linux' in args.platform:
                existing = read(target, [])
                for binding in LINUX_NAVIGATION:
                    if not any(b.get('key') == binding['key'] for b in merged):
                        local = [b for b in existing if b.get('key') == binding['key']]
                        merged.extend(local or [binding])
        if write(target, merged):
            changes.append(name)
    print('T3 portable settings: ' + (', '.join(changes) if changes else 'already current'))


if __name__ == '__main__':
    main()
