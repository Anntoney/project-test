# Basic test to check if FastAPI app can be imported
def test_can_import_main():
    """Test if we can import the main module"""
    try:
        import main
        assert hasattr(main, 'app')
        print("✅ Successfully imported main module")
    except Exception as e:
        pytest.fail(f"Failed to import main module: {str(e)}")

def test_app_exists():
    """Test if the app object exists"""
    try:
        from main import app
        assert app is not None
        print("✅ App object exists")
    except Exception as e:
        pytest.fail(f"App object not found: {str(e)}")

def test_app_type():
    """Test if app is a FastAPI instance"""
    try:
        from main import app
        from fastapi import FastAPI
        assert isinstance(app, FastAPI)
        print("✅ App is a FastAPI instance")
    except Exception as e:
        pytest.fail(f"App is not a FastAPI instance: {str(e)}") 