export class Counter
  constructor:->
    @_ = new Map()

  get:(key)->
    @_.get(key) or 0

  incr:(key, n=1)->
    v = @get(key) + n
    if v != 0
      @_.set key, v
    else
      @_.delete key
    console.log "Counter", @_
    return v

  decr:(key,n=1)->
    @incr key,-n

  del:(key)->
    @_.delete key
    console.log "Counter", @_
    return

export default =>
  new Counter()

