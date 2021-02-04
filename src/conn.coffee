#!/usr/bin/env coffee

import nkn from 'nkn-sdk'
import BASE64 from 'urlsafe-base64'
import {randomBytes} from 'crypto'
import CONFIG from "@rmw/config"
import {CLIENT_N} from './const/conn'
import {join} from 'path'

export default =>

  {seed} = CONFIG
  if seed
    seedbin = BASE64.decode seed
  else
    seedbin = randomBytes(32)
    CONFIG.seed = BASE64.encode seedbin

  seedhex = Buffer.from(seedbin).toString('hex')

  conn = new nkn.MultiClient({
    numSubClients: CLIENT_N
    originalClient: false
    seed:seedhex
    rpcServerAddr: CONFIG.rpc or "https://mainnet-rpc-node-0001.nkn.org/mainnet/api/wallet"
  })
  new Promise (resolve)=>
    conn.onConnect =>
      resolve(conn)

