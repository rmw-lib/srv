#!/usr/bin/env coffee
import {existsSync} from 'fs'
import {CLIENT_N} from './const/conn'
import Counter from './lib/counter'
import chunk from 'lodash/chunk'
import R from './lib/redis/r'
import {ftruncateSync} from 'fs'
import {join,dirname} from 'path'
import BASE64 from 'urlsafe-base64'
import fs from 'fs/promises'
import b64dir from './lib/b64dir'
import DIR from './const/dir/rmw'
import uniq from 'lodash/uniq'
import * as B64 from './base'
import * as time from './lib/time'
import {hex,binary} from './const.mjs'
import * as url_offset from './lib/url_offset'
import site_or_hash from './util/site_or_hash'
import int2bin from './lib/int2bin'
import {MB} from '@rmw/fsrv/const'
import {FLAG_URL as _FLAG_URL} from './flag.mjs'

GB = MB*1024
FLAG_URL = Buffer.from [_FLAG_URL]
DIR_FS = join DIR, "fs"
DIR_TMP = join DIR_FS, "tmp"

# 每分钟统计上一分钟发出的请求数，响应的请求数，然后如果发出请求数<响应的请求数，追加发max(响应的请求数*0.1,1)个请求

export default ->
  new Down(...arguments)


class Down
  constructor:(@redis, @db, @conn, @split)->
    @_ing = ing = {}
    @_fs = new Map()
    @_counter = Counter()
    self = @
    {_send} = self
    _send = _send.bind self

    timer = =>
      setTimeout(
        =>
          now = time.now()
          count = 0
          for task_addr_offset of ing
            ++count
            cost = now - ing[task_addr_offset]
            if cost < 60
              break
            delete ing[task_addr_offset]
            console.log "timeout", cost, [task_addr_offset]
            @_resend task_addr_offset[...6]
            console.log ing
          console.log "runing", Object.keys(ing).length
          if count
            timer()
          else
            self._send = tsend
          return
        3000
      )
    @_send = tsend = ->
      timer()
      self._send = _send
      _send.apply @,arguments
    @_boot()

  _send_addr_id_key_url:(addr_id,key_url,offset)->
    {db} = @
    {addr} = await db.addr.findOne(selector:id:addr_id).exec()
    key_id = Buffer.from(key_url[...6],binary).readUIntBE(0,6)
    url = key_url[6..]
    {key} = await db[site_or_hash(url)].findOne(selector:id:key_id).exec()
    @_send_bin(addr,key,url,offset)

  _send_bin:(addr,key,url,offset)->
    @_send(
      Buffer.from(addr,binary).toString(hex)
      Buffer.from(key, binary)
      url
      offset
    )

  _resend:(task_id)->
    task_id_int = Buffer.from(task_id,binary).readUIntBE(0,6)
    r_addr = R.task.addr+task_id
    r_todo = R.task.todo+task_id
    [[_,offset],[_,addr_id],[_,[key_url]]]= await @redis.pipeline()
      .rpoplpush(
        r_todo
        r_todo
      )
      .rpoplpush(r_addr, r_addr)
      .zrangebyscore("task",task_id_int,task_id_int)
    .exec()
    console.log "resend", key_url
    if key_url
      offset = parseInt offset
      addr_id = parseInt addr_id
      @_ing[task_id+int2bin(addr_id)+int2bin(offset)] = time.now()
      @_send_addr_id_key_url(addr_id, key_url, offset)


  _boot:->
    {redis, db} = @
    li = chunk await redis.zrevrangebyscore("task",'+inf',0,'withscores'),2
    if not li.length
      return
    p = redis.pipeline()
    for [key_url, id],pos in li
      id = int2bin parseInt id
      r_todo = R.task.todo+id
      p.rpoplpush(r_todo,r_todo)
      r_addr = R.task.addr+id
      p.rpoplpush(r_addr, r_addr)
      li[pos] = [id, key_url]

    todo = []
    now = time.now()
    for [offset, addr_id],pos in chunk((parseInt(i[1]) for i in await p.exec()),2)
      if addr_id
        [task_id, key_url] = li[pos]
        @_ing[task_id+int2bin(addr_id)+int2bin(offset)] = now
        todo.push @_send_addr_id_key_url(addr_id, key_url, offset)

    Promise.all todo

  _task_key:(key, url)->
    {id} = await @db[site_or_hash(url)].id {key}
    int2bin(id)+url

  _task_id:(key, url)->
    await @redis.id "task", await @_task_key(key,url)

  get:(key, url, addr_li)->
    if not addr_li.length
      return
    db_task = await @db.task.get({key,url})
    if db_task
      if existsSync join(DIR_FS, site_or_hash(url), b64dir(Buffer.from(key,binary)), url)
        #TODO 触发完成事件
        return
      task_bin = db_task.id
      @redis.zadd "task", Buffer.from(task_bin).readUIntBE(0,6) ,task_bin+url
    else
      task_id = await @_task_id key, url
      task_bin = int2bin task_id
    {db,redis} = @
    m = await db.addr.findByIds addr_li
    addr_id_rank = new Map()
    addr_id_li = []
    id_addr = new Map()
    for addr from addr_li
      o =  m.get addr
      if o
        id = o.id
        if o.recv
          addr_id_rank.set id, o.recv
      else
        {id} = await db.addr.id {addr}
      id_addr.set(id, addr)
      addr_id_li.push id

    addr_id_li.sort (a,b)=>
      (addr_id_rank.get(b) or 0) - (addr_id_rank.get(a) or 0)

    now = time.now()

    r_todo = R.task.todo+task_bin
    r_addr = R.task.addr+task_bin
    offset = (await redis.rpoplpush r_todo,r_todo) or 0
    p = redis.pipeline()
    if offset
      offset = parseInt offset
      addr_li = await redis.lrange r_addr,0,-1
      exist = new Set addr_li.map((n)=>parseInt(n))
      new_addr = []
      for i from addr_id_li
        if not exist.has i
          new_addr.push i
      if new_addr.length
        p.lpush r_addr,...new_addr
    else
      p
        .lpush(r_todo, 0)
        .lpush(
          r_addr,...addr_id_li
        )
      if not db_task
        await db.task.insert({
          id:task_bin
          key
          url
          time:-now
        })

    addr_id = addr_id_li[addr_id_li.length-1]

    @_ing[task_bin+int2bin(addr_id)+int2bin(offset)] = now
    await p.exec()

    await @_send_bin(
      id_addr.get(addr_id)
      key
      url
      offset
    )
    return

  recv:(src, key, url, offset, more, payload)->
    console.log "recv",url,offset,payload.length
    {db, _counter, redis} = @

    keybuf = Buffer.from key, binary
    dir_suffix = join site_or_hash(url), b64dir(keybuf)
    dir = join DIR_TMP, dir_suffix
    outpath = join dir,url

    task_key = await @_task_key key,url
    task_id = await redis.zscore("task", task_key)
    if not task_id
      return

    task_bin = int2bin parseInt task_id

    addr = await db.addr.id({addr:Buffer.from(src,hex).toString binary})
    task_src = task_bin+int2bin(addr.id)

    p = redis.pipeline()

    r_todo = R.task.todo+task_bin
    [[_,ismember],[_,remain]] = await redis.pipeline().lpos(r_todo,offset).llen(r_todo).exec()
    if ismember == null
      return

    _done = =>
      _counter.del task_bin
      p.zrem("task", task_key)
       .del(r_todo)
       .del(R.task.addr+task_bin)
      await (await db.task.get(task_bin)).atomicPatch(
        time:time.now()
      )
      fsdir = join(DIR_FS, dir_suffix)
      await fs.mkdir(fsdir, { recursive: true })
      await fs.rename(outpath, join(fsdir, url))
      #TODO 触发完成事件

    _send = (next)=>
      @_ing[task_src+int2bin(next)] = time.now()
      @_send src, keybuf, url, next

    await fs.mkdir(dirname(outpath), { recursive: true })

    if offset == 0
      if more
        size = payload.readUIntBE 0,6
        payload = payload[6..]
        n = payload.length
        size += n
        todo = []
        while n < size
          todo.push n
          n += @split

        fh = await fs.open(outpath, "w")
        await fh.truncate(size)
        await fh.write(payload)
        @_fs.set task_key, fh
        next = todo[0]
        p.del(
          r_todo
        ).lpush(
          r_todo, ...todo
        )
        await _send next
      else
        await fs.writeFile outpath, payload
        size = payload.length
        _done()
      await p.exec()
      await (await db.task.get(task_bin)).atomicPatch {
        size
      }
    else
      fh = @_fs.get task_key
      if not fh
        fh = await fs.open(outpath,"r+")
        @_fs.set task_key, fh
      await fh.write(
        payload
        0
        payload.length
        offset
      )
      if 1 == remain
        await fh.close()
        _done()
        await p.exec()
      else
        p.lrem(
          r_todo
          1
          offset
        )
        exist = _counter.get(task_bin)
        send2 = (remain >= (exist+CLIENT_N)) and (exist < CLIENT_N)

        p.rpoplpush(r_todo, r_todo)
        if send2
          p.rpoplpush(r_todo, r_todo)
          _counter.incr(task_bin)

        r = await p.exec()

        next = parseInt r.pop()[1]
        await _send next

        if send2
          next = parseInt r.pop()[1]
          await _send next


    delete @_ing[task_src+int2bin(offset)]
    addr.update({$inc:recv:(payload.length+33+url.length)/GB}).catch(=>)

    console.log [
      url
      offset
      outpath
      more
      payload.length
      payload.toString('utf8')[..32]
      BASE64.encode(Buffer.from(src,hex))
      BASE64.encode(Buffer.from(key,binary))
      next
    ]
    return

  _send: (addr, key, url, offset)->
    console.log "send", BASE64.encode(Buffer.from(addr,hex)), key.length, url, offset
    @conn.send(
      addr
      Buffer.concat [
        FLAG_URL
        key
        url_offset.dump(url, offset)
      ]
      noReply:true
    )



    # 每10秒检查一下，给这10秒没有更新的，重发一个请求，连续失败7次，那么放弃这个地址，如果没有可用的地址，任务暂时失败
    # 30分钟后清零，重试9999次后任务失败

