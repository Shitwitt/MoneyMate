import { useEffect, useReducer, useRef } from 'react';
import { demoStore } from '../data/demoStore.js';

/**
 * Subscribe to the live store.
 *
 * Unlike useSyncExternalStore's `getSnapshot`, selectors may return freshly
 * derived objects (weekly series, report data, grouped charts). We cache the
 * last value and use shallow equality so those selectors are safe and don't
 * trigger an infinite render loop.
 */
function shallowEqual(a, b) {
  if (Object.is(a, b)) return true;
  if (typeof a !== 'object' || typeof b !== 'object' || a === null || b === null) return false;
  const ka = Object.keys(a);
  const kb = Object.keys(b);
  if (ka.length !== kb.length) return false;
  return ka.every((k) => Object.prototype.hasOwnProperty.call(b, k) && Object.is(a[k], b[k]));
}

export function useStore(selector = (s) => s, equals) {
  const [, force] = useReducer((x) => x + 1, 0);
  const selectorRef = useRef(selector);
  const equalsRef = useRef(equals);
  const initialized = useRef(false);
  const valueRef = useRef();
  selectorRef.current = selector;
  equalsRef.current = equals;

  const isEqual = (a, b) => (equalsRef.current ? equalsRef.current(a, b) : shallowEqual(a, b));
  const compute = () => selectorRef.current(demoStore.getState());
  const current = compute();
  if (!initialized.current || !isEqual(valueRef.current, current)) {
    valueRef.current = current;
    initialized.current = true;
  }

  useEffect(() => {
    const check = (next) => {
      const nextValue = selectorRef.current(next);
      if (!isEqual(valueRef.current, nextValue)) {
        valueRef.current = nextValue;
        force();
      }
    };
    check(demoStore.getState());
    return demoStore.subscribe(check);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return valueRef.current;
}

export function usePrivacy() {
  return useStore((s) => s.privacy);
}

export function useBaseCurrency() {
  return useStore((s) => s.profile.baseCurrency);
}
