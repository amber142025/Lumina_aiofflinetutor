import os
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_env: str = "development"
    database_url: str = "sqlite:///./lumina_dev.db"
    jwt_secret: str = "CHANGE_THIS_IN_PRODUCTION"
    access_token_minutes: int = 20
    refresh_token_days: int = 14
    cors_origins: str = "http://localhost:3000,http://localhost:5173"
    ai_provider: str = "none"
    ai_api_key: str = ""
    openai_model: str = ""
    ai_timeout_seconds: int = 30

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]

    def validate_for_startup(self) -> None:
        """Fail closed when required production configuration is missing or unsafe."""
        if self.app_env.lower() != "production":
            return
        if len(self.jwt_secret) < 32 or self.jwt_secret == "CHANGE_THIS_IN_PRODUCTION":
            raise RuntimeError("Production requires JWT_SECRET with at least 32 random characters.")
        if not self.database_url.startswith(("postgresql://", "postgresql+psycopg2://")):
            raise RuntimeError("Production requires a PostgreSQL DATABASE_URL.")
        if not self.cors_origin_list or "*" in self.cors_origin_list:
            raise RuntimeError("Production CORS_ORIGINS must list explicit trusted origins.")
        if any("localhost" in origin or "127.0.0.1" in origin for origin in self.cors_origin_list):
            raise RuntimeError("Production CORS_ORIGINS cannot contain localhost origins.")
        if self.ai_provider.lower() not in {"openai", "none"}:
            raise RuntimeError("AI_PROVIDER must be 'openai' or 'none'.")
        if self.ai_provider.lower() == "openai" and (not self.ai_api_key or not self.openai_model):
            raise RuntimeError("OPENAI_API_KEY and OPENAI_MODEL are required when AI_PROVIDER=openai.")
        if self.ai_timeout_seconds < 5 or self.ai_timeout_seconds > 120:
            raise RuntimeError("AI_TIMEOUT_SECONDS must be between 5 and 120.")


settings = Settings()
