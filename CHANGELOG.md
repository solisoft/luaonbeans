# Changelog

## [0.8.0](https://github.com/solisoft/luaonbeans/compare/v0.7.0...v0.8.0) (2024-09-03)


### Features

* add tailwindcss as local dependency ([e91fe52](https://github.com/solisoft/luaonbeans/commit/e91fe52d55a37dd2aadd990ceaefd7e17e9b448a))
* add tailwindcss as local dependency ([f3183ed](https://github.com/solisoft/luaonbeans/commit/f3183edd8be9ba198f2b30d9fcc362b1db659a92))


### Bug Fixes

* remove a warning in linter ([b593f82](https://github.com/solisoft/luaonbeans/commit/b593f82b970b90f5f3bfa84f78f57b756f9b78e4))

## [0.7.0](https://github.com/solisoft/luaonbeans/compare/v0.6.0...v0.7.0) (2024-07-09)


### Features

* wrapper for surrealdb ([16ad4eb](https://github.com/solisoft/luaonbeans/commit/16ad4ebd9eb3b80fd545a6468093a26322c05cf3))
* wrapper for surrealdb ([d9abc8b](https://github.com/solisoft/luaonbeans/commit/d9abc8ba3024e675d0d11592a89903ac78f618a2))


### Bug Fixes

* improve performance for loading layouts, partials & views ([4481931](https://github.com/solisoft/luaonbeans/commit/44819313366a9df1e15759b0e62de294b20adbb5))
* remove unused controller action ([81a56cd](https://github.com/solisoft/luaonbeans/commit/81a56cd76223f40541149489b7a296dc9e5ba975))
* Remove useless routes (debug) ([bfa09b9](https://github.com/solisoft/luaonbeans/commit/bfa09b964f964dccf7cbcdfe766a211f6acbe59a))
* update documentation ([1a6c5d9](https://github.com/solisoft/luaonbeans/commit/1a6c5d91c6c83c02b8ea9f2c0ddcd029aa6e29d0))

## [0.6.0](https://github.com/solisoft/luaonbeans/compare/v0.5.0...v0.6.0) (2024-06-22)


### Features

* add splat support on GET routes ([15a7fb7](https://github.com/solisoft/luaonbeans/commit/15a7fb72dafafdd644f511afb098e75ca347f084))


### Bug Fixes

* add specs for router + fix router ([d6ed140](https://github.com/solisoft/luaonbeans/commit/d6ed1407b2a64ee349772dc5d1940de877991329))
* remove useless code ([6625497](https://github.com/solisoft/luaonbeans/commit/6625497de4e813c1e933d5a1ad6ccfab85cbfc25))
* small refactor of .init.lua file ([cc7aec5](https://github.com/solisoft/luaonbeans/commit/cc7aec5153be82fd71ee0c02903e48e00d2578e8))

## [0.5.0](https://github.com/solisoft/luaonbeans/compare/v0.4.0...v0.5.0) (2024-05-05)


### Features

* latest redbean version (including UuidV4 method) ([c77b862](https://github.com/solisoft/luaonbeans/commit/c77b862a08fcf705d40a872476c466fa50097e95))


### Bug Fixes

* increase router performances ([75b713b](https://github.com/solisoft/luaonbeans/commit/75b713b059b8b128123ba0b68dbdd9d6f368b06b))
* increase router performances ([1970e48](https://github.com/solisoft/luaonbeans/commit/1970e48f06578051426eaa2541c6af336a4e51d1))
* typo ([6c75790](https://github.com/solisoft/luaonbeans/commit/6c75790fbac823e9644cb9f531b155abde791d47))
* update default route definition ([fbde67d](https://github.com/solisoft/luaonbeans/commit/fbde67d1c416d0ca25ca2c10413e6c4f8bc2b242))

## [0.4.0](https://github.com/solisoft/luaonbeans/compare/v0.3.0...v0.4.0) (2024-04-22)


### Features

* implement sqlite3 support ([53c6644](https://github.com/solisoft/luaonbeans/commit/53c664450b55eea0981dbf8759dd51a3f6faf863))
* new Uuid() method which is just random ([fb9cd1e](https://github.com/solisoft/luaonbeans/commit/fb9cd1e0bd9453ea2578cf7ae404109157688080))
* Remove Lua UuidV4 because redbean has it natively ([29a1908](https://github.com/solisoft/luaonbeans/commit/29a1908d14d9a0e455dec07e2a09b5edc3298505))
* UuidV4() Lua function ([bdfbbab](https://github.com/solisoft/luaonbeans/commit/bdfbbabe3a058860978d321c2ea8841f1fa6a02a))
* UuidV4() Lua function ([d16201a](https://github.com/solisoft/luaonbeans/commit/d16201a866348da5dcff52d220e28be711b2ae88))

## [0.3.0](https://github.com/solisoft/luaonbeans/compare/v0.2.3...v0.3.0) (2024-03-23)


### Features

* docker compose healthy check ([bf7770b](https://github.com/solisoft/luaonbeans/commit/bf7770b293df16a516161b77cef3426f5d9c48df))


### Bug Fixes

* filter migrations by filename ([e6eebb3](https://github.com/solisoft/luaonbeans/commit/e6eebb3bd6d7225ea7e5bd6b46a0a0b9f284222c))
* fix specs env ([6893eb7](https://github.com/solisoft/luaonbeans/commit/6893eb7f264421f1acc870791467b8cbae3a7453))

## [0.2.3](https://github.com/solisoft/luaonbeans/compare/v0.2.2...v0.2.3) (2024-03-14)


### Bug Fixes

* add context to files created ([a4b2049](https://github.com/solisoft/luaonbeans/commit/a4b20495d166132f7666b37cabd33dda5f2cd458))
* fix specs ([c6d63d9](https://github.com/solisoft/luaonbeans/commit/c6d63d9b169405c52386a46baa0d747a95f43863))
* remove debug print ([fe797f3](https://github.com/solisoft/luaonbeans/commit/fe797f34ff4293862930d79bfbb80df43397f2bd))
* rename beans to beans.lua ([b560026](https://github.com/solisoft/luaonbeans/commit/b560026a724d1767f394ed921de34bbdf010a1e5))
* rename beans to beans.lua ([94a4a52](https://github.com/solisoft/luaonbeans/commit/94a4a52747a4f81c270f212f5a181e5799cdfbbb))

## [0.2.2](https://github.com/solisoft/luaonbeans/compare/v0.2.1...v0.2.2) (2024-03-10)


### Bug Fixes

* add spaces ([0744f8d](https://github.com/solisoft/luaonbeans/commit/0744f8d01b900575d5123bbc585abaf250b919d2))
* fix typo and add comments on .init.lua ([c0379f3](https://github.com/solisoft/luaonbeans/commit/c0379f39cdc94147af97e95f803aa0784cb063c9))
* remove spaces ([f38d9a6](https://github.com/solisoft/luaonbeans/commit/f38d9a63f218e380b870bed11d0c98f88df1e060))
* remove spaces ([5f1811a](https://github.com/solisoft/luaonbeans/commit/5f1811aed4dabfabf1567d399096453452a602bb))

## [0.2.1](https://github.com/solisoft/luaonbeans/compare/v0.2.0...v0.2.1) (2024-03-10)


### Bug Fixes

* missing to_slug code ([8e942a7](https://github.com/solisoft/luaonbeans/commit/8e942a76c6e949acbc03a26b2f07c25e8488a060))

## [0.2.0](https://github.com/solisoft/luaonbeans/compare/v0.1.0...v0.2.0) (2024-03-10)


### Features

* move routes to the routes.lua files ([8a7956e](https://github.com/solisoft/luaonbeans/commit/8a7956e18ec18d618fa8ee5fc6c5597c98a529aa))
* move routes to the routes.lua files ([a847545](https://github.com/solisoft/luaonbeans/commit/a8475459edf77876864d35effd75b579ce2cd08c))

## [0.1.0](https://github.com/solisoft/luaonbeans/compare/v0.0.1...v0.1.0) (2024-03-08)


### Features

* add yml github action ([e95b7be](https://github.com/solisoft/luaonbeans/commit/e95b7be2df0f5938cfdb69170b190de5bce6516b))
* add yml github action ([ca9df9f](https://github.com/solisoft/luaonbeans/commit/ca9df9ff08d3c3e6589cf75d696307cd186b6b06))
* implement conventional commits ([23ccb5f](https://github.com/solisoft/luaonbeans/commit/23ccb5fa037068786a6f467d62f2b2cc5e59d93c))
* implement conventional commits ([c0a5099](https://github.com/solisoft/luaonbeans/commit/c0a5099ccbcbc67646786531a825c1099780d4ff))
* implement conventional commits ([518f96a](https://github.com/solisoft/luaonbeans/commit/518f96aa92be2e3658f0ab626bb240cd8721b868))
* implement conventional commits ([1f2a478](https://github.com/solisoft/luaonbeans/commit/1f2a478c277f6c031c55fb663ec75b50a6082bbe))
* implement conventional commits ([8eaf40e](https://github.com/solisoft/luaonbeans/commit/8eaf40e67253aeba1ee82b0c431c1021b6ebbd4d))
* implement conventional commits ([478efb8](https://github.com/solisoft/luaonbeans/commit/478efb89e1fe5d654f818dab0cb16c4c834e8606))
* implement conventional commits ([05a7de8](https://github.com/solisoft/luaonbeans/commit/05a7de871800966030de6e148602f403fb7c622c))
* update semver ([08c679f](https://github.com/solisoft/luaonbeans/commit/08c679f978d780dad270a84e4fff267e21c0af46))
