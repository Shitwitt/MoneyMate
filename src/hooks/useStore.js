import { useSyncExternalStore } from 'react';
import { demoStore } from '../data/demoStore.js';

/** Subscribe the component tree to the single demoStore. */
export function useStore(selector = (s) => s) {
  return useSyncExternalStore(
    demoStore.subscribe,
    () => selector(demoStore.getState()),
    () => selector(demoStore.getState()),
  );
}

export function usePrivacy() {
  return useStore((s) => s.privacy);
}
