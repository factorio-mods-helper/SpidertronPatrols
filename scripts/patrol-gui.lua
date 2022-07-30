
PatrolGui = {}

dropdown_contents = {
  {"description.no-limit"},
  {"gui-train.add-time-condition"},
  {"gui-train.add-inactivity-condition"},
  {"gui-patrol.full-inventory-condition"},
  {"gui-patrol.empty-inventory-condition"},
  {"gui-train.add-item-count-condition"},
  {"gui-train.add-robots-inactive-condition"},
  {"gui-patrol.driver-present"},
  {"gui-patrol.driver-not-present"},
}

dropdown_index = {
  ["none"] = 1,
  ["time-passed"] = 2,
  ["inactivity"] = 3,
  ["full-inventory"] = 4,
  ["empty-inventory"] = 5,
  ["item-count"] = 6,
  ["robots-inactive"] = 7,
  ["passenger-present"] = 8,
  ["passenger-not-present"] = 9,
}

dropdown_index_lookup = {
  "none",
  "time-passed",
  "inactivity",
  "full-inventory",
  "empty-inventory",
  "item-count",
  "robots-inactive",
  "passenger-present",
  "passenger-not-present",
}


condition_dropdown_contents = {">", "<", "=", "≥", "≤", "≠"}


local slider_values = {5, 10, 30, 60, 120, 600}
slider_values[0] = 0

local function slider_value_index(input_value)
  for i, slider_value in pairs(slider_values) do
    if input_value == slider_value then
      return i
    elseif input_value < slider_value then
      return i - 1
    end
  end
  return #slider_values
end


local function build_waypoint_player_input(i, waypoint)
  local waypoint_type = waypoint.type
  if waypoint_type == "time-passed" or waypoint_type == "inactivity" then
    return {
      {
        type = "slider", style = "sp_compact_notched_slider", minimum_value = 0, maximum_value = #slider_values, value = slider_value_index(waypoint.wait_time), discrete_slider = true,
        ref = {"time_slider", i},
        actions = {on_value_changed = {gui = "patrol", action = "update_text_field", index = i}}
      },
      {
        type = "textfield", style = "sp_compact_slider_value_textfield", text = tostring(waypoint.wait_time) .. " s",  numeric = true, allow_decimal = false, allow_negative = false, lose_focus_on_confirm = true,
        ref = {"time_textfield", i},
        actions = {
          on_text_changed = {gui = "patrol", action = "update_slider", index = i},
          on_click = {gui = "patrol", action = "remove_s", index = i},
          on_confirmed = {gui = "patrol", action = "add_s", index = i}}
      }
    }
  elseif waypoint_type == "item-count" then
    local info = waypoint.item_count_info
    return {
      {
        type = "choose-elem-button", style = "train_schedule_item_select_button", elem_type = "item", item = info.item_name,
        actions = {on_elem_changed = {gui = "patrol", action = "item_selected", index = i}}
      },
      {
        type = "drop-down", style = "circuit_condition_comparator_dropdown", items = condition_dropdown_contents, selected_index = info.condition,
        actions = {on_selection_state_changed = {gui = "patrol", action = "condition_changed", index = i}}
      },
      {
        type = "textfield", style = "sp_compact_slider_value_textfield", text = tostring(info.count), numeric = true, allow_decimal = false, allow_negative = false, lose_focus_on_confirm = true,
        actions = {on_text_changed = {gui = "patrol", action = "item_count_changed", index = i}}
      },
    }
  end
end

local function generate_button_status(waypoint_info, index)
  local style = "train_schedule_action_button"
  local sprite = "utility/play"
  if waypoint_info.on_patrol and waypoint_info.current_index == index then
    style = "sp_clicked_train_schedule_action_button"
    if waypoint_info.tick_arrived then
      sprite = "utility/stop"
    end
  end
  return {style = style, sprite = sprite}
end

