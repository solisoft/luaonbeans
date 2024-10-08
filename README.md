# luaonbeans

A tiny [redbean](https://redbean.dev/) MVC Lua framework

[![CI](https://github.com/solisoft/luaonbeans/actions/workflows/specs.yml/badge.svg?branch=main)](https://github.com/solisoft/luaonbeans/actions/workflows/specs.yml)

## Getting started

First clone the repository

```sh
git clone https://github.com/solisoft/luaonbeans.git --depth=1
```

You need then to configure arangoDB (using brew or docker) and create a new database :

Then configure the `config/database.json` file

Then run `./luaonbeans.org -D .` ; You should be able to open : [http://localhost:8080](http://localhost:8080)

## Running tests

```sh
beans specs
```

Shoud return something similar

```text
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
[PASS] utilities | Slugify
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

beans db:setup
beans db:migrate
beans db:rollback

beans specs
```

## File upload

You can handle file upload now easily. Any multipart data form will
add Params to the global `Params` variable.

by example this request :

```sh
curl -F "file[]=@redbean.png" -F "file[]=@logo.png" -F file2=@resume.pdf -F demo=1 http://localhost:8080/upload
```

will generate :

```json
{
  "demo": "1",
  "file2": {
    "content": "<data>",
    "ext": "pdf",
    "size": 1234,
    "filename": "resume.pdf",
    "content_type": "application/pdf"
  },
  "file": [
    {
      "content": "<data>",
      "ext": "png",
      "size": 1234,
      "filename": "redbean.png",
      "content_type": "image/png"
    },
    {
      "content": "<data>",
      "ext": "png",
      "size": 4321,
      "filename": "logo.png",
      "content_type": "image/png"
    }
  ]
}
```

You can then iterate and do whatever you want with your content.
