local math2d = require "__core__.lualib.math2d"

local function on_built(event)
  local entity = event.created_entity or event.entity
  if entity then
    if entity.name == "sp-spidertron-dock-0" then
      global.spidertron_docks[entity.unit_number] = {dock = entity, name = "Default"}
      script.register_on_entity_destroyed(entity)
    elseif entity.type == "spider-vehicle" then
        script.register_on_entity_destroyed(entity)
    else
      -- from on_entity_cloned, a non-zero-capacity dock has been created
      entity = replace_dock(entity, "sp-spidertron-dock-0")
      global.spidertron_docks[entity.unit_number] = {dock = entity, name = "Default"}
    end
  end
end
script.on_event(defines.events.on_built_entity, on_built, {{filter = "name", name = "sp-spidertron-dock-0"}, {filter = "type", type = "spider-vehicle"}})
script.on_event(defines.events.on_robot_built_entity, on_built, {{filter = "name", name = "sp-spidertron-dock-0"}, {filter = "type", type = "spider-vehicle"}})
script.on_event(defines.events.script_raised_revive, on_built, {{filter = "name", name = "sp-spidertron-dock-0"}, {filter = "type", type = "spider-vehicle"}})
script.on_event(defines.events.script_raised_built, on_built, {{filter = "name", name = "sp-spidertron-dock-0"}, {filter = "type", type = "spider-vehicle"}})

local function on_entity_cloned(event)
  local entity = event.destination
  if entity.type == "spider-vehicle" or string.sub(entity.name, 0, 19) == "sp-spidertron-dock-" then
    on_built{entity = entity}
  end
end
script.on_event(defines.events.on_entity_cloned, on_entity_cloned, {{filter = "type", type = "container"}, {filter = "type", type = "logistic-container"}, {filter = "type", type = "spider-vehicle"}})

function on_entity_destroyed(event)
  local unit_number = event.unit_number
  if unit_number then
    -- Entity is a dock
    local dock_data = global.spidertron_docks[unit_number]
    if dock_data then
      local spidertron = dock_data.connected_spidertron
      if spidertron and spidertron.valid then
        global.spidertrons_docked[spidertron.unit_number] = nil
      end
      global.spidertron_docks[unit_number] = nil
    end

    -- Entity is a spidertron
    local dock_unit_number = global.spidertrons_docked[unit_number]
    if dock_unit_number then
      global.spidertrons_docked[unit_number] = nil

      dock_data = global.spidertron_docks[dock_unit_number]
      if dock_data then
        local dock = dock_data.dock
        if dock.valid then
          dock.surface.create_entity{name = "flying-text", position = dock.position, text = {"flying-text.spidertron-removed"}}

          dock = replace_dock(dock, "sp-spidertron-dock-0")
          global.spidertron_docks[dock.unit_number] = {dock = dock, name = dock_data.name}
        end
      end
    end
  end
end


script.on_event(defines.events.on_pre_player_mined_item,
  function(event)
    -- Dock inventories should never return their contents to the player
    -- because all their items are duplicates from the spidertron's inventory
    local dock = event.entity
    if dock and string.sub(dock.name, 0, 14) == "sp-spidertron-" then
      local dock_inventory = dock.get_inventory(defines.inventory.chest)
      dock_inventory.clear()
    end
  end
)


function replace_dock(dock, new_dock_name)
  local health = dock.health
  local last_user = dock.last_user
  --local circuit_connected_entities = dock.circuit_connected_entities
  local circuit_connection_definitions = dock.circuit_connection_definitions
  local to_be_deconstructed = dock.to_be_deconstructed()

  local request_from_buffers
  local requests
  if dock.type == "logistic-container" then
    request_from_buffers = dock.request_from_buffers
    requests = {}
    for slot_index = 1, dock.request_slot_count do
      requests[slot_index] = dock.get_request_slot(slot_index)
    end
  end

  local players_with_gui_open = {}
  for _, player in pairs(game.connected_players) do
    if player.opened == dock then
      table.insert(players_with_gui_open, player)
    end
  end

  old_dock = dock
  dock = dock.surface.create_entity{name = new_dock_name, position = dock.position, force = dock.force, spill = false, create_build_effect_smoke = false, fast_replace = true}

  dock.health = health
  dock.last_user = last_user

  for _, definition in pairs(circuit_connection_definitions) do
    dock.connect_neighbour{
      wire = definition.wire,
      target_entity = definition.target_entity,
      target_circuit_id = definition.target_circuit_id
    }
  end

  if to_be_deconstructed then
    dock.order_deconstruction(dock.force)
  end

  if request_from_buffers then
    dock.request_from_buffers = request_from_buffers
  end
  if requests then
    for slot_index, request in pairs(requests) do
      dock.set_request_slot(request, slot_index)
    end
  end


  for _, player in pairs(players_with_gui_open) do
    if player.valid then
      player.opened = dock
    end
  end

  script.register_on_entity_destroyed(dock)
  old_dock.destroy()

  return dock
end

local function get_filters(inventory)
  if not inventory.is_filtered() then return {} end
  local filters = {}
  for i = 1, #inventory do
    local filter = inventory.get_filter(i)
    if filter then
      filters[i] = filter
    end
  end
  return filters
end

