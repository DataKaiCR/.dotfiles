-- Git accounts configuration
-- Maps to SSH hosts in /Users/hstecher/.ssh/config
return {
    ["datakaicr"] = {
        name = "datakaicr",
        email = "hstecher@datakai.net",
        ssh_host = "github.com",
    },
    ["wm"] = {
        name = "hstecher",
        email = "hstecher@westmonroe.com",
        ssh_host = "github.com-wm",
    },
    ["trulieve"] = {
        name = "hstecher",
        email = "hstecher@westmonroe.com", -- Update if you have different email for trulieve
        ssh_host = "github.com-trulieve",
    },
}