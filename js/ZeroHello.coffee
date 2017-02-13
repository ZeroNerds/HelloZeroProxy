window.h = maquette.h

class ZeroHello extends ZeroFrame
	init: ->
		@params = {}
		@site_info = null
		@server_info = null
		@address = null

		@on_site_info = new Promise()
		@on_local_storage = new Promise()
		@local_storage = null

		@latest_version = "0.5.2"
		@mode = "Sites"
		@change_timer = null
		@proxy_info={
			name:"HelloZeroProxy",
			show:{
				update:true,
				updateAll:true,
				checkFiles:true
			},
			#owner:"nobody",
			#owner_contact:{
			#	type:"email",
			#	value:"nobody@example.com"
			#},
			#donate:{
			#	type:"Bitcoin",
			#	value:"1SomeAddress"
			#}
			admin:false,
			header:"Welcome to a ZeroProxy",
			description:["ZeroProxies are websites which allow you to access ZeroNet Zites just like regular Sites","     —     ","Disclaimer: No content here is served by us nor are we associated with it in any way"],
			sites:[
				{
					bg:"bg1",
					url:"Board.ZeroNetwork.bit",
					title:"ZeroBoard",
					description:"Simple messaging board",
					action:"Activate \u2501"
				},
				{
					bg:"bg2",
					url:"Talk.ZeroNetwork.bit",
					title:"ZeroTalk",
					description:"Reddit-like, decentralized forum",
					action:"Activate \u2501"
				},
				{
					bg:"bg3",
					url:"Blog.ZeroNetwork.bit",
					title:"ZeroBlog",
					description:"Microblogging platform",
					action:"Activate \u2501"
				},
				{
					bg:"bg4",
					url:"Mail.ZeroNetwork.bit",
					title:"ZeroMail",
					description:"End-to-end encrypted mailing",
					action:"Activate \u2501"
				},
				{
					bg:"bg5",
					url:"Me.ZeroNetwork.bit",
					title:"ZeroMe",
					description:"P2P social network",
					action:"Activate \u2501"
				},
				{
					bg:"bg6",
					url:"donate.bit",
					title:"Donate",
					description:"Donate to keep this ZeroProxy alive",
					action:"Donate \u2501"
				}
			]
		}
		document.body.id = "Page#{@mode}"

	setProjectorMode: (mode) ->
		@log "setProjectorMode", mode
		if mode == "Sites"
			try
				@projector.detach(@file_list.render)
			catch
				@
			@projector.replace($("#FeedList"), @feed_list.render)
			@projector.replace($("#SiteList"), @site_list.render)
		else if mode == "Files"
			try
				@projector.detach(@feed_list.render)
				@projector.detach(@site_list.render)
			catch
				@
			@projector.replace($("#FileList"), @file_list.render)
		if @mode != mode
			@mode = mode
			setTimeout ( ->
				# Delayed to avoid loosing anmation because of dom re-creation
				document.body.id = "Page#{mode}"

				if @change_timer
					clearInterval @change_timer
				document.body.classList.add("changing")
				@change_timer = setTimeout ( ->
					document.body.classList.remove("changing")
				), 400

			), 60


	createProjector: ->
		@projector = maquette.createProjector()  # Dummy, will set later
		@projectors = {}

		@site_list = new SiteList(( => return @proxy_info ))
		@feed_list = new FeedList(( => return @proxy_info ))
		@file_list = new FileList(( => return @proxy_info ))
		@head = new Head(( => return @proxy_info ))
		@dashboard = new Dashboard(( => return @proxy_info ))
		@mute_list = new MuteList(( => return @proxy_info ))

		@route("")

		@loadLocalStorage()
		@on_site_info.then =>
			@projector.replace($("#Head"), @head.render)
			@projector.replace($("#Dashboard"), @dashboard.render)
			@setProjectorMode(@mode)

		# Update every minute to keep time since fields up-to date
		setInterval ( ->
			Page.projector.scheduleRender()
		), 60*1000


	# Route site urls
	route: (query) ->
		@params = Text.parseQuery(query)
		@log "Route", @params

	# Add/remove/change parameter to current site url
	createUrl: (key, val) ->
		params = JSON.parse(JSON.stringify(@params))  # Clone
		if typeof key == "Object"
			vals = key
			for key, val of keys
				params[key] = val
		else
			params[key] = val
		return "?"+Text.encodeQuery(params)

	setUrl: (url, mode="push") ->
		url = url.replace(/.*?\?/, "")
		@log "setUrl", @history_state["url"], "->", url
		if @history_state["url"] == url
			@content.update()
			return false
		@history_state["url"] = url
		if mode == "replace"
			@cmd "wrapperReplaceState", [@history_state, "", url]
		else
			@cmd "wrapperPushState", [@history_state, "", url]
		@route url
		return false

	loadLocalStorage: ->
		@on_site_info.then =>
			@log "Loading localstorage"
			@cmd "wrapperGetLocalStorage", [], (@local_storage) =>
				@log "Loaded localstorage"
				@local_storage ?= {}
				@local_storage.sites_orderby ?= "peers"
				@local_storage.favorite_sites ?= {}
				@on_local_storage.resolve(@local_storage)

	saveLocalStorage: (cb) ->
		if @local_storage
			@cmd "wrapperSetLocalStorage", @local_storage, (res) =>
				if cb then cb(res)


	onOpenWebsocket: (e) =>
		@reloadSiteInfo()
		@reloadServerInfo()
		for i in [1...10] by 1
			setTimeout ( ->
				Page.projector.scheduleRender()
			), i*1000

	reloadSiteInfo: =>
		@cmd "siteInfo", {}, (site_info) =>
			@address = site_info.address
			@setSiteInfo(site_info)

	reloadServerInfo: =>
		@cmd "serverInfo", {}, (server_info) =>
			@setServerInfo(server_info)

	# Parse incoming requests from UiWebsocket server
	onRequest: (cmd, params) ->
		if cmd == "setSiteInfo" # Site updated
			@setSiteInfo(params)
		else
			@log "Unknown command", params

	setSiteInfo: (site_info) ->
		if site_info.address == @address
			@site_info = site_info
		@site_list.onSiteInfo(site_info)
		@feed_list.onSiteInfo(site_info)
		@file_list.onSiteInfo(site_info)
		@on_site_info.resolve()

	setServerInfo: (server_info) ->
		@server_info = server_info
		if server_info.HelloZeroProxy
			@proxy_info=server_info.HelloZeroProxy #the HelloZeroProxy plugin sets the admin value
		else
			if server_info.multiuser and server_info.master_address
				@proxy_info.admin=true
			else if not server_info.multiuser
				@proxy_info.admin=true
		@projector.scheduleRender()

	# Simple return false to avoid link clicks
	returnFalse: ->
		return false

window.Page = new ZeroHello()
window.Page.createProjector()
