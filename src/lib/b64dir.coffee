import {join} from 'path'
import BASE64 from 'urlsafe-base64'

export default (addr)=>
  addr = BASE64.encode addr
  join(
    ...addr[...8]
    addr[8..]
  )