local function build_waypoint_frames(waypoint_info)
  --waypoint_info.waypoints = {{type = "none"}, {type = "time-passed", wait_time = 5}, {type = "inactivity", wait_time = 10}}--{type = "full-inventory"}, {type = "empty-inventory"}, {type = "robots-inactive"}, {type = "passenger-present"}, {type = "passenger-not-present"}, {type = "none"}, {type = "time-passed", wait_time = 5}, {type = "inactivity", wait_time = 10}, {type = "full-inventory"}, {type = "empty-inventory"}, {type = "robots-inactive"}, {type = "passenger-present"}, {type = "passenger-not-present"}, {type = "none"}, {type = "time-passed", wait_time = 5}, {type = "inactivity", wait_time = 10}, {type = "full-inventory"}, {type = "empty-inventory"}, {type = "robots-inactive"}, {type = "passenger-present"}, {type = "passenger-not-present"}}
  local frames = {}
  for i, waypoint in pairs(waypoint_info.waypoints) do
    local button_status = generate_button_status(waypoint_info, i)
    table.insert(frames,
      {type = "frame", name = "schedule-waypoint-" .. i, style = "sp_spidertron_schedule_station_frame", children = {
        {
          type = "sprite-button", name = "status_button", style = button_status.style, mouse_button_filter = {"left"}, sprite = button_status.sprite,
          actions = {on_click = {gui = "patrol", action = "go_to_waypoint", index = i}}
        },
        {
          type = "label", style = "sp_spidertron_waypoint_label", caption = "#" .. tostring(i),
          actions = {on_click = {gui = "patrol", action = "move_camera_to_waypoint", index = i}}
        },
        {
          type = "drop-down", items = dropdown_contents, selected_index = dropdown_index[waypoint.type],
          ref = {"waypoint_dropdown", i},
          actions = {on_selection_state_changed = {gui = "patrol", action = "waypoint_type_changed", index = i}}
        },
        {
          type = "flow", style = "sp_player_input_horizontal_flow", children =
          build_waypoint_player_input(i, waypoint)
        },
        {type = "empty-widget", style = "sp_empty_filler"},
        {
          type = "sprite-button", name = "up", style = "sp_schedule_move_button", mouse_button_filter = {"left"}, sprite = "sp-up-white", hovered_sprite = "sp-up-black", clicked_sprite = "sp-up-black",
          ref = {"waypoint_button", i, "up"},
          actions = {on_click = {gui = "patrol", action = "move_waypoint_up", index = i}}
        },
        {
          type = "sprite-button", name = "down", style = "sp_schedule_move_button", mouse_button_filter = {"left"}, sprite = "sp-down-white", hovered_sprite = "sp-down-black", clicked_sprite = "sp-down-black",
          ref = {"waypoint_button", i, "down"},
          actions = {on_click = {gui = "patrol", action = "move_waypoint_down", index = i}}
        },
        {
          type = "sprite-button", style = "train_schedule_delete_button", mouse_button_filter = {"left"}, sprite = "utility/close_white", hovered_sprite = "utility/close_black", clicked_sprite = "utility/close_black",
          actions = {on_click = {gui = "patrol", action = "delete_waypoint", index = i}}
        },
      }}
    )
  end
  return frames
end

local function build_on_patrol_switch(waypoint_info)
  local switch_state
  if waypoint_info.on_patrol then switch_state = "left" else switch_state = "right" end
  return {
    type = "switch",
    ref = {"on_patrol_switch"},
    actions = {on_switch_state_changed = {action = "toggle_on_patrol"}},
    switch_state = switch_state,
    left_label_caption = {"gui-train.automatic-mode"},
    right_label_caption = {"gui-train.manual-mode"}}
end


