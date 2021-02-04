export default (err)=>
  if err
    console.trace err
    process.exit 2

