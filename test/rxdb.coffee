#!/usr/bin/env coffee

import AdapterLeveldb from 'pouchdb-adapter-leveldb'
import Rxdb from 'rxdb'
import fs from 'fs'
import leveldown from 'leveldown'
import CONFIG from '../src/const/dir'
import {join} from 'path'

{createRxDatabase, addRxPlugin} = Rxdb

addRxPlugin AdapterLeveldb

export default =>
  dbdir = join(CONFIG.rmw, 'rxdb')
  await fs.promises.mkdir(dbdir, { recursive: true })

  await createRxDatabase({
    name: join(dbdir, 'srv')
    adapter: 'leveldb'
    pouchSettings:
      revs_limit: 1
      auto_compaction: true
  })

# import srv from '@rmw/srv'
# import redis from '@rmw/srv/redis'
# import rxdb from './rxdb'
#
# do =>
#   db = await rxdb()
#   down = await srv(db)
#   addr = "p4bHzAquvx_5h_tK5j-WpQokOhv7JteHbPfADIIP2bQ"
#   key = BASE64.decode(addr)
#   addrbin = Buffer.from(key)
#   if await redis.incrby("task.id",0)
#     return
#   for url in "test xaa test.txt 1.mp4".split(' ')
#     console.log "get url", url
#     await down.get(
#       addr[0]+"/"+addr[1]+"/"+addr[2]+"/"+addr[3]+"/"+addr[4]+"/"+addr[5]+"/"+addr[6]+"/"+addr[7..]
#       key.toString 'binary'
#       url
#       [
#         addrbin.toString 'binary'
#       ]
#     )
#
#   #process.exit()
