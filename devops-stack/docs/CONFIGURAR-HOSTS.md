# Configuração do Arquivo Hosts para DevOps Stack

## Visão Geral

Para acessar os serviços da DevOps Stack pelos domínios configurados (ex: `gitea.local`), é necessário mapear esses domínios para o endereço IP da sua máquina local (127.0.0.1) no arquivo hosts do seu sistema operacional.

## Serviços e Domínios

| Serviço       | Domínio                 | Porta  | Descrição                     |
|---------------|-------------------------|--------|-------------------------------|
| Gitea         | http://gitea.local      | 3000   | Git server com UI            |
| Drone CI      | http://drone.local      | 80     | Pipeline CI/CD               |
| SonarQube     | http://sonar.local      | 9000   | Análise de qualidade de código |
| Grafana       | http://grafana.local:3001 | 3001 | Dashboard de monitoramento   |
| Prometheus    | http://localhost:9090   | 9090   | Coleta de métricas           |
| Loki          | http://localhost:3100   | 3100   | Armazenamento de logs        |
| cAdvisor      | http://localhost:8080   | 8080   | Monitoramento de containers  |
| Build Server  | http://localhost:8000   | 8000   | Ambiente de execução CI      |

**Nota:** Os serviços Prometheus, Loki, cAdvisor e Build Server são acessados via `localhost` (127.0.0.1) e, portanto, não requerem alterações no arquivo hosts. Apenas os domínios `gitea.local`, `drone.local`, `sonar.local` e `grafana.local` precisam ser mapeados.

## Configuração por Sistema Operacional

### Linux e macOS

1. Abra um terminal.
2. Abra o arquivo hosts com um editor de texto, usando sudo para permissões de escrita:

   ```bash
   sudo nano /etc/hosts
   ```

3. Adicione as seguintes linhas no final do arquivo:

   ```
   127.0.0.1    gitea.local drone.local sonar.local grafana.local
   ```

4. Salve o arquivo e saia do editor.

   - No nano: `Ctrl + O` para salvar, `Enter` para confirmar, `Ctrl + X` para sair.

5. Para verificar se as alterações foram aplicadas, execute:

   ```bash
   cat /etc/hosts
   ```

6. Opcionalmente, limpe o cache DNS do seu sistema:

   ```bash
   sudo systemctl restart systemd-resolved  # Para sistemas com systemd
   # ou
   sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder  # macOS
   ```

### Windows

1. Pressione `Win + R` para abrir a caixa de diálogo Executar.
2. Digite `notepad` e pressione `Ctrl + Shift + Enter` para abrir o Bloco de Notas como administrador.

   - Se não for possível, abra o menu Iniciar, procure por "Bloco de Notas", clique com o botão direito e selecione "Executar como administrador".

3. No Bloco de Notas, abra o arquivo hosts localizado em:

   ```
   C:\Windows\System32\drivers\etc\hosts
   ```

4. Adicione as seguintes linhas no final do arquivo:

   ```
   127.0.0.1    gitea.local
   127.0.0.1    drone.local
   127.0.0.1    sonar.local
   127.0.0.1    grafana.local
   ```

5. Salve o arquivo.

6. Abra o prompt de comando como administrador e execute o seguinte comando para limpar o cache DNS:

   ```cmd
   ipconfig /flushdns
   ```

## Verificação da Configuração

Para verificar se a configuração foi aplicada corretamente, execute os seguintes comandos:

```bash
ping gitea.local
ping drone.local
ping sonar.local
ping grafana.local
```

Cada comando deve retornar respostas de `127.0.0.1`.

## Solução de Problemas

- Se os domínios não estiverem resolvendo, verifique se o arquivo hosts foi salvo sem extensão (especialmente no Windows).
- Certifique-se de que não há erros de digitação no arquivo hosts.
- No Windows, se não conseguir salvar o arquivo hosts, certifique-se de que o Bloco de Notas foi executado como administrador.
- Após alterações, sempre limpe o cache DNS do seu sistema.

## Considerações Adicionais

- Em alguns sistemas, pode ser necessário reiniciar o navegador ou até mesmo o computador para que as alterações tenham efeito.
- Se você estiver usando uma rede corporativa, verifique se as configurações de proxy não estão interferindo na resolução de nomes locais.

## Acesso aos Serviços

Após configurar o arquivo hosts, você pode acessar os serviços pelos seguintes URLs:

- Gitea: http://gitea.local:3000
- Drone CI: http://drone.local
- SonarQube: http://sonar.local:9000
- Grafana: http://grafana.local:3001

Os demais serviços (Prometheus, Loki, cAdvisor, Build Server) já estão acessíveis via localhost nas portas indicadas.

---

**Nota:** Esta configuração é necessária apenas para desenvolvimento e testes locais. Em ambientes de produção, utilize um servidor DNS real ou registros DNS apropriados.