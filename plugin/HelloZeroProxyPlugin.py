import json
from Plugin import PluginManager

@PluginManager.registerTo("UiWebsocket")
class UiWebsocketPlugin(object):
    # HelloZeroProxy override
    def formatServerInfo(self):
        server_info = super(UiWebsocketPlugin, self).formatServerInfo()
        server_info["HelloZeroProxy"] = json.loads(open("plugins/HelloZeroProxy/config.json").read())
        return server_info
