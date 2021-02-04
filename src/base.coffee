DIGS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

BASE = DIGS.length


export encode = (number) ->
  if isNaN(Number(number)) or number == null or number == Number.POSITIVE_INFINITY
    return ''
  if number < 0
    return '-'+encode(-number)
  rixit = undefined
  residual = Math.floor(number)
  result = []
  loop
    rixit = residual % BASE
    result.unshift DIGS.charAt(rixit)
    residual = Math.floor(residual / BASE)
    if residual == 0
        break
  return result.join ''


INDEX = new Map()

do =>
  for i,pos in DIGS
    INDEX.set(i, pos)

export decode = (rixits) ->
  if rixits.charAt(0) == '-'
    return - decode(rixits.slice(1))
  result = 0
  rixits = rixits.split('')
  for e in rixits
    result = (result * BASE) + INDEX.get(e)
  return result


