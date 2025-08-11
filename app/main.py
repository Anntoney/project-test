from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import logging
import os

# Set up logging - pretty basic but gets the job done
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Insight-Agent",
    description="AI-powered customer feedback analysis service",
    version="1.0.0"
)

# Request model - just needs the text to analyze
class TextAnalysisRequest(BaseModel):
    text: str

# Response model - gives back the original text plus some basic stats
class TextAnalysisResponse(BaseModel):
    original_text: str
    word_count: int
    character_count: int
    analysis_timestamp: str

@app.get("/health")
async def health_check():
    """Health check endpoint - load balancers and monitoring tools hit this"""
    return {"status": "healthy", "service": "insight-agent"}

@app.post("/analyze", response_model=TextAnalysisResponse)
async def analyze_text(request: TextAnalysisRequest):
    """
    Main endpoint - takes some text and spits back basic stats about it
    """
    try:
        if not request.text.strip():
            raise HTTPException(status_code=400, detail="Text cannot be empty")
        
        # Do the actual analysis - pretty simple stuff really
        text = request.text.strip()
        word_count = len(text.split())
        character_count = len(text)
        
        # Import datetime here to avoid startup overhead
        from datetime import datetime
        timestamp = datetime.utcnow().isoformat()
        
        logger.info(f"Analyzed text: {text[:50]}... (words: {word_count}, chars: {character_count})")
        
        return TextAnalysisResponse(
            original_text=text,
            word_count=word_count,
            character_count=character_count,
            analysis_timestamp=timestamp
        )
    
    except Exception as e:
        logger.error(f"Error analyzing text: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port) 