import os
from dotenv import load_dotenv
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Carrega as variáveis de ambiente do arquivo .env
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
dotenv_path = os.path.join(CURRENT_DIR, "..", ".env")
load_dotenv(dotenv_path)

SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./expoagro.db")

# Tenta inicializar a engine de banco de dados
try:
    connect_args = {"check_same_thread": False} if SQLALCHEMY_DATABASE_URL.startswith("sqlite") else {}
    engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args=connect_args)
    # Efetua um teste de conexão imediato para validar se o servidor e credenciais estão OK
    with engine.connect() as conn:
        pass
except Exception as e:
    # Se falhar (ex: PostgreSQL offline/senha de exemplo no .env), faz fallback seguro para SQLite local
    print(f"⚠️ [AVISO] Falha ao conectar ao banco principal ({SQLALCHEMY_DATABASE_URL}): {e}")
    print("👉 Efetuando fallback automático para SQLite local ('expoagro.db')...")
    SQLALCHEMY_DATABASE_URL = "sqlite:///./expoagro.db"
    engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()