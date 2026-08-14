---
tipo: instrucao-projeto
tags: [cap, cds, nodejs, btp, clean-core, s4hana]
status: ativo
date: 2026-08-14
---

# CLAUDE.md — Expert em SAP CAP (Node.js)

> Instrução para qualquer agente que trabalhe num projeto CAP Node.js.
> Copie este arquivo pra raiz do projeto (`./CLAUDE.md`) ou use como referência.
> Assume nível avançado. Não explique o básico de CDS, OData ou BTP.

---

## 0. Regras de ouro (não negociáveis)

1. **Clean Core sempre.** Nada de modificar objeto SAP standard. Extensão side-by-side ou in-app via API liberada.
2. **CDS é a fonte da verdade.** Modelo de dados, serviços e anotações vivem em `.cds`. Lógica só quando o CDS não resolve.
3. **Convention over configuration.** Se o CAP faz por convenção, não escreva handler. Handler genérico (CRUD) é anti-pattern.
4. **Segurança não é opcional.** Todo serviço tem `@requires` / `@restrict`. Serviço sem auth só com justificativa explícita.
5. **Multitenancy-ready por padrão.** Não assuma single-tenant. Nada de estado global, nada de schema hardcoded.
6. **Zero SQL cru.** Use CQL / CQN. `SELECT.from`, `INSERT.into`, etc. String de SQL só em último caso e comentada.

---

## 1. Stack e versões

- Runtime: **Node.js LTS** (18/20/22, checar `.nvmrc`).
- Framework: **@sap/cds** (CAP Node.js).
- ORM/Query: **CQL / CQN** nativo (não usar TypeORM/Prisma).
- DB local: **SQLite** (`@cap-js/sqlite`). DB produção: **SAP HANA Cloud** (`@cap-js/hana`).
- Deploy: **SAP BTP Cloud Foundry** ou **Kyma**. MTA via `mta.yaml`.
- Auth: **XSUAA** (prod) / **mocked-auth** (dev).
- Antes de sugerir API nova, checar versão do `@sap/cds` no `package.json`. A API muda entre major versions.

---

## 2. Estrutura de projeto (padrão CAP)

```
projeto/
  db/
    schema.cds          # entidades, aspects, tipos
    data/               # CSVs de seed (Entity-Namespace.csv)
  srv/
    service.cds         # service definitions (projections)
    service.js          # handlers (só o necessário)
    lib/                # lógica reutilizável, sem acoplar ao handler
  app/                  # UIs (Fiori elements / freestyle)
  test/
  package.json          # cds config em "cds": {}
  mta.yaml              # deploy descriptor
  .cdsrc.json           # profiles (dev/prod/hybrid)
```

Regra: `db` modela, `srv` expõe e protege, `app` consome. Não vaze lógica de negócio pra `app`.

---

## 3. Modelagem CDS (db/)

- Use **aspects** pra DRY: `managed` (createdAt/By, modifiedAt/By), `cuid` (UUID key), custom aspects próprios.
- Chave primária: **UUID** (`cuid`) por padrão. Sequencial só se o negócio exigir.
- Associations vs Compositions: **composition** = dono do ciclo de vida (deep insert/delete). **association** = referência.
- Reuse types (`@sap/cds/common`): `Country`, `Currency`, `Language`, `sap.common.CodeList`.
- Nunca duplique enum em string. Modele CodeList.
- Localização: use `localized` em campos de texto quando houver i18n.

```cds
using { cuid, managed, sap.common.CodeList } from '@sap/cds/common';

entity Contratos : cuid, managed {
  numero      : String(20) @mandatory;
  cliente     : Association to Clientes;
  itens       : Composition of many ContratoItens on itens.contrato = $self;
  status      : Association to StatusContrato;
  valorTotal  : Decimal(15,2) default 0;
}

entity StatusContrato : CodeList {
  key code : String(10);
}
```

---

## 4. Service layer (srv/)

- Serviço = **projeção** do modelo, não cópia. Exponha só o que a UI/consumidor precisa.
- Use `@readonly`, `@insertonly`, `@mandatory`, `@assert.*` no CDS antes de validar em JS.
- Actions/functions pra operações que não são CRUD (ex: `submitContrato`, `calcularReajuste`).
- Draft (`@odata.draft.enabled`) só quando a UI Fiori precisa de rascunho. Não ligue por reflexo.

```cds
using { my.domain as db } from '../db/schema';

service ContratoService @(requires: 'ContratoUser') {
  entity Contratos as projection on db.Contratos
    actions {
      action submit() returns Contratos;
    };
  @readonly entity Status as projection on db.StatusContrato;
}
```

---

## 5. Handlers (srv/*.js)

Ordem mental: **before** (valida/muta input) → **on** (executa, substitui o default) → **after** (enriquece output).

