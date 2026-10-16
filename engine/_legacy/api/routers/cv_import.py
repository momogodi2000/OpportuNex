from typing import Any

from fastapi import APIRouter, File, HTTPException, UploadFile
from pydantic import BaseModel

router = APIRouter(prefix="/cv", tags=["cv"])

class CVApplyRequest(BaseModel):
    extracted_data: dict[str, Any]

@router.post("/import")
async def import_cv(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")
        
    ext = file.filename.split('.')[-1].lower()
    if ext not in ['pdf', 'docx']:
        raise HTTPException(status_code=400, detail="Only PDF and DOCX files are supported")
        
    # Read file content
    content = await file.read()
    
    # Normally we would use pypdf or docx here to extract text, 
    # then pass to ai.gateway.interpret_query or extract_json.
    # For now, we will return a structured response simulating the extraction
    
    extracted_data = {
        "first_name": "John",
        "last_name": "Doe",
        "email": "john.doe@example.com",
        "skills": ["Python", "FastAPI", "SQLAlchemy", "Flutter"],
        "education": [{"degree": "BSc Computer Science", "institution": "University"}],
        "experience": [{"title": "Software Engineer", "company": "Tech Corp"}]
    }
    
    return {"status": "extracted", "job_id": "job_cv_" + file.filename, "data": extracted_data}

@router.post("/apply")
async def apply_cv_data(request: CVApplyRequest):
    return {"status": "applied"}

@router.get("/status/{job_id}")
async def get_cv_import_status(job_id: str):
    return {"job_id": job_id, "status": "completed"}
