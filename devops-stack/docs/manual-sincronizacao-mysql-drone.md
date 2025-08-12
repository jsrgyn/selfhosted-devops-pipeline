# Manual Completo: Sincronização de Schema e Dados MySQL com Drone CI

Objetivo

Este guia apresenta uma solução automática e robusta para:
	•	Comparar schemas entre ambientes MySQL 8 (DEV → HML → PRD).
	•	Sincronizar dados de tabelas específicas (ex.: produto).
	•	Integrar o processo em uma pipeline Drone CI.
	•	Garantir precisão e segurança com ferramentas open-source.

⸻

## Ferramentas Utilizadas

Ferramenta	Finalidade	Licença
Liquibase	Comparação e sincronização de schema.	Apache 2.0
Skeema	Modelagem e migração de schema MySQL.	Apache 2.0
mysqldump + pt-table-sync (Percona Toolkit)	Comparação e sincronização de dados.	GPL
Drone CI	Automação CI/CD.	Apache 2.0


⸻

### Pré-requisitos
	•	MySQL 8 instalado nos ambientes DEV, HML, PRD.
	•	Acesso via usuário com privilégios de SELECT, SHOW VIEW, TRIGGER, EVENT, LOCK TABLES e ALTER.
	•	Servidor Drone CI configurado com runner e plugins Docker habilitados.
	•	Docker disponível no runner.
	•	Conexões MySQL expostas via rede interna ou VPN.

⸻

## Estrutura da Solução
	1.	Comparar Schema
Usar Liquibase diff ou Skeema diff para gerar scripts de atualização.
	2.	Aplicar Schema no Destino
Executar scripts no ambiente alvo.
	3.	Comparar Dados
Usar pt-table-sync para gerar e aplicar diffs de dados.
	4.	Pipeline CI/CD
Executar de forma sequencial: DEV → HML → PRD.

⸻

## Exemplo Prático

### Cenário
	•	DEV: mysql-dev.local
	•	HML: mysql-hml.local
	•	PRD: mysql-prd.local

### Tabelas envolvidas:
	•	teste01 → Apenas schema.
	•	produto → Schema + dados.

⸻

## Configuração do Liquibase

Crie o arquivo liquibase.properties:

changeLogFile=changelog.xml
driver=com.mysql.cj.jdbc.Driver

# Banco de origem (DEV)
referenceUrl=jdbc:mysql://mysql-dev.local:3306/meubanco?useSSL=false
referenceUsername=dev_user
referencePassword=dev_pass

# Banco de destino (HML)
url=jdbc:mysql://mysql-hml.local:3306/meubanco?useSSL=false
username=hml_user
password=hml_pass

Gerar diferença de schema:

```bash 
liquibase --defaultsFile=liquibase.properties diffChangeLog
```

Aplicar mudanças no destino:

```bash
liquibase --defaultsFile=liquibase.properties update
```

⸻

Sincronizando Dados com Percona Toolkit

Para sincronizar apenas a tabela produto:

```bash
pt-table-sync \
  --execute \
  --sync-to-master \
  h= mysql-hml.local,u=hml_user,p=hml_pass,D=meubanco,t=produto \
  h= mysql-dev.local,u=dev_user,p=dev_pass
```

No modo dry-run (somente ver diferenças):

```bash
pt-table-sync \
  --print \
  h= mysql-hml.local,u=hml_user,p=hml_pass,D=meubanco,t=produto \
  h= mysql-dev.local,u=dev_user,p=dev_pass
```

⸻

### Pipeline .drone.yml Completo

```yml
kind: pipeline
type: docker
name: mysql-schema-data-sync

steps:
  - name: compare-schema-dev-to-hml
    image: liquibase/liquibase:latest
    environment:
      LIQUIBASE_COMMAND_CHANGELOG_FILE: changelog-dev-hml.xml
    commands:
      - liquibase --defaultsFile=liquibase-dev-hml.properties diffChangeLog
      - liquibase --defaultsFile=liquibase-dev-hml.properties update

  - name: sync-produto-data-dev-to-hml
    image: percona/percona-toolkit:latest
    commands:
      - pt-table-sync \
          --execute \
          --sync-to-master \
          h=mysql-hml.local,u=hml_user,p=$HML_PASS,D=meubanco,t=produto \
          h=mysql-dev.local,u=dev_user,p=$DEV_PASS

  - name: compare-schema-hml-to-prd
    image: liquibase/liquibase:latest
    commands:
      - liquibase --defaultsFile=liquibase-hml-prd.properties diffChangeLog
      - liquibase --defaultsFile=liquibase-hml-prd.properties update

  - name: sync-produto-data-hml-to-prd
    image: percona/percona-toolkit:latest
    commands:
      - pt-table-sync \
          --execute \
          --sync-to-master \
          h=mysql-prd.local,u=prd_user,p=$PRD_PASS,D=meubanco,t=produto \
          h=mysql-hml.local,u=hml_user,p=$HML_PASS

trigger:
  branch:
    - main
```

⸻

## Recursos Avançados
### 1.	Backup Automático Antes da Execução

```bash
mysqldump -h mysql-hml.local -u hml_user -p$HML_PASS meubanco > backup_hml.sql
``` 

### 2.	Validação Pós-Sincronização

	•	Usar pt-table-checksum para garantir integridade.

```bash
pt-table-checksum \
  h=mysql-hml.local,u=hml_user,p=$HML_PASS,D=meubanco
``` 

### 3.	Controle de Execução por Flag

	•	Configurar variáveis no Drone para rodar somente quando houver mudanças.
### 4.	Logs Centralizados

	•	Enviar logs para Elasticsearch/Kibana para auditoria.

⸻

### Boas Práticas

	•	Sempre validar o diff antes de aplicar.
	•	Usar usuário com permissões mínimas necessárias.
	•	Configurar rede segura (VPN/TLS).
	•	Testar em ambiente de staging antes de PRD.
	•	Habilitar backup automático no início da pipeline.

⸻

Links Oficiais

 -	[Liquibase Documentation](https://www.liquibase.org/documentation/index.html)
 -	[Skeema Documentation](https://www.skeema.io/docs/)
 -	[Percona Toolkit Documentation](https://docs.percona.com/percona-toolkit/)
 -	[Drone CI Documentation](https://docs.drone.io/)
 
 ⸻