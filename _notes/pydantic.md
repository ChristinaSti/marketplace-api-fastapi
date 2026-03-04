# Pydantic
- primarily used for data validation and settings management
- leverages standard Python type hints to enforce data structures at runtime =>  ensuring that untrusted data conforms to a specific schema before it is processed

## Common use cases:
1. **Configuration Management**: use **strongly typed** `BaseSettings` class to load and validate application configurations from environment variables or .env files
2. ...

## 1. Configuration Management
- avoid calling os.getenv() and validating env vars everywhere in the code
- use strong types, avoid str whenever possible

### `BaseSettings`class
- is designed to prioritize loading values from Environment Variables first, then an .env file, and finally fallback to defaults defined in the code
- will automatically match the field names (case-insensitive by default) to the environment variables
- Type Coercion: It converts the string "true" in your .env file into the Python boolean True automatically (can be deactivated via `SettingsConfigDict(strict=True,)`)
- Validation **at Startup**: If a value is missing or isn't the right data type, the application will **fail immediately** with a clear error, preventing "silent" configuration bugs

#### some syntax
- `Annotated` (from typing) with constraints, e.g. `port: Annotated[int, Field(ge=1, le=65535)]`
- Strict enums via `Literal`, e.g. `app_env: Literal["local", "staging", "production"] = "local"`
- Built-in URL validation: `database_url: PostgresDsn` 
    - note: it may need secret masking e.g. due to included password
        - use it's separate components (e.f. db_user, db_host) as fields
        - db_url as derived field using `@property` decorator and `@computed_field` decorator, that integrates with pydantic's serialization (field appears in `model_dump()`, `model_dump_json()`, and `repr()`)
- Secret masking: `secret_key: SecretStr`, e.g. when using `print(settings)`, `repr(settings.secret_key)`, `settings.model_dump()` => is replaced by `"*****"`
    - forces developers to consciously/explicitly unwrap the secret: `settings.secret_key.get_secret_value()`
    - for logging, automatic masking depends on the serializer, therefore:
    ``` python
    safe_config = settings.model_dump()
    safe_config["secret_key"] = "***"
    logger.info("Loaded configuration", extra=safe_config)
    ```
- Validation Across Fields, e.g.:
    ``` python 
    @model_validator(mode="after")
    def validate_production_security(self):
        if self.app_env == "production":
            if self.jwt_algorithm != "RS256":
                raise ValueError("Production must use RS256")
        return self
    ```
#### Testing
- always test cross-field validation, or more generally anything self-implemented via `@field_validator` and `@model_validator`, e.g.
    ``` python
    def test_debug_forbidden_in_production(monkeypatch):
        monkeypatch.setenv("APP_ENV", "production")
        monkeypatch.setenv("DEBUG", "true")

        with pytest.raises(ValidationError):
            Settings()
    ```
- test fields with custom constraints, e.g. `port: Annotated[int, Field(ge=1, le=65535)]`
    ```  python
    def test_port_range(monkeypatch):
    monkeypatch.setenv("PORT", "70000")

    with pytest.raises(ValidationError):
        Settings()
    ```
- do NOT test pydantics built-in Types, it is redundant with it's own testing => no added value
- test defaults (can easily break during refactoring), e.g. `debug: bool = False`
    ``` python
    def test_debug_default(monkeypatch):
        monkeypatch.delenv("DEBUG", raising=False)
        monkeypatch.setenv("APP_ENV", "local")

        settings = Settings()
        assert settings.debug is False
    ```

#### Ensure `Settings()` is only instantiated ONCE per process
##### why?
- repeated I/O-bound reading from .env or the environment, type conversions and validation are inefficient
- ensures deterministic configuration (e.g. temporary secret could be rotated)

##### solution:
- using `@lru_cache` (lru=least-recently-used) decorator => `Settings()` is instantiated once per process, every call to `get_settings()` returns the same instance
- Benefits:
    - enables clean dependency injection
        - many production systems use dependency injection in API routes, background tasks (unlike in modules with business logic like services, repositories, utilities: use direct import)
            ``` python
            @app.get("/db-url")
            def read_db_url(settings: Settings = Depends(get_settings)):
                ...
            ```
    - enables test isolation:
        ``` python
        get_settings.cache_clear()
        monkeypatch.setenv("APP_ENV", "production")
        settings = get_settings() # re-instantiate
        ```
        - clean override mechanism
        - without caching, there is a risk of accidental multiple instances and instantiation timing is harder to control
    - thread safety in concurrent web servers / async workloads
    - clear semantic intent: Settings are immutable and process-scoped


