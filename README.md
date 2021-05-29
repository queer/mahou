# mahou 魔法

魔法 - Mahō is a highly-opinionated yet quite magical research project into
microservice-based application infrastructure.

https://mahou.io

https://discord.gg/RQZ8CV9ceQ

## Current status

魔法 is in the **prototype** stage. It's the bare minimum of "this stuff works
enough that more functionality can be built." You should not attempt to use
this for anything but development.

## Table of contents

- [What is it?](#what-is-it)
  - [Specifics vs. semantics](#specifics-vs-semantics)
  - [But this doesn't work for \<application type\>!](#but-this-doesnt-work-for-application-type)
- [Opinionated?](#opinionated)
- [Why?](#why)
- [How does it work?](#how-does-it-work)
- [Pieces and parts](#pieces-and-parts)

## What is it?

More specifically, 魔法 is an exploration into what microservice infrastructure
could look like if we didn't cling to the legacy we have. While this legacy
exists for very good reason, as massive amounts of legacy code depends on it,
魔法 does not aim to support that as a use-case. Instead, the goal of 魔法 is to
try and see what the world might look like in a future version of app
development, where we look past the *specifics* of what our code does and
instead think more about the semantics, *what* the goal is.

To expand on what this means, [this blog post I wrote](https://b.amy.gg/what-might-messaging-be)
may be helpful.

### Specifics vs. semantics

In 魔法's worldview, *specifics* are *how* your application does something. This
is the layer 魔法 focuses on, and tries to keep out of mind. For an example, we
traditionally have to think about *how* to do things:

- *how* to discover a service
- *how* to communicate with a service (HTTP, MQ, ...)
- *how* to deploy some code
- *how* to document inter-service layers
- *how* to handle a service going down

The goal of 魔法 is that you don't have to think about these layers. Instead, the
魔法 way of doing things is to describe the *semantics* of *what* you want. So
for example, instead of saying "Connect to Consul/Etcd/... to find a service,
and hit this REST endpoint, and do this to handle failure and recovery," 魔法's
goal is that you can describe WHAT you want: "send a message to this service,
to what takes this kind of message, and await a response." While this may seem
a lot like the *specifics*, it's at a higher level -- rather than saying *how*
it should be done, and worrying about the plumbing required to do so, you
should be able to describe the *semantics* of what you want, and let all the
infrastructure layers figure it out for you.

This extends down to things like deploying code. You shouldn't have to describe
all the specifics of exactly what a service wants / needs. You should just be
able to say "Here's some code, here's some minimal info about what it does.
Make it happen." Ideally, 魔法 would be able to analyse the behaviour of your
application -- things like latencies, CPU / RAM usage, ... -- and automagically
be able to handle scaling, load-balancing, potentially spawning more nodes for
the cluster, ...

### But this doesn't work for \<application type\>!

And that's okay! Not everything can / will fit into this idea, and it's pretty
unlikely that this takes over the world of app development / deployment. 魔法 is
just an exploration into what we could be doing better.

Additionally, 魔法 is meant to be incrementally adopted. You don't need to opt
into the entire worldview to get benefit out of it! Instead, you can just use
the bits and pieces you want. You might use just 신경 to move messages around, or
you might just use it to adopt automagic documentation into your services, or
you might go all the way! It's completely up to you.

## Opinionated?

Apps managed by 魔法 are expected to fit into several patterns:

- They don't care about their host port bind, as 魔法 assigns one to them.
- They don't care about DNS, as 魔法 requires all communication to be via 신경 for
  load-balancing, failover, autodoc, ...
- They do not want to talk to other applications directly, don't want to deal
  with service discovery, etc. See previous point.
- They are stateless, as 魔法 does not aim to support stateful apps. If you need
  a database, your cloud provider is more than happy to sell it to you.
- They are HTTP servers, or they don't care about serving requests of some
  sort. 魔法 is not meant for hosting game servers or the like in its current
  form.

If your app doesn't agree with these, it's not a good fit for 魔法. Existing
tooling like [Kubernetes](https://kubernetes.io) is a better choice for you.

## Why?

My work, both personal and professional, is around developer tooling and app
infrastructure. A problem I often run into is that dev tooling **sucks**. For
any number of reasons, really:

- is very in-your-face, forcing you to dump in a lot of brain power, or write
  massive config files, or...
- is quite buggy, generates broken / confusing code, abuses a language's type
  system to create incomprehensible errors, ...
- requires self-hosting a bunch of extra tooling
- has a complicated setup / installation process
- breaks with errors that lead to the tool's source code when searched up, and
  there's no other results.
- straight-up doesn't work
- \<insert your reason here\>

While I understand the trade-offs made in tooling, it still bothers me, a lot.
Developer tooling should *just work*, it shouldn't get in your face and make
you think about what you're doing with it. It should get out of the way and let
you focus on the important thing: developing your application and hammering out
code.

Lots of PaaS platforms exist to solve this, but they all have their own faults.
Too much config effort, not self-hostable, closed source, too expensive, ...
Take your pick, really.

## How does it work?

Everything is powered by [singyeong (신경)](https://github.com/queer/singyeong).

At a high level, the major components are the CLI (wand), the scheduler (PIG),
and the host daemon (agma (악마)). wand is aware of the manifests describing *how* an
app should be deployed, and it pushes that data to PIG. PIG can then take
advantage of 신경 queries to schedule containers on hosts very quickly, as the
scheduler can just ask 신경 for a 악마 node that fits the scheduler requirements.

## Pieces and parts

- wand: CLI interface for the entire system.
- PIG: Control plane. The Pretty Insane Group scheduler, schedules containers across 악마-managed hosts. "Pretty-Insane" because why would I ever write my own container scheduler lmao
- agma: Data plane. Host daemon, stats, container mangler.
- shoujo: Data plane. Ingress + router, autossl soon:tm:
- libmahou: Shared code library that holds everything together.

Powered by:
- https://github.com/queer/singyeong: Message queuing, pubsub, HTTP proxying, and more. Communication between everything, used by shoujo for routing to services. Its own standalone project.
- https://github.com/queer/crush: Time-traveling datastore for deployment etc. status. Its own standalone project.
