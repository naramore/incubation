# Incubation

Personal Elixir incubation monorepo.

## Overview

  - interceptor (see exoscale, pedestal, lispcast)
  - fqa (i.e. fully-qualified atoms)
      - struct w/ fqa/2, sigil_f/2, sigil_F/2, name/2 & namespace/2 functions?
      - ~F|foo.bar.my-baz/my-buz| == ~f|Foo.Bar.MyBaz/my_buz|
  - diff + patch
  - domino (ideally come up with another name?)
  - edn
  - eql
  - pathom (+ filter, sort, pagination)
  - dtabs
  - datalog
  - ivy.{core, query, pull, client, peer, ...}
  - datafy + nav
  - transit
  - pathom phoenix & live view integration
  - vow
  
## Xenex

> NOTE: delegation tables as Tesla middleware?

  - Dashboard: phoenix live view
  - API: edn + eql + pathom (-ish)
  - Collectors:
    - GenServer
    - session managment (i.e. login, re-login, logout, pools)
    - request metrics -> metrics provider
    - request events -> aggregate events
    - track polling frequency of metrics & events
  - Metrics Provider behaviour
  - RRD metrics decoding / parsing
  - XAPI Client (Tesla, JSONRPC)
  - Model:
  
  > Is there a 'better' way to express the equivalent of
  > namespaced / fully qualified keys / attributes in Elixir?
  
    ```clojure
    {:xenex.session.host/name string?
     :xenex.session.host/uuid uuid?
     :xenex.session.host/ref ::opaque-ref
     :xenex.session.host/ip ::ip
     :xenex.session.host/enabled? bool?
     :xenex.session.auth/username string?
     :xenex.session.auth/password string?
     :xenex.session/ref ::opaque-ref
     :xenex.session/token string?
     :xenex.session/last-requested datetime?
     {:xenex.session/ref-counts {:xenex.ref-count/type string?
                                 :xenex.ref-count/count integer?}}
     {:xenex.session/events {:xenex.event.obj/uuid uuid?
                             :xenex.event.obj/class string?
                             :xenex.event.obj/snapshot map?
                             :xenex.event.obj/ref ::opaque-ref
                             :xenex.event/id integer?
                             :xenex.event/operation #{:xenex.event.operation/add
                                                      :xenex.event.operation/del
                                                      :xenex.event.operation/mod}
                             :xenex.event/timestamp datetime?}}}
    ```
    
    ```clojure
    {:xapi.host/* any?}
    ```
    
    aliases: :xenex.session.host/uuid <-> :xapi.host/uuid
             :xenex.session.host/ref  <-> :xapi.host/ref
             :xenex.session.ref       <-> :xapi.session/ref
