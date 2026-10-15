-- 1. Ativar a extensão de geolocalização (PostGIS)
CREATE EXTENSION IF NOT EXISTS postgis;

-- 2. Criar a tabela de Empresas
CREATE TABLE companies (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_name text NOT NULL,
  cnpj text UNIQUE NOT NULL,
  industry_type text,
  zip_code text,
  latitude double precision,
  longitude double precision,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Criar a tabela de Materiais/Resíduos
CREATE TABLE materials (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  company_id uuid REFERENCES companies(id) NOT NULL,
  material_name text NOT NULL,
  category text,
  quantity_kg numeric NOT NULL,
  status text DEFAULT 'available',
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Criar a tabela de Matches (Negociações)
CREATE TABLE matches (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  material_id uuid REFERENCES materials(id) NOT NULL,
  buyer_company_id uuid REFERENCES companies(id) NOT NULL,
  match_status text DEFAULT 'pending',
  carbon_saved_estimate_kg numeric,
  created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Criar a função que calcula a distância e o carbono poupado
CREATE OR REPLACE FUNCTION calculate_carbon_saved()
RETURNS TRIGGER AS $$
DECLARE
  lat_geradora FLOAT;
  lon_geradora FLOAT;
  lat_compradora FLOAT;
  lon_compradora FLOAT;
  distancia_km FLOAT;
  peso_material FLOAT;
  -- Fator de emissão fictício: 0.15 kg de CO2 por tonelada por km rodado (transporte rodoviário)
  fator_emissao FLOAT := 0.15; 
BEGIN
  -- Pegar as coordenadas da empresa compradora
  SELECT latitude, longitude INTO lat_compradora, lon_compradora 
  FROM companies WHERE id = NEW.buyer_company_id;

  -- Pegar as coordenadas da empresa geradora e o peso do resíduo (cruzando as tabelas)
  SELECT c.latitude, c.longitude, m.quantity_kg INTO lat_geradora, lon_geradora, peso_material
  FROM materials m
  JOIN companies c ON m.company_id = c.id
  WHERE m.id = NEW.material_id;

  -- Calcular a distância em km usando a extensão PostGIS
  distancia_km := ST_DistanceSphere(
    ST_MakePoint(lon_geradora, lat_geradora), 
    ST_MakePoint(lon_compradora, lat_compradora)
  ) / 1000;

  -- Calcular a estimativa de carbono poupado (Peso em toneladas * Distância em km * Fator de emissão)
  NEW.carbon_saved_estimate_kg := (peso_material / 1000) * distancia_km * fator_emissao;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. Criar o Gatilho (Trigger) para executar a função automaticamente sempre que houver um match
CREATE TRIGGER trigger_calculate_carbon
BEFORE INSERT ON matches
FOR EACH ROW
EXECUTE FUNCTION calculate_carbon_saved();
