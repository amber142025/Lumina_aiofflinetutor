import pytest
from app.config import Settings

def test_production_rejects_default_jwt_secret():
    settings = Settings(app_env="production", database_url="postgresql://user:pass@localhost/db",
                        jwt_secret="CHANGE_THIS_IN_PRODUCTION", cors_origins="https://example.com")
    with pytest.raises(RuntimeError, match="JWT_SECRET"):
        settings.validate_for_startup()

def test_production_rejects_sqlite():
    settings = Settings(app_env="production", database_url="sqlite:///./lumina.db",
                        jwt_secret="a-unique-secret-value-longer-than-32-chars",
                        cors_origins="https://example.com")
    with pytest.raises(RuntimeError, match="PostgreSQL"):
        settings.validate_for_startup()

def test_production_rejects_localhost_cors():
    settings = Settings(app_env="production", database_url="postgresql://user:pass@localhost/db",
                        jwt_secret="a-unique-secret-value-longer-than-32-chars",
                        cors_origins="http://localhost:3000")
    with pytest.raises(RuntimeError, match="localhost"):
        settings.validate_for_startup()

def test_production_accepts_required_basics():
    settings = Settings(app_env="production", database_url="postgresql://user:pass@localhost/db",
                        jwt_secret="a-unique-secret-value-longer-than-32-chars",
                        cors_origins="https://lumina.example.com")
    settings.validate_for_startup()
