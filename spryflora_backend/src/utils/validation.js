export const isValidEmail = (email) => {
  if (!email || typeof email !== 'string') return false;
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email.trim().toLowerCase());
};

export const sanitizeString = (str, fallback = '') => {
  if (typeof str !== 'string') return fallback;
  return str.trim();
};
