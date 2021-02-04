import {binary, utf8} from '../const.mjs'
import {int2buf} from './int2bin'

export dump = (url, offset)=>
  return Buffer.concat [
    int2buf url.length, 2
    Buffer.from url, utf8
    int2buf offset, 6
  ]

export load = (bin)=>
  url_len = bin.readUIntBE 0,2
  end = 2+url_len
  url = bin[2...end]
  offset = bin.readUIntBE end,6
  return [url.toString(utf8), offset, bin[end+6..]]

