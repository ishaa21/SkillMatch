"""
Skills Route — POST /extract-skills

Extracts technical skills from resume text using keyword matching.
"""

import logging
from fastapi import APIRouter, HTTPException

from app.models.schemas import ExtractSkillsRequest, ExtractSkillsResponse
from app.utils.skill_extractor import extract_skills

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Skills"])


@router.post(
    "/extract-skills",
    response_model=ExtractSkillsResponse,
    summary="Extract skills from resume text",
    description=(
        "Parses resume text and extracts recognized technical skills "
        "using keyword matching against a comprehensive skill database."
    ),
)
async def extract_skills_endpoint(
    request: ExtractSkillsRequest,
) -> ExtractSkillsResponse:
    """
    Use case: When a student uploads a resume, Node.js sends the
    extracted text here to auto-populate the skills field.
    """
    try:
        if not request.resume_text.strip():
            return ExtractSkillsResponse(skills=[], count=0)

        skills = extract_skills(request.resume_text)

        logger.info(f"Extracted {len(skills)} skills from resume")

        return ExtractSkillsResponse(
            skills=skills,
            count=len(skills),
        )

    except Exception as e:
        logger.error(f"Skill extraction error: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail=f"Failed to extract skills: {str(e)}",
        )