local function update_dock_inventory(dock, spidertron, previous_contents)
  local previous_items = previous_contents.items
  local previous_filters = previous_contents.filters
  if not previous_items then
    -- Pre-2.2.7 migration
    previous_items = previous_contents
    previous_filters = {}
  end

  local spidertron_inventory = spidertron.get_inventory(defines.inventory.spider_trunk)
  local spidertron_contents = spidertron_inventory.get_contents()
  local spidertron_filters = get_filters(spidertron_inventory)

  local dock_inventory = dock.get_inventory(defines.inventory.chest)
  local dock_contents = dock_inventory.get_contents()
  local dock_filters = get_filters(dock_inventory)

  local spidertron_filter_diff = filter_table_diff(spidertron_filters, previous_filters)
  for index, filter in pairs(spidertron_filter_diff) do
    if filter == -1 then
      dock_inventory.set_filter(index, nil)
    else
      dock_inventory.set_filter(index, filter)
    end
  end

  local dock_filter_diff = filter_table_diff(dock_filters, previous_filters)
  for index, filter in pairs(dock_filter_diff) do
    if filter == -1 then
      spidertron_inventory.set_filter(index, nil)
    else
      spidertron_inventory.set_filter(index, filter)
    end
  end

  local spidertron_diff = table_diff(spidertron_contents, previous_items)
  for item_name, count in pairs(spidertron_diff) do
    if count > 0 then
      dock_inventory.insert{name = item_name, count = count}
    else
      dock_inventory.remove{name = item_name, count = -count}
    end
  end

  local dock_diff = table_diff(dock_contents, previous_items)
  for item_name, count in pairs(dock_diff) do
    if count > 0 then
      spidertron_inventory.insert{name = item_name, count = count}
    else
      spidertron_inventory.remove{name = item_name, count = -count}
    end
  end

  spidertron_inventory.sort_and_merge()
  dock_inventory.sort_and_merge()

  local new_spidertron_contents = {items = spidertron_inventory.get_contents(), filters = get_filters(spidertron_inventory)}
  --local new_dock_contents = dock_inventory.get_contents()
  --assert(table_equals(new_spidertron_contents, new_dock_contents))  -- TODO Remove for release
  return new_spidertron_contents
end


local function increase_bounding_box(bounding_box)
  local left_top = bounding_box.left_top
  local right_bottom = bounding_box.right_bottom
  local increase = 1.5
  return {left_top = {x = left_top.x - increase, y = left_top.y - increase}, right_bottom = {x = right_bottom.x + increase, y = right_bottom.y + increase}}
end

local function update_dock(dock_data)
  local dock = dock_data.dock
  local delete = false
  if dock.valid then
    local surface = dock.surface
    local spidertron = dock_data.connected_spidertron
    if spidertron and spidertron.valid then
      -- Dock is connected. Check update inventories, then undock if needed
      dock_data.previous_contents = update_dock_inventory(dock, spidertron, dock_data.previous_contents)

      -- 0.1 * 216 ~ 20km/h
      if dock.to_be_deconstructed() or spidertron.speed > 0.2 or not math2d.bounding_box.collides_with(increase_bounding_box(dock.bounding_box), spidertron.bounding_box) then
        -- Spidertron needs to become undocked
        global.spidertrons_docked[spidertron.unit_number] = nil
        surface.create_entity{name = "flying-text", position = dock.position, text = {"flying-text.spidertron-undocked"}}

        dock = replace_dock(dock, "sp-spidertron-dock-0")
        global.spidertron_docks[dock.unit_number] = {dock = dock, name = dock_data.name}
        delete = true
      end
    else
      if spidertron then
        -- `spidertron` is not valid
        dock_data = {dock = dock_data.dock, name = dock_data.name}
      end

      -- Check if dock should initiate connection
      if not dock.to_be_deconstructed() then
        local nearby_spidertrons = surface.find_entities_filtered{type = "spider-vehicle", area = dock.bounding_box, force = dock.force}
        local spidertrons_docked = global.spidertrons_docked
        for _, spidertron in pairs(nearby_spidertrons) do
          if not spidertrons_docked[spidertron.unit_number] and spidertron.speed < 0.1 and spidertron.name ~= "companion" then
            local inventory = spidertron.get_inventory(defines.inventory.spider_trunk)
            local inventory_size = #inventory
            if inventory_size > 0 then
              -- Switch dock entity out for one with the correct inventory size
              dock = replace_dock(dock, "sp-spidertron-dock-" .. inventory_size)
              dock_data.dock = dock
              global.spidertron_docks[dock.unit_number] = dock_data
              delete = true

              dock_data.connected_spidertron = spidertron
              spidertrons_docked[spidertron.unit_number] = dock.unit_number
              --game.print("Spidertron docked")
              surface.create_entity{name = "flying-text", position = dock.position, text = {"flying-text.spidertron-docked"}}

              local spidertron_contents = {items = inventory.get_contents(), filters = get_filters(inventory)}
              local dock_inventory = dock.get_inventory(defines.inventory.chest)
              for index, filter in pairs(spidertron_contents.filters) do
                dock_inventory.set_filter(index, filter)
              end
              for item_name, count in pairs(spidertron_contents.items) do
                dock_inventory.insert{name = item_name, count = count}
              end
              dock_data.previous_contents = spidertron_contents
              break
            end
          end
        end
      end
    end
  else
    delete = true
  end
  return nil, delete  -- Deletes dock from global table
end

local function on_tick()
  if next(global.spidertron_docks) then
    -- TODO Replace '20' with configurable setting?
    global.from_k = for_n_of(global.spidertron_docks, global.from_k, 20, update_dock)
  end
end

return {on_entity_destroyed = on_entity_destroyed, on_tick = on_tick}