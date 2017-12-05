**SETUP**

This bot has been integrated into the MoJ Digital & Technology Slack workspace
as an outgoing webhook.

Currently it is only activated for the #pingutest channel.


**USAGE**
Once activated for all channels typing the following into slack will
issue the callback to the webhook, resulting in response being sent
to the channel.

Any domains specified must have paths for ping and/or healthcheck

To call a ping endpoint on an app:
```
pingu ping <domain-name[,domain-name-1][,domain-name-2]>
```

To call a healthcheck endpoint on an app:
```
pingu healthcheck <domain-name[,domain-name-1][,domain-name-2]>
```

**TODO**
  - [X] enable ping and healthcheck on single domain
  - [X] enable ping and healthcheck on multiple domains
  - [X] happy path spes
  - [ ] unhappy path specs
  - [X] handle timeout on a call to ping/healthcheck
  - [ ] add logging
  - [ ] enable inviting bot to channel
  - [ ] enable slack reminder calling
  - [ ] move rspec external service stubbing to separate file
  - [X] move command class to separate file and spec
  - [X] move slack ping response class to separate file and spec
  - [ ] move string extension to separate file and spec
  - [X] rename token
  - [ ] send separate response per endpoint call
  - [ ] send mutiple responses as soon as received??
  - [ ] handle ping to domains that do not respond to ping or do not return JSON
  - [ ] set maximum of 20 domains to be pinged
  --------------------------------------------------------------
  - [ ] activate for all channels in workspace
