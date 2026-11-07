/* Built-in avatar artwork, encoded as data URLs so profile photos work
   offline and persist directly in localStorage. */

const svg = (body) => `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 140"><defs><radialGradient id="g" cx="35%" cy="25%"><stop offset="0" stop-color="#5A2D44"/><stop offset="1" stop-color="#150A12"/></radialGradient></defs><rect width="140" height="140" rx="70" fill="url(#g)"/>${body}</svg>`)}`;

export const PRESET_AVATARS = [
  {
    id: 'floral',
    label: 'Midnight floral',
    src: svg(Array.from({ length: 14 }, (_, i) => {
      const a = (i / 14) * Math.PI * 2;
      const x = 70 + Math.cos(a) * 28;
      const y = 70 + Math.sin(a) * 28;
      return `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="15" fill="#B5125B" opacity=".92"/><circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="8" fill="#F20574" opacity=".9"/><circle cx="${x + 3}" cy="${y + 2}" r="3" fill="#FFC7E7"/>`;
    }).join('') + '<circle cx="70" cy="70" r="18" fill="#081015"/><circle cx="64" cy="66" r="3" fill="#F7D774"/><circle cx="78" cy="72" r="2" fill="#F7D774"/>'),
  },
  { id: 'peach', label: 'Peach', src: svg('<circle cx="70" cy="52" r="25" fill="#FBB69D"/><path d="M24 133c3-30 22-47 46-47s43 17 46 47" fill="#FBB69D"/><circle cx="60" cy="50" r="3" fill="#2B150D"/><circle cx="80" cy="50" r="3" fill="#2B150D"/><path d="M61 64q9 8 18 0" stroke="#2B150D" stroke-width="3" fill="none" stroke-linecap="round"/>') },
  { id: 'mint', label: 'Mint', src: svg('<circle cx="70" cy="52" r="25" fill="#B3DFDB"/><path d="M24 133c3-30 22-47 46-47s43 17 46 47" fill="#4EB7AD"/><circle cx="60" cy="50" r="3" fill="#173B38"/><circle cx="80" cy="50" r="3" fill="#173B38"/><path d="M61 64q9 8 18 0" stroke="#173B38" stroke-width="3" fill="none" stroke-linecap="round"/>') },
  { id: 'indigo', label: 'Indigo', src: svg('<circle cx="70" cy="52" r="25" fill="#B9BEF4"/><path d="M24 133c3-30 22-47 46-47s43 17 46 47" fill="#5C6BC0"/><circle cx="60" cy="50" r="3" fill="#171A3A"/><circle cx="80" cy="50" r="3" fill="#171A3A"/><path d="M61 64q9 8 18 0" stroke="#171A3A" stroke-width="3" fill="none" stroke-linecap="round"/>') },
  { id: 'gold', label: 'Gold', src: svg('<circle cx="70" cy="52" r="25" fill="#F3D18B"/><path d="M24 133c3-30 22-47 46-47s43 17 46 47" fill="#D89A35"/><circle cx="60" cy="50" r="3" fill="#3B2219"/><circle cx="80" cy="50" r="3" fill="#3B2219"/><path d="M61 64q9 8 18 0" stroke="#3B2219" stroke-width="3" fill="none" stroke-linecap="round"/>') },
];

export const DEFAULT_AVATAR = PRESET_AVATARS[0].src;

export function avatarInitials(name = '') {
  const parts = String(name).trim().split(/\s+/).filter(Boolean);
  if (!parts.length) return 'P';
  return (parts[0][0] + (parts.length > 1 ? parts[parts.length - 1][0] : '')).toUpperCase();
}

export function readImageFile(file) {
  return new Promise((resolve, reject) => {
    if (!file) return reject(new Error('No file selected'));
    const reader = new FileReader();
    reader.onload = () => resolve(String(reader.result || ''));
    reader.onerror = () => reject(reader.error || new Error('Could not read image'));
    reader.readAsDataURL(file);
  });
}
