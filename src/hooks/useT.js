import { useCallback } from 'react';
import { useStore } from './useStore.js';
import { t } from '../data/i18n.js';

/** Returns a stable translator bound to the persisted app language. */
export function useT() {
  const language = useStore((s) => s.language || 'en');
  return useCallback((key, fallback) => t(key, language, fallback), [language]);
}