local function build_gui(player, spidertron)
  local waypoint_info = get_waypoint_info(spidertron)
  local anchor = {gui = defines.relative_gui_type.spider_vehicle_gui, position = defines.relative_gui_position.right}
  if not next(waypoint_info.waypoints) then return end

  -- Avoid by setting (configurable) max height https://forums.factorio.com/viewtopic.php?f=7&t=98151
  local maximal_height = 930
  if script.active_mods["AutoTrash"] then maximal_height = 650 end
  maximal_height = maximal_height * player.mod_settings["sp-window-height-scale"].value
  return gui.build(player.gui.relative, {
    {
      type = "frame",
      style = "sp_relative_stretchable_frame",
      name = "sp-relative-frame",
      direction = "vertical",
      anchor = anchor,
      style_mods = {maximal_height = maximal_height},
      children = {
        {type = "flow", ref = {"titlebar", "flow"}, children = {
          {type = "label", style = "frame_title", caption = {"gui-train.schedule"}, ignored_by_interaction = true},
          {type = "empty-widget", style = "sp_titlebar_drag_handle", ignored_by_interaction = true},
          --[[{
            type = "sprite-button",
            style = "frame_action_button",
            sprite = "utility/close_white",
            hovered_sprite = "utility/close_black",
            clicked_sprite = "utility/close_black",
            ref = {"titlebar", "close_button"},
            actions = {
              on_click = {gui = "demo", action = "close"}
            }
          }]]
        }},
        {type = "flow", direction = "vertical", style = "inset_frame_container_vertical_flow", children = {
          {type = "frame", style = "inside_shallow_frame", children = {
            --{type = "frame", style = "sp_spidertron_minimap_frame", children = {
              {
                type = "camera", style = "sp_spidertron_camera", position = spidertron.position, surface_index = spidertron.surface.index, zoom = 0.75,
                elem_mods = {entity = spidertron},
                ref = {"camera"},
              },

              --{type = "minimap", style = "minimap", position = spidertron.position, surface_index = spidertron.surface.index, zoom = 2},
            --}},
          }},
          {type = "frame", direction = "vertical", style = "inside_shallow_frame", children = {
            {type = "frame", direction = "horizontal", style = "sp_stretchable_subheader_frame", children = {
              {type = "flow", style = "sp_patrol_schedule_mode_switch_horizontal_flow", children = {
                build_on_patrol_switch(waypoint_info),
                {type = "empty-widget", style = "sp_stretchable_empty_widget"},
                {
                  type = "sprite-button", style = "sp_clicked_tool_button", mouse_button_filter = {"left"}, sprite = "sp-camera", tooltip = {"gui-patrol.toggle-camera"},
                  ref = {"toggle_camera_button"},
                  actions = {on_click = {gui = "patrol", action = "toggle_camera"}},
                },
                {
                  type = "sprite-button", style = "sp_clicked_tool_button", mouse_button_filter = {"left"}, sprite = "utility/center", tooltip = {"gui-patrol.toggle-center-on-spidertron"},
                  ref = {"toggle_center_button"},
                  actions = {on_click = {gui = "patrol", action = "toggle_camera_center_on_spidertron"}},
                },
                {
                  type = "sprite-button", style = "tool_button", mouse_button_filter = {"left"}, sprite = "utility/map", tooltip = {"gui-train.open-in-map"},
                  actions = {on_click = {gui = "patrol", action = "open_location_in_map"}},
                },
                {
                  type = "sprite-button", style = "tool_button_red", mouse_button_filter = {"left"}, sprite = "utility/reset", tooltip = {"gui-patrol.delete-all-waypoints"},
                  actions = {on_click = {gui = "patrol", action = "delete_all_waypoints"}},
                },
              }},
            }},
            {type = "scroll-pane", style = "sp_spidertron_schedule_scroll_pane", ref = {"schedule-scroll-pane"}, horizontal_scroll_policy = "never", vertical_scroll_policy = "auto-and-reserve-space", children =
              build_waypoint_frames(waypoint_info)
            }
          }},
        }},
      }
    }
  })
  --frame.add{type = "label", caption = player.name}
end

function PatrolGui.update_gui_button_states(waypoint_info)
  -- Lightweight version of PatrolGui.update_gui_schedule that only touches the play/stop buttons
  -- Use when not the result of a GUI interaction
  for _, player in pairs(game.players) do
    if player.opened_gui_type == defines.gui_type.entity and player.opened == waypoint_info.spidertron then
      local gui_elements = global.open_gui_elements[player.index]
      if gui_elements then
        local scroll_pane = gui_elements["schedule-scroll-pane"]
        for i, frame in pairs(scroll_pane.children) do
          local button_status = generate_button_status(waypoint_info, i)
          local status_button = frame.status_button
          status_button.style = button_status.style
          status_button.sprite = button_status.sprite
        end
      end
    end
  end
end

