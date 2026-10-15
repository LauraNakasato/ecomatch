# EcoMatch

​Projeto desenvolvido para o seminário da disciplina de Logística e Meio Ambiente (UFABC).
O EcoMatch é um modelo de marketplace B2B focado em Simbiose Industrial e Logística Reversa.

​**Arquitetura Técnica**

​A base de dados foi modelada em PostgreSQL (Supabase) com a extensão PostGIS para geolocalização. O objetivo é cruzar indústrias que geram resíduos com indústrias que os compram.
​O diferencial deste backend é uma função SQL (Trigger) que, ao registar um novo match entre empresas, calcula a distância física entre elas e estima a pegada de carbono poupada ao evitar transportes longos e a extração de matéria-prima virgem.

​Ficheiro principal: schema.sql contém a modelagem completa das tabelas e o algoritmo de cálculo ambiental.
