package.path = package.path .. ";.lua/?.lua;migrations/?.lua;specs/?.lua"
require("utilities")
lester = require("lester")

ENV = {}
for _, var in pairs(unix.environ()) do
  var = string.split(var, "=")
  ENV[var[1]] = var[2]
end

BeansEnv = ENV['BEANS_ENV'] or "development"

DBConfig = DecodeJson(Slurp("config/database.json"))
Adb = require "arango"

RecursiveFiles = function(dir, files_found)
  files_found = files_found or {}
  for name, kind, ino, off in assert(unix.opendir(unix.getcwd() .. dir)) do
    if name ~= '.' and name ~= '..' then
      if path.isdir(dir:sub(2) .. "/" .. name) then
        files_found = RecursiveFiles(dir .. "/" .. name, files_found)
      else
        files_found = table.append(files_found, { dir .. "/" .. name })
      end
    end
  end
  return files_found
end

JSONPrint = function(value)
  print(EncodeJson(value))
end

DefineWords = function(name)
  return {
    model = Camelize(name),
    plural = Pluralize(name),
    singular = name
  }
end

ProcessTemplate = function(template, words)
  template = string.gsub(template, "##model_plural##", words.plural)
  template = string.gsub(template, "##model_singular##", words.singular)
  return string.gsub(template, "##model_singular_capitalized##", words.model)
end

CreateView = function(controller_name)
  local words = DefineWords(controller_name)
  unix.mkdir("views/" .. words.plural)
  local template = Slurp(".templates/views/index.etlua")
  template = ProcessTemplate(template, words)
  Barf("app/views/" .. words.plural .. "/index.etlua", template)

  template = Slurp(".templates/views/new.etlua")
  template = ProcessTemplate(template, words)
  Barf("app/views/" .. words.plural .. "/new.etlua", template)

  template = Slurp(".templates/views/edit.etlua")
  template = ProcessTemplate(template, words)
  Barf("app/views/" .. words.plural .. "/edit.etlua", template)

  template = Slurp(".templates/views/show.etlua")
  template = ProcessTemplate(template, words)
  Barf("app/views/" .. words.plural .. "/show.etlua", template)
end

CreateController = function(controller_name)
  local words = DefineWords(controller_name)
  local template = Slurp(".templates/controller.lua")
  local spec = Slurp(".templates/empty_spec.lua")
  template = ProcessTemplate(template, words)
  Barf("app/controllers/" .. words.plural .. "_controller.lua", template)
  Barf("specs/controllers/" .. words.plural .. "_spec.lua", spec)
  print("✅ app/controller/" .. words.plural .. "_controller.lua created")
  print("✅ specs/controllers/" .. words.plural .. "_spec.lua created")
end

CreateMigration = function(name)
  local words = DefineWords(name)
  local template = Slurp(".templates/migration.lua")
  template = ProcessTemplate(template, words)
  Barf("migrations/" .. os.date("%Y%m%d-%H%I%S_") .. Slugify(name) .. ".lua", template)
  print("✅ migrations/" .. os.date("%Y%m%d-%H%I%S_") .. Slugify(name) .. ".lua created")
end

CreateModel = function(model_name)
  local words = DefineWords(model_name)
  local template = Slurp(".templates/model.lua")
  local spec = Slurp(".templates/empty_spec.lua")
  template = ProcessTemplate(template, words)
  Barf("app/models/" .. words.singular .. ".lua", template)
  Barf("specs/models/" .. words.singular .. "_spec.lua", spec)
  CreateMigration("create " .. words.plural .. " table")
  print("✅ app/models/" .. words.singular .. ".lua created")
  print("✅ specs/models/" .. words.singular .. "_spec.lua created")
end

if arg[1] == "create" then
  if arg[2] == "migration" then
    CreateMigration(arg[3])
  end

  if arg[2] == "controller" then
    CreateController(Singularize(arg[3]))
  end

  if arg[2] == "model" then
    CreateModel(Singularize(arg[3]))
  end

  if arg[2] == "scaffold" then
    singular = Singularize(arg[3])
    CreateController(singular)
    CreateView(singular)
    CreateModel(singular)
  end
end

