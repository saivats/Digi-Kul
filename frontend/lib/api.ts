import axios from "axios";
import { getToken, clearAuth } from "./auth";

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000";

const api = axios.create({
  baseURL: API_BASE_URL,
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
    if (error.response?.status === 401) {
      clearAuth();
      if (typeof window !== "undefined") {
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

export async function createInstitution(body: any) {
  const { data } = await api.post("/api/institutions", body);
  return data;
}

export async function updateInstitution(id: string, body: any) {
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
