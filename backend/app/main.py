from fastapi import FastAPI, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from app import models, schemas
from app.database import engine, get_db
from app.routers import predicao

from fastapi.middleware.cors import CORSMiddleware


#
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="API Hackathon Expoagro Crateús",
    description="Sistema de Coleta de Dados Genéticos e Predição Reprodutiva",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Em produção usaríamos o domínio real
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(predicao.router)

@app.post("/api/animais", response_model=schemas.AnimalResponse, tags=["Animais"])
def criar_animal(animal: schemas.AnimalCreate, db: Session = Depends(get_db)):
    db_animal = models.Animal(**animal.model_dump())
    db.add(db_animal)
    db.commit()
    db.refresh(db_animal)
    return db_animal

@app.get("/api/animais", response_model=List[schemas.AnimalResponse], tags=["Animais"])
def listar_animais(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    animais = db.query(models.Animal).offset(skip).limit(limit).all()
    return animais


@app.post("/api/animais/{animal_id}/inseminacoes", response_model=schemas.InseminacaoResponse, tags=["Inseminações"])
def registrar_inseminacao(animal_id: int, inseminacao: schemas.InseminacaoCreate, db: Session = Depends(get_db)):
    animal_db = db.query(models.Animal).filter(models.Animal.id == animal_id).first()
    if not animal_db:
        raise HTTPException(status_code=404, detail="Animal não encontrado na base de dados.")

 
    db_inseminacao = models.Inseminacao(**inseminacao.model_dump(), animal_id=animal_id)
    
    db.add(db_inseminacao)
    db.commit()
    db.refresh(db_inseminacao)
    
    return db_inseminacao