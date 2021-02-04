#!/usr/bin/env coffee

import BASE64 from 'urlsafe-base64'
import srv from '@rmw/srv'
import rxdb from './rxdb'

do =>
  db = await rxdb()
  down = await srv(db)
  # addr = "p4bHzAquvx_5h_tK5j-WpQokOhv7JteHbPfADIIP2bQ"
  # addrbin = Buffer.from(BASE64.decode(addr))
  #
  # url = "test"
  # await down.get(
  #   addr[0]+"/"+addr[1]+"/"+addr[2]+"/"+addr[3]+"/"+addr[4]+"/"+addr[5]+"/"+addr[6]+"/"+addr[7..]
  #   url
  #   [
  #     addrbin.toString 'binary'
  #   ]
  # )
