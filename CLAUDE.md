# n8n-builder

Questo progetto usa Claude Code per creare workflow n8n di alta qualità su richiesta dell'utente. Claude dispone di due strumenti principali: il **server MCP n8n** (accesso diretto all'API n8n) e le **N8N Skills** (expertise specializzata per la qualità dei workflow).

## Obiettivo Primario

Quando l'utente chiede un workflow n8n, Claude DEVE:
1. Capire a fondo il requisito prima di costruire
2. Seguire il processo di creazione descritto sotto
3. Restituire il link completo al workflow alla fine — ogni volta, senza eccezioni

La risposta finale all'utente DEVE sempre includere:
```
✅ Workflow creato: http://localhost:5678/workflow/<id>
📋 Nome: <nome del workflow>
🔗 URL Webhook (se presente): <url>
🧪 Test: <esito dell'esecuzione di test>
```

---

## Strumento 1: Server MCP n8n (`czlonkowski/n8n-mcp`)

Il server MCP dà a Claude accesso programmatico diretto a n8n con 1.236 nodi documentati e 2.709 template.

### Configurazione

Creare il file `.mcp.json` nella root del progetto (se non esiste):

```json
{
  "mcpServers": {
    "n8n-mcp": {
      "command": "npx",
      "args": ["n8n-mcp"],
      "env": {
        "MCP_MODE": "stdio",
        "LOG_LEVEL": "error",
        "DISABLE_CONSOLE_OUTPUT": "true",
        "N8N_API_URL": "http://localhost:5678",
        "N8N_API_KEY": "<inserire_qui_la_propria_api_key>",
        "WEBHOOK_SECURITY_MODE": "moderate"
      }
    }
  }
}
```

Per ottenere la API Key: in n8n vai su `Impostazioni → API → Crea API Key`.

### Tool di Documentazione (sempre disponibili)

Usare questi tool PRIMA di costruire per ricercare nodi e validare le scelte:

| Tool | Scopo |
|------|-------|
| `search_nodes` | Trovare il nodo giusto per un task |
| `get_node` | Dettagli completi del nodo (modalità: `info`, `docs`, `search_properties`) |
| `validate_node` | Validare la configurazione di un nodo prima dell'uso |
| `search_templates` | Trovare template esistenti (modalità: `keyword`, `by_nodes`, `by_task`) |
| `get_template` | Recuperare un template completo |
| `search_community_nodes` | Cercare nodi della community |
| `tools_documentation` | Meta-documentazione di tutti i tool MCP |
| `ai_agents_guide` | Guida per workflow con AI agent |

### Tool di Gestione Workflow (richiedono N8N_API_URL + N8N_API_KEY)

