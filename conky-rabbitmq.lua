local http = require('socket.http')
local json = require('cjson')

do
  -- URL of the RabbitMQ management api, including basic authentication username and password
  local RABBITMQ_URL = 'http://guest:guest@localhost:15672/api/queues'
  -- Columns/individual queue statistics to be returned from the API
  local RABBITMQ_COLUMNS = 'columns=name,messages,consumers,message_stats.ack_details,message_stats.publish_details,message_stats.deliver_details'
  -- Frequency (in seconds) to refresh data from the RabbitMQ manegement API
  local RABBITMQ_REFRESH_INTERVAL = 5

  local rabbitmq_url = RABBITMQ_URL..'?'..RABBITMQ_COLUMNS
  local next_update
  local stats

  local function multi_key(mk, t)
    k, newmk = mk:match('([^.]+)%.(.*)')
    if not k then
      return t[mk]
    elseif not t[k] then
      return 0
    else
      return multi_key(newmk, t[k])
    end
  end

  local function refresh_rabbitmq_stats()
    local now = os.time()

    if next_update == nil or now >= next_update then
      next_update = now + RABBITMQ_REFRESH_INTERVAL
      local body, code, headers = http.request(rabbitmq_url)

      if code ~= 200 then
        print('conky-rabbitmq: Received non 200 response from RabbitMQ:', code)
      else
        stats = json.decode(body)
      end
    end
  end

  function conky_rabbitmq_stats(name, field)
    refresh_rabbitmq_stats()

    if not stats then
      return
    end

    for i = 1, #stats do
      if stats[i].name == name then
        return multi_key(field, stats[i]) or 0
      end
    end
  end

  function conky_rabbitmq_stats_sum(pattern, field)
    local count = 0

    refresh_rabbitmq_stats()

    if not stats then
      return
    end

    for i = 1, #stats do
      if string.match(stats[i].name, pattern) then
        val = multi_key(field, stats[i])
        if val then
          count = count + val
        end
      end
    end
    return count
  end

  function conky_rabbitmq_stats_max(pattern, field)
    local max

    refresh_rabbitmq_stats()

    if not stats then
      return
    end

    for i = 1, #stats do
      if string.match(stats[i].name, pattern) then
        val = multi_key(field, stats[i])
        if val then
          if max == nil then
            max = val
          elseif val > max then
            max = val
          end
        end
      end
    end
    return max
  end

  function conky_rabbitmq_stats_min(pattern, field)
    local min

    refresh_rabbitmq_stats()

    if not stats then
      return
    end

    for i = 1, #stats do
      if string.match(stats[i].name, pattern) then
        val = multi_key(field, stats[i])
        if val then
          if min == nil then
            min = val
          elseif val < min then
            min = val
          end
        end
      end
    end
    return min
  end

  function conky_rabbitmq_next_refresh()
    if next_update == nil then
      return 0
    else
      return next_update - os.time()
    end
  end
end
