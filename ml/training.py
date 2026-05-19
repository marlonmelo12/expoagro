import pandas as pd
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import classification_report, confusion_matrix
import joblib
import time

# =========================================================
# 1. CARREGAR E PREPARAR OS DADOS
# =========================================================
print("Carregando o dataset...")
df = pd.read_csv('dataset_inseminacao_sintetico_melhorado.csv')

X = df.drop(columns=['id_animal', 'sucesso_prenhez'])
y = df['sucesso_prenhez']

# Separando colunas por tipo
colunas_numericas = ['idade_meses', 'ecc', 'tentativas_previas', 
                     'indice_genetico_reprodutor', 'dias_pos_parto']
colunas_categoricas = ['especie', 'estacao', 'fazenda']

# Pipeline de Transformação (O mesmo de antes para manter compatibilidade)
preprocessor = ColumnTransformer(
    transformers=[
        ('num', StandardScaler(), colunas_numericas),
        ('cat', OneHotEncoder(handle_unknown='ignore'), colunas_categoricas)
    ]
)

# Divisão de Treino e Teste
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# =========================================================
# 2. CONFIGURAR O PIPELINE BASE E O GRID DE PARÂMETROS
# =========================================================
# Instanciamos o pipeline com o modelo base (mantendo o class_weight para não perder o Recall de falhas)
pipeline_base = Pipeline(steps=[
    ('preprocessor', preprocessor),
    ('classifier', RandomForestClassifier(class_weight='balanced', random_state=42))
])

# Aqui definimos o "espaço de busca". O GridSearchCV vai testar todas essas combinações.
# Nota: O prefixo 'classifier__' é obrigatório para indicar que o parâmetro é do RandomForest e não do preprocessor.
param_grid = {
    'classifier__n_estimators': [100, 200, 300],        # Quantidade de árvores na floresta
    'classifier__max_depth': [7, 10, 15, None],         # Profundidade máxima (evita decorar os dados)
    'classifier__min_samples_split': [2, 5, 10],        # Mínimo de amostras para dividir um nó
    'classifier__min_samples_leaf': [1, 2, 4]           # Mínimo de amostras na folha final (suaviza o modelo)
}

# =========================================================
# 3. EXECUTAR A BUSCA (A MAGIA ACONTECE AQUI)
# =========================================================
print("\nIniciando o GridSearchCV (Isso pode levar de 1 a 3 minutos dependendo do seu processador)...")
inicio = time.time()

grid_search = GridSearchCV(
    estimator=pipeline_base,
    param_grid=param_grid,
    cv=5,               # Validação cruzada (divide o treino em 5 pedaços para validar)
    scoring='accuracy', # Nosso objetivo principal para otimização
    n_jobs=-1,          # Usa todos os núcleos do processador para paralelizar e ir mais rápido
    verbose=1           # Mostra o progresso no terminal
)

grid_search.fit(X_train, y_train)

tempo_total = time.time() - inicio

# =========================================================
# 4. RESULTADOS E AVALIAÇÃO DO MELHOR MODELO
# =========================================================
print("-" * 50)
print(f"Busca concluída em {tempo_total:.2f} segundos!")
print("-" * 50)
print(f"Melhores hiperparâmetros encontrados:\n{grid_search.best_params_}\n")

# O GridSearchCV já salva automaticamente o melhor modelo treinado com todos os dados de X_train
melhor_modelo = grid_search.best_estimator_

print("Avaliando o super-modelo nos dados de Teste (Dados Inéditos):")
y_pred = melhor_modelo.predict(X_test)

print(classification_report(y_test, y_pred))

print("Matriz de Confusão:")
print(confusion_matrix(y_test, y_pred))

# =========================================================
# 5. EXPORTAÇÃO DEFINITIVA
# =========================================================
nome_arquivo = 'pipeline_inseminacao_rf_otimizado.pkl'
joblib.dump(melhor_modelo, nome_arquivo)

print("-" * 50)
print(f"MVP Pronto! O modelo otimizado foi salvo como: '{nome_arquivo}'")
print("Basta substituir esse arquivo no seu backend FastAPI.")