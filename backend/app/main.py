import io
import pandas as pd
from fastapi import FastAPI, Depends, HTTPException
from fastapi.responses import Response
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List, Optional

from app import models, schemas
from app.database import engine, get_db
from app.routers import predicao

from fastapi.middleware.cors import CORSMiddleware


# Criação das tabelas
models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="API Hackathon Expoagro Crateús",
    description="Sistema de Coleta de Dados Genéticos e Predição Reprodutiva",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(predicao.router)

# --- MÓDULO 2: GESTÃO DO REBANHO (CRUD DE ANIMAIS) ---

@app.post("/api/animais", response_model=schemas.AnimalResponse, tags=["Animais"])
def criar_animal(animal: schemas.AnimalCreate, db: Session = Depends(get_db)):
    data = animal.model_dump()
    idade_meses = data.pop("idade_meses", None)
    if not data.get("data_nascimento") and idade_meses is not None:
        from datetime import date, timedelta
        data["data_nascimento"] = date.today() - timedelta(days=idade_meses * 30)
    db_animal = models.Animal(**data)
    db.add(db_animal)
    db.commit()
    db.refresh(db_animal)
    return db_animal

@app.get("/api/animais", response_model=List[schemas.AnimalResponse], tags=["Animais"])
def listar_animais(especie: Optional[str] = None, status_reprodutivo: Optional[str] = None, skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    query = db.query(models.Animal)
    if especie:
        query = query.filter(models.Animal.especie == especie)
    if status_reprodutivo:
        query = query.filter(models.Animal.status_reprodutivo == status_reprodutivo)
    animais = query.offset(skip).limit(limit).all()
    return animais

@app.get("/api/animais/{animal_id}", response_model=schemas.AnimalResponse, tags=["Animais"])
def obter_animal(animal_id: int, db: Session = Depends(get_db)):
    db_animal = db.query(models.Animal).filter(models.Animal.id == animal_id).first()
    if not db_animal:
        raise HTTPException(status_code=404, detail="Animal não encontrado na base de dados.")
    return db_animal

@app.delete("/api/animais/{animal_id}", tags=["Animais"])
def deletar_animal(animal_id: int, db: Session = Depends(get_db)):
    db_animal = db.query(models.Animal).filter(models.Animal.id == animal_id).first()
    if not db_animal:
        raise HTTPException(status_code=404, detail="Animal não encontrado na base de dados.")
    db.delete(db_animal)
    db.commit()
    return {"success": True, "message": f"Animal com ID {animal_id} deletado com sucesso."}

@app.patch("/api/animais/{animal_id}", response_model=schemas.AnimalResponse, tags=["Animais"])
def editar_animal(animal_id: int, dados: schemas.AnimalUpdate, db: Session = Depends(get_db)):
    db_animal = db.query(models.Animal).filter(models.Animal.id == animal_id).first()
    if not db_animal:
        raise HTTPException(status_code=404, detail="Animal não encontrado na base de dados.")
    update_data = dados.model_dump(exclude_none=True)
    for campo, valor in update_data.items():
        setattr(db_animal, campo, valor)
    db.commit()
    db.refresh(db_animal)
    return db_animal

@app.patch("/api/animais/{animal_id}/status", response_model=schemas.AnimalResponse, tags=["Animais"])
def atualizar_status_animal(animal_id: int, payload: dict, db: Session = Depends(get_db)):
    from fastapi import Body
    db_animal = db.query(models.Animal).filter(models.Animal.id == animal_id).first()
    if not db_animal:
        raise HTTPException(status_code=404, detail="Animal não encontrado na base de dados.")
    novo_status = payload.get("status_reprodutivo")
    if not novo_status:
        raise HTTPException(status_code=400, detail="Campo 'status_reprodutivo' é obrigatório.")
    db_animal.status_reprodutivo = novo_status
    db.commit()
    db.refresh(db_animal)
    return db_animal


@app.get("/api/animais/exportar/csv", tags=["Animais"])
def exportar_animais_csv(db: Session = Depends(get_db)):
    animais = db.query(models.Animal).all()
    
    data = []
    for a in animais:
        data.append({
            "ID": a.id,
            "Registro": a.registro_id,
            "Nome": a.nome,
            "Especie": a.especie,
            "Raca": a.raca,
            "Idade_Meses": a.idade_meses,
            "Status_Reprodutivo": a.status_reprodutivo,
            "Peso": a.peso,
            "ECC": a.ecc,
            "Origem_Paterna": a.origem_paterna,
            "ID_Mae": a.mae_id
        })
        
    df = pd.DataFrame(data)
    stream = io.StringIO()
    df.to_csv(stream, index=False)
    
    response = Response(content=stream.getvalue(), media_type="text/csv")
    response.headers["Content-Disposition"] = "attachment; filename=animais_rebanho.csv"
    return response

# --- MÓDULO 3: GESTÃO REPRODUTIVA (EVENTOS) ---

@app.post("/api/animais/{animal_id}/inseminacoes", response_model=schemas.InseminacaoResponse, tags=["Eventos"])
def registrar_inseminacao(animal_id: int, inseminacao: schemas.InseminacaoCreate, db: Session = Depends(get_db)):
    animal_db = db.query(models.Animal).filter(models.Animal.id == animal_id).first()
    if not animal_db:
        raise HTTPException(status_code=404, detail="Animal não encontrado na base de dados.")

    db_inseminacao = models.Inseminacao(**inseminacao.model_dump(), animal_id=animal_id)
    
    # Atualizar o status reprodutivo da fêmea para "Inseminada"
    animal_db.status_reprodutivo = "Inseminada"
    
    # Adicionar evento histórico correspondente
    evento = models.EventoHistorico(
        animal_id=animal_id,
        categoria_evento="Reprodutivo",
        titulo_evento="Inseminação",
        data_evento=inseminacao.data_inseminacao,
        detalhes=f"Sêmen ID/Genética: {inseminacao.indice_genetico_reprodutor}"
    )
    db.add(evento)
    
    db.add(db_inseminacao)
    db.commit()
    db.refresh(db_inseminacao)
    
    return db_inseminacao

@app.put("/api/inseminacoes/{inseminacao_id}", response_model=schemas.InseminacaoResponse, tags=["Eventos"])
def atualizar_inseminacao(inseminacao_id: int, status: schemas.InseminacaoUpdateStatus, db: Session = Depends(get_db)):
    db_inseminacao = db.query(models.Inseminacao).filter(models.Inseminacao.id == inseminacao_id).first()
    if not db_inseminacao:
        raise HTTPException(status_code=404, detail="Inseminação não encontrada na base de dados.")
    
    db_inseminacao.sucesso_prenhez = status.sucesso_prenhez
    db.commit()
    db.refresh(db_inseminacao)
    return db_inseminacao

@app.post("/api/animais/{animal_id}/partos", response_model=schemas.AnimalResponse, tags=["Eventos"])
def registrar_parto(animal_id: int, parto: schemas.PartoCreate, db: Session = Depends(get_db)):
    mae = db.query(models.Animal).filter(models.Animal.id == animal_id).first()
    if not mae:
        raise HTTPException(status_code=404, detail="Mãe não encontrada.")
    
    # A) Atualiza o status da mãe
    mae.status_reprodutivo = "Lactante"
    
    # C) Descobre a origem paterna buscando a última inseminação bem-sucedida ou pendente
    ultima_ins = db.query(models.Inseminacao).filter(
        models.Inseminacao.animal_id == mae.id,
        models.Inseminacao.sucesso_prenhez != False # Pode ser True ou None
    ).order_by(models.Inseminacao.data_inseminacao.desc()).first()
    
    origem_paterna = None
    if ultima_ins:
        origem_paterna = f"Genética {ultima_ins.indice_genetico_reprodutor}"
    
    cria_sexo = parto.cria.sexo or "Fêmea"
    
    # B) Insere o evento na linha do tempo da mãe
    if cria_sexo == "Macho":
        if parto.cria.peso is not None:
            peso_val = parto.cria.peso
            peso_str = f"{int(peso_val)}kg" if peso_val.is_integer() else f"{peso_val}kg"
        else:
            peso_str = "35kg"
        texto_evento = f"Parto concluído. Cria Macho ({peso_str}) destinado à engorda/venda"
    else:
        texto_evento = parto.detalhes or f"Parto natural. Cria Fêmea registrada."
        
    evento = models.EventoHistorico(
        animal_id=mae.id,
        categoria_evento="Reprodutivo",
        titulo_evento="Parto",
        data_evento=parto.data_parto,
        detalhes=texto_evento
    )
    db.add(evento)
    
    # D) Insere a cria apenas se for fêmea
    cria_data = parto.cria.model_dump()
    cria_data.pop("idade_meses", None)
    cria = models.Animal(**cria_data)
    cria.mae_id = mae.id
    cria.origem_paterna = origem_paterna
    
    if cria_sexo == "Fêmea":
        db.add(cria)
        db.commit()
        db.refresh(cria)
    else:
        db.commit()
        cria.id = 0
        
    return cria

@app.post("/api/animais/{animal_id}/eventos", response_model=schemas.EventoHistoricoResponse, tags=["Eventos"])
def registrar_evento(animal_id: int, evento_in: schemas.EventoHistoricoCreate, db: Session = Depends(get_db)):
    animal = db.query(models.Animal).filter(models.Animal.id == animal_id).first()
    if not animal:
        raise HTTPException(status_code=404, detail="Animal não encontrado.")
    
    evento = models.EventoHistorico(
        animal_id=animal.id,
        categoria_evento=evento_in.categoria_evento,
        titulo_evento=evento_in.titulo_evento,
        data_evento=evento_in.data_evento,
        detalhes=evento_in.detalhes
    )
    db.add(evento)
    
    # Se for Pesagem de Rotina
    if evento_in.categoria_evento == "Manejo" and "pesagem" in evento_in.titulo_evento.lower() and evento_in.novo_peso:
        animal.peso = evento_in.novo_peso
        
    db.commit()
    db.refresh(evento)
    return evento

@app.get("/api/animais/{animal_id}/eventos", response_model=List[schemas.EventoHistoricoResponse], tags=["Eventos"])
def listar_eventos(animal_id: int, db: Session = Depends(get_db)):
    eventos = db.query(models.EventoHistorico).filter(models.EventoHistorico.animal_id == animal_id).order_by(models.EventoHistorico.data_evento.desc()).all()
    return eventos

# --- MÓDULO 4: ANALYTICS (KPIs DO DASHBOARD) ---

@app.get("/api/dashboard/kpis", tags=["Analytics"])
def obter_dashboard_kpis(db: Session = Depends(get_db)):
    from datetime import date
    
    total_matrizes = db.query(models.Animal).count()
    
    # Taxa de prenhez baseada em inseminações com resultado
    inseminacoes_com_resultado = db.query(models.Inseminacao).filter(models.Inseminacao.sucesso_prenhez.isnot(None)).all()
    total_inseminacoes = len(inseminacoes_com_resultado)
    taxa_prenhez_media = 0.0
    if total_inseminacoes > 0:
        total_sucessos = sum(1 for ins in inseminacoes_com_resultado if ins.sucesso_prenhez is True)
        taxa_prenhez_media = round((total_sucessos / total_inseminacoes) * 100, 2)
        
    # Contagem por espécie (case-insensitive via lower())
    counts = db.query(models.Animal.especie, func.count(models.Animal.id)).group_by(models.Animal.especie).all()
    detalhe_especies = {}
    for esp, count in counts:
        detalhe_especies[esp.lower()] = detalhe_especies.get(esp.lower(), 0) + count
    
    for esp in ["bovino", "ovino", "caprino"]:
        if esp not in detalhe_especies:
            detalhe_especies[esp] = 0
    
    # Nascimentos no mês atual (eventos de Parto registrados neste mês)
    hoje = date.today()
    primeiro_dia_mes = hoje.replace(day=1)
    nascimentos_mes = db.query(models.EventoHistorico).filter(
        models.EventoHistorico.categoria_evento == "Reprodutivo",
        models.EventoHistorico.titulo_evento == "Parto",
        models.EventoHistorico.data_evento >= primeiro_dia_mes,
        models.EventoHistorico.data_evento <= hoje,
    ).count()
            
    # Alertas Críticos tipados
    alertas_criticos = []
    
    # 1. ECC Crítico (< 2.5)
    alertas_ecc = db.query(models.Animal).filter(
        models.Animal.ecc.isnot(None),
        models.Animal.ecc < 2.5
    ).all()
    for a in alertas_ecc:
        alertas_criticos.append({
            "id": a.id,
            "nome": a.nome or f"ID {a.id}",
            "tipo": "ecc_critico",
            "mensagem": f"{a.nome or 'ID ' + str(a.id)} com ECC {a.ecc:.1f} — abaixo do limite."
        })
    
    # 2. Parto Próximo (matrizes com status 'Prenha')
    alertas_prenhe = db.query(models.Animal).filter(
        models.Animal.status_reprodutivo.in_(["Prenhe", "Prenha"])
    ).all()
    for a in alertas_prenhe:
        alertas_criticos.append({
            "id": a.id,
            "nome": a.nome or f"ID {a.id}",
            "tipo": "parto_proximo",
            "mensagem": f"{a.nome or 'ID ' + str(a.id)} está prenha — monitorar parto."
        })
            
    return {
        "total_matrizes": total_matrizes,
        "taxa_prenhez_media": taxa_prenhez_media,
        "bovinos": detalhe_especies["bovino"],
        "ovinos": detalhe_especies["ovino"],
        "caprinos": detalhe_especies["caprino"],
        "nascimentos_mes": nascimentos_mes,
        "alertas_criticos": alertas_criticos
    }