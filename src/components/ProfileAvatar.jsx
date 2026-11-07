import React from 'react';

import { demoStore } from '../data/demoStore.js';
import { avatarInitials } from '../data/avatars.js';
import { useStore } from '../hooks/useStore.js';

/**
 * Circular profile control used by every main-app header. Shows the uploaded
 * Base64 photo, a built-in avatar, or the user's initials.
 */
export default function ProfileAvatar({ className = 'avatar-btn', onClick, label, small = false }) {
  const name = useStore((s) => s.profile.name);
  const photo = useStore((s) => s.profile.photo);
  const initials = avatarInitials(name);
  return (
    <button
      type="button"
      className={`profile-avatar ${className}${small ? ' small' : ''}`.trim()}
      aria-label={label || `Profile: ${name || 'Paisa'}`}
      onClick={onClick || demoStore.openProfile}
    >
      {photo ? (
        <img src={photo} alt="" className="profile-avatar-img" />
      ) : (
        <span className="profile-avatar-initials">{initials}</span>
      )}
    </button>
  );
}
