import json
from Plugin import PluginManager

@PluginManager.registerTo("UiWebsocket")
class UiWebsocketPlugin(object):
    # HelloZeroProxy override
    def formatServerInfo(self):
        server_info = super(UiWebsocketPlugin, self).formatServerInfo()
        server_info["HelloZeroProxy"] = json.loads(open("plugins/HelloZeroProxy/config.json").read())
        if "Multiuser" in PluginManager.plugin_manager.plugin_names:
            server_info["HelloZeroProxy"]["admin"]=False
        else:
            server_info["HelloZeroProxy"]["admin"]=True
        return server_info
