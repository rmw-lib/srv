import TYPE from '../lib/rxdb/type'

res = schema:
  required: "id"
  indexes:"id"
  properties:
    key:
      type: TYPE.string
      primary: true
    id:
      type: TYPE.integer
      final: true

export default {
  hash:res
  site:res
  task:
    schema:
      indexes:[
        "id"
        "time"
        ["key","url"]
        ["key","time"]
      ]
      required: "time"
      properties:
        id:
          type: TYPE.string
          primary: true
        key:
          type: TYPE.string
        url:
          type: TYPE.string
        time: # 小于0表示下载中
          type: TYPE.integer
        size:
          type: TYPE.integer
  addr:
    schema:
      indexes:"recv id"
      required: "id"
      properties:
        addr:
          type: TYPE.string
          primary: true
        id:
          type: TYPE.integer
          final: true
        recv:
          type: TYPE.number
          default: 0
}
