window.MenuURL=(a,b,c) ->
  getType= (type) ->
  	if type=="mail" or type=="email"
  		return "mailto"
  	if type=="bitmessage"
  		return "bm"
  	return type
  getArray= (val,text,br) ->
    _val=val.value.split("?")[0]
    _what=val.type
    url=getUrl(val.type,val.value)
    msg=text.replace("%what",_what).replace("%val",_val)
    if br
      msg=msg.split(": ")
      msg[0]+=":"
      res=[[msg[0],h("br"),msg[1]],url]
    else
      res=[msg,url]
    return res
  getUrl= (type_,val) ->
  	type=type_.toLowerCase().replace(/-/g,"")
  	getType(type)+":"+val
  return getArray(a,b,c)
