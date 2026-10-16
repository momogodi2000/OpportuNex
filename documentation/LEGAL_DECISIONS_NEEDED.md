# Legal and governance decisions still needed (owner action)

- [ ] Search for prior trademarks on the name "Opportunex" (Cameroon/OAPI, EU, US) before public launch.
- [ ] Confirm that ETS Monthe Network is the legal entity publishing the software, and that Momo Godi Yvan's contributions are licensed or assigned to it (affects the copyright line in `NOTICE`).
- [ ] Get a lawyer to check the dual-licensing clause (commercial licence alongside AGPL v3) and the inbound licence grant in `CONTRIBUTING.md`.
- [ ] Apply to SignPath Foundation (free code signing for open-source projects). Until it is approved, binaries ship unsigned.
- [ ] Set up an official contact address for security reports (`SECURITY.md`) and support (user guide).
- [ ] Review the terms of use of each source in the catalogue (D-20). Sources without clear permission are disabled by default.
- [ ] Confirm the AGPL compatibility of the `regex` package (Apache-2.0 AND CNRI-Python, a transitive dependency of `dateparser`); see `THIRD_PARTY_NOTICES.md`, section "Reviewed by hand".
- [ ] Decide whether `documentation/Ai-agents-rule/` stays in the repository. It holds 854 files of third-party AI-agent
      skill packs that are not part of Opportunex and do not ship with it. Three packs are MIT-licensed
      (`awesome-agent-skills-main`, `awesome-design-skills-main`, `ui-ux-pro-max-skill-main`); six have **no licence
      file** (`acquire-codebase-knowledge`, `agentic-workflows`, `ai-team-orchestration`, `developer`,
      `devops-rollout-plan`, `error-messages`), so their redistribution terms are unknown. Recommended: move them out of
      the public repository before publication.
