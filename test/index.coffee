#!/usr/bin/env coffee

import BASE64 from 'urlsafe-base64'
import srv from '@rmw/srv'
import redis from '@rmw/srv/redis'
import rxdb from './rxdb'

do =>
  db = await rxdb()
  down = await srv(db)
  addr = "p4bHzAquvx_5h_tK5j-WpQokOhv7JteHbPfADIIP2bQ"
  key = BASE64.decode(addr)
  addrbin = Buffer.from(key)
  if await redis.incrby("task.id",0)
    return
  for url in "test xaa test.txt 1.mp4".split(' ')
    console.log "get url", url
    await down.get(
      key.toString 'binary'
      url
      [
        addrbin.toString 'binary'
      ]
    )

  #process.exit()
