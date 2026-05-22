import os
import random
from datetime import date, timedelta
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app import models
from app.database import Base

# Caminho do banco local
CURRENT_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(CURRENT_DIR, "expoagro.db")
SQLALCHEMY_DATABASE_URL = f"sqlite:///{DB_PATH}"

engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# ─── Dados auxiliares ────────────────────────────────────────────────────────

NOMES_BOVINOS = [
    "Estrela", "Mimosa", "Bonita", "Princesa", "Formosa",
    "Jasmim", "Pérola", "Jóia", "Vitória", "Beleza",
    "Aurora", "Safira", "Cristal", "Dama", "Flora",
]
NOMES_OVINOS = [
    "Algodão", "Neve", "Luna", "Lã Branca", "Serena",
    "Nuvem", "Pétala", "Brisa", "Chuva", "Flor",
]
NOMES_CAPRINOS = [
    "Mel", "Canela", "Pipoca", "Fofinha", "Pandora",
    "Amora", "Cereja", "Cacau", "Morena", "Docinho",
]

RACAS_BOVINOS = ["Nelore", "Girolando", "Gir", "Angus", "Brahman"]
RACAS_OVINOS = ["Santa Inês", "Dorper", "Morada Nova", "Texel"]
RACAS_CAPRINOS = ["Boer", "Saanen", "Anglo-Nubiana", "Toggenburg"]

LINHAGENS = ["Lemgruber", "Fardo", "Tradicional", "Top Elite", "Premium", None]
FAZENDAS = ["Fazenda Modelo", "Fazenda Esperança", "Fazenda Boa Vista"]
ESTACOES = ["Chuva", "Seca"]


def gerar_data_nascimento(min_anos=2, max_anos=8):
    """Gera uma data de nascimento aleatória entre min_anos e max_anos atrás."""
    dias = random.randint(min_anos * 365, max_anos * 365)
    return date.today() - timedelta(days=dias)