function PatrolGui.update_gui_schedule(waypoint_info)
  local spidertron = waypoint_info.spidertron

  for _, player in pairs(game.players) do
    if player.opened_gui_type == defines.gui_type.entity and player.opened == waypoint_info.spidertron then
      local gui_elements = global.open_gui_elements[player.index]
      if gui_elements then
        local scroll_pane = gui_elements["schedule-scroll-pane"]
        scroll_pane.clear()
        local waypoint_frames = build_waypoint_frames(waypoint_info)
        if next(waypoint_frames) then
          local new_gui_elements = gui.build(scroll_pane, waypoint_frames)
          -- Copy across new gui elements to global storage
          gui_elements.waypoint_dropdown = new_gui_elements.waypoint_dropdown
          gui_elements.time_slider = new_gui_elements.time_slider
          gui_elements.time_textfield = new_gui_elements.time_textfield
          gui_elements.waypoint_button = new_gui_elements.waypoint_button
        else
          -- Clear GUI
          local relative_frame = player.gui.relative["sp-relative-frame"]
          if relative_frame then
            relative_frame.destroy()
          end
          global.open_gui_elements[player.index] = nil
        end
      else
        global.open_gui_elements[player.index] = build_gui(player, spidertron)
      end
    end
  end
end

function PatrolGui.update_gui_switch(waypoint_info)
  for _, player in pairs(game.players) do
    if player.opened_gui_type == defines.gui_type.entity and player.opened == waypoint_info.spidertron then
      local gui_elements = global.open_gui_elements[player.index]
      if gui_elements then
        local switch = gui_elements.on_patrol_switch
        gui.update(
          switch,
          {elem_mods = {switch_state = build_on_patrol_switch(waypoint_info).switch_state}}
        )
        PatrolGui.update_gui_button_states(waypoint_info)
      end
    end
  end
end

function PatrolGui.update_gui_highlights()
  -- Called every tick
  for player_index, button_info in pairs(global.player_highlights) do
    local button = button_info.button
    local tick_started = button_info.tick_started
    if button and button.valid then
      if (game.tick - tick_started) > 20 then
        button.style = "sp_schedule_move_button"
        button.sprite = "sp-" .. button.name .. "-white"
        global.player_highlights[player_index] = nil
      end
    else
      global.player_highlights[player_index] = nil
    end
  end
end


function PatrolGui.clear_highlights_for_player(player)
  local button_info = global.player_highlights[player.index]
  if button_info then
    local button = button_info.button
    if button and button.valid then
      button.style = "sp_schedule_move_button"
      button.sprite = "sp-" .. button.name .. "-white"
    end
    global.player_highlights[player.index] = nil
  end
end


function PatrolGui.on_gui_opened(event)
  local player = game.get_player(event.player_index)
  local entity = event.entity
  if entity and entity.type == "spider-vehicle" then
    update_player_render_paths(player)

    local relative_frame = player.gui.relative["sp-relative-frame"]
    if relative_frame then
      relative_frame.destroy()
    end
    global.open_gui_elements[player.index] = build_gui(player, entity)
  end
end


function PatrolGui.on_gui_closed(event)
  local player = game.get_player(event.player_index)
  local entity = event.entity
  if entity and entity.type == "spider-vehicle" then
    local relative_frame = player.gui.relative["sp-relative-frame"]
    if relative_frame then
      relative_frame.destroy()
    end
    global.open_gui_elements[player.index] = nil

    -- Spidertron's color could have changed
    update_render_text(entity)
  end
end

