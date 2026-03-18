"""
Pydantic models for request/response validation.
Every API request and response is strictly typed.
"""

from pydantic import BaseModel, Field
from typing import Optional


# ═══════════════════════════════════════════════════════════
# RECOMMENDATION MODELS
# ═══════════════════════════════════════════════════════════

class InternshipInput(BaseModel):
    """
    Represents a single internship posting sent from Node.js.
    Fields match what the Node.js backend sends from MongoDB.
    """
    id: str = Field(..., description="MongoDB ObjectId as string")
    title: str = Field(..., description="Internship title")
    description: str = Field(default="", description="Full internship description")
    required_skills: list[str] = Field(default_factory=list, description="List of required skill names")
    domains: list[str] = Field(default_factory=list, description="Domain categories, e.g. ['Web Development', 'AI']")
    location: str = Field(default="", description="Location string, e.g. 'Mumbai, India' or 'Remote'")
    work_mode: str = Field(default="Remote", description="Remote | On-site | Hybrid")
    company_name: str = Field(default="", description="Name of the company")


class RecommendRequest(BaseModel):
    """
    Input payload for the /recommend endpoint.
    Node.js sends the student profile + list of internships to rank.
    """
    student_skills: list[str] = Field(
        default_factory=list,
        description="Student's skill names, e.g. ['Python', 'Flutter', 'MongoDB']"
    )
    resume_text: str = Field(
        default="",
        description="Plain text of the student's resume (or bio)"
    )
    preferred_domain: str = Field(
        default="",
        description="Student's preferred domain, e.g. 'Web Development'"
    )
    preferred_location: str = Field(
        default="",
        description="Student's preferred location, e.g. 'Bangalore'"
    )
    internships: list[InternshipInput] = Field(
        ...,
        description="List of internships to rank"
    )


class ScoreBreakdown(BaseModel):
    """Detailed score breakdown for transparency."""
    skills: float = Field(..., description="Skills similarity score contribution (0-40)")
    resume: float = Field(..., description="Resume-description similarity contribution (0-30)")
    domain: float = Field(..., description="Domain match contribution (0-15)")
    location: float = Field(..., description="Location match contribution (0-15)")


class RecommendationItem(BaseModel):
    """A single recommendation result."""
    id: str = Field(..., description="Internship ID from MongoDB")
    title: str = Field(default="", description="Internship title for convenience")
    company_name: str = Field(default="", description="Company name for convenience")
    score: int = Field(..., description="Final normalized score (0-100)")
    breakdown: ScoreBreakdown = Field(..., description="Per-factor score breakdown")
    explanation: str = Field(
        default="", 
        description="Human-readable explanation of why this internship was recommended"
    )
    skill_gaps: list[str] = Field(
        default_factory=list,
        description="Skills required by this internship that the student is missing"
    )


class RecommendResponse(BaseModel):
    """Response from the /recommend endpoint."""
    recommendations: list[RecommendationItem] = Field(
        ...,
        description="Ranked list of internship recommendations"
    )
    total: int = Field(..., description="Total number of recommendations returned")
    weights_used: dict[str, float] = Field(
        ...,
        description="The weight configuration used for this ranking"
    )


# ═══════════════════════════════════════════════════════════
# SKILL EXTRACTION MODELS
# ═══════════════════════════════════════════════════════════

class ExtractSkillsRequest(BaseModel):
    """Input for the /extract-skills endpoint."""
    resume_text: str = Field(
        ...,
        description="Plain text of the resume to extract skills from"
    )


class ExtractSkillsResponse(BaseModel):
    """Response from the /extract-skills endpoint."""
    skills: list[str] = Field(
        ...,
        description="Extracted skill names, deduplicated and lowercased"
    )
    count: int = Field(..., description="Number of skills extracted")


# ═══════════════════════════════════════════════════════════
# HEALTH CHECK
# ═══════════════════════════════════════════════════════════

class HealthResponse(BaseModel):
    """Response from the /health endpoint."""
    status: str = Field(default="ok")
    model_loaded: bool = Field(..., description="Whether the ML model is loaded and ready")
    version: str = Field(default="1.0.0")
