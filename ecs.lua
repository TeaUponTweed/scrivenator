local ecs = {}

ecs.NONE = {}
ecs.KILL = {}
ecs.REMOVE_COMPONENT = {}
ecs.entity_num = 0
ecs.components_constructors = {}
ecs.components = {}
ecs.entities = {}
ecs.tokill ={}


function ecs:with(name, args, id)
    id = id or self.entity_num
    self.components[name][self.entity_num] = self.components_constructors[name](unpack(args))
    return self
end

function ecs:new_entity()
    self.entity_num = self.entity_num + 1
    self.entities[self.entity_num] = self.NONE
    return self
end

function  ecs:remove_entity(id)
    self.entities[id] = nil
end

function ecs:new_component(name, func)
    assert(name, 'need name')
    assert(not (self.components[name] or self.components_constructors[name]),
           'need unique component name')
    self.components_constructors[name] = func
    self.components[name] = {}
end

function ecs:add_component(name, args, id)
    assert(id, "need id")
    assert(self.entities[id], "unkown id " .. id)
    assert(not self.components[name][id], component .. " already present for " .. id)
    self:with(name, args, id)
end

function ecs:process(component_names, func)
    if type(component_names) == "string" then
        local component_name
        component_name = component_names
        assert(self.components[component_name], "no compontent " .. component_name)
        for id, component in ipairs(self.components[component_name]) do
            local ret
            ret = func(component)
            if ret == self.NONE then
                self.components[id] = nil
            elseif ret then
                self.components[id] = ret
            end
        end
    else
        assert(type(component_names) == "table", "need table of components")
        for id, _ in ipairs(self.entities) do
            for _, component_name in ipairs(component_names) do
                assert(self.components[component_name], "unkown component " .. component_name)
                if not self.components[component_name][id] then
                    goto continue
                end
            end
            local args
            args = {}
            for i=1,#component_names do
                args[i] = self.components[component_names[i]][id]
            end
            local ret = func(unpack(args))
            if ret == ecs.KILL then
                ecs.tokill[#ecs.tokill+1] = id
            elseif ret == ecs.REMOVE_COMPONENT:
                self.components[component_name][id] = nil
            elseif ret then
                self.components[component_name][id] = ret
            end
            ::continue::
        end
    end
end

return ecs