function PatrolGui.handle_action(action)
  local player = game.get_player(event.player_index)
  local spidertron = player.opened
  if not spidertron then return end
  assert(spidertron.type == "spider-vehicle")
  local gui_elements = global.open_gui_elements[player.index]

  local action_name = action.action

  if action_name == "go_to_waypoint" then
    -- 'Play' button
    local waypoint_info = global.spidertron_waypoints[spidertron.unit_number]
    if not waypoint_info.on_patrol or action.index ~= waypoint_info.current_index then
      set_on_patrol(true, spidertron, waypoint_info)
      spidertron_control.go_to_next_waypoint(spidertron, action.index)
    end
  elseif action_name == "delete_waypoint" then
    -- Delete waypoint button
    local waypoint_info = global.spidertron_waypoints[spidertron.unit_number]
    local waypoints = waypoint_info.waypoints
    local index_to_delete = action.index
    if waypoint_info.current_index > index_to_delete then
      waypoint_info.current_index = waypoint_info.current_index - 1
    end
    rendering.destroy(waypoints[index_to_delete].render_id)
    table.remove(waypoints, index_to_delete)
    if not next(waypoints) then
      -- All waypoints are gone, so cleanup
      clear_spidertron_waypoints(spidertron)
    end
    if not waypoints[index_to_delete] then
      waypoint_info.current_index = 1
    end
    if waypoint_info.on_patrol then
      spidertron_control.go_to_next_waypoint(spidertron, waypoint_info.current_index)
    end
    PatrolGui.update_gui_schedule(waypoint_info)
    update_render_text(spidertron)

  elseif action_name == "delete_all_waypoints" then
    clear_spidertron_waypoints(spidertron)

  elseif action_name == "move_waypoint_up" then
    local waypoint_info = global.spidertron_waypoints[spidertron.unit_number]
    local waypoints = waypoint_info.waypoints
    local index_to_move = action.index
    if index_to_move ~= 1 then
      local index_above = action.index - 1

      --[[
      -- TODO Get shift-click working. Currently swaps top and current instead of shifting all down
      if event.shift then
        index_above = 1
      end
      ]]

      local waypoint_to_move = util.table.deepcopy(waypoints[index_to_move])
      local waypoint_above = util.table.deepcopy(waypoints[index_above])

      waypoints[index_above] = waypoint_to_move
      waypoints[index_to_move] = waypoint_above

      local current_index = waypoint_info.current_index
      if current_index then
        if current_index == index_above then waypoint_info.current_index = index_to_move end
        if current_index == index_to_move then waypoint_info.current_index = index_above end
      end

      PatrolGui.update_gui_schedule(waypoint_info)
      update_render_text(spidertron)

      local button = gui_elements.waypoint_button[index_above].up
      button.style = "sp_selected_schedule_move_button"
      button.sprite = "sp-up-black"

      PatrolGui.clear_highlights_for_player(player)
      global.player_highlights[player.index] = {button = button, tick_started = game.tick}
    end
  elseif action_name == "move_waypoint_down" then
    local waypoint_info = global.spidertron_waypoints[spidertron.unit_number]
    local waypoints = waypoint_info.waypoints
    local index_to_move = action.index
    if index_to_move ~= #waypoints then
      local index_below = action.index + 1

      --[[
      if event.shift then
        index_below = #waypoints
      end
      ]]

      local waypoint_to_move = util.table.deepcopy(waypoints[index_to_move])
      local waypoint_below = util.table.deepcopy(waypoints[index_below])

      waypoints[index_below] = waypoint_to_move
      waypoints[index_to_move] = waypoint_below

      local current_index = waypoint_info.current_index
      if current_index then
        if current_index == index_below then waypoint_info.current_index = index_to_move end
        if current_index == index_to_move then waypoint_info.current_index = index_below end
      end

      PatrolGui.update_gui_schedule(waypoint_info)
      update_render_text(spidertron)

      local button = gui_elements.waypoint_button[index_below].down
      button.style = "sp_selected_schedule_move_button"
      button.sprite = "sp-down-black"

      PatrolGui.clear_highlights_for_player(player)
      global.player_highlights[player.index] = {button = button, tick_started = game.tick}
    end

  elseif action_name == "open_location_in_map" then
    local camera = gui_elements.camera
    local entity = camera.entity
    if entity then
      player.open_map(entity.position, 0.109)  -- 0.109 deduced by experimentation to be close to vanilla 'open in map' scale
    else
      log("Opening map in position, " .. serpent.block(camera.position))
      player.open_map(camera.position, 0.109)
    end
    player.opened = nil
  elseif action_name == "toggle_camera" then
    if gui_elements then
      local camera_button = gui_elements.toggle_camera_button
      local camera = gui_elements.camera
      if camera_button.style.name == "tool_button" then
        -- Button was clicked
        camera_button.style = "sp_clicked_tool_button"
        camera.parent.visible = true
      else
        -- Button was unclicked
        camera_button.style = "tool_button"
        camera.parent.visible = false
      end
    end

  elseif action_name == "toggle_camera_center_on_spidertron" then
    -- Recenter button
    if gui_elements then
      local center_button = gui_elements.toggle_center_button
      local camera = gui_elements.camera
      if center_button.style.name == "tool_button" then
        -- Button was clicked
        center_button.style = "sp_clicked_tool_button"
        camera.entity = spidertron
      else
        -- Button was unclicked
        center_button.style = "tool_button"
        camera.entity = nil
        camera.position = spidertron.position
      end
    end

  elseif action_name == "move_camera_to_waypoint" then
    -- Numbered labels
    if gui_elements then
      local center_button = gui_elements.toggle_center_button
      local camera = gui_elements.camera
      local waypoint_info = global.spidertron_waypoints[spidertron.unit_number]

      center_button.style = "tool_button"
      camera.entity = nil
      camera.position = waypoint_info.waypoints[action.index].position
    end
  elseif action_name == "remove_s" then
    local textfield = gui_elements.time_textfield[action.index]
    local current_text = textfield.text
    if string.sub(current_text, -2, -1) == " s" then
      textfield.text = string.sub(textfield.text, 0, -3)
    end

  elseif action_name == "toggle_on_patrol" then
    local switch = gui_elements.on_patrol_switch
    local waypoint_info = global.spidertron_waypoints[spidertron.unit_number]
    local on_patrol = switch.switch_state == "left"
    set_on_patrol(on_patrol, spidertron, waypoint_info)

  elseif action_name == "waypoint_type_changed" then
    local dropdown = gui_elements.waypoint_dropdown[action.index]
    local waypoint_info = global.spidertron_waypoints[spidertron.unit_number]
    local waypoint = waypoint_info.waypoints[action.index]
    local new_waypoint_type = dropdown_index_lookup[dropdown.selected_index]
    if waypoint.type ~= new_waypoint_type then
      waypoint.type = new_waypoint_type
      if new_waypoint_type == "time-passed" then
        waypoint.wait_time = 30
      elseif new_waypoint_type == "inactivity" then
        waypoint.wait_time = 5
      else
        waypoint.wait_time = nil
      end
      if new_waypoint_type == "item-count" then
        waypoint.item_count_info = {item_name = nil, condition = 4, count = 100}
      else
        waypoint.item_count_info = nil
      end
      PatrolGui.update_gui_schedule(waypoint_info)
    end

  elseif action_name == "condition_changed" then
    local dropdown = event.element
    local waypoint_info = global.spidertron_waypoints[spidertron.unit_number]
    local item_count_info = waypoint_info.waypoints[action.index].item_count_info
    item_count_info.condition = dropdown.selected_index

  elseif action_name == "update_text_field" then
    local wait_time = slider_values[gui_elements.time_slider[action.index].slider_value]
    gui_elements.time_textfield[action.index].text = tostring(wait_time) .. " s"

    set_waypoint_time(wait_time, player.opened, action.index)

  elseif action_name == "item_selected" then
    local elem_button = event.element
    local waypoint_info = global.spidertron_waypoints[spidertron.unit_number]
    local item_count_info = waypoint_info.waypoints[action.index].item_count_info
    item_count_info.item_name = elem_button.elem_value

  elseif action_name == "update_slider" then
    local text = gui_elements.time_textfield[action.index].text
    if text == "" then text = "0" end
    local wait_time = tonumber(text)
    gui_elements.time_slider[action.index].slider_value = slider_value_index(wait_time)
    set_waypoint_time(wait_time, player.opened, action.index)

  elseif action_name == "item_count_changed" then
    local waypoint_info = global.spidertron_waypoints[spidertron.unit_number]
    local item_count_info = waypoint_info.waypoints[action.index].item_count_info
    local text = event.element.text
    if text == "" then text = "0" end
    local item_count = tonumber(text)
    item_count_info.count = item_count

  elseif action_name == "add_s" then
    local textfield = gui_elements.time_textfield[action.index]
    textfield.text = textfield.text .. " s"
  end

end


function set_on_patrol(on_patrol, spidertron, waypoint_info)
  if on_patrol then
    --local next_waypoint = waypoint_info.waypoints[waypoint_info.current_index] or waypoint_info.waypoints[1]
    spidertron_control.go_to_next_waypoint(spidertron, waypoint_info.current_index)
  else
    spidertron.autopilot_destination = nil
  end
  waypoint_info.on_patrol = on_patrol
  PatrolGui.update_gui_switch(waypoint_info)

end


function set_waypoint_time(wait_time, spidertron, waypoint_index)
  local waypoint_info = get_waypoint_info(spidertron)
  local waypoint = waypoint_info.waypoints[waypoint_index]
  waypoint.wait_time = wait_time
end

return PatrolGui