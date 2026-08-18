export type Role = 'mentor' | 'mentee'
export type ApplicationStatus = 'pending' | 'viewed' | 'accepted' | 'rejected'
export type ProjectRequestStatus = 'pending' | 'accepted' | 'rejected'
export type AccountStatus = 'pending' | 'active' | 'paused' | 'suspended' | 'deactivated'
export type DocType =
  | 'terms_of_service'
  | 'privacy_policy'
  | 'code_of_conduct'
  | 'mentor_agreement'
  | 'mentor_nda'
  | 'marketing_consent'

export interface Profile {
  id: string
  full_name: string
  email: string
  phone: string | null
  role: Role
  account_status: AccountStatus
  rejection_reason: string | null
  reviewed_by: string | null
  reviewed_at: string | null
  specialization: string | null
  motivation: string | null
  linkedin_url: string | null
  institution: string | null
  title: string | null
  photo_url: string | null
  created_at: string
  updated_at: string
}

export interface PlatformDocument {
  id: string
  doc_type: DocType
  version: string
  title: string
  body_url: string | null
  body_text: string | null
  applies_to_role: 'mentor' | 'mentee' | 'all'
  is_active: boolean
  created_at: string
}

export interface UserConsent {
  id: string
  user_id: string
  document_id: string
  doc_type: DocType
  version: string
  method: string
  signed_at: string
}

export interface ResearchOpportunity {
  id: string
  mentor_id: string
  title: string
  description: string
  tags: string[]
  total_spots: number
  filled_spots: number
  is_open: boolean
  duration: string | null
  contact_email?: string | null
  contact_telegram?: string | null
  created_at: string
  updated_at: string
  mentor?: Pick<Profile, 'full_name' | 'institution' | 'specialization'>
}

export interface Application {
  id: string
  mentee_id: string
  opportunity_id: string
  motivation_text: string
  cv_url: string | null
  status: ApplicationStatus
  created_at: string
  updated_at: string
  mentee?: Pick<Profile, 'full_name' | 'email' | 'institution' | 'specialization' | 'linkedin_url'>
  opportunity?: Pick<ResearchOpportunity, 'title' | 'tags' | 'contact_email' | 'contact_telegram'> & {
    mentor?: Pick<Profile, 'full_name' | 'email' | 'linkedin_url'>
  }
}

export interface Project {
  id: string
  creator_id: string
  title: string
  description: string
  tags: string[]
  contact_email: string | null
  contact_telegram: string | null
  deadline: string | null
  max_members: number
  filled_members: number
  is_open: boolean
  created_at: string
  updated_at: string
  creator?: Pick<Profile, 'full_name' | 'email' | 'institution'>
}

export interface ProjectRequest {
  id: string
  project_id: string
  requester_id: string
  message: string | null
  status: ProjectRequestStatus
  created_at: string
  updated_at: string
  user?: Pick<Profile, 'full_name' | 'email' | 'institution'>
  project?: Pick<Project, 'title'>
}