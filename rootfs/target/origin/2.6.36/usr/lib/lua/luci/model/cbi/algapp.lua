m = Map("algapp", translate("ALG"),
        translate("Application-level Gateway Rules"))

s = m:section(TypedSection, "rule")
s.addremove = false

o = s:option(Flag, "enabled", translate("Enabled"))

return m
