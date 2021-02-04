#!/usr/bin/env coffee

import fs from 'fs'
import {join} from 'path'
import {thisdir} from "@rmw/thisfile"

export default (db)=>
  dbstr = "db"
  dir =  join thisdir(`import.meta`), dbstr
  prefix = "./"+dbstr+"/"
  todo = []
  new Promise (resolve)=>
    for file from fs.readdirSync(dir)
      if file.endsWith('.map')
        continue
      fp = prefix+file
      o = (await import(fp)).default
      for k of o
        {schema} = o[k]
        if 'type' not of schema
          schema.type = 'object'
        if 'version' not of schema
          schema.version = 0
        for key from ['required','indexes']
          v = schema[key]
          if v and typeof(v) == 'string'
            schema[key] = v.split(' ')
      todo.push db.addCollections(o)
    try
      await Promise.all todo
    catch err
      console.trace err
    resolve()


