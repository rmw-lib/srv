export int2buf = (i, len)=>
  b = Buffer.allocUnsafe len
  b.writeUIntBE i, 0, len
  b

export default (i,len=6)=>
  int2buf(i,len).toString 'binary'
