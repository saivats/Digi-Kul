import axios from "axios";
import { getToken, clearAuth } from "./auth";
import { API_URL } from "./env";

const api = axios.create({
  baseURL: API_URL,
  headers: { "Content-Type": "application/json" },
});

api.interceptors.request.use((config) => {
  const token = getToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    const status = error.response?.status;
    const url: string = error.config?.url ?? "";
    // A 401 from the login/refresh endpoints is a bad credential, not an
    // expired session — let the form show the error instead of reloading.
    const isAuthCall = url.includes("/api/auth/login") || url.includes("/api/auth/refresh");
    if (status === 401 && !isAuthCall) {
      clearAuth();
      if (typeof window !== "undefined" && !window.location.pathname.startsWith("/login")) {
        window.location.href = "/login";
      }
    }
    return Promise.reject(error);
  }
);

export default api;

export async function login(
  email: string,
  password: string,
  userType: string
) {
  const { data } = await api.post("/api/auth/login", {
    email,
    password,
    user_type: userType,
  });
  return data;
}

export async function logout() {
  const { data } = await api.post("/api/auth/logout");
  return data;
}

export async function validateSession() {
  const { data } = await api.get("/api/auth/validate-session");
  return data;
}

export async function fetchHealth() {
  const { data } = await api.get("/api/health");
  return data;
}

export async function listCohorts() {
  const { data } = await api.get("/api/cohorts");
  return data;
}

export async function getCohort(cohortId: string) {
  const { data } = await api.get(`/api/cohorts/${cohortId}`);
  return data;
}

export async function createCohort(body: {
  name: string;
  description?: string;
  enrollment_code: string;
  max_students?: number;
  academic_year?: string;
  semester?: number;
  start_date?: string;
  end_date?: string;
}) {
  const { data } = await api.post("/api/cohorts", body);
  return data;
}

export async function getCohortStudents(cohortId: string) {
  const { data } = await api.get(`/api/cohorts/${cohortId}/students`);
  return data;
}

export async function listLectures() {
  const { data } = await api.get("/api/lectures");
  return data;
}

export async function listLecturesByCohort(cohortId: string) {
  const { data } = await api.get(`/api/lectures/cohort/${cohortId}`);
  return data;
}

export async function createLecture(body: {
  cohort_id: string;
  title: string;
  description?: string;
  scheduled_time: string;
  duration?: number;
}) {
  const { data } = await api.post("/api/lectures", body);
  return data;
}

export async function startLecture(lectureId: string) {
  const { data } = await api.post(`/api/lectures/${lectureId}/start`);
  return data;
}

export async function endLecture(lectureId: string) {
  const { data } = await api.post(`/api/lectures/${lectureId}/end`);
  return data;
}

export async function listStudents() {
  const { data } = await api.get("/api/students");
  return data;
}

export async function listTeachers() {
  const { data } = await api.get("/api/teachers");
  return data;
}

export async function listQuizSets(cohortId: string) {
  const { data } = await api.get(`/api/quizzes/sets/cohort/${cohortId}`);
  return data;
}

export async function getTeacherProfile() {
  const { data } = await api.get("/api/teachers/me");
  return data;
}

export async function getStudentProfile() {
  const { data } = await api.get("/api/students/me");
  return data;
}

export async function listInstitutions() {
  const { data } = await api.get("/api/institutions");
  return data;
}

export interface InstitutionPayload {
  name?: string;
  domain?: string;
  subdomain?: string;
  description?: string;
  contact_email?: string;
  contact_phone?: string;
  address?: string;
  website?: string;
  primary_color?: string;
  is_active?: boolean;
}

export async function createInstitution(body: InstitutionPayload) {
  const { data } = await api.post("/api/institutions", body);
  return data;
}

export async function updateInstitution(id: string, body: InstitutionPayload) {
  const { data } = await api.patch(`/api/institutions/${id}`, body);
  return data;
}

export async function deleteInstitution(id: string) {
  const { data } = await api.delete(`/api/institutions/${id}`);
  return data;
}

export async function getPlatformStats() {
  const { data } = await api.get("/api/super-admin/platform-stats");
  return data;
}

export async function getInstitutionStats(institutionId: string) {
  const { data } = await api.get(`/api/institutions/${institutionId}/stats`);
  return data;
}


// ---- student (web) --------------------------------------------------------
export async function getStudentDashboard() {
  const { data } = await api.get("/api/students/dashboard");
  return data;
}

export async function listStudentCohorts() {
  const { data } = await api.get("/api/students/cohorts");
  return data;
}

export async function listStudentQuizHistory() {
  const { data } = await api.get("/api/students/quiz-history");
  return data;
}

export async function listStudentLectures() {
  const { data } = await api.get("/api/students/lectures");
  return data;
}

export async function listStudentMaterials() {
  const { data } = await api.get("/api/students/materials");
  return data;
}

export async function joinCohortByCode(enrollment_code: string) {
  const { data } = await api.post("/api/cohorts/join", { enrollment_code });
  return data;
}

/** Download an uploaded material through the authenticated API. */
export async function downloadMaterial(materialId: string, fileName: string) {
  const res = await api.get(`/api/materials/${materialId}/file`, { responseType: "blob" });
  const url = URL.createObjectURL(res.data as Blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}

// ---- admin ---------------------------------------------------------------
export async function toggleStudentActive(studentId: string) {
  const { data } = await api.post(`/api/students/${studentId}/toggle-active`);
  return data;
}

export async function toggleTeacherActive(teacherId: string) {
  const { data } = await api.post(`/api/teachers/${teacherId}/toggle-active`);
  return data;
}

export async function registerTeacher(body: {
  name: string;
  email: string;
  password: string;
  institution_id: string;
  subject: string;
}) {
  const { data } = await api.post("/api/auth/register/teacher", body);
  return data;
}

export async function listCohortMaterials(cohortId: string) {
  const { data } = await api.get(`/api/materials/cohort/${cohortId}`);
  return data;
}

export async function uploadMaterial(form: FormData, params: { cohort_id?: string; lecture_id?: string; title?: string; description?: string }) {
  const { data } = await api.post("/api/materials", form, {
    params,
    headers: { "Content-Type": "multipart/form-data" },
  });
  return data;
}

export async function deleteMaterial(materialId: string) {
  const { data } = await api.delete(`/api/materials/${materialId}`);
  return data;
}

export async function deleteLecture(lectureId: string) {
  const { data } = await api.delete(`/api/lectures/${lectureId}`);
  return data;
}

export async function getLecture(lectureId: string) {
  const { data } = await api.get(`/api/lectures/${lectureId}`);
  return data;
}
