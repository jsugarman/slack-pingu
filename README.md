**USAGE**

To call a ping endpoint on an app:
```
pingu ping <domain-name[,domain-name-1][,domain-name-2]>
```

To call a healthcheck endpoint on an app:
```
pingu healthcheck <domain-name[,domain-name-1][,domain-name-2]>
```

**TODO**
  - [X] happy path spes
  - [ ] unhappy path specs
  - [ ] handle timeout on a call to ping
  - [ ] add logging
  - [ ] enable inviting bot to channel
  - [ ] enable slack reminder calling
  - [ ] move rspec external service stubbing to separate file
  - [ ] move command class to separate file and spec
  - [ ] move slack ping response class to separate file and spec
  - [ ] move string extension to separate file and spec
  - [X] rename token
  - [ ] send separate response per endpoint call
