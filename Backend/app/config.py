from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_env: str = "development"
    database_url: str = "sqlite:///./lumina_dev.db"
    jwt_secret: str = "CHANGE_THIS_IN_PRODUCTION"
    access_token_minutes: int = Field(default=20, ge=5, le=60)
    refresh_token_days: int = Field(default=14, ge=1, le=60)
    cors_origins: str = "http://localhost:3000,http://localhost:5173"
    ai_provider: str = "none"
    ai_api_key: str = ""
    ai_model: str = "gpt-4.1-mini"
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @field_validator("app_env")
    @classmethod
    def normalize_environment(cls, value: str) -> str:
        value = value.strip().lower()
        if value not in {"development", "test", "staging", "production"}:
            raise ValueError("APP_ENV must be development, test, staging, or production")
        return value

    def validate_for_startup(self) -> None:
        if self.app_env != "production":
            return
        if len(self.jwt_secret) < 32 or self.jwt_secret == "CHANGE_THIS_IN_PRODUCTION":
            raise RuntimeError("Production requires a unique JWT_SECRET of at least 32 characters.")
        if self.database_url.startswith("sqlite"):
            raise RuntimeError("Production requires PostgreSQL; SQLite is development/offline-only.")
        if not self.cors_origins.strip():
            raise RuntimeError("Production CORS_ORIGINS must contain the real website origin.")
        if any("localhost" in origin or "127.0.0.1" in origin for origin in self.cors_origins.split(",")):
            raise RuntimeError("Production CORS_ORIGINS cannot contain localhost.")
        if self.ai_provider.lower() == "openai" and not self.ai_api_key:
            raise RuntimeError("AI_PROVIDER=openai requires AI_API_KEY.")

settings = Settings()
