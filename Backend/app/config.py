from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    database_url: str = "sqlite:///./lumina_dev.db"
    jwt_secret: str = "CHANGE_THIS_IN_PRODUCTION"
    access_token_minutes: int = 20
    refresh_token_days: int = 14
    cors_origins: str = "http://localhost:3000,http://localhost:5173"
    ai_provider: str = "none"
    ai_api_key: str = ""
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

settings = Settings()