| Tool | Scopo |
|------|-------|
| `n8n_create_workflow` | Crea un nuovo workflow (ritorna l'ID) |
| `n8n_update_partial_workflow` | Aggiornamento incrementale — **PREFERIRE SEMPRE** alle riscritture complete (17 tipi di operazione, 99% success rate) |
| `n8n_validate_workflow` | Valida un workflow per ID dopo la creazione |
| `n8n_autofix_workflow` | Auto-fix problemi di validazione comuni |
| `n8n_deploy_template` | Deploy diretto di un template in n8n |
| `n8n_test_workflow` | Esegue un test del workflow |
| `n8n_executions` | Storico esecuzioni |
| `list_workflows` / `get_workflow` | Elenco e recupero workflow esistenti |
| `execute_workflow` | Trigger manuale di un workflow |
| `delete_workflow` | Elimina un workflow (irreversibile) |

### Pattern d'Uso Tipici

```
Ricerca:   search_nodes → get_node → search_templates
Crea:      n8n_create_workflow → n8n_validate_workflow
Aggiorna:  n8n_update_partial_workflow → n8n_validate_workflow (ripeti fino a clean)
Fix:       n8n_validate_workflow → n8n_autofix_workflow → n8n_validate_workflow
```

**Nota:** `n8n_update_partial_workflow` è sempre preferibile alle riscritture complete. Un'attesa di ~56 secondi tra le modifiche è normale.

---

## Strumento 2: N8N Skills (`czlonkowski/n8n-skills`)

**Installazione:** `/plugin install czlonkowski/n8n-skills`

Le 7 skill si attivano **automaticamente** in base al contesto — non invocarle manualmente.

| Skill | Quando si attiva |
|-------|-----------------|
| **n8n MCP Tools Expert** | Sempre — selezione e uso corretto dei tool MCP (priorità massima) |
| **n8n Expression Syntax** | Scrittura espressioni `{{}}`, variabili `$json`, `$node`, `$workflow` |
| **n8n Workflow Patterns** | Progettazione architettura e struttura del workflow |
| **n8n Validation Expert** | Errori di validazione (~40% sono falsi positivi) |
| **n8n Node Configuration** | Configurazione nodi, dipendenze tra proprietà, operation-specific settings |
| **n8n Code JavaScript** | Nodi Code in JS, formato `[{json: {...}}]`, `$helpers`, DateTime |
| **n8n Code Python** | Nodi Code in Python (usare JS nel 95% dei casi per le limitazioni delle librerie) |

**⚠️ Gotcha critico:** I dati webhook sono sempre sotto `$json.body`, MAI `$json` direttamente. Questo è l'errore più comune.

---

## Processo di Creazione Workflow

Seguire questi step per ogni richiesta di workflow:

### Step 1: Analisi della Richiesta
Prima di costruire qualsiasi cosa, confermare:
- Qual è il **trigger** del workflow? (webhook, schedule, manuale, evento)
- Quali sono i **dati in input** attesi?
- Qual è l'**output** o il risultato finale?
- Ci sono **servizi esterni** da integrare? (chiedere credenziali/API key se necessarie)
- Il workflow deve essere **attivato subito** dopo la creazione?

### Step 2: Ricerca
```
1. search_templates (by_task o keyword) — verifica se esiste già un template
2. search_nodes — identifica i nodi giusti per ogni step
3. get_node (dettaglio completo) — conferma proprietà e operazioni del nodo
```

### Step 3: Scegliere il Pattern Architetturale
Scegliere uno dei 5 pattern prima di costruire:
- **Webhook**: trigger esterno → processa → risponde
- **HTTP API**: scheduled/manuale → fetch dati → trasforma → archivia/notifica
- **Database**: trigger → query → trasforma → scrittura
- **AI Agent**: input → loop di ragionamento AI → tool → output
- **Scheduled**: trigger cron → fetch → processa → consegna

Decomporre workflow grandi (>30 nodi) in sub-workflow. Ogni sub-workflow deve fare una cosa sola.

### Step 4: Build
```
n8n_create_workflow (con definizioni complete dei nodi)
  → n8n_validate_workflow
  → n8n_update_partial_workflow (fix problemi)
  → n8n_validate_workflow (ripetere fino a clean)
```

Se esiste un template, usare `n8n_deploy_template` poi `n8n_update_partial_workflow` per personalizzarlo.

### Step 5: Test
```
n8n_test_workflow → n8n_executions (verifica risultato)
```

Rivedere l'output dell'esecuzione e correggere eventuali errori runtime prima di consegnare.

### Step 6: Restituire il Link

Dopo creazione e validazione, fornire sempre:
```
✅ Workflow creato: http://localhost:5678/workflow/<id>
📋 Nome: <nome descrittivo>
🔗 URL Webhook (se presente): <url webhook di produzione>
🧪 Test: Eseguito con successo / Fallito (<dettaglio errore>)
```

---

## Standard di Qualità

Ogni workflow creato da Claude DEVE rispettare questi standard. Nessuna eccezione.

### Nomi dei Nodi
- Mai usare nomi generici di default (es. "HTTP Request", "Merge", "Code", "IF")
- Iniziare sempre con un verbo: "Recupera Dati Utente", "Invia Notifica Slack", "Valida Email"
- I nomi devono essere 3–7 parole che descrivono esattamente cosa fa il nodo
- Sub-workflow: prefisso `"Sub - "` (es. "Sub - Formatta Dati Fattura")

### Gestione degli Errori
Ogni workflow DEVE includere:
- **Retry on Fail**: abilitare su tutti i nodi con chiamate API esterne (3 retry, 1s di attesa)
- **Continue on Fail**: abilitare sui nodi di batch processing
- **Error Workflow**: configurare un workflow di errore centralizzato per gli alert di fallimento
- **Validazione input**: usare un nodo IF all'inizio dei webhook per validare i campi richiesti
- **Nodo Stop and Error**: per fallimenti espliciti su condizioni non recuperabili

### Credenziali
- Usare sempre il credential manager di n8n. Mai hardcodare API key o segreti nei parametri
- Nominare le credenziali in modo descrittivo (es. "Stripe Produzione", "SendGrid Marketing")
- Se le credenziali non sono ancora configurate, segnalarlo nell'handoff con istruzioni

### Struttura del Workflow
- Massimo 30 nodi per workflow — estrarre logica riutilizzabile in sub-workflow
- Aggiungere un nodo **Sticky Note** all'inizio con: scopo, trigger, input atteso, output atteso
- Ogni ramo di nodi IF o Switch DEVE essere connesso — nessun ramo morto
- Trigger in alto a sinistra, sviluppo da sinistra a destra

### ⚠️ Avvertenza Importante
MAI modificare workflow di produzione direttamente con AI. Lavorare sempre su copie o ambienti di sviluppo. I risultati AI possono essere imprevedibili.

---

## Convenzioni di Naming

| Elemento | Formato | Esempio |
|----------|---------|---------|
| Workflow | `[Trigger] - [Scopo]` | `Webhook - Processa Ordini Stripe` |
| Sub-workflow | `Sub - [Scopo]` | `Sub - Formatta Dati Fattura` |
| Scheduled | `Schedule - [Scopo]` | `Schedule - Report Giornaliero Vendite` |
| Nodo | Verbo + sostantivo specifico | `Recupera Ordini Cliente`, `Invia Alert Slack` |
| Tag | Parole di categoria | `produzione`, `fatturazione`, `notifiche`, `dev` |

---

## Gestione Errori Comuni

### Errori Tool MCP
- Se `n8n_create_workflow` fallisce: verificare che `N8N_API_URL` e `N8N_API_KEY` siano configurati nel `.mcp.json`
- Se `n8n_validate_workflow` restituisce warning: usare prima `n8n_autofix_workflow`; investigare manualmente solo se i problemi persistono dopo l'autofix
- Se la validazione va in loop (fix → valida → stesso errore): il warning è probabilmente un falso positivo; documentarlo e procedere
- Se `n8n_test_workflow` fallisce: leggere l'errore in `n8n_executions`, correggere il nodo responsabile, ri-validare, ri-testare

### Errori API n8n
- **401 Unauthorized**: API key non valida o non impostata — fermarsi e chiedere all'utente di verificare la chiave n8n
- **404 Not Found**: ID workflow inesistente — verificare con `list_workflows`
- **409 Conflict**: nome workflow già esistente — aggiungere suffisso versione o chiedere all'utente
- **422 Unprocessable**: configurazione nodo non valida — usare `validate_node` sul nodo specifico

### Quando Fermarsi e Chiedere
Fermarsi e chiedere all'utente quando:
- Le credenziali richieste non sono disponibili in n8n
- Il requisito è ambiguo in modo tale da cambiare l'architettura
- Un nodo o un'integrazione richiesta non esiste e non ci sono alternative community
- L'istanza n8n non è raggiungibile (i tool MCP restituiscono errori di connessione)

---

## Checklist Pre-Fine Sessione

Prima di terminare qualsiasi sessione, verificare:
- [ ] Workflow creato in n8n (confermato con `get_workflow`)
- [ ] Validazione pulita (`n8n_validate_workflow` senza errori)
- [ ] Almeno un'esecuzione di test completata con successo
- [ ] URL del workflow restituito all'utente nel formato corretto
- [ ] Tutte le modifiche committate e pushate

---

## Setup Iniziale (una tantum)

1. Ottenere la API Key di n8n: `Impostazioni → API → Crea API Key`
2. Copiare `.mcp.json` nella root del progetto e inserire la propria API key
3. Installare le skill: `/plugin install czlonkowski/n8n-skills`
4. Verificare la connessione: chiedere a Claude "elenca i workflow n8n attivi"

**Repository di riferimento:**
- Server MCP: https://github.com/czlonkowski/n8n-mcp
- Skills: https://github.com/czlonkowski/n8n-skills