def seed_database():
    print("🗑️  Removendo tabelas antigas...")
    Base.metadata.drop_all(bind=engine)
    print("🏗️  Criando novas tabelas...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    todos_animais = []
    
    # ─── BOVINOS (15 matrizes) ───────────────────────────────────────────────
    print("🐄 Criando 15 matrizes bovinas...")
    for i, nome in enumerate(NOMES_BOVINOS):
        status = random.choice(["Vazia", "Vazia", "Prenha", "Lactante", "Vazia"])
        animal = models.Animal(
            registro_id=f"BR-BOV-{i+1:03d}",
            nome=nome,
            especie="Bovino",
            raca=random.choice(RACAS_BOVINOS),
            linhagem=random.choice(LINHAGENS),
            data_nascimento=gerar_data_nascimento(2, 7),
            status_reprodutivo=status,
            peso=round(random.uniform(350, 550), 1),
            ecc=round(random.uniform(2.0, 4.5), 1),
            fazenda="Fazenda Única",
            sexo="Fêmea",
        )
        db.add(animal)
        db.flush()
        todos_animais.append(animal)

    # ─── OVINOS (10 matrizes) ────────────────────────────────────────────────
    print("🐑 Criando 10 matrizes ovinas...")
    for i, nome in enumerate(NOMES_OVINOS):
        status = random.choice(["Vazia", "Prenha", "Lactante", "Vazia"])
        animal = models.Animal(
            registro_id=f"BR-OVI-{i+1:03d}",
            nome=nome,
            especie="Ovino",
            raca=random.choice(RACAS_OVINOS),
            linhagem=random.choice(LINHAGENS),
            data_nascimento=gerar_data_nascimento(1, 5),
            status_reprodutivo=status,
            peso=round(random.uniform(45, 85), 1),
            ecc=round(random.uniform(2.0, 4.0), 1),
            fazenda="Fazenda Única",
            sexo="Fêmea",
        )
        db.add(animal)
        db.flush()
        todos_animais.append(animal)

    # ─── CAPRINOS (10 matrizes) ──────────────────────────────────────────────
    print("🐐 Criando 10 matrizes caprinas...")
    for i, nome in enumerate(NOMES_CAPRINOS):
        status = random.choice(["Vazia", "Vazia", "Prenha", "Lactante"])
        animal = models.Animal(
            registro_id=f"BR-CAP-{i+1:03d}",
            nome=nome,
            especie="Caprino",
            raca=random.choice(RACAS_CAPRINOS),
            linhagem=random.choice(LINHAGENS),
            data_nascimento=gerar_data_nascimento(1, 5),
            status_reprodutivo=status,
            peso=round(random.uniform(35, 75), 1),
            ecc=round(random.uniform(2.2, 4.0), 1),
            fazenda="Fazenda Única",
            sexo="Fêmea",
        )
        db.add(animal)
        db.flush()
        todos_animais.append(animal)

    db.commit()
    print(f"   ✅ {len(todos_animais)} matrizes criadas.\n")
    
    # ─── INSEMINAÇÕES (variadas, com resultado) ──────────────────────────────
    print("💉 Criando inseminações...")
    inseminacoes_criadas = 0
    for animal in todos_animais:
        n_inseminacoes = random.randint(0, 3)
        for j in range(n_inseminacoes):
            dias_atras = random.randint(30, 300)
            sucesso = random.choice([True, True, False, None])
            ins = models.Inseminacao(
                animal_id=animal.id,
                data_inseminacao=date.today() - timedelta(days=dias_atras),
                ecc=round(random.uniform(2.5, 4.0), 1),
                tentativas_previas=j,
                indice_genetico_reprodutor=random.choice([85, 88, 90, 94, 98]),
                estacao=random.choice(ESTACOES),
                dias_pos_parto=random.randint(45, 180),
                sucesso_prenhez=sucesso,
            )
            db.add(ins)
            inseminacoes_criadas += 1

            # Evento correspondente
            ev = models.EventoHistorico(
                animal_id=animal.id,
                categoria_evento="Reprodutivo",
                titulo_evento="Inseminação",
                data_evento=ins.data_inseminacao,
                detalhes=f"Sêmen Genética {ins.indice_genetico_reprodutor}. Tentativa {j+1}."
            )
            db.add(ev)

    db.commit()
    print(f"   ✅ {inseminacoes_criadas} inseminações registradas.\n")

    # ─── EVENTOS SANITÁRIOS (vacinas) ────────────────────────────────────────
    print("💊 Criando eventos sanitários...")
    vacinas = [
        ("Vacinação Aftosa", "Dose de reforço anual aplicada."),
        ("Vacinação Brucelose", "Dose única – fêmea entre 3 e 8 meses."),
        ("Vermifugação", "Ivermectina 1% aplicada via subcutânea."),
        ("Vacinação Raiva", "Dose anual preventiva aplicada."),
    ]
    eventos_san = 0
    for animal in todos_animais:
        n_vacinas = random.randint(1, 3)
        for _ in range(n_vacinas):
            vacina = random.choice(vacinas)
            ev = models.EventoHistorico(
                animal_id=animal.id,
                categoria_evento="Sanitário",
                titulo_evento=vacina[0],
                data_evento=date.today() - timedelta(days=random.randint(5, 180)),
                detalhes=vacina[1],
            )
            db.add(ev)
            eventos_san += 1
    db.commit()
    print(f"   ✅ {eventos_san} eventos sanitários.\n")

    # ─── EVENTOS DE MANEJO (pesagens) ────────────────────────────────────────
    print("⚖️  Criando pesagens de rotina...")
    pesagens = 0
    for animal in todos_animais:
        n_pesagens = random.randint(1, 2)
        for _ in range(n_pesagens):
            ev = models.EventoHistorico(
                animal_id=animal.id,
                categoria_evento="Manejo",
                titulo_evento="Pesagem de Rotina",
                data_evento=date.today() - timedelta(days=random.randint(1, 90)),
                detalhes=f"Peso registrado: {animal.peso}kg",
            )
            db.add(ev)
            pesagens += 1
    db.commit()
    print(f"   ✅ {pesagens} pesagens registradas.\n")

    # ─── PARTOS (nascimentos no mês atual para o KPI) ────────────────────────
    print("🍼 Criando partos e crias...")
    maes_para_parto = [a for a in todos_animais if a.status_reprodutivo in ("Lactante",)]
    partos = 0
    for mae in maes_para_parto:
        # Parto no mês atual para aparecer no KPI de nascimentos
        dia_parto = random.randint(1, min(date.today().day, 28))
        data_parto = date.today().replace(day=dia_parto)

        cria = models.Animal(
            nome=f"Cria de {mae.nome}",
            especie=mae.especie,
            raca=mae.raca,
            data_nascimento=data_parto,
            status_reprodutivo="Vazia",
            peso=round(random.uniform(5, 40), 1) if mae.especie == "Bovino" else round(random.uniform(2, 8), 1),
            ecc=3.0,
            fazenda="Fazenda Única",
            sexo="Fêmea",
            mae_id=mae.id,
            origem_paterna=random.choice([
                "Rem Torixoréu FIV (Genética 98)",
                "Fardo FIV F. Mutum (Genética 85)",
                "Sertão TE 102 (Genética 88)",
                "Capitão Boer 44 (Genética 94)",
            ]),
        )
        db.add(cria)
        db.flush()

        ev = models.EventoHistorico(
            animal_id=mae.id,
            categoria_evento="Reprodutivo",
            titulo_evento="Parto",
            data_evento=data_parto,
            detalhes=f"Parto natural. Cria: {cria.nome} (ID: {cria.id}).",
        )
        db.add(ev)
        partos += 1

    db.commit()
    print(f"   ✅ {partos} partos com crias registrados.\n")

    # ─── RESUMO FINAL ────────────────────────────────────────────────────────
    total = db.query(models.Animal).count()
    total_ins = db.query(models.Inseminacao).count()
    total_ev = db.query(models.EventoHistorico).count()
    bovinos = db.query(models.Animal).filter(models.Animal.especie == "Bovino").count()
    ovinos = db.query(models.Animal).filter(models.Animal.especie == "Ovino").count()
    caprinos = db.query(models.Animal).filter(models.Animal.especie == "Caprino").count()

    print("=" * 50)
    print(f"🎉 BANCO POPULADO COM SUCESSO!")
    print(f"   📊 Total de Animais:     {total}")
    print(f"      🐄 Bovinos:           {bovinos}")
    print(f"      🐑 Ovinos:            {ovinos}")
    print(f"      🐐 Caprinos:          {caprinos}")
    print(f"   💉 Inseminações:         {total_ins}")
    print(f"   📋 Eventos Históricos:   {total_ev}")
    print("=" * 50)

    db.close()


if __name__ == "__main__":
    seed_database()