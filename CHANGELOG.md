# Changelog

## [0.12.0](https://github.com/solisoft/luaonbeans/compare/v0.11.0...v0.12.0) (2024-11-18)


### Features

* add header / footer and pagination to pages ([23fdc2a](https://github.com/solisoft/luaonbeans/commit/23fdc2a1d4912f02f4098b731593866b86184195))
* add support to postgrest ([00be8a6](https://github.com/solisoft/luaonbeans/commit/00be8a696f14eb50dc439d4228615ee8b2d5dcf2))
* allow isAPI global variable to handle 404 errors ([b6ef99c](https://github.com/solisoft/luaonbeans/commit/b6ef99c09f90fe81243c0086af9502cc985ba7d5))
* cronjobs + fix database.json.sqlite.sampl ([88011f6](https://github.com/solisoft/luaonbeans/commit/88011f6ff25bc0d894c1d6f7fe182b11eb22bc7c))
* Dockerfile is working ([6fcbaff](https://github.com/solisoft/luaonbeans/commit/6fcbaff1590db87edd49286b77af14c72f56ed96))
* improve controller performances by 50% ([84ecc96](https://github.com/solisoft/luaonbeans/commit/84ecc96256335d878e795aa82cdf896bb9f604d8))
* improve controller performances by 50% ([46fbfb7](https://github.com/solisoft/luaonbeans/commit/46fbfb766c3a0647b9ff810743760bdd397027f8))
* improve controller performances by 50% ([bc68813](https://github.com/solisoft/luaonbeans/commit/bc68813d6e3365144fd7c493154da72d318e2405))
* LogError() ([3e813ff](https://github.com/solisoft/luaonbeans/commit/3e813ffab4fadfcfe266d2c84fd022f4bc3e45f2))
* PostGrest =&gt; remove upsert for now ([f73b519](https://github.com/solisoft/luaonbeans/commit/f73b519261dfaa14461e64ccd6a6d0a8c347c94f))
* WIP PDFGenerator ([4f39d38](https://github.com/solisoft/luaonbeans/commit/4f39d387eacc3c0c71a9116fe879c07431196a15))


### Bug Fixes

* add controllers requirable ([f1f1d13](https://github.com/solisoft/luaonbeans/commit/f1f1d13a6d6fc26eaa75164299ea161dd773cfbe))
* add header / footer and pagination to pages ([e5abe92](https://github.com/solisoft/luaonbeans/commit/e5abe9279dba57fc8271de979330219feb8ca74a))
* add header / footer and pagination to pages ([cf328b3](https://github.com/solisoft/luaonbeans/commit/cf328b3b1de8d96ddaddcc459a07fa43806abb34))
* allow POST on / in the CustomRoutes ([3a004bf](https://github.com/solisoft/luaonbeans/commit/3a004bf896ad171a65dbb4f9a75d7b36c21067ee))
* controller template ([8561f98](https://github.com/solisoft/luaonbeans/commit/8561f98dc0d2820d51f1ea0dd73fdc82917a274a))
* enhance tables ([cefcbf1](https://github.com/solisoft/luaonbeans/commit/cefcbf19cd032f204ed659eea16ce252fa137adf))
* HandleSqliteFork ([042ce81](https://github.com/solisoft/luaonbeans/commit/042ce812f6ac3ab6664dd5f7ef125dbd4bfc4d93))
* pdf =&gt; set metrics for Helvetica-Bold ([08986f7](https://github.com/solisoft/luaonbeans/commit/08986f7928ddaf3a51b02dd39ce00279e2f5956d))
* PDF: add textCOlor to cells ([4dc4667](https://github.com/solisoft/luaonbeans/commit/4dc4667154f25d03308250299fd7067b82175140))
* PDF: custom & default font fixes ([a87ba35](https://github.com/solisoft/luaonbeans/commit/a87ba350f00c7bcc35eb986b93d0ea0d79d3002f))
* PDF: provide a pdf usage sample ([43d213d](https://github.com/solisoft/luaonbeans/commit/43d213de0b2eb15e76ee54bc331cc39c81473b75))
* PDF: provide a pdf usage sample ([96368cd](https://github.com/solisoft/luaonbeans/commit/96368cde1c102918a448f2f8c8e05c47cc434734))
* PDF: provide an easy way to update it for lpais ([d1af8d6](https://github.com/solisoft/luaonbeans/commit/d1af8d604b187cdc58a83dcca0849fc86e19fddc))
* PDF: put cursor_y after image ([1ed1702](https://github.com/solisoft/luaonbeans/commit/1ed170277509e2c5c5c5827ee165a12141ad8e05))
* remove log file ([7ad46be](https://github.com/solisoft/luaonbeans/commit/7ad46bed22628e7374a7b80301cb9429285abb90))
* rename DefineRoutes method ([54c714e](https://github.com/solisoft/luaonbeans/commit/54c714eb7644091f65d235fea6a9ececc0bb3330))
* restore controller specs ([f94a4e5](https://github.com/solisoft/luaonbeans/commit/f94a4e5037a3e1ffcf8d32a9f04764912a9890f7))
* restore controller specs ([cda66fb](https://github.com/solisoft/luaonbeans/commit/cda66fbb676009d1f4cf8f602cc8e4236b21d45e))
* restore controller specs ([8c54443](https://github.com/solisoft/luaonbeans/commit/8c544436a0b92e30233684e73ca6bd150024de83))
* test mode ([cb67dc3](https://github.com/solisoft/luaonbeans/commit/cb67dc38b5d248e1cf50c0cb3df07f8eafa81bbd))

## [0.11.0](https://github.com/solisoft/luaonbeans/compare/v0.10.0...v0.11.0) (2024-10-07)


### Features

* add PublicPath method ([2c9e7f9](https://github.com/solisoft/luaonbeans/commit/2c9e7f93ace842df5447f825d2c5d795107443f4))
* add users params to ArangoDB CreateDatabase ([92a5eb9](https://github.com/solisoft/luaonbeans/commit/92a5eb99ce8bb235c1e986d19cc21696c823dbc1))
* preload views / layouts / partials ([c90605a](https://github.com/solisoft/luaonbeans/commit/c90605a21ea7700f770c3d104b7b6d5caa63203a))


### Bug Fixes

* arangodb create database ([4f250db](https://github.com/solisoft/luaonbeans/commit/4f250db7ce8ece0e19702759b10a5767496c627b))
* routing ([4195d9b](https://github.com/solisoft/luaonbeans/commit/4195d9b1887edb8e59fcb80f7f7efb950136a574))
* routing ([2fcf67e](https://github.com/solisoft/luaonbeans/commit/2fcf67e86fa76141dd5b9ca7239c5fa381c7b597))

## [0.10.0](https://github.com/solisoft/luaonbeans/compare/v0.9.0...v0.10.0) (2024-10-01)


### Features

* add specs for CustomRoute with POST method ([53de711](https://github.com/solisoft/luaonbeans/commit/53de711e039728cf3c9573095cbe2600732679d3))


### Bug Fixes

* CSRF token ([e891f79](https://github.com/solisoft/luaonbeans/commit/e891f79ccf1f47fec88e8eb9386e757dbef81188))
* CSRF token =&gt; encrypt session ([43927b0](https://github.com/solisoft/luaonbeans/commit/43927b0bd6696be56f64dc0417617e250b5d326c))
* method for assignroutes ([b4f07e5](https://github.com/solisoft/luaonbeans/commit/b4f07e5664d69fdcd451ff0c5ba0bbd4e2c6685d))
* update package path ([3da86bb](https://github.com/solisoft/luaonbeans/commit/3da86bb72d242bb2b0943d25c109da0766dbcc26))
* use hook properly ([04aea63](https://github.com/solisoft/luaonbeans/commit/04aea63d12f0d5153e3ded184aefb4a2bce12b5e))

## [0.9.0](https://github.com/solisoft/luaonbeans/compare/v0.8.0...v0.9.0) (2024-09-29)


### Features

* add totp feature ([c49b4f9](https://github.com/solisoft/luaonbeans/commit/c49b4f9e75c2c140817224dae4e9fd5169b240c5))
* OTP ([a743a7e](https://github.com/solisoft/luaonbeans/commit/a743a7ee31c3d13b7fddb202d4d588237c749599))
* OTP =&gt; Generate recoverable codes ([8c084ab](https://github.com/solisoft/luaonbeans/commit/8c084ab52b5bc5cba6d5e5c80d0b0e76df9c7b42))

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