SetupDB = function(env)
  print("Setup " .. env .. " DB")
  assert(Adb.Auth(DBConfig.system) ~= nil)
  if env == "test" then
    Adb.DeleteDatabase(DBConfig[env].db_name)
  end
  Adb.CreateDatabase(DBConfig[env].db_name)
  assert(Adb.Auth(DBConfig[env]) ~= nil)
  Adb.CreateCollection("migrations")
  Adb.CreateIndex("migrations", { type = "persistent", unique = true, fields = { "filename" } })
  Adb.CreateDocument("migrations", { filename = "0" })
end

if arg[1] == "db:setup" then
  if DBConfig["engine"] == "arngodb" then
    SetupDB(BeansEnv)
  end
end

ArangoDB_DBMigrate = function()
  print("Running migrations ...")
  assert(Adb.Auth(DBConfig[BeansEnv]) ~= nil)
  local latest_version = Adb.Aql(
    "FOR m IN migrations SORT m.filename DESC LIMIT 1 RETURN m.filename"
  ).result[1]
  for name, kind, ino, off in assert(unix.opendir(unix.getcwd() .. "/migrations")) do
    if name ~= '.' and name ~= '..' then
      if name > latest_version then
        print("Processing " .. name)
        local migration = require(string.gsub(name, ".lua", ""))
        if migration.up() then
          Adb.CreateDocument("migrations", { filename = name })
        end
      end
    end
  end
end

Sqlite_DBMigrate = function()
  print("Running migrations ...")
  local sqlite3 = require 'lsqlite3'
  local db = sqlite3.open(DBConfig[BeansEnv]["db_name"] .. '.sqlite3')
  local latest_version = ""
  for row in db:nrows([[
  SELECT filename FROM migrations ORDER BY migrations.filename DESC LIMIT 1
]]) do
    latest_version = row['filename']
  end

  for name, kind, ino, off in assert(unix.opendir(unix.getcwd() .. "/migrations")) do
    if name ~= '.' and name ~= '..' and name ~= '.keep' then
      if name > latest_version then
        print("Processing " .. name)
        local migration = require(string.gsub(name, ".lua", ""))
        if migration.up() then
          local stm = db:prepare [[
          INSERT INTO migrations (filename) VALUES (?)
        ]]
          stm:bind_values(name)
          for r in stm:nrows() do return r end
        end
      end
    end
  end
end

if arg[1] == "db:migrate" then
  if DBConfig["engine"] == "arangodb" then
    ArangoDB_DBMigrate()
  elseif DBConfig["engine"] == "sqlite" then
    Sqlite_DBMigrate()
  end
end

if arg[1] == "db:rollback" then
  if DBConfig["engine"] == "arangodb" then
    assert(Adb.Auth(DBConfig[BeansEnv]) ~= nil)
    local latest_version = Adb.Aql(
      "FOR m IN migrations SORT TO_NUMBER(m._key) DESC LIMIT 1 RETURN m"
    ).result[1]
    if latest_version.filename ~= "0" then
      print("Processing " .. latest_version.filename)
      local migration = require(string.gsub(latest_version.filename, ".lua", ""))
      if migration.down() then
        Adb.DeleteDocument(latest_version._id)
      end
    else
      print("Nothing to rollback!")
    end
  elseif DBConfig["engine"] == "sqlite" then
    local sqlite3 = require 'lsqlite3'
    local db = sqlite3.open(DBConfig[BeansEnv]["db_name"] .. '.sqlite3')
    local latest_version = ""

    for row in db:nrows([[
      SELECT filename FROM migrations ORDER BY migrations.filename DESC LIMIT 1
    ]]) do
      latest_version = row['filename']
    end

    print("Processing " .. latest_version)
    if latest_version ~= "" then
      local migration = require(string.gsub(latest_version, ".lua", ""))
      if migration.down() then
        local stm, err = db:prepare([[
          DELETE FROM migrations WHERE filename = ?
        ]])
        stm:bind_values(latest_version)
        for r in stm:nrows() do return print(EncodeJson(r)) end
      end
    end
  end
end

if arg[1] == "specs" then
  BeansEnv = "test"
  SetupDB("test")

  if DBConfig["engine"] == "arangodb" then
    ArangoDB_DBMigrate()
  elseif DBConfig["engine"] == "sqlite" then
    Sqlite_DBMigrate()
  end

  describe, it, expect = lester.describe, lester.it, lester.expect

  for _, spec in pairs(RecursiveFiles("/specs")) do
    if string.find(spec, "_spec.lua") then
      spec = spec:sub(8)
      spec = require(string.gsub(spec, ".lua", ""))
      spec.run()
    end
  end

  lester.report()
  lester.exit()
end