- `before`: validação, defaults, autorização fina.
- `on`: só quando precisa substituir o CRUD padrão ou implementar action.
- `after`: campos calculados, mascaramento, agregações.
- Nunca reimplemente CRUD que o CAP já faz. Se seu `on('READ')` só faz `SELECT`, apague.
- Erros: use `req.error(400, 'msg')` / `req.reject`. Não jogue `throw` cru.
- `req` carrega tenant e user. Use `req.user`, `cds.context.tenant`. Nunca hardcode.

```js
const cds = require('@sap/cds');

module.exports = class ContratoService extends cds.ApplicationService {
  init() {
    const { Contratos } = this.entities;

    this.before('CREATE', Contratos, req => {
      if (req.data.valorTotal < 0) req.error(400, 'valorTotal não pode ser negativo');
    });

    this.on('submit', async req => {
      const tx = cds.tx(req);
      await tx.update(Contratos).set({ status_code: 'SUBMITTED' }).where({ ID: req.params[0].ID });
      return req.reply();
    });

    return super.init();
  }
};
```

---

## 6. Query (CQL / CQN)

- Sempre CQL: `SELECT.from(Entity).where(...)`, `INSERT.into`, `UPDATE`, `DELETE`, `UPSERT`.
- Use `cds.tx(req)` pra ficar no contexto transacional/tenant certo.
- Expand via `.columns(c => { c('*'), c.itens('*') })` em vez de N+1.
- Nada de concatenar valor de usuário em query. CQN já parametriza, não abra brecha de injection.
- Serviço externo: use `cds.connect.to('ServiceName')` e consuma via API do próprio serviço, não fetch cru.

---

## 7. Integração e Clean Core

- Consumo de S/4HANA: importe o **serviço OData** como modelo externo (`cds import`), gere o serviço remoto, consuma via CQN.
- Extensão in-app só via **released APIs** (checar SAP API Business Hub / `whitelisted`).
- Eventos: use **CAP messaging** (`@sap/cds` messaging + Event Mesh / SAP Integration Suite). Emita/consuma eventos, não faça polling.
- Side-by-side na BTP é o default pra lógica que não cabe no Clean Core do S/4.
- Nunca acople direto no banco do S/4. Sempre via serviço/API.

```js
const s4 = await cds.connect.to('API_BUSINESS_PARTNER');
const bps = await s4.run(SELECT.from('A_BusinessPartner').where({ BusinessPartnerCategory: '2' }));
```

---

## 8. Segurança

- `@requires: 'role'` no serviço. `@restrict` pra regra fina (grant/where).
- Roles definidos em `xs-security.json`, mapeados em role collections na BTP.
- Instance-based auth: `@restrict: [{ grant: 'READ', where: 'cliente.owner = $user' }]`.
- Nunca confie em input. `@assert.range`, `@assert.format`, validação no `before`.
- Segredos: **destinations / credential store da BTP**. Nunca `.env` commitado, nunca hardcode.

---

## 9. Testes

- `cds.test` pra testes de integração de serviço (sobe o servidor em memória com SQLite).
- Teste comportamento do serviço (request → response), não implementação interna.
- Cubra: happy path, validação (400), autorização (403), edge de composition.

```js
const cds = require('@sap/cds');
const { GET, POST, expect } = cds.test(__dirname + '/..');

describe('ContratoService', () => {
  it('rejeita valor negativo', async () => {
    await expect(POST('/contrato/Contratos', { valorTotal: -1 }))
      .to.be.rejectedWith(/negativo/);
  });
});
```

---

## 10. Deploy BTP

- `mta.yaml` descreve módulos (srv, db-deployer, app) e recursos (HANA, XSUAA, destination).
- Build: `mbt build`. Deploy: `cf deploy mta_archives/*.mtar`.
- Migração de schema: **cds deploy** / hdi-deployer. Nunca `DROP` em prod sem migration.
- Profiles: `cds.requires` por profile (`[development]` SQLite mock, `[production]` HANA + XSUAA).
- Multitenancy: `@sap/cds-mtxs` pra provisionamento por tenant.

---

## 11. Anti-patterns (não faça)

- Handler `on('READ')` que só refaz o SELECT default.
- Lógica de negócio na UI (`app/`) em vez do serviço.
- SQL string concatenada com input de usuário.
- Modificar objeto SAP standard (fere Clean Core).
- Serviço sem `@requires`.
- Estado global no módulo (quebra multitenancy).
- Expor a entidade `db` inteira sem projeção.
- Reimplementar draft/CRUD que o CAP já entrega.

---

## 12. Checklist antes de dar PR

- [ ] Modelo em CDS, não em JS.
- [ ] Serviço protegido (`@requires`/`@restrict`).
- [ ] Sem SQL cru, tudo CQN.
- [ ] Sem acoplamento a standard SAP (Clean Core ok).
- [ ] Multitenant-safe (sem estado global, tenant via `req`).
- [ ] Testes de serviço cobrindo validação e auth.
- [ ] `mta.yaml` e profiles atualizados.
- [ ] i18n onde houver texto pro usuário.

---

## Conexões
- [[CLAUDE]]
- [[INDEX - Dante OS]]
