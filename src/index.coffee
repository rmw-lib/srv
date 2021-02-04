#!/usr/bin/env coffee

# import init_db from './db'
# await init_db db
import BASE64 from 'urlsafe-base64'
import {MB} from '@rmw/fsrv/const'
import Conn from './conn'
import Down from './down'
import Fsrv from '@rmw/fsrv'
import DIR from './const/dir/rmw'

export default (redis, db)=>

  console.log "根目录", DIR
  split = MB/8
  fsrv = Fsrv DIR, split

  conn = await Conn()
  down = await Down(redis, db, conn, split)
  onMessage = (
    await import('./onMessage')
  ).default

  onMessage conn, down, fsrv
  console.log "网络地址" , BASE64.encode(
    Buffer.from(conn.addr,'hex')
  )
  console.log conn.addr
  return down
