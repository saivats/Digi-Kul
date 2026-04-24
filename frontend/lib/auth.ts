const TOKEN_KEY = "digi_kul_token";
const USER_KEY = "digi_kul_user";

export interface AuthUser {
  user_id: string;
  user_type: string;
  user_name: string;
  user_email: string;
  institution_id?: string;
  cohort_id?: string;
}

export function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token);
}

export function getUser(): AuthUser | null {
  if (typeof window === "undefined") return null;
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as AuthUser;
  } catch {
    return null;
  }
}

export function setUser(user: AuthUser): void {
  localStorage.setItem(USER_KEY, JSON.stringify(user));
}

export function saveAuth(token: string, user: AuthUser): void {
  setToken(token);
  setUser(user);
}

export function clearAuth(): void {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
}

export function isAuthenticated(): boolean {
  return !!getToken();
}

export function getDashboardPath(userType: string): string {
  switch (userType) {
    case "teacher":
      return "/dashboard/teacher";
    case "student":
      return "/dashboard/student";
    case "institution_admin":
      return "/dashboard/admin";
    case "super_admin":
    case "admin":
      return "/dashboard/admin";
    default:
      return "/login";
  }
}
