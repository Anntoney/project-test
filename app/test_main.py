import pytest
from fastapi.testclient import TestClient
from main import app

# Set up the test client
client = TestClient(app)

def test_health_check():
    """Test the health check endpoint - makes sure the service is running"""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy", "service": "insight-agent"}

def test_analyze_text_success():
    """Test successful text analysis - the main functionality"""
    test_data = {"text": "I love cloud engineering!"}
    response = client.post("/analyze", json=test_data)
    
    assert response.status_code == 200
    data = response.json()
    assert data["original_text"] == "I love cloud engineering!"
    assert data["word_count"] == 4
    assert data["character_count"] == 23
    assert "analysis_timestamp" in data

def test_analyze_text_empty():
    """Test empty text handling - should give an error"""
    test_data = {"text": ""}
    response = client.post("/analyze", json=test_data)
    
    assert response.status_code == 400
    assert "Text cannot be empty" in response.json()["detail"]

def test_analyze_text_whitespace():
    """Test whitespace-only text handling - also should error"""
    test_data = {"text": "   "}
    response = client.post("/analyze", json=test_data)
    
    assert response.status_code == 400
    assert "Text cannot be empty" in response.json()["detail"]

def test_analyze_text_special_characters():
    """Test text with special characters - numbers, punctuation, etc."""
    test_data = {"text": "Hello, World! 123"}
    response = client.post("/analyze", json=test_data)
    
    assert response.status_code == 200
    data = response.json()
    assert data["word_count"] == 3
    assert data["character_count"] == 16 