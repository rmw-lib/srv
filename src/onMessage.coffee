import * as url_offset from './lib/url_offset'
import {binary} from './const.mjs'
import b64dir from './lib/b64dir'
import {FLAG_URL} from './flag.mjs'
import {FLAG_FILE, FLAG_END} from '@rmw/fsrv/const'
import {join} from 'path'
import {int2buf} from './lib/int2bin'
import site_or_hash from './util/site_or_hash'

export default (conn, down, fsrv)=>
  conn.onMessage ({src, payload})=>
    flag = payload[0]
    payload = Buffer.from payload[1..]
    site = payload[...32]
    [url,offset, payload] = url_offset.load(payload[32..])
    if flag & FLAG_FILE
      await down.recv(src, site.toString(binary), url, offset, not (flag&FLAG_END), payload)
      return
    else
      if FLAG_URL & flag
        siteb64 = b64dir site

        [flag, bin] = await fsrv.read join(site_or_hash(url),siteb64,url), offset
        console.log ">", siteb64, url, offset, bin.length
        await conn.send(
          src
          Buffer.concat [
            Buffer.from [flag]
            site
            url_offset.dump url, offset
            bin
          ]
          noReply: true
        )
        return
    return
  return
