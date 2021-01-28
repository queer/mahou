# mahou

魔法 - Mahō is a highly-opinionated yet quite magical infrastructure stack for microservice-based applications.

https://mahou.io

CLI:
- https://github.com/queer/wand: CLI interface for the entire system.

Powered by:
- https://github.com/queer/singyeong: Message queuing, pubsub, HTTP proxying, and more. Its own standalone project.
- https://github.com/queer/crush: Consistent, distributed, replicated, time-traveling JSON store. Its own standalone project.

Control plane:
- https://github.com/queer/pig: The Pretty Insane Group scheduler, schedules containers across 악마-managed hosts. "Pretty-Insane" because why would I ever write my own container scheduler lmao

Data plane:
- https://github.com/queer/agma: Host daemon, stats, container mangler
- ~~https://github.com/queer/shoujo~~ TODO: ingress + autossl + router
- ~~https://github.com/queer/sajeon~~ TODO: autodoc

Shared code:
- https://github.com/queer/libmahou: Shared code library that holds everything together.
