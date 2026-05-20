# Configuração do Supabase - UniReceitas

## O que é Supabase?

Supabase é um backend open-source que fornece:
- **Autenticação** integrada com PostgreSQL
- **Banco de dados** PostgreSQL
- **APIs** REST automáticas
- **Sincronização** em tempo real
- **Storage** para arquivos

## Passo 1: Criar Conta no Supabase

1. Acesse [https://supabase.com](https://supabase.com)
2. Clique em "Sign Up"
3. Faça login com GitHub, Google ou crie uma conta com email

## Passo 2: Criar Novo Projeto

1. Na dashboard, clique em "New Project"
2. Preencha os dados:
   - **Project Name**: `unireceitas`
   - **Database Password**: Crie uma senha forte e guarde!
   - **Region**: Escolha a mais próxima de você
3. Aguarde o projeto ser criado (pode levar 2-3 minutos)

## Passo 3: Obter Credenciais

Após o projeto ser criado:

1. Vá em **Settings** → **API**
2. Copie:
   - **Project URL** (será sua `supabaseUrl`)
   - **anon public key** (será sua `supabaseKey`)

## Passo 4: Configurar as Tabelas no Banco de Dados

### Tabela `usuarios`

No editor SQL do Supabase, execute:

```sql
CREATE TABLE usuarios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  senha TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Tabela `receitas`

```sql
CREATE TABLE receitas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nome TEXT NOT NULL,
  ingredientes TEXT NOT NULL,
  modo_preparo TEXT NOT NULL,
  tempo_preparo TEXT NOT NULL,
  proprietario_id UUID REFERENCES usuarios(id) ON DELETE CASCADE,
  acesso TEXT DEFAULT 'privada',
  favorita BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Criar Índices (para melhor performance)

```sql
CREATE INDEX idx_receitas_proprietario ON receitas(proprietario_id);
CREATE INDEX idx_receitas_acesso ON receitas(acesso);
```

## Passo 5: Configurar as Políticas de Acesso (RLS)

### Habilitar RLS

1. Vá para **Authentication** → **Policies**
2. Para a tabela `usuarios`:
   - Clique em "Enable RLS"
   - Crie uma política: usuários só podem ler/atualizar seus próprios dados

3. Para a tabela `receitas`:
   - Clique em "Enable RLS"
   - Crie políticas para leitura de públicas e leitura/escrita de privadas

### Políticas SQL Recomendadas

**Para `usuarios`:**
```sql
-- Qualquer um autenticado pode ler todos os usuários
CREATE POLICY "Todos podem ler usuários" ON usuarios
FOR SELECT USING (true);

-- Usuários só podem atualizar seus próprios dados
CREATE POLICY "Usuários atualizam próprios dados" ON usuarios
FOR UPDATE USING (auth.uid()::text = id::text);
```

**Para `receitas`:**
```sql
-- Todos podem ler receitas públicas
CREATE POLICY "Ler receitas públicas" ON receitas
FOR SELECT USING (acesso = 'publica' OR proprietario_id::text = auth.uid()::text);

-- Usuários podem criar receitas
CREATE POLICY "Usuários criam receitas" ON receitas
FOR INSERT WITH CHECK (proprietario_id::text = auth.uid()::text);

-- Usuários podem atualizar suas próprias receitas
CREATE POLICY "Usuários atualizam suas receitas" ON receitas
FOR UPDATE USING (proprietario_id::text = auth.uid()::text);

-- Usuários podem deletar suas próprias receitas
CREATE POLICY "Usuários deletam suas receitas" ON receitas
FOR DELETE USING (proprietario_id::text = auth.uid()::text);
```

## Passo 6: Atualizar Credenciais no Projeto

1. Abra `lib/config/supabase_config.dart`
2. Substitua:
   - `YOUR_SUPABASE_PROJECT` pela URL do seu projeto
   - `YOUR_SUPABASE_KEY` pela sua anon key

Exemplo:
```dart
static const String supabaseUrl = 'https://abcdefgh123456.supabase.co';
static const String supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

## Passo 7: Testar Conexão

Execute o app e verifique no console:
- Se vir erro: credenciais incorretas
- Se funcionar: sucesso! Os dados serão sincronizados

## Modo Offline-First

O app funciona mesmo sem internet:
- Dados são salvos **localmente primeiro** (SQLite)
- Quando conectar à internet, dados sincronizam com Supabase
- Sem perda de dados!

## Dicas de Segurança

⚠️ **IMPORTANTE:**
- Nunca compartilhe sua `supabaseKey`
- Use variáveis de ambiente em produção
- A `anon key` é pública, use RLS para proteção
- Para produção, configure uma `service_key` separada

## Troubleshooting

### Erro: "Supabase não está configurado"
- Verifique se preencheu as credenciais em `supabase_config.dart`

### Erro: "Falha ao sincronizar"
- Verifique sua conexão de internet
- Verifique as políticas RLS no Supabase

### Dados não aparecem
- Verifique em **SQL Editor** se os dados estão na tabela
- Verifique as políticas RLS

## Próximos Passos

1. Integrar autenticação melhorada com email/senha
2. Adicionar upload de fotos de receitas
3. Configurar sincronização em tempo real
4. Adicionar backup automático

## Referências

- [Documentação Supabase](https://supabase.com/docs)
- [Supabase Flutter SDK](https://pub.dev/packages/supabase_flutter)
- [SQL Editor Tutorial](https://supabase.com/docs/reference/sql)
