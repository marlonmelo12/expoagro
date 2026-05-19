import pandas as pd
import numpy as np

# =========================================================
# CONFIGURAÇÕES GERAIS
# =========================================================

np.random.seed(42)
num_registros = 5000

# =========================================================
# 1. ESPÉCIES
# =========================================================

especies = np.random.choice(
    ['Bovino', 'Ovino', 'Caprino'],
    size=num_registros,
    p=[0.5, 0.3, 0.2]
)

# =========================================================
# 2. IDADE DOS ANIMAIS
# =========================================================

idades_meses = []

for esp in especies:

    if esp == 'Bovino':
        # 14 meses até 10 anos
        idade = np.random.randint(14, 120)

    elif esp == 'Ovino':
        # 7 meses até 7 anos
        idade = np.random.randint(7, 84)

    else:  # Caprino
        idade = np.random.randint(7, 84)

    idades_meses.append(idade)

idades_meses = np.array(idades_meses)

# =========================================================
# 3. ECC - ESCORE DE CONDIÇÃO CORPORAL
# =========================================================

ecc = np.round(
    np.random.normal(loc=3.1, scale=0.7, size=num_registros),
    1
)

ecc = np.clip(ecc, 1.0, 5.0)

# =========================================================
# 4. TENTATIVAS PRÉVIAS
# =========================================================

tentativas_previas = np.random.choice(
    [0, 1, 2, 3],
    size=num_registros,
    p=[0.6, 0.25, 0.1, 0.05]
)

# =========================================================
# 5. ÍNDICE GENÉTICO DO REPRODUTOR
# =========================================================

indice_genetico_reprodutor = np.random.randint(
    50,
    100,
    size=num_registros
)

# =========================================================
# 6. ESTAÇÃO DO ANO
# =========================================================

estacao = np.random.choice(
    ['Seca', 'Chuva'],
    size=num_registros,
    p=[0.45, 0.55]
)

# =========================================================
# 7. DIAS PÓS-PARTO
# =========================================================

dias_pos_parto = np.random.randint(
    20,
    250,
    size=num_registros
)

# =========================================================
# 8. FAZENDA
# =========================================================

fazendas = np.random.choice(
    ['Fazenda_A', 'Fazenda_B', 'Fazenda_C', 'Fazenda_D'],
    size=num_registros
)

# =========================================================
# 9. FERTILIDADE INDIVIDUAL
# =========================================================

fertilidade_individual = np.random.normal(
    loc=0,
    scale=1,
    size=num_registros
)

# =========================================================
# 10. EFEITOS DAS VARIÁVEIS
# =========================================================

# ---------------------------------------------------------
# ECC IDEAL
# ---------------------------------------------------------

distancia_ecc_ideal = np.abs(ecc - 3.2)

efeito_ecc = -(distancia_ecc_ideal * 2.2)

# ---------------------------------------------------------
# IDADE IDEAL POR ESPÉCIE
# ---------------------------------------------------------

idade_ideal = []

for esp in especies:

    if esp == 'Bovino':
        idade_ideal.append(48)

    elif esp == 'Ovino':
        idade_ideal.append(30)

    else:
        idade_ideal.append(30)

idade_ideal = np.array(idade_ideal)

distancia_idade = np.abs(idades_meses - idade_ideal)

efeito_idade = -(distancia_idade * 0.015)

# ---------------------------------------------------------
# TENTATIVAS PRÉVIAS
# ---------------------------------------------------------

efeito_tentativas = -(tentativas_previas * 1.4)

# ---------------------------------------------------------
# GENÉTICA
# ---------------------------------------------------------

efeito_genetica = indice_genetico_reprodutor * 0.055

# ---------------------------------------------------------
# ESPÉCIE
# ---------------------------------------------------------

efeito_especie = []

for esp in especies:

    if esp == 'Bovino':
        efeito_especie.append(0.5)

    elif esp == 'Ovino':
        efeito_especie.append(-0.2)

    else:
        efeito_especie.append(0.0)

efeito_especie = np.array(efeito_especie)

# ---------------------------------------------------------
# ESTAÇÃO
# ---------------------------------------------------------

efeito_estacao = np.where(estacao == 'Chuva', 0.6, -0.4)

# ---------------------------------------------------------
# DIAS PÓS-PARTO
# Melhor faixa: 60 a 120 dias
# ---------------------------------------------------------

distancia_dpp_ideal = np.abs(dias_pos_parto - 90)

efeito_dpp = -(distancia_dpp_ideal * 0.01)

# ---------------------------------------------------------
# EFEITO DA FAZENDA
# ---------------------------------------------------------

efeito_fazenda_dict = {
    'Fazenda_A': 0.4,
    'Fazenda_B': 0.1,
    'Fazenda_C': -0.3,
    'Fazenda_D': 0.0
}

efeito_fazenda = np.array([
    efeito_fazenda_dict[f]
    for f in fazendas
])

# =========================================================
# 11. INTERAÇÕES ENTRE VARIÁVEIS
# =========================================================

bonus_interacao = np.zeros(num_registros)

# Bovinos respondem melhor com ECC alto
bonus_interacao += np.where(
    (especies == 'Bovino') & (ecc >= 3.5),
    0.8,
    0
)

# Muitas tentativas + ECC ruim piora muito
bonus_interacao += np.where(
    (tentativas_previas >= 2) & (ecc < 2.5),
    -1.2,
    0
)

# =========================================================
# 12. RUÍDO BIOLÓGICO
# =========================================================

ruido = np.random.normal(
    0,
    1.2,
    num_registros
)

# =========================================================
# 13. SCORE REPRODUTIVO
# =========================================================

score_reprodutivo = (
    efeito_ecc +
    efeito_idade +
    efeito_tentativas +
    efeito_genetica +
    efeito_especie +
    efeito_estacao +
    efeito_dpp +
    efeito_fazenda +
    fertilidade_individual +
    bonus_interacao +
    ruido
)

# =========================================================
# 14. FUNÇÃO SIGMOIDE
# =========================================================

probabilidade_prenhez = 1 / (
    1 + np.exp(-score_reprodutivo)
)

# =========================================================
# 15. TARGET
# =========================================================

sucesso_prenhez = np.random.binomial(
    1,
    probabilidade_prenhez
)

# =========================================================
# 16. DATAFRAME FINAL
# =========================================================

df_inseminacao = pd.DataFrame({

    'id_animal': [
        f'ANM_{i:05d}'
        for i in range(1, num_registros + 1)
    ],

    'especie': especies,

    'idade_meses': idades_meses,

    'ecc': ecc,

    'tentativas_previas': tentativas_previas,

    'indice_genetico_reprodutor':
        indice_genetico_reprodutor,

    'estacao': estacao,

    'dias_pos_parto': dias_pos_parto,

    'fazenda': fazendas,

    'sucesso_prenhez': sucesso_prenhez
})

# =========================================================
# 17. ANÁLISE RÁPIDA
# =========================================================

print("\nDistribuição das classes:\n")

print(
    df_inseminacao['sucesso_prenhez']
    .value_counts(normalize=True) * 100
)

print("\nPrimeiras linhas:\n")

print(df_inseminacao.head())

# =========================================================
# 18. EXPORTAÇÃO
# =========================================================

df_inseminacao.to_csv(
    'dataset_inseminacao_sintetico_melhorado.csv',
    index=False
)

print(
    "\nDataset gerado com sucesso:"
    " 'dataset_inseminacao_sintetico_melhorado.csv'"
)