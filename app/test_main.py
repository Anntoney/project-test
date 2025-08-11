import pytest
import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from fastapi.testclient import TestClient
    from main import app
    
    # Set up the test client
    client = TestClient(app)
    
    def test_health_check():
        """Test the health check endpoint - makes sure the service is running"""
        try:
            response = client.get("/health")
            assert response.status_code == 200
            assert response.json() == {"status": "healthy", "service": "insight-agent"}
        except Exception as e:
            pytest.fail(f"Health check failed: {str(e)}")
    
    def test_analyze_text_success():
        """Test successful text analysis - the main functionality"""
        try:
            test_data = {"text": "I love cloud engineering!"}
            response = client.post("/analyze", json=test_data)
            
            assert response.status_code == 200
            data = response.json()
            assert data["original_text"] == "I love cloud engineering!"
            assert data["word_count"] == 4
            assert data["character_count"] == 25  # Fixed: includes the exclamation mark
            assert "analysis_timestamp" in data
        except Exception as e:
            pytest.fail(f"Analyze text test failed: {str(e)}")
    
    def test_analyze_text_empty():
        """Test empty text handling - should give an error"""
        try:
            test_data = {"text": ""}
            response = client.post("/analyze", json=test_data)
            
            assert response.status_code == 400
            assert "Text cannot be empty" in response.json()["detail"]
        except Exception as e:
            pytest.fail(f"Empty text test failed: {str(e)}")
    
    def test_analyze_text_whitespace():
        """Test whitespace-only text handling - also should error"""
        try:
            test_data = {"text": "   "}
            response = client.post("/analyze", json=test_data)
            
            assert response.status_code == 400
            assert "Text cannot be empty" in response.json()["detail"]
        except Exception as e:
            pytest.fail(f"Whitespace text test failed: {str(e)}")
    
    def test_analyze_text_special_characters():
        """Test text with special characters - numbers, punctuation, etc."""
        try:
            test_data = {"text": "Hello, World! 123"}
            response = client.post("/analyze", json=test_data)
            
            assert response.status_code == 200
            data = response.json()
            assert data["word_count"] == 3
            assert data["character_count"] == 17  # Fixed: includes comma, exclamation, and spaces
        except Exception as e:
            pytest.fail(f"Special characters test failed: {str(e)}")

except ImportError as e:
    # If we can't import, create a test that explains the issue
    def test_import_error():
        pytest.fail(f"Failed to import required modules: {str(e)}")
except Exception as e:
    # If there's any other error, create a test that explains it
    def test_setup_error():
        pytest.fail(f"Test setup failed: {str(e)}") 