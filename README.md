# luaonbeans

A tiny redbean Lua framework

## Getting started

First clone the repository and download [redbean](https://redbean.dev)

```sh
git clone https://github.com/solisoft/luaonbeans.git
cd luaonbeans
wget https://redbean.dev/redbean-2.2.com
chmod +x ./redbean.com
```

You need then to configure arangoDB (using brew or docker) and create a new database :

Then configure the `config/database.json` file

Then run `./redbean.com -D .`

https://github.com/solisoft/luaonbeans/assets/6237/d304a1b8-4f55-4b3a-a7ac-513ec3c7ba1b

Create a `beans` alias for your favorite shell

```
alias beans="./luaonbeans.org -i beans"
```

then once your shell is reloaded simply run

```
beans specs
```

Shoud return somthing similar

```sh
Setup test DB
Running migrations ...
[PASS] arangodb driver | Aql | run request
[PASS] arangodb driver | Aql | fail running request
[PASS] arangodb driver | CreateDocument | create document
[PASS] arangodb driver | GetDocument | get document
[PASS] arangodb driver | UpdateDocument | update document
[PASS] arangodb driver | DeleteDocument | delete document
[PASS] arangodb driver | Create and delete Collection | create and delete collection
[PASS] arangodb driver | GetAllIndexes | get all indexes
[PASS] arangodb driver | CreateIndex | create index
[PASS] arangodb driver | DeleteIndex | delete index
[PASS] arangodb driver | Create and Delete Database | create and delete database
[SKIP] arangodb driver | GetQueryCacheEntries | get query cache
[SKIP] arangodb driver | GetQueryCacheConfiguration | get query cache configuration
[SKIP] arangodb driver | UpdateCacheConfiguration | update query cache configuration
[SKIP] arangodb driver | DeleteQueryCache | delete query cache configuration
[SKIP] arangodb driver | RefreshToken | refresh auth token
[====] arangodb driver | 11 successes / 5 skipped / 0.056264 seconds
[PASS] luaonbeans | welcome#index | load page
[====] luaonbeans | 1 successes / 0.017907 seconds
[PASS] utilities | table.keys
[PASS] utilities | table.append
[PASS] utilities | table.contains
[PASS] utilities | table.merge
[PASS] utilities | string.split
[PASS] utilities | string.to_slug
[PASS] utilities | Pluralize
[PASS] utilities | Singularize
[PASS] utilities | Capitalize
[PASS] utilities | Camelize
[====] utilities | 10 successes / 0.000343 seconds
22 successes / 5 skipped / 0 failures / 0.077219 seconds
```

## Beans commands

```sh
beans create controller posts
beans create model post
beans create scaffold posts
beans create migration add_indexes_to_posts

beans db:migrate
beans db:rollback

beans specs
```

## TODO

- File Upload
- Oauth2

!!! This project is under development !!!
